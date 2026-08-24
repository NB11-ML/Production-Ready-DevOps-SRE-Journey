# 🚀 Day 34: Docker Compose – Real-World Multi-Container Apps

> **Part of the Production-Ready DevOps & SRE Journey**  
> *Engineering resilient, self-healing, and production-like container stacks.*

---

## 📌 Overview

Today we move beyond basic container orchestration. Real-world applications require precise startup ordering (a web app cannot function if its database isn't ready), health monitoring, segmented network security, and automated recovery. 

We are building a 3-tier architecture (Web App + Redis Cache + PostgreSQL Database) entirely defined as Code.

---

## 📂 The Project Structure

Before creating the Compose file, set up your directory like this:
```text
Day-34/
├── docker-compose.yml
└── app/
    ├── Dockerfile
    ├── app.py
    └── requirements.txt

```

### 1. The Custom Application (`app/`)

**`app/requirements.txt`**

```text
Flask==3.0.0
redis==5.0.1
psycopg2-binary==2.9.9

```

**`app/app.py`**

```python
import os
from flask import Flask
import redis

app = Flask(__name__)
cache = redis.Redis(host='cache', port=6379)

@app.route('/')
def hello():
    count = cache.incr('hits')
    return f"🚀 SRE Web App Online! This page has been viewed {count} times."

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

```

**`app/Dockerfile`**

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
CMD ["python", "app.py"]

```

---

## 🏗️ The Production-Ready Compose File

This `docker-compose.yml` tackles Tasks 1, 2, 4, and 5 simultaneously. Save this in your root `Day-34/` folder.

**`docker-compose.yml`**

```yaml
services:
  web:
    build: ./app                  # Task 4: Custom Dockerfile build
    container_name: sre_webapp
    ports:
      - "8080:5000"
    networks:
      - frontend                  # Task 5: Explicit networking
      - backend
    depends_on:                   # Task 2: Strict dependency & Healthcheck
      db:
        condition: service_healthy
      cache:
        condition: service_started
    labels:                       # Task 5: Organizational labels
      - "environment=production"
      - "tier=frontend"
    restart: on-failure           # Task 3: Restart policy

  db:
    image: postgres:15-alpine
    container_name: sre_postgres
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: securepass
      POSTGRES_DB: sre_db
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - backend
    healthcheck:                  # Task 2: Database health validation
      test: ["CMD-SHELL", "pg_isready -U admin -d sre_db"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: always

  cache:
    image: redis:7-alpine
    container_name: sre_redis
    networks:
      - backend
    restart: always

networks:                         # Task 5: Explicit Network Definitions
  frontend:
    driver: bridge
  backend:
    driver: bridge

volumes:                          # Task 5: Explicit Volume Definitions
  db_data:

```

---

## 🔬 Task 2: Healthchecks & Startup Sequencing

* **Test:** Run `docker compose up -d` and watch the logs with `docker compose logs -f`.
* **Observation:** The `web` container stays in a "Created" or "Waiting" state until the `db` container officially passes its `healthcheck` (meaning PostgreSQL is fully ready to accept connections, not just that the container powered on).
* **SRE Impact:** Prevents "CrashLoopBackOff" scenarios where frontend apps constantly restart because they boot faster than the heavy backend databases they rely on.

<img width="2940" height="1734" alt="image" src="https://github.com/user-attachments/assets/20f99119-06ba-42d5-9570-672aaa3720f7" />


---

## 🔄 Task 3: Restart Policies

If a process dies, we need the system to self-heal. 

| Policy | Behavior | SRE Use Case |
| :--- | :--- | :--- |
| `restart: always` | Always restarts the container if it stops, regardless of the exit code. Even if manually stopped, it restarts when the Docker daemon reboots. | **Databases & Caches** - Infrastructure that must be running at all times. |
| `restart: on-failure` | Only restarts if the container exits with a non-zero exit code (indicating an error/crash). | **Web Apps & Workers** - If the app crashes due to a code error, try to recover. If we stop it manually, keep it stopped. |

*   **Test 1 (The Admin Override):** Run `docker kill sre_postgres`, then `docker compose ps`.
    *   *Result:* The database stays dead (`Exited (137)`). Why? Docker assumes an explicit CLI command is an admin intervention and suspends the restart policy so it doesn't fight you.
*   **Test 2 (The Real-World Crash):** Bring it back up with `docker compose up -d`. Then simulate an internal software crash by killing the main process from the inside: `docker exec -u root sre_postgres kill 1`.
    *   *Result:* Run `docker compose ps` immediately. You will see the database instantly pop back up (`Up 2 seconds`). Docker detected an unexpected internal failure and automatically healed it!

<img width="2940" height="1728" alt="image" src="https://github.com/user-attachments/assets/0dcb7498-7c4f-43e7-a7eb-3058a9cb1400" />


---

## 🛠️ Task 4: Custom Dockerfiles & Rebuilding

When using `build: ./app`, Compose acts as both the image builder and the orchestrator.
*   **The Workflow:** If you edit `app.py` (e.g., changing the text), you must tell Compose to reconstruct the image layer.
*   **The Command:** `docker compose up -d --build` (The `--build` flag forces a fresh image compilation before starting the stack).

**Testing the Rebuild Workflow:**
1. **Make a code change:** Open `app.py` and change the return message (e.g., from `"🚀 SRE Web App Online!..."` to `"🛠️ SRE Web App UPDATED!..."`).
2. **Run the rebuild command:**
   ```bash
   docker compose up -d --build
---

<img width="2932" height="1734" alt="image" src="https://github.com/user-attachments/assets/c8e33ede-267a-42fb-badd-58749ff735ef" />

---

## 🌐 Task 5: Named Networks & Volumes

In production, we don't rely on Docker's default configurations. We explicitly define where our data lives and how our traffic flows.

*   **Named Volumes (`db_data`):** Containers are ephemeral (temporary). If the database container is deleted, the data inside it is destroyed. By mapping a named volume (`db_data:/var/lib/postgresql/data`), we ensure that even if the container is killed or recreated, the actual database records persist safely on the host machine.
*   **Explicit Networks (`frontend` & `backend`):** We use custom bridge networks to isolate traffic for security. 
    *   The `web` service is connected to both `frontend` (to talk to users) and `backend` (to talk to the DB/Cache).
    *   The `db` and `cache` are *only* on the `backend` network, meaning they are completely isolated and inaccessible from the outside world.
*   **Organizational Labels:** Adding metadata like `tier=frontend` allows SREs to easily filter and monitor specific groups of containers.

**Testing the Infrastructure:**

**1. Verify the Named Volume:**
```bash
docker volume ls

```

*Expected Output:*

```text
DRIVER    VOLUME NAME
local     day-34_db_data

```

**2. Verify the Custom Networks:**

```bash
docker network ls

```

*Expected Output:*

```text
NETWORK ID     NAME              DRIVER    SCOPE
a1b2c3d4e5f6   day-34_backend    bridge    local
f6e5d4c3b2a1   day-34_frontend   bridge    local

```

**3. Verify Organizational Labels (SRE Filtering):**

```bash
docker ps --filter "label=tier=frontend"

```

*Expected Output:*

```text
CONTAINER ID   IMAGE                COMMAND           STATUS          PORTS                    NAMES
abcd12345678   day-34-web           "python app.py"   Up 15 minutes   0.0.0.0:8080->5000/tcp   sre_webapp


```

<img width="2188" height="820" alt="image" src="https://github.com/user-attachments/assets/ca58192f-5efb-457e-9036-3e2f20fcea82" />

---

## ⚖️ Task 6: Scaling the Web App (Bonus)

**The Experiment:**
```bash
docker compose up --scale web=3

```

**The Result:** It breaks! You will receive an error like:
`Bind for 0.0.0.0:8080 failed: port is already allocated.`

**The Root Cause (SRE Notes):**
Simple scaling breaks when you hardcode host port mappings (`"8080:5000"`).

* Replica 1 takes host port `8080`.
* Replica 2 attempts to bind to host port `8080`, but it is already in use by Replica 1, causing a fatal crash.

**The Solution & Proof of Work:**
To scale successfully, you must let Docker assign random host ports.

**1. Update `docker-compose.yml`:**
Change the `ports` mapping under the `web` service to exclude the host port:

```yaml
  web:
    # ... other configurations ...
    ports:
      - "5000"  # Only specify the container port

```

**2. Apply and Scale:**

```bash
docker compose up -d --scale web=3

```

**3. Verify Ephemeral Ports (The Output):**

```bash
docker compose ps

```

*Expected Output:*

```text
NAME               IMAGE                COMMAND                  SERVICE   STATUS          PORTS
sre_postgres       postgres:15-alpine   "docker-entrypoint.s…"   db        Up 20 minutes   5432/tcp
sre_redis          redis:7-alpine       "docker-entrypoint.s…"   cache     Up 20 minutes   6379/tcp
day-34-web-1       day-34-web           "python app.py"          web       Up 2 minutes    0.0.0.0:32768->5000/tcp
day-34-web-2       day-34-web           "python app.py"          web       Up 2 minutes    0.0.0.0:32769->5000/tcp
day-34-web-3       day-34-web           "python app.py"          web       Up 2 minutes    0.0.0.0:32770->5000/tcp

```

<img width="2920" height="1452" alt="image" src="https://github.com/user-attachments/assets/fa7650b0-2c8a-4ed2-a3f8-c10b978c0dd3" />


*(Notice how Docker automatically assigned random ports like `32768`, `32769`, and `32771` to avoid conflicts! In a real production setup, an Nginx Load Balancer would sit in front of these to route traffic seamlessly).*

