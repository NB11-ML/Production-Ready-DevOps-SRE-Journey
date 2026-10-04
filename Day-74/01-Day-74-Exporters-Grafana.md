# Day 74 of #90DaysOfDevOps: Node Exporter, cAdvisor, and Grafana Dashboards

Prometheus is running and you can query metrics, but right now it is only monitoring itself. In production, Site Reliability Engineers need to monitor two critical things: the underlying host machine (CPU, memory, disk, network) and the Docker containers running on it.

Today, we added Node Exporter for host metrics, cAdvisor for container metrics, and set up Grafana to visualize everything in custom and community dashboards.

## 📌 Task 1: Add Node Exporter for Host Metrics

Node Exporter exposes Linux system hardware and OS-level metrics in a format Prometheus can scrape. 

**Update `docker-compose.yml` to add the service:**
```yaml
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped

```

**Why these volume mounts?**
To read host metrics from inside a Docker container, Node Exporter requires read-only (`ro`) access to specific host directories:

* `/proc` – Kernel and process information (CPU stats, memory info).
* `/sys` – Hardware and driver details.
* `/` (mounted to `/rootfs`) – Filesystem usage to track disk space.

**Update `prometheus.yml` to scrape Node Exporter:**

```yaml
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "node-exporter"
    static_configs:
      - targets: ["node-exporter:9100"]

```

**Host Metrics PromQL Queries Tested:**

* `node_cpu_seconds_total{mode="idle"}`
* `node_memory_MemTotal_bytes`
* `node_memory_MemAvailable_bytes`
* `(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100`
* `(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100`
* `rate(node_network_receive_bytes_total[5m])`

## 📌 Task 2: Add cAdvisor for Container Metrics

cAdvisor (Container Advisor) monitors the resource usage and performance characteristics of running Docker containers.

**Update `docker-compose.yml` to add the service:**

```yaml
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    restart: unless-stopped

```

**Why these volume mounts?**

* `/var/run/docker.sock` – Lets cAdvisor talk to the Docker daemon to discover running containers.
* `/sys` – Accesses kernel-level cgroups to read container resource limits.
* `/var/lib/docker/` – Reads container filesystem information.

**Update `prometheus.yml` to scrape cAdvisor:**

```yaml
  - job_name: "cadvisor"
    static_configs:
      - targets: ["cadvisor:8080"]

```

**Difference Between Node Exporter and cAdvisor:**
Node Exporter looks at the physical/virtual host server (tracking total CPU, RAM, disk). cAdvisor looks at the containerization layer (tracking exactly which individual Docker container is hogging memory or CPU).

**Container Metrics PromQL Queries Tested:**

* `rate(container_cpu_usage_seconds_total{name!=""}[5m])`
* `container_memory_usage_bytes{name!=""}`
* `rate(container_network_receive_bytes_total{name!=""}[5m])`
* `topk(3, container_memory_usage_bytes{name!=""})`

## 📌 Task 3: Set Up Grafana

Grafana is the visualization layer. It connects to Prometheus to turn raw time-series metrics into actionable dashboards.

**Update `docker-compose.yml` to add Grafana and required volumes:**

```yaml
  grafana:
    image: grafana/grafana-enterprise:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:

```

Once running, logged into `http://localhost:3000` (admin/admin123) and added Prometheus as the first Datasource by pointing it to the internal Docker network URL: `http://prometheus:9090`.

## 📌 Task 4: Build Your First Dashboard

Created a custom "DevOps Observability Overview" dashboard with 5 specific panels:

1. **CPU Usage % (Gauge):** `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
2. **Memory Usage % (Gauge):** `(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100`
3. **Container CPU Usage (Time Series):** `rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100`
4. **Container Memory MB (Bar Chart):** `container_memory_usage_bytes{name!=""} / 1024 / 1024`
5. **Disk Usage % (Stat):** `(1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100`

## 📌 Task 5: Auto-Provision Datasources with YAML

Manually clicking through a UI to add datasources is an anti-pattern. We implemented Infrastructure as Code (IaC) by creating `grafana/provisioning/datasources/datasources.yml`:

```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false

```

**Update the Grafana service in `docker-compose.yml` to mount the provisioning directory:**

```yaml
  grafana:
    image: grafana/grafana-enterprise:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    restart: unless-stopped

```

**Why is YAML provisioning better?**
It ensures repeatability and disaster recovery. If the Grafana container is destroyed, spinning up a new container automatically mounts this YAML file and reconnects to Prometheus without human intervention. Configuration files can also be securely version-controlled in Git.

## 📌 Task 6: Import a Community Dashboard

The Grafana community provides pre-built dashboards. We imported two industry standards:

* **ID 1860 (Node Exporter Full):** The gold standard for host monitoring, translating `node_` metrics into comprehensive system panels.
* **ID 193 (Docker monitoring via cAdvisor):** Tracks container-level resource exhaustion.

---

## 🛠️ Complete Final Configuration Files

### Final `prometheus.yml`

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

  - job_name: "node-exporter"
    static_configs:
      - targets: ["node-exporter:9100"]

  - job_name: "cadvisor"
    static_configs:
      - targets: ["cadvisor:8080"]

```

### Final `docker-compose.yml`

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

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    restart: unless-stopped

  grafana:
    image: grafana/grafana-enterprise:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    restart: unless-stopped

  notes-app:
    image: trainwithshubham/notes-app:latest
    container_name: notes-app
    ports:
      - "8000:8000"
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:

```
To get those final two screenshots, you need to log into your local Grafana instance and create/import the dashboards. Since I can't capture your local screen, I will walk you through exactly how to build them right now so you can take the screenshots yourself.

### Step 1: Log into Grafana

1. Open your browser and go to: **http://localhost:3000**
2. Log in with the credentials from your compose file:
* **Username:** `admin`
* **Password:** `admin123`
*(Note: It might ask you to change your password on the first login; you can just click "Skip").*



Since you set up the YAML provisioning file (`datasources.yml`), Prometheus is already connected! You can jump straight into building.

---

## 🛠️ Troubleshooting & Platform-Specific Modifications

During the setup, I encountered a few edge cases caused by running this stack on Docker Desktop for Mac (which uses a lightweight Linux VM), requiring adjustments to the standard PromQL queries.

### 1. cAdvisor Missing Container Names
**Issue:** The standard query for container CPU/Memory uses the `{name!=""}` filter. However, in this environment, cAdvisor failed to attach the human-readable `name` label to the metrics, returning "No Data" in Grafana.
**Debugging:** By querying the raw `container_memory_usage_bytes` metric in Prometheus, I discovered the containers were only being identified by their raw Docker hashes under the `id` label (e.g., `id="/docker/594f931ebbc..."`).
**Resolution:** I modified the Grafana panels to use a regex filter on the `id` label instead, successfully restoring the visualizations:
*   **Modified CPU Query:** `rate(container_cpu_usage_seconds_total{id=~"/docker/.+"}[5m]) * 100`
*   **Modified Memory Query:** `container_memory_usage_bytes{id=~"/docker/.+"} / 1024 / 1024`
*(Note: The Grafana legend was also updated to `{{id}}` to reflect this).*

### 2. Node Exporter Root Filesystem Mount
**Issue:** The standard disk usage query checks the `/` mountpoint (`{mountpoint="/"}`). This returned "No Data" for the Stat panel.
**Debugging:** Querying `node_filesystem_size_bytes` revealed that the Docker Desktop VM does not expose a simple `/` root directory to Node Exporter. Instead, the primary virtual disk (`/dev/vda1`) is mounted at `/var/lib`.
**Resolution:** I updated the panel to target the correct virtual mount point:
*   **Modified Disk Query:** `(1 - node_filesystem_avail_bytes{mountpoint="/var/lib"} / node_filesystem_size_bytes{mountpoint="/var/lib"}) * 100`


---

## 📸 Proof of Execution

<img width="3312" height="1876" alt="image" src="https://github.com/user-attachments/assets/6938e26d-c426-4b34-bf3c-77c6f473c131" />

<img width="3064" height="1730" alt="image" src="https://github.com/user-attachments/assets/cac76c04-812f-4f83-9671-ee3c34d4f72c" />

<img width="3298" height="1868" alt="image" src="https://github.com/user-attachments/assets/fc9dcd44-01d3-487c-9e4c-440a989d8d62" />


```
