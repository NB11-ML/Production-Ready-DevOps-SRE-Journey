# 🐙 Day 34 Cheat Sheet: Advanced Docker Compose & SRE Patterns
> **Quick-reference guide for healthchecks, self-healing policies, and dynamic scaling.**

### Healthchecks & Startup Sequencing

* Use `depends_on` with `condition: service_healthy` to block container startup until dependencies are fully ready, preventing frontend CrashLoopBackOffs.
* Define custom `healthcheck` blocks (e.g., using `pg_isready`) with explicit intervals, timeouts, and retry limits.
* Remember that healthchecks primarily govern the initial orchestration boot sequence rather than continuous microservice communication.

### Resilience & Restart Policies

* Apply `restart: always` for foundational infrastructure like databases and caches to ensure aggressive, constant uptime.
* Apply `restart: on-failure` for application containers to gracefully recover from internal code crashes without fighting manual stops.
* Note that explicit administrative commands (`docker kill`) suspend policies; simulate real crashes internally (e.g., `kill 1`) to validate self-healing mechanics.

### State & Network Isolation

* Map explicit named volumes (e.g., `db_data:/var/lib/postgresql/data`) to guarantee persistent state even if the host container is destroyed.
* Isolate traffic by defining custom bridge networks, placing databases strictly on backend networks while bridging web tiers to the frontend.
* Tag active services with organizational labels (e.g., `tier=frontend`) to streamline targeted log filtering and infrastructure monitoring workflows.

### Dynamic Scaling & Rebuilding

* Force a complete image reconstruction after modifying source code by appending the `--build` flag to your startup command.
* Remove hardcoded `container_name` variables before scaling out to prevent fatal unique naming constraint violations.
* Omit strict host-to-container port bindings (e.g., strictly use `"5000"`) to allow the orchestrator to dynamically assign ephemeral ports across new replicas.
