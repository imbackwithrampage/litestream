FROM golang:1.19 as builder

WORKDIR /src/litestream
COPY . .

ARG LITESTREAM_VERSION=latest

RUN --mount=type=cache,target=/root/.cache/go-build \
	--mount=type=cache,target=/go/pkg \
	go build -ldflags "-s -w -X 'main.Version=${LITESTREAM_VERSION}' -extldflags '-static'" -tags osusergo,netgo,sqlite_omit_load_extension -o /usr/local/bin/litestream ./cmd/litestream


FROM alpine

# for debugging
RUN apk add --no-cache sqlite && \
    printf '#!/bin/sh\nexec /usr/bin/sqlite3 -cmd "PRAGMA foreign_keys=ON; PRAGMA journal_mode=WAL; PRAGMA wal_autocheckpoint=0; PRAGMA busy_timeout=5000;" "$@"\n' > /usr/local/bin/sqlite3 && \
    chmod +x /usr/local/bin/sqlite3

COPY --from=builder /usr/local/bin/litestream /usr/local/bin/litestream
ENTRYPOINT ["/usr/local/bin/litestream"]
CMD []
