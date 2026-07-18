# Local infrastructure tools

A collection of Docker Compose configurations for local development: databases,
a message broker, S3-compatible storage, and an SMTP server for testing emails.
Each tool can be started independently from its own directory.

> These configurations are intended for local development only. The repository
> uses simple credentials, and some services are exposed on all host network
> interfaces. Do not use these settings in production.

## Requirements

- Docker Engine;
- Docker Compose v2 (`docker compose`);
- available ports for the services you want to run.

Verify your installation:

```bash
docker --version
docker compose version
```

## Included services

| Directory | Service | Host ports | Default access |
| --- | --- | --- | --- |
| `postgres/` | PostgreSQL 15 + pgAdmin 4 | `5432`, `8080` | PostgreSQL: `postgres` / `postgres`; pgAdmin: `admin@admin.com` / `admin` |
| `redis/` | Redis 7 + Redis Insight | `6379`, `5540` | Redis starts without authentication being effectively enabled; UI: <http://localhost:5540> |
| `redis-cluster/` | Six-node Redis Cluster | `7000`–`7005` | password: `secret`; 3 masters + 3 replicas |
| `clickhouse/` | Standalone ClickHouse | `8123` (HTTP), `9090` (native) | `your_user` / `your_password`; database: `your_database` |
| `clickhouse-cluster/` | 3 ClickHouse + 3 Keeper nodes | `8123`–`8125`, `9090`–`9092`, `9181`–`9183` | user: `default`; no password; cluster: `dev` |
| `rabbitmq/` | RabbitMQ + Management UI | `5672`, `15672` | `rmuser` / `rmpassword`; UI: <http://localhost:15672> |
| `minio/` | MinIO + Console | `9000`, `9001` | `miniouser` / `admin123`; Console: <http://localhost:9001> |
| `mailcatcher/` | Mailpit | `2525` (SMTP), `2626` (UI) | SMTP authentication accepts any credentials; UI: <http://localhost:2626> |

## Usage

Change to the directory of the tool you need and start its Compose project:

```bash
cd postgres
docker compose up -d
```

Check the service status and follow its logs:

```bash
docker compose ps
docker compose logs -f
```

Stop the services:

```bash
docker compose down
```

Remove the services together with their named volumes and stored data:

```bash
docker compose down -v
```

Use `-v` with care: data removed from Docker volumes cannot be recovered through
Compose.

### ClickHouse Cluster

The cluster uses `${PWD}` in its bind-mount paths, so it must be started from the
`clickhouse-cluster/` directory:

```bash
cd clickhouse-cluster
docker compose up -d
```

Check each node through its HTTP interface:

```bash
curl 'http://localhost:8123/?query=SELECT%20version()'
curl 'http://localhost:8124/?query=SELECT%20version()'
curl 'http://localhost:8125/?query=SELECT%20version()'
```

### Mailpit

Example application settings for sending test emails:

```text
SMTP_HOST=localhost
SMTP_PORT=2525
SMTP_TLS=false
```

Messages are captured locally instead of being delivered and can be viewed at
<http://localhost:2626>.

## Running multiple tools

The configurations are independent, but some ports overlap:

- standalone ClickHouse and the first ClickHouse Cluster node both use `8123`
  and `9090`;
- MinIO uses `9000`, while ClickHouse publishes its native interface on `9090`,
  so these services do not conflict.

To resolve a conflict, change the left side of the relevant mapping under
`ports`. For example, `"15432:5432"` exposes PostgreSQL on host port `15432`.

## Data persistence

- PostgreSQL and RabbitMQ use bind mounts inside their respective directories;
- standalone ClickHouse, MinIO, and Redis Insight use named Docker volumes;
- Redis Cluster and ClickHouse Cluster do not retain data after their containers
  are recreated (the ClickHouse Cluster configuration remains in the repository).

The PostgreSQL and RabbitMQ runtime data directories are excluded through
`.gitignore`.

## Known limitations

- `REDIS_PASSWORD`, `REDIS_USER`, and `REDIS_USER_PASSWORD` in
  `redis/docker-compose.yml` do not configure the official Redis image. The
  standalone Redis instance is currently accessible without a password. To
  enable authentication, add `redis-server --requirepass ...` or provide a
  custom `redis.conf`.
- Images tagged with `latest` (MinIO, Redis Cluster, Redis Insight, and Mailpit)
  may change on the next pull. Pin exact versions for a reproducible environment.
- The obsolete Compose `version` field in several files is ignored by Compose
  v2 and does not prevent the services from starting.
- The optional `postgres/deb_init.sh` helper modifies data directory permissions
  and attaches to the logs interactively. Use the direct `docker compose`
  commands above when that behavior is not required.

## Configuration validation

Validate every Compose file without starting containers:

```bash
while IFS= read -r file; do
  docker compose -f "$file" config --quiet
done < <(find . -name docker-compose.yml -print)
```

For `clickhouse-cluster/docker-compose.yml`, this command validates the Compose
model but not the bind mounts relative to the future working directory. Always
start the cluster from `clickhouse-cluster/` as described above.
