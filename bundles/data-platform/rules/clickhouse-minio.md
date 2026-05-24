## Data platform — ClickHouse & MinIO

### ClickHouse (analytics / OLAP)
- It is OLAP, not OLTP: batch inserts (thousands of rows), never row-at-a-time. No transactional update patterns.
- Choose the engine deliberately — `MergeTree` family; set `ORDER BY` (the primary key) to match query filters.
- Prefer partitioning by date (`PARTITION BY toYYYYMM(...)`) for time-series; keep partitions coarse.
- Avoid `SELECT *` on wide tables; ClickHouse is columnar — read only needed columns.
- Use `FINAL`/dedup patterns sparingly; design keys so you don't need them.
- Parameter-bind queries; never build ClickHouse SQL from raw user input.

### MinIO (S3-compatible object storage)
- Use the S3 SDK; never hardcode endpoints/keys — read from config/secret store.
- Bucket + key naming: lower-case, no spaces; partition keys by date/tenant for listability.
- Set lifecycle policies for transient data; don't rely on manual cleanup.
- Use presigned URLs for client up/download instead of proxying large objects through the app.
- Always enable TLS to the endpoint; verify the certificate.
