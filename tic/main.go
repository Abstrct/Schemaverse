// The Schemaverse ticker.
//
// One tic is:
//
//	CALL tic_open()      round rollover, then ship movement
//	fleet scripts        every enabled fleet, run as its owning player
//	CALL tic_close()     ship actions, mining, health, stats, tic_seq++
//
// The two procedures own all the game physics; this program only sequences them
// and runs the fleet phase. Fleet scripts must execute in a session whose
// authenticated user is the player (role switching is escapable with RESET
// ROLE), so the runner opens a connection per player over the trusted unix
// socket. Each script gets statement_timeout = the fleet's purchased runtime
// and a context deadline a little longer as a hard backstop. A fleet that runs
// past its runtime is disabled, as ref.pl used to do.
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5"
)

type fleet struct {
	ID           int
	Username     string
	ErrorChannel string
	Runtime      time.Duration
}

func main() {
	interval := time.Duration(envInt("TIC_SECONDS", 60)) * time.Second
	concurrency := envInt("FLEET_CONCURRENCY", 1)
	log := slog.New(slog.NewTextHandler(os.Stdout, nil))
	ctx := context.Background()

	base, err := pgx.ParseConfig("") // PGHOST, PGUSER, PGDATABASE, PGPASSWORD from the environment
	if err != nil {
		log.Error("bad connection config", "err", err)
		os.Exit(1)
	}
	log.Info("schemaverse ticker starting", "host", base.Host, "database", base.Database, "owner", base.User,
		"interval", interval, "fleet_concurrency", concurrency)

	for turn := 1; ; turn++ {
		started := time.Now()
		if err := runTic(ctx, log, base, concurrency); err != nil {
			log.Error("tic failed", "turn", turn, "err", err)
		}
		if rest := interval - time.Since(started); rest > 0 {
			time.Sleep(rest)
		}
	}
}

func runTic(ctx context.Context, log *slog.Logger, base *pgx.ConnConfig, concurrency int) error {
	owner, err := pgx.ConnectConfig(ctx, base)
	if err != nil {
		return fmt.Errorf("connect as owner: %w", err)
	}
	defer owner.Close(ctx)

	var tic int64
	if err := owner.QueryRow(ctx, "SELECT last_value FROM tic_seq").Scan(&tic); err != nil {
		return err
	}
	log.Info("tic open", "tic", tic)

	// Procedures commit internally, so they must run outside a transaction and
	// through the simple protocol.
	if _, err := owner.Exec(ctx, "CALL tic_open()", pgx.QueryExecModeSimpleProtocol); err != nil {
		return fmt.Errorf("tic_open: %w", err)
	}

	fleets, err := loadFleets(ctx, owner)
	if err != nil {
		return err
	}
	ok, failed := runFleets(ctx, log, base, owner, fleets, concurrency)

	if _, err := owner.Exec(ctx, "CALL tic_close()", pgx.QueryExecModeSimpleProtocol); err != nil {
		return fmt.Errorf("tic_close: %w", err)
	}
	log.Info("tic closed", "tic", tic, "fleets", len(fleets), "ok", ok, "failed", failed)
	return nil
}

func loadFleets(ctx context.Context, owner *pgx.Conn) ([]fleet, error) {
	rows, err := owner.Query(ctx, `
		SELECT fleet.id, player.username, player.error_channel,
		       EXTRACT(epoch FROM fleet.runtime)::float8
		  FROM fleet JOIN player ON player.id = fleet.player_id
		 WHERE fleet.enabled AND fleet.runtime > '0 minutes'::interval
		 ORDER BY player.username, fleet.id`)
	if err != nil {
		return nil, fmt.Errorf("load fleets: %w", err)
	}
	defer rows.Close()
	var out []fleet
	for rows.Next() {
		var f fleet
		var secs float64
		if err := rows.Scan(&f.ID, &f.Username, &f.ErrorChannel, &secs); err != nil {
			return nil, err
		}
		f.Runtime = time.Duration(secs * float64(time.Second))
		out = append(out, f)
	}
	return out, rows.Err()
}

// runFleets executes every fleet script. With concurrency 1 the order is the
// classic one (by username, then fleet id). Higher values run fleets in
// parallel; the schema's table locks keep that correct but change fairness.
func runFleets(ctx context.Context, log *slog.Logger, base *pgx.ConnConfig, owner *pgx.Conn, fleets []fleet, concurrency int) (ok, failed int) {
	type result struct {
		f       fleet
		err     error
		elapsed time.Duration
	}
	results := make(chan result)
	sem := make(chan struct{}, max(concurrency, 1))
	for _, f := range fleets {
		go func(f fleet) {
			sem <- struct{}{}
			defer func() { <-sem }()
			started := time.Now()
			err := runFleet(ctx, base, f)
			results <- result{f, err, time.Since(started)}
		}(f)
	}
	for range fleets {
		r := <-results
		if r.err == nil && r.elapsed < r.f.Runtime {
			ok++
			continue
		}
		failed++
		// The script's own failure was already logged as a FLEET_FAIL event by
		// run_fleet_script. Running past the paid runtime is the runner's call:
		// disable the fleet and tell the player on their error channel.
		if r.elapsed >= r.f.Runtime || errors.Is(r.err, context.DeadlineExceeded) {
			log.Warn("fleet exceeded runtime, disabling", "fleet", r.f.ID, "player", r.f.Username, "elapsed", r.elapsed, "runtime", r.f.Runtime)
			msg := fmt.Sprintf("Fleet script %d ran for %s, past its %s runtime, and has been disabled", r.f.ID, r.elapsed.Round(time.Millisecond), r.f.Runtime)
			if _, err := owner.Exec(ctx, "SELECT disable_fleet($1), pg_notify($2, $3)", r.f.ID, r.f.ErrorChannel, msg); err != nil {
				log.Error("could not disable fleet", "fleet", r.f.ID, "err", err)
			}
		} else {
			log.Warn("fleet script failed", "fleet", r.f.ID, "player", r.f.Username, "err", r.err)
		}
	}
	return ok, failed
}

func runFleet(ctx context.Context, base *pgx.ConnConfig, f fleet) error {
	cfg := base.Copy()
	cfg.User = f.Username
	cfg.Password = "" // trusted socket; the runner never holds player passwords
	cfg.RuntimeParams["application_name"] = strconv.Itoa(f.ID)
	cfg.RuntimeParams["statement_timeout"] = strconv.FormatInt(f.Runtime.Milliseconds(), 10)

	// Hard backstop a little past the runtime: pgx cancels the query and drops
	// the connection when the deadline passes.
	ctx, cancel := context.WithTimeout(ctx, f.Runtime+5*time.Second)
	defer cancel()

	conn, err := pgx.ConnectConfig(ctx, cfg)
	if err != nil {
		return fmt.Errorf("connect as %s: %w", f.Username, err)
	}
	defer conn.Close(context.Background())

	var completed bool
	if err := conn.QueryRow(ctx, "SELECT run_fleet_script($1)", f.ID).Scan(&completed); err != nil {
		return err
	}
	if !completed {
		return errors.New("run_fleet_script reported failure (see FLEET_FAIL event)")
	}
	return nil
}

func envInt(name string, def int) int {
	if v, err := strconv.Atoi(os.Getenv(name)); err == nil && v > 0 {
		return v
	}
	return def
}
