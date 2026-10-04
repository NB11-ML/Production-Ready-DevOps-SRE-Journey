# Day 75: Log Management with Loki and Promtail

Yesterday, we successfully implemented the first pillar of observability: **Metrics** (the "What is broken?"). Today, we are tackling the second critical pillar: **Logs** (the "Why is it broken?").

We will deploy Grafana Loki (the log storage backend) and Promtail (the log shipping agent). By the end of this setup, your observability stack will be capable of seamlessly correlating CPU/Memory spikes directly with the exact application log lines that caused them.

---

## 📌 Task 1: Understand the Logging Pipeline

Before writing any configuration files, it is crucial to understand the architecture of our log aggregation pipeline.

### The Architecture flow

```text
[Docker Containers] 
       │ (writes raw JSON logs to /var/lib/docker/containers/)
       ▼
  [Promtail] (Agent)
       │ (reads log files, attaches labels like container name, pushes to Loki)
       ▼
    [Loki] (Storage/Backend)
       │ (stores log chunks locally, indexes ONLY the labels)
       ▼
   [Grafana] (Visualization)
       │ (queries Loki via LogQL to display log streams)
       ▼
 [SRE / DevOps Engineer]

```

### Loki vs. ELK Stack: The Storage Trade-off

Traditional log aggregators like the ELK stack (Elasticsearch, Logstash, Kibana) ingest logs and index the *full text* of every single log line. This provides lightning-fast keyword searches but requires massive amounts of RAM and storage compute.

**Why does Loki only index labels instead of full text?**
Drawing parallels to enterprise backup and storage administration, full-text indexing is incredibly expensive from a storage I/O and compute perspective. Loki takes a different approach: it behaves exactly like Prometheus. It only indexes metadata labels (e.g., `job="docker"`, `container_name="notes-app"`). The actual log text is compressed and stored as raw chunks in a standard filesystem or object storage (like S3).

**The Trade-off:**

* **Pros:** Loki requires a fraction of the memory and storage infrastructure compared to Elasticsearch, making it highly cost-effective and simpler to operate.
* **Cons:** Keyword searches across massive unindexed log volumes are slower, as Loki has to grep through the compressed chunks at query time rather than looking up a pre-built index.

---

## 📌 Task 2: Add Loki to the Stack

Loki will act as our time-series database for log data.

**1. Create the Loki configuration directory:**

```bash
mkdir -p loki

```

**2. Create the configuration file (`loki/loki-config.yml`):**
This file configures Loki to run in a lightweight, single-instance mode, storing its index and compressed log chunks directly on the local filesystem.

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

**3. Update `docker-compose.yml` to include Loki:**
Add the `loki` service and declare the `loki_data` volume.

```yaml
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

volumes:
  prometheus_data:
  grafana_data:
  loki_data:

```

**4. Start and Verify Loki:**

```bash
docker compose up -d loki
curl http://localhost:3100/ready

```
<img width="1698" height="704" alt="image" src="https://github.com/user-attachments/assets/00565225-d2be-4967-b599-3feda077cbaa" />


*Expected Output: `ready`*

---

## 📌 Task 3: Add Promtail to Collect Container Logs

Promtail is the agent deployed to every node in a cluster. Its job is to read the raw log files, attach Prometheus-style labels, and ship them to Loki.

**1. Create the Promtail directory:**

```bash
mkdir -p promtail

```

**2. Create the configuration file (`promtail/promtail-config.yml`):**

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

*Note on `positions.yaml`: This file acts as a bookmark. If Promtail restarts, it looks at this file to know exactly which log line it read last, preventing log duplication or loss.*

**3. Update `docker-compose.yml` to include Promtail:**

```yaml
  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    volumes:
      - ./promtail/promtail-config.yml:/etc/promtail/promtail-config.yml
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock
    command: -config.file=/etc/promtail/promtail-config.yml
    restart: unless-stopped

```

*SRE Mac Note: Because you are likely running Docker Desktop on macOS (ARM64), the `/var/lib/docker/containers` path doesn't exist on your physical Mac hard drive. It exists entirely inside Docker's underlying Linux VM. By running Promtail as a container and mounting these volumes, Promtail can successfully access the VM's internal file paths.*

**4. Apply changes and generate test logs:**

```bash
docker compose up -d
for i in $(seq 1 20); do curl -s http://localhost:8000 > /dev/null; done

```

---

## 📌 Task 4: Add Loki as a Grafana Datasource

To maintain our Infrastructure as Code (IaC) standards, we will avoid manual UI configuration and auto-provision Loki alongside Prometheus.

**1. Update `grafana/provisioning/datasources/datasources.yml`:**

```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: false

```

**2. Restart Grafana:**

```bash
docker compose restart grafana

```

Loki is now permanently wired into Grafana as a queryable datasource.

---

## 📌 Task 5: Query Logs with LogQL

LogQL is specifically designed to mimic PromQL, minimizing the learning curve for DevOps engineers.

Go to **Grafana > Explore** (the compass icon) and select **Loki** from the datasource dropdown at the top left.

### 5 Essential LogQL Queries to Test:

1. **Basic Stream Selector (Show all Docker logs):**
`{job="docker"}`
2. **Filter by Container:**
`{container_name="notes-app"}` *(Note: Depending on how Docker maps metadata, you may need to rely on the raw container ID or image name).*
3. **Keyword Search (Find errors):**
`{job="docker"} |= "error"`
4. **Regex HTTP Status Filter (Find 4xx or 5xx codes):**
`{job="docker"} |~ "status=[45]\\d{2}"`
5. **Log Volume Metric (Top 5 noisy containers):**
`topk(5, sum by (container_name) (rate({job="docker"}[5m])))`

### Practical Exercise Answers:

* **Query to find all error logs from notes-app in the last 1 hour:**
`{container_name="notes-app"} |= "error"` *(Set the time picker in Grafana to "Last 1 hour")*
* **Query to count error lines per minute:**
`sum(rate({container_name="notes-app"} |= "error" [1m]))`

---

## 📌 Task 6: Correlate Metrics and Logs in Grafana

The true power of this stack is cross-correlation.

**How does having metrics and logs in the same tool help during incident response?**
During a severe production outage, context switching between a metrics dashboard (like Datadog/Prometheus) and a separate logging tool (like Kibana/Splunk) costs critical minutes. By keeping both in Grafana, an SRE can use the **Split View** feature. When you highlight a CPU spike on a PromQL metrics graph, Grafana automatically narrows the LogQL window to that exact same millisecond timeframe. This allows you to instantly see the specific application error or database timeout that triggered the hardware spike, vastly reducing Mean Time to Resolution (MTTR).

**To set this up:**

1. Go to **Grafana Explore**.
2. Click the **Split** button at the top (two panels side-by-side).
3. **Left Panel (Prometheus):** `rate(container_cpu_usage_seconds_total{id=~"/docker/.+"}[5m]) * 100`
4. **Right Panel (Loki):** `{job="docker"} `

---

## 📸 Proof of Execution

<img width="3412" height="1894" alt="image" src="https://github.com/user-attachments/assets/2c393d62-9639-44c9-8d1f-096604ae9e85" />

<img width="3416" height="2046" alt="image" src="https://github.com/user-attachments/assets/1c6c4818-496e-47e5-9e0c-af8e047c7c75" />
