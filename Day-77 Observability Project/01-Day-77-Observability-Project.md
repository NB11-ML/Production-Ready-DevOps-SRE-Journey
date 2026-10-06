# Day 77: Observability Project — Full Stack with Docker Compose

Over the past four days, we built the pillars of modern observability piece by piece: metrics with Prometheus and Node Exporter/cAdvisor, visualization and alerting with Grafana, centralized log management with Loki and Promtail, and vendor-neutral telemetry collection with the OpenTelemetry (OTEL) Collector.

Today, we bring everything together into a production-ready reference architecture by spinning up a complete 8-service stack using Docker Compose, validating data flows end to end, building a unified dashboard, and structuring a comprehensive handover document.

---

## 🏗️ Architecture Overview & Data Flow

```text
                  METRICS PIPELINE
[Node Exporter:9100] ---> [Prometheus:9090] ---> [Grafana Dashboards:3000]
[cAdvisor:8080] ---------> [Prometheus:9090] ---> [Grafana Dashboards:3000]
[OTEL Collector:8889] -> [Prometheus:9090] ---> [Grafana Dashboards:3000]

                  LOGS PIPELINE
[Notes App Container] -> [Promtail:9080] -> [Loki:3100] -> [Grafana Explore/Dashboards:3000]

                  TRACES PIPELINE
[Client / App OTLP] ---> [OTEL Collector:4317/4318] -> [Debug Console / Exporter]

```

### Core Components & Roles

1. **Prometheus:** Scrapes and stores multi-dimensional time-series metrics.
2. **Node Exporter:** Exposes host-level hardware and OS metrics (CPU, memory, disk, network).
3. **cAdvisor:** Exposes container-level resource usage and performance metrics.
4. **Grafana:** Unified visualization platform combining Prometheus metrics, Loki logs, and dashboards.
5. **Loki:** Horizontally-scalable, highly-cost-effective log aggregation system using label indexing.
6. **Promtail:** Agent that gathers local container logs, appends metadata labels, and pushes them to Loki.
7. **OTEL Collector:** Vendor-neutral proxy that accepts, processes, and exports OTLP telemetry data (metrics and traces).
8. **Notes App:** A sample Django REST application generating live web traffic, requests, and structured logs.

---

## 🚀 Task 1: Clone and Launch the Reference Stack

### 1. Clone the Reference Repository

```bash
git clone https://github.com/LondheShubham153/observability-for-devops.git
cd observability-for-devops

```

### 2. Examine the Project Structure

```bash
tree -I 'node_modules|build|staticfiles|__pycache__'
```

```text
observability-for-devops/
  ├── docker-compose.yml                    # Orchestrates all 8 services
  ├── prometheus.yml                        # Prometheus global scrape configurations
  ├── alert-rules.yml                       # Pre-configured alert rules
  ├── grafana/
  │   └── provisioning/
  │       datasources/datasources.yml       # Auto-provisioned Prometheus + Loki
  │       dashboards/dashboards.yml         # Auto-provisioned dashboard configuration
  ├── loki/
  │   └── loki-config.yml                   # Loki schema and storage parameters
  ├── promtail/
  │   └── promtail-config.yml               # Docker container log scraping setup
  ├── otel-collector/
  │   └── otel-collector-config.yml         # OTLP receivers, batch processors, and exporters
  └── notes-app/                            # Sample Django application

```

<img width="2726" height="1904" alt="image" src="https://github.com/user-attachments/assets/caa20ef9-43ee-4da6-bd89-83bd4f9d3ab0" />


### 3. Launch the Infrastructure

Bring up all services in detached mode using Docker Compose:

```bash
docker compose up -d
```

<img width="3214" height="920" alt="image" src="https://github.com/user-attachments/assets/490b3e8d-c6f3-4cf1-97ca-b996b22694d6" />

### 4. Verify Service Health

Run `docker compose ps` to inspect running containers and cross-reference them against the health check endpoints:

| Service | Port | Health Check Command / URL | Expected Status |
| --- | --- | --- | --- |
| **Prometheus** | `9090` | `http://localhost:9090` | Running / Up |
| **Node Exporter** | `9100` | `curl http://localhost:9100/metrics \| head -5` | Active metrics stream |
| **cAdvisor** | `8080` | `http://localhost:8080` | Running / Up |
| **Grafana** | `3000` | `http://localhost:3000` (admin/admin) | Running / Up |
| **Loki** | `3100` | `curl http://localhost:3100/ready` | Returns `ready` |
| **Promtail** | `9080` | Internal target scraping | Running / Up |
| **OTEL Collector** | `4317/4318` | `docker logs otel-collector` | Active initialization |
| **Notes App** | `8000` | `http://localhost:8000` | Running / Up |

---

## 📊 Task 2: Validate the Metrics Pipeline

1. **Verify Scrape Targets:** Navigate to `http://localhost:9090/targets` and confirm all 4 targets (`prometheus`, `node-exporter`, `cadvisor`, `otel-collector`) show a status of **UP**.
2. **Execute Validation PromQL Queries:** Run these expressions in the Prometheus UI (`http://localhost:9090/graph`):
* **Target Health Check:** `up`
* **Host CPU Usage:** `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
* **Memory Utilization:** `(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100`
* **Container CPU Consumption:** `rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100`
* **Top Memory-Hungry Containers:** `topk(3, container_memory_usage_bytes{name!=""})`


<img width="3412" height="2026" alt="image" src="https://github.com/user-attachments/assets/b9824255-4815-47a9-ab2f-dfdf81dbc339" />
<img width="3416" height="2034" alt="image" src="https://github.com/user-attachments/assets/c1b60451-4526-47b8-9f60-68e7f3c382c6" />

---

## 🪵 Task 3: Validate the Logs Pipeline

1. **Generate Synthetic Web Traffic:**
```bash
for i in $(seq 1 50); do
  curl -s http://localhost:8000 > /dev/null
  curl -s http://localhost:8000/api/ > /dev/null
done

```


2. **Query Logs in Grafana:** Go to Grafana (`http://localhost:3000`), navigate to **Explore**, select **Loki** as the datasource, and test these LogQL statements:
* *All container logs:* `{job="docker"}`
* *Specific app logs:* `{container_name="notes-app"}`
* *Error filtering:* `{job="docker"} |= "error"`
* *HTTP requests:* `{container_name="notes-app"} |= "GET"`
* *Log rate metrics:* `sum by (container_name) (rate({job="docker"}[5m]))`

<img width="3332" height="1876" alt="image" src="https://github.com/user-attachments/assets/26566a04-b41e-4f2f-b688-08058c20e00e" />
<img width="3338" height="1884" alt="image" src="https://github.com/user-attachments/assets/185ef7d0-237e-4cae-890b-1ad5ca39c00b" />

---

## ⚡ Task 4: Validate the Traces Pipeline

Simulate an application request trace by pushing an OTLP JSON payload directly to the collector:

```bash
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{
    "resourceSpans": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": { "stringValue": "notes-app" }
        }]
      },
      "scopeSpans": [{
        "spans": [{
          "traceId": "aaaabbbbccccdddd1111222233334444",
          "spanId": "1111222233334444",
          "name": "GET /api/notes",
          "kind": 2,
          "startTimeUnixNano": "1700000000000000000",
          "endTimeUnixNano": "1700000000150000000",
          "attributes": [
            {"key": "http.method", "value": { "stringValue": "GET" }},
            {"key": "http.route", "value": { "stringValue": "/api/notes" }},
            {"key": "http.status_code", "value": { "intValue": "200" }}
          ],
          "status": { "code": 1 }
        }]
      }]
    }]
  }'

```

Inspect the debug collector logs to confirm processing:

```bash
docker logs otel-collector 2>&1 | grep -A 20 "GET /api/notes"
OR
docker logs otel-collector --tail 30 
```

<img width="3416" height="1720" alt="image" src="https://github.com/user-attachments/assets/9cdffa87-84db-49a0-b753-b0396c3bb72b" />

---

## 📈 Task 5: Build a Unified "Production Overview" Dashboard

Create a new dashboard in Grafana named **"Production Overview -- Observability Stack"** organized into 4 distinct rows:

* **Row 1 — System Health (Prometheus + Node Exporter):**
* CPU Usage (Gauge): `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
* Memory Usage (Gauge): `(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100`
* Disk Usage (Gauge): `(1 - (sum(node_filesystem_avail_bytes) / sum(node_filesystem_size_bytes))) * 100`
* Targets Up (Stat): `sum(up) / count(up)`

<img width="3332" height="1516" alt="image" src="https://github.com/user-attachments/assets/b568b409-48dc-4658-ab70-3a7c5c5d8b9f" />


* **Row 2 — Container Metrics (cAdvisor):**
* Container CPU (Time Series): `rate(container_cpu_usage_seconds_total[5m]) * 100`
* Container Memory (Bar Chart): `container_memory_usage_bytes / 1024 / 1024`
* Active Container Count (Stat): `count(container_last_seen)`

<img width="3334" height="1602" alt="image" src="https://github.com/user-attachments/assets/4ec9ec5a-9ea5-450d-ad21-8445c3169df7" />


* **Row 3 — Application Logs (Loki / LogQL):**
* App Logs Stream (Logs Panel): `{job="docker"} |= "notes-app"`
* Error Rate (Time Series): `sum(rate({job="docker"} |= "error" [5m]))`

<img width="3312" height="1080" alt="image" src="https://github.com/user-attachments/assets/95ab87d1-cd27-4152-8d75-9e33071bb961" />


* **Row 4 — Service Overview:**
* Prometheus Scrape Duration (Time Series): `prometheus_target_interval_length_seconds{quantile="0.99"}`

<img width="3420" height="1148" alt="image" src="https://github.com/user-attachments/assets/8da2f2f5-61ad-4bd9-b240-a4ecc665d9f6" />

---

## 🔍 Task 6: Configuration Comparison & Documentation

### Component Comparison Table

| Component | Custom Build (Days 73–76) | Reference Repository | Key Notes |
| --- | --- | --- | --- |
| **`prometheus.yml`** | Root directory | Root directory | Identical structure; reference repo includes clean target mapping. |
| **`loki-config.yml`** | `loki/` folder | `loki/` folder | Standard single-instance TSDB schema setup. |
| **`promtail-config.yml`** | `promtail/` folder | `promtail/` folder | Scrapes docker container paths via socket mounts. |
| **`otel-collector-config.yml`** | `otel-collector/` folder | `otel-collector/` folder | Configured with OTLP receivers and debug/prometheus exporters. |
| **`datasources.yml`** | `grafana/provisioning/` | `grafana/provisioning/` | Auto-provisions Prometheus and Loki datasources cleanly. |
| **`docker-compose.yml`** | Root directory | Root directory | Orchestrates all 8 services securely on an internal network. |

### 🗺️ Observability Progression Mapping

* **Day 73:** Prometheus core architecture, TSDB configuration, and fundamental PromQL queries.
* **Day 74:** Host monitoring via Node Exporter, container metrics via cAdvisor, and Grafana dashboard provisioning.
* **Day 75:** Log aggregation using Loki and Promtail, LogQL filtering, and cross-correlation.
* **Day 76:** Distributed tracing fundamentals, OpenTelemetry Collector pipelines, and Prometheus alerting rules.
* **Day 77:** Full 8-service reference integration, multi-pipeline validation, and unified dashboarding.

### 🚀 Production-Readiness Enhancements

To transition this reference architecture to enterprise production, consider implementing:

1. **Alertmanager Integration:** Route firing alerts directly to Slack, PagerDuty, or Webhooks.
2. **Trace Backends:** Replace the debug exporter with **Grafana Tempo** or Jaeger for persistent trace storage.
3. **Security:** Enforce HTTPS/TLS encryption across all collector endpoints and implement strong RBAC authentication on Grafana/Prometheus.
4. **Data Retention & Limits:** Configure strict log retention policies in Loki and time-series retention windows in Prometheus.
5. **High Availability:** Deploy multi-replica setups for Prometheus and Loki behind load balancers.

---

## 📂 Configuration Files Reference

### 1. `docker-compose.yml`

```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./alert-rules.yml:/etc/prometheus/alert-rules.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    ports:
      - "9090:9090"
    restart: unless-stopped

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    restart: unless-stopped

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    restart: unless-stopped

  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    volumes:
      - ./loki/loki-config.yml:/etc/loki/loki-config.yml
      - loki_data:/loki
    command: -config.file=/etc/loki/loki-config.yml
    restart: unless-stopped

  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    volumes:
      - ./promtail/promtail-config.yml:/etc/promtail/promtail-config.yml
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock
    command: -config.file=/etc/promtail/promtail-config.yml
    restart: unless-stopped

  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    container_name: otel-collector
    ports:
      - "4317:4317"
      - "4318:4318"
      - "8889:8889"
    volumes:
      - ./otel-collector/otel-collector-config.yml:/etc/otelcol-contrib/config.yaml
    restart: unless-stopped

  notes-app:
    build: ./notes-app
    container_name: notes-app
    ports:
      - "8000:8000"
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
  loki_data:

```

### 2. `prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "/etc/prometheus/alert-rules.yml"

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "node-exporter"
    static_configs:
      - targets: ["node-exporter:9100"]

  - job_name: "cadvisor"
    static_configs:
      - targets: ["cadvisor:8080"]

  - job_name: "otel-collector"
    static_configs:
      - targets: ["otel-collector:8889"]

```

### 3. `loki/loki-config.yml`

```yaml
auth_enabled: false
server:
  http_listen_port: 3100
common:
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory
  replication_factor: 1
  path_prefix: /loki
schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h
storage_config:
  filesystem:
    directory: /loki/chunks

```

### 4. `promtail/promtail-config.yml`

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0
positions:
  filename: /tmp/positions.yaml
clients:
  - url: http://loki:3100/loki/api/v1/push
scrape_configs:
  - job_name: docker
    static_configs:
      - targets:
          - localhost
        labels:
          job: docker
          __path__: /var/lib/docker/containers/*/*-json.log
    pipeline_stages:
      - docker: {}

```

### 5. `otel-collector/otel-collector-config.yml`

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
processors:
  batch:
exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
  debug:
    verbosity: detailed
service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus]
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]

```

---

*Clean up resources when finished exploring:*

```bash
docker compose down -v

```
---
