# Schemaverse brand and interface design notes

Derived from the original assets in `docs/brand/`: the DEF CON 19 pin set
(`pins/`), the colour logo sheet (`logo-sheet.svg`, exported from
`schemaverse-logo.ai`), the wordmark used by TrainingWheels
(`logo-wordmark.png`), and the "Boss Schemaverse" elephant mech (`boss-mech.png`).

The new web interface should look like it was cut from the same sheet as the pins.

## Palette

Sampled from the pins. Two inks and paper, nothing else.

| Token | Hex | Used for |
|---|---|---|
| `--ink` | `#464749` | Ship hulls, headlines, planet silhouettes, frames |
| `--steel` | `#516c9e` | Engine stripes, cockpit glass, stars, dots, laser lines, logo slashes |
| `--paper` | `#fefefe` | Background |

Derived tones for screen use, kept close to the originals:

| Token | Hex | Used for |
|---|---|---|
| `--ink-2` | `#959192` | Secondary text, grid lines, disabled |
| `--ink-3` | `#d9d9db` | Hairlines, table borders |
| `--steel-2` | `#7d93bd` | Hover, selection, secondary accents |
| `--steel-3` | `#e3e9f4` | Selected row tint, code background |
| `--danger` | `#b8473f` | Only for destroyed ships and errors. The pins have no red; use it sparingly so it means something. |

Dark mode inverts paper and ink: `--paper: #2b2c2e`, `--ink: #ececed`, steel stays `#6f8dc4`.
The map defaults to dark because the pins' "space" is white and the map wants
the opposite contrast for thousands of small marks, but it should support both.

## Typography

The wordmark is a light geometric sans with wide tracking. The trophy
headlines are a heavy geometric sans, tightly tracked, all caps, with one word
rotated 90 degrees and stacked against the rest.

The original fonts are not embedded in the files. Closest open equivalents:

- Headlines and trophy names: **Montserrat** 800 or 900, uppercase, letter-spacing `-0.02em`.
- Wordmark-style labels: **Montserrat** 300, uppercase, letter-spacing `0.12em`.
- Body and UI: **Open Sans** or the system UI stack.
- Code and query console: **JetBrains Mono** or **IBM Plex Mono**.

The rotated-word lockup is the signature. Use it for section titles on cards
and for trophy displays: the short word (`STAR`, `THE`, `SPACE`, `SIZE`) rotated
counter-clockwise on the left, the long word huge on the right, the SQL that
earns it underneath in sentence case.

## Iconography and illustration

- Ships are flat, angular, side-on silhouettes in ink, with a steel cockpit
  wedge and three to four vertical steel stripes for engines. Ship size in the
  pins correlates with importance ("Size Matters"). On the map, ship glyphs
  should be this silhouette, rotated to heading, scaled by `max_health`, filled
  with the player's `rgb`.
- Planets are ink circles, usually cut off by the frame edge. On the map, a
  planet is an ink disc with a steel or player-coloured ring when conquered.
- Stars are four-point steel sparkles. Use them for background texture, never
  for data.
- Lasers are thin steel lines ending in a steel star; repair beams are dashed
  steel lines with steel `+` marks; mining is a steel-striped column with ink
  rocks. These three are the event glyphs for ATTACK, REPAIR, and MINE on the
  live map and in the event log.
- Frames: every pin has a thick ink border with a small `DC19` tag in a
  corner. Cards in the UI can carry the same frame with the round number or tic
  in the corner.
- The elephant. The logo elephant is a Postgres nod with a steel ear. The Boss
  mech is the same elephant as a suit of armour; it is the natural avatar for
  player 0, `schemaverse`, which owns planet 1 and is the house. Use it for
  system notices and for a possible NPC opponent.

## Layout rules for the new interface

1. Paper background, ink text, steel for anything interactive or live. If a
   third colour is showing up, ask why.
2. Thick frames, square corners, no shadows, no gradients. The pins are
   screen-printed; the UI should feel printed too.
3. Every trophy is rendered as a pin drawn in code: 3:2 card, rotated-word
   headline, SQL line, an inline SVG illustration chosen by what the trophy is
   about (`web/src/lib/components/Pin.svelte`). The original pin bitmaps in
   `docs/brand/pins/` are reference material and are not shipped in the app.
4. The query console is the hero. Results grids use hairlines, not zebra
   stripes.
5. The map uses the ship silhouette, not dots, once zoomed past a threshold.
   Below that threshold ships collapse to steel points so the galaxy view reads
   as a star chart.
6. Motion is limited to the map and to a laser or mining glyph appearing on an
   event. Interface chrome does not animate.

## Files

```
docs/brand/
  pins/{attack,mine,repair}.png            action pins, 900x600
  pins/{emperor,environ,firstblood,jerk,peace,pillager,size,supremacy}.png  trophy pins
  logo-sheet.svg / logo-sheet.png          elephant, wordmark, DEFCON lockup (vector)
  logo-wordmark.png                        the raster wordmark TrainingWheels shipped
  boss-mech.png                            mech render from the poster PSD
  schemaverse-logo.ai                      source
```

The original TIFFs and the poster PSD stay outside the repo in
`/Users/abstract/Documents/Schemaverse/Assets`.


## Screen edition (2026-09-21)

The pins are two inks on paper. On screen the same inks move into space. The
tokens live in `web/src/app.css`; the map treatment in
`web/src/lib/components/SpaceMap.svelte`; the ship in `web/src/lib/ship.ts`.

| Token | Hex | Used for |
|---|---|---|
| `--void` | `#0b0d13` | The ground of every game screen |
| `--void-2` / `--void-3` | `#12141c` / `#181b25` | Panels, code |
| `--line` | `#262a38` | Hairlines |
| `--light` / `--light-2` | `#ededee` / `#9c9da3` | Text, ship hulls |
| `--steel-b` | `#7d96cc` | Your colour on the map, active tabs |
| `--glow` | `#8fb0ff` | Anything live: beams, the playhead, the selected ship, the tic bar |
| `--silver`, `--indigo` | `#e3e5ec`, `#4b62b3` | Other players. Nobody gets a warm colour. |

Rules that extend the print rules above:

1. Pins, mission cards and trophy cards stay paper with a thick ink frame,
   even on the void. They are the printed objects in a dark room.
2. Interface chrome is one hairline, a translucent panel (`.hud`) with
   crop-mark corners, and one thick frame only on a card.
3. The map is the one place gradients are allowed: nebula blobs, lit spheres
   with craters, owner glow under a planet, a soft halo on a beam. The chrome
   never has a gradient.
4. The ship is the pin ship, traced from the DC19 "attack" and "mine" pins:
   raised rear deck, two slanted cockpit panels, an engine block split into
   two rows of three stripes, a lower slab with a keel. One geometry draws it
   on the canvas and in SVG so a ship on the map and a ship on a pin match.
5. Ships are small next to planets. Streams of particles show what a ship is
   doing: planet to ship for mining, ship to target with a burst for attack,
   ship to destination for a course.
6. Motion is limited to the map: streams drift, the beam burst pulses, the
   view flies. Chrome does not animate.
7. A ship's cockpit and engine stripes take the colour of what it is doing
   (`ACTION_COLORS` in `web/src/lib/types.ts`): steel when idle, glow when a
   course is set, ice `#7fd6e0` mining, mint `#8fd7a8` repairing, and the
   danger red attacking. Hulls stay light. Ships that share a spot are spread
   on a small ring with a hairline back to the true position.
