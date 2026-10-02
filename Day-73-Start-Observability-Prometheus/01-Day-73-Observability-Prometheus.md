# 👁️ Day 73: Introduction to Observability and Prometheus


You have built infrastructure with Terraform, configured servers with Ansible, and containerized applications with Docker. But once everything is running in a production environment—how do you know it is healthy? How do you find out why a critical service broke at 3 AM?

That is where observability comes in. Today, we transition from deploying infrastructure to monitoring its heartbeat, starting with the industry standard for metrics collection: **Prometheus**.

## 📌 Task 1: Understanding Observability

### Monitoring vs. Observability
Think of traditional monitoring as the dashboard in your car—it tells you when something is wrong (the check engine light turns on, or the engine overheats). **Monitoring tells you *what* is broken.**

Observability is like opening the hood with a diagnostic toolkit. It allows you to explore, query, and correlate data to find the root cause of an issue you may not have predicted. **Observability tells you *why* it is broken.**

### The Three Pillars of Observability
To achieve true observability, DevOps and SRE teams rely on three specific types of telemetry data:

1. **Metrics (The "What"):** Numerical measurements tracked over time.
   * *Example:* CPU usage is at 98%, or the API is serving 500 requests per second.
   * *Tools:* Prometheus, Datadog, CloudWatch.
2. **Logs (The "Why"):** Timestamped text records of specific events.
   * *Example:* A stack trace error showing a database connection timeout.
   * *Tools:* Loki, ELK Stack (Elasticsearch, Logstash, Kibana), Fluentd.
3. **Traces (The "Where"):** The end-to-end journey of a single user request as it hops across multiple microservices.
   * *Example:* Seeing that a checkout request took 12 seconds because the payment gateway service was lagging.
   * *Tools:* OpenTelemetry, Jaeger, Zipkin.

### Why Do DevOps & SRE Engineers Need All Three?
A single telemetry stream rarely tells the full story during a production outage. You need all three pillars working together to diagnose and remediate issues rapidly:

  * **Metrics tell you WHAT is broken:** Prometheus alerts trigger because error rates on `/api/users` suddenly spiked to 35%.
  * **Traces tell you WHERE it broke:** Distributed tracing pinpoints that the request stalled inside downstream calls to the payment gateway service, which took 12 seconds instead of 100 milliseconds.
  * **Logs tell you WHY it broke:** Inspecting the container logs reveals the root cause: an uncaught database timeout exception with a full stack trace.

### 📐 The Observability Architecture
Over the next few days, we will build out this exact telemetry stack:

```text
[Your App] --> metrics --> [Prometheus] --> [Grafana Dashboards]
[Your App] --> logs    --> [Promtail]   --> [Loki] --> [Grafana]
[Your App] --> traces  --> [OTEL Collector] --> [Grafana/Debug]

# Infrastructure Metrics
[Host]     --> metrics --> [Node Exporter] --> [Prometheus]
[Docker]   --> metrics --> [cAdvisor]      --> [Prometheus]

```

## 📌 Task 2: Setting up Prometheus with Docker

Prometheus operates on a **pull-based model**. It reaches out to designated endpoints (called scrape targets) at regular intervals to pull their current metrics.

### 1. Create the Workspace

```bash
mkdir observability-stack && cd observability-stack

```

### 2. Configure Prometheus (`prometheus.yml`)

This configuration tells Prometheus to scrape its own internal metrics every 15 seconds.

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

```

### 3. Deploy via Docker Compose (`docker-compose.yml`)

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    restart: unless-stopped

volumes:
  prometheus_data:

```

Launch the stack using `docker compose up -d` and navigate to `http://localhost:9090`. In the UI, navigate to **Status > Targets** to verify the `prometheus` job is in the **UP** state.

## 📌 Task 3: Core Prometheus Concepts

### Metric Types Explained: Counter vs. Gauge

Understanding the data type is critical for writing accurate queries:

* **Counter:** A metric that only goes up (until the system restarts).
* *Real-world example:* The odometer on a car. It only ever increases to show total miles driven.
* *Tech example:* Total HTTP requests served, or total errors generated.


* **Gauge:** A metric that can go up and down arbitrarily.
* *Real-world example:* A car's speedometer. You can go from 0 to 60, and back down to 30.
* *Tech example:* Current memory usage, or active active network connections.



## 📌 Task 4: PromQL (Prometheus Query Language) Basics

PromQL allows you to ask questions about your collected data. You can test these in the Prometheus Graph UI (`http://localhost:9090/graph`):

1. **Check if a target is alive (Instant Vector):**
```promql
up

```


2. **View total Prometheus requests:**
```promql
prometheus_http_requests_total

```


3. **Filter by specific labels:**
```promql
prometheus_http_requests_total{handler="/api/v1/query"}

```


4. **Convert bytes to Megabytes (Arithmetic):**
```promql
process_resident_memory_bytes / 1024 / 1024

```



**🔥 Exercise:** *Show the per-second rate of non-200 HTTP requests over the last 5 minutes.*

```promql
rate(prometheus_http_requests_total{code!="200"}[5m])

```

*(Note: `rate()` calculates the per-second average of a counter over a specified time window, converting constantly rising numbers into a readable "speed" metric).*

## 📌 Task 5: Adding a Sample Application

Prometheus is only useful if it has applications to monitor. We will deploy a sample Python app that exposes a `/metrics` endpoint.

Update your `docker-compose.yml`:

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    restart: unless-stopped

  notes-app:
    image: trainwithshubham/notes-app:latest
    container_name: notes-app
    ports:
      - "8000:8000"
    restart: unless-stopped

volumes:
  prometheus_data:

```

Update your `prometheus.yml` to tell Prometheus where to find it:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "notes-app"
    static_configs:
      - targets: ["notes-app:8000"]

```

Restart the stack with `docker compose up -d`. Generate some fake traffic by running `curl http://localhost:8000` a few times in your terminal, then check your Prometheus Targets page to see both endpoints active.

## 📌 Task 6: Data Retention and Storage

Prometheus stores its metric data in a custom local Time-Series Database (TSDB).

### What happens when retention is exceeded?

By default, Prometheus retains data for 15 days. Once this limit (or a configured size limit) is reached, Prometheus begins discarding the oldest data blocks first. This is a standard FIFO (First-In-First-Out) rotation to prevent the server from running out of disk space.

### Why is a Volume Mount Important?

Docker containers are ephemeral. If Prometheus is restarted or updated, any data written inside the container is permanently lost. By mounting a named volume (`prometheus_data:/prometheus`), we ensure the TSDB survives container restarts, allowing us to maintain historical metrics for long-term trend analysis.

---
