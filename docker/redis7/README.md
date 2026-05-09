# Redis 7 with Docker Compose

This folder contains a Docker Compose setup for running Redis 7 with:

- persistent storage via a named Docker volume
- append-only file (AOF) enabled for better durability
- a built-in healthcheck

## Prerequisites

- Docker Engine installed
- Docker Compose plugin (`docker compose`) available

## Files

- `docker-compose-redis7.yml` - Compose definition for Redis 7

## Start Redis

From this directory:

```bash
docker compose -f docker-compose-redis7.yml up -d
```

## Check status

```bash
docker compose -f docker-compose-redis7.yml ps
docker compose -f docker-compose-redis7.yml logs -f redis7
```

## Test connection

From your host:

```bash
redis-cli -h 127.0.0.1 -p 6379 ping
```

Expected response:

```text
PONG
```

If `redis-cli` is not installed locally, run:

```bash
docker exec -it redis7 redis-cli ping
```

## Stop Redis

```bash
docker compose -f docker-compose-redis7.yml down
```

## Remove everything including data volume

```bash
docker compose -f docker-compose-redis7.yml down -v
```

## Notes

- Redis data is stored in the `redis7-data` Docker volume.
- Port `6379` is exposed to the host.
