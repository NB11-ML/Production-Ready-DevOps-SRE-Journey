
# Day 76: OpenTelemetry and Alerting

With Metrics (Prometheus) and Logs (Loki) successfully implemented, today we complete the triad of observability by adding the third pillar: **Traces**, using OpenTelemetry (OTEL). Finally, we will configure active **Alerting** so the system proactively notifies us of failures, eliminating the need to constantly watch dashboards.

---

## 📌 Task 1: Understand OpenTelemetry

OpenTelemetry (OTEL) is the industry-standard, vendor-neutral framework for generating, collecting, and exporting telemetry data (Metrics, Logs, and Traces). It is not a storage backend itself; rather, it acts as a universal translator and router that ships data to backends like Prometheus, Jaeger, or Datadog.

### Core Concepts

* **The OTEL Collector:** A standalone service that sits between your applications and your storage backends. It consists of three pipeline stages:
1. **Receivers:** Accept incoming data (e.g., OTLP, Prometheus, Jaeger formats).
2. **Processors:** Transform and filter the data (e.g., batching to reduce network overhead).
3. **Exporters:** Ship the processed data to the final backend (e.g., Prometheus for metrics, Jaeger for traces, or the debug console).


* **OTLP (OpenTelemetry Protocol):** The standard wire format for sending telemetry. It operates over gRPC (port 4317) and HTTP (port 4318).
* **Distributed Traces:** A trace tracks a single request as it travels across multiple microservices.
* Each hop in the journey is called a **span**.
* Spans contain vital debugging context: Trace ID, Span ID, start time, duration, and custom attributes (e.g., HTTP status codes).



---

## 📌 Task 2: Add the OpenTelemetry Collector

We will configure the OTEL collector to receive data via OTLP, batch it, and export the metrics to Prometheus while sending traces to the debug console.

**1. Create the configuration directory:**

```bash
mkdir -p otel-collector

```

**2. Create the configuration file (`otel-collector/otel-collector-config.yml`):**

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

**3. Update `docker-compose.yml` to include the Collector:**

```yaml
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    container_name: otel-collector
    ports:
      - "4317:4317"   # OTLP gRPC
      - "4318:4318"   # OTLP HTTP
      - "8889:8889"   # Prometheus exporter
    volumes:
      - ./otel-collector/otel-collector-config.yml:/etc/otelcol-contrib/config.yaml
    restart: unless-stopped

```

**4. Add the Collector as a Prometheus target in `prometheus.yml`:**

```yaml
  - job_name: "otel-collector"
    static_configs:
      - targets: ["otel-collector:8889"]

```

**5. Start the Collector and Verify:**

```bash
docker compose up -d
docker logs otel-collector 2>&1 | tail -5

```

<img width="3412" height="1310" alt="image" src="https://github.com/user-attachments/assets/90b5bb1a-0f7e-4f33-806e-241ff9eaee10" />


*Check your Prometheus Targets page at `http://localhost:9090/targets` to confirm `otel-collector` is UP.*

<img width="3338" height="676" alt="image" src="https://github.com/user-attachments/assets/f15cfda9-def0-4bd3-b4fb-98b2f9d9f883" />

---

## 📌 Task 3: Send Test Traces to the Collector

To validate the pipeline without instrumenting a full application, we can manually send OTLP data payloads using `curl`.

**1. Send a Test Trace:**

```bash
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{    "resourceSpans": [{      "resource": {        "attributes": [{          "key": "service.name",          "value": { "stringValue": "my-test-service" }        }]      },      "scopeSpans": [{        "spans": [{          "traceId": "5b8efff798038103d269b633813fc60c",          "spanId": "eee19b7ec3c1b174",          "name": "test-span",          "kind": 1,          "startTimeUnixNano": "1544712660000000000",          "endTimeUnixNano": "1544712661000000000",          "attributes": [{            "key": "http.method",            "value": { "stringValue": "GET" }          },          {            "key": "http.status_code",            "value": { "intValue": "200" }          }]        }]      }]    }]  }'

```

**2. Verify the Trace in the Collector Logs:**

```bash
docker logs otel-collector 2>&1 | grep -A 10 "test-span"

```

<img width="3416" height="880" alt="image" src="https://github.com/user-attachments/assets/2da1f101-4701-47f1-b2d1-e87de35ce47e" />

*You should see the detailed span printed directly to the console. In production, this output is sent to a dedicated trace backend like Jaeger.*

**3. Send a Test Metric and Query it:**

```bash
curl -X POST http://localhost:4318/v1/metrics \
  -H "Content-Type: application/json" \
  -d '{    "resourceMetrics": [{      "resource": {        "attributes": [{          "key": "service.name",          "value": { "stringValue": "my-test-service" }        }]      },      "scopeMetrics": [{        "metrics": [{          "name": "test_requests_total",          "sum": {            "dataPoints": [{              "asInt": "42",              "startTimeUnixNano": "1544712660000000000",              "timeUnixNano": "1544712661000000000"            }],            "aggregationTemporality": 2,            "isMonotonic": true          }        }]      }]    }]  }'

```
<img width="3410" height="436" alt="image" src="https://github.com/user-attachments/assets/f4372558-36a5-4ab6-82c3-c62784551670" />

*Go to Prometheus (`http://localhost:9090/graph`) and query `test_requests_total`. The metric successfully traveled from `curl` -> OTEL Receiver -> OTEL Processor -> OTEL Exporter -> Prometheus TSDB.*

<img width="3334" height="732" alt="image" src="https://github.com/user-attachments/assets/b100424c-7d33-447a-a16c-00ddaf6cccc7" />

---

## 📌 Task 4: Set Up Prometheus Alerting Rules

Alerting rules tell Prometheus to constantly evaluate PromQL queries and trigger a state change if a threshold is breached.

**1. Create the alerting rules file (`alert-rules.yml`):**
*(Note: The Disk Usage alert has been pre-adjusted to `/var/lib` to accurately monitor your Docker Desktop virtual environment).*

```yaml
groups:
  - name: system-alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage has been above 80% for more than 2 minutes. Current value: {{ $value }}%"

      - alert: HighMemoryUsage
        expr: (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 > 85
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 85%. Current value: {{ $value }}%"

      - alert: ContainerDown
        expr: absent(container_last_seen{name="notes-app"})
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Container is down"
          description: "The notes-app container has not been seen for over 1 minute"

      - alert: TargetDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Scrape target is down"
          description: "{{ \(labels.job }} target {{\)labels.instance }} is unreachable"

      - alert: HighDiskUsage
        expr: (1 - node_filesystem_avail_bytes{mountpoint="/var/lib"} / node_filesystem_size_bytes{mountpoint="/var/lib"}) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Disk space running low"
          description: "Root filesystem usage is above 90%. Current value: {{ $value }}%"

```

*Platform Note: If `ContainerDown` immediately fires in your environment, it is because cAdvisor on Docker Desktop sometimes suppresses the `name` label. Prometheus evaluates the absence of that metric as an immediate failure.*

**2. Update `prometheus.yml` to load the rules:**
Add the `rule_files` block just below your global configurations:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/alert-rules.yml

```

**3. Mount the rules file in `docker-compose.yml` under `prometheus`:**

```yaml
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./alert-rules.yml:/etc/prometheus/alert-rules.yml
      - prometheus_data:/prometheus

```

<img width="3334" height="1828" alt="image" src="https://github.com/user-attachments/assets/591da078-dd5b-44f3-bea0-b361a092d679" />


**4. Apply changes and Test:**

```bash
docker compose up -d prometheus
docker compose stop test-app
```

*Wait 1-2 minutes and check `http://localhost:9090/alerts`. The alert will move from green (Inactive) to yellow (Pending) to red (Firing).*

<img width="3350" height="1688" alt="image" src="https://github.com/user-attachments/assets/903ddae1-8363-4b4c-8583-d306acccb832" />


---

## 📌 Task 5: Set Up Grafana Alerts

While Prometheus evaluates the raw metrics, Grafana provides a highly robust alerting engine for routing those notifications to third-party services.

**1. Create a Contact Point:**

* Navigate to **Alerting > Contact points > Add contact point**.
* Name: `DevOps Team`
* Integration: Email (or Slack). Save the configuration.

**2. Create a Grafana Alert Rule:**

* Navigate to **Alerting > Alert rules > New alert rule**.
* Name: `High Container Memory`
* Query: `container_memory_usage_bytes{name="notes-app"} / 1024 / 1024` *(Replace `name="notes-app"` with your specific container `id` regex if needed).*
* Condition: `IS ABOVE 100`
* Evaluation: `every 1m`, `for 2m`.
* Link it to the `DevOps Team` contact point and Save.

**Prometheus Alerts vs. Grafana Alerts:**

* **Prometheus Alerts:** Built directly into the TSDB. They are incredibly fast, lightweight, and perfect for core infrastructure alerting evaluated as code. However, without configuring a separate `Alertmanager` service, they do not natively send emails/Slack messages.
* **Grafana Alerts:** Highly visual and deeply integrated with communication channels. They are ideal for cross-correlating data (e.g., triggering an alert based on a combination of Prometheus metrics and Loki log counts) and managing on-call routing policies via a UI.

---

## 📌 Task 6: Review the Full Stack Architecture

With all components active, our observability infrastructure operates across three distinct pipelines:

```text
                    METRICS PIPELINE
[Node Exporter] -----> [Prometheus] -----> [Grafana Dashboards]
[cAdvisor] ----------> [Prometheus] -----> [Grafana Dashboards]
[OTEL Collector:8889]> [Prometheus] -----> [Grafana Dashboards]
                                    -----> [Alert Rules -> Notifications]

                    LOGS PIPELINE
[Docker Containers] -> [Promtail] -> [Loki] -> [Grafana Explore/Dashboards]

                    TRACES PIPELINE
[curl/App OTLP] -----> [OTEL Collector] -> [Debug Console]

```

### Active Service Registry

| Service | Port | Purpose |
| --- | --- | --- |
| **Prometheus** | `9090` | Metrics storage and alerting evaluation |
| **Node Exporter** | `9100` | Host system hardware metrics |
| **cAdvisor** | `8080` | Container resource metrics |
| **Grafana** | `3000` | Visualization, cross-correlation, and alert routing |
| **Loki** | `3100` | Label-indexed log storage |
| **Promtail** | `9080` | Docker log collection agent |
| **OTEL Collector** | `4317`/`4318` | Universal telemetry collection pipeline |

Run `docker compose ps` to ensure all containers report a healthy, running status.

---
