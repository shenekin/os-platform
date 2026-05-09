# MySQL 8.0 with Docker Compose

This project runs a MySQL 8.0 container using Docker Compose.

## Configuration

- **Image:** `mysql:8.0`
- **Container name:** `mysql8.0`
- **Username:** `root`
- **Password:** `1qaz@WSX`
- **Port:** `3306` (default MySQL port)
- **Compose file:** `docker-compose-mysql8.yml`

## Start

```bash
docker compose -f docker-compose-mysql8.yml up -d
```

## Check status

```bash
docker compose -f docker-compose-mysql8.yml ps
```

## View logs

```bash
docker compose -f docker-compose-mysql8.yml logs -f
```

## Stop

```bash
docker compose -f docker-compose-mysql8.yml down
```

## Stop and remove data volume

```bash
docker compose -f docker-compose-mysql8.yml down -v
```

## Connect from local machine

```bash
mysql -h 127.0.0.1 -P 3306 -u root -p
```
