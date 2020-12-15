# PostgreSQL Connection Pooling with PgBouncer

## Ligtweight connection pooler for PostgreSQL

The PgBouncer behaivor depends on the pooling mode configured:

* **session pooling** (default): When a client connects, a server connection will be assigned to it for the whole duration the client stays connected. When the client disconnects, the server connection will be put back into the pool.
* **transaction pooling**: A server connection is assigned to a client only during a transaction. When PgBouncer notices that the transaction is over, the server connection will be put back into the pool.
* **statement pooling**: The server connection will be put back into the pool immediately after a query completes. Multi-statement transactios are disallowed in this mod as they would break.

sudo apt update

sudo apt install -y pgbouncer