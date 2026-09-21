# The Go ticker. Static binary, tiny image.
FROM golang:1.26-alpine AS build
WORKDIR /src
COPY tic/go.mod tic/go.sum* ./
RUN go mod download
COPY tic/ ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags='-s -w' -o /tic .

FROM alpine:3.20
RUN adduser -D -u 1000 tic
USER tic
COPY --from=build /tic /usr/local/bin/tic
ENTRYPOINT ["tic"]
