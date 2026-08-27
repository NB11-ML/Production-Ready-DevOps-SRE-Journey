# 🐳 Docker Project: Dockerize a Full Applicationk

This repository contains a containerised **Python Flask REST API** backed by a **PostgreSQL Database** designed for advanced Docker and Docker Compose orchestration practice. 

The architecture demonstrates production DevOps methodologies, including **multi-stage optimization**, **non-root security permissions**, **dynamic environmental injection**, and **automated database service health checks**.

---

## 🏗️ Architecture Overview

*   **🌐 Frontend Service (`web`)**: A lightweight Python 3.11 web layer running Flask and SQLAlchemy under a non-privileged system user profile.
*   **🗄️ Backend Database (`db`)**: A robust, persistent PostgreSQL 15 instance optimized using the Alpine Linux ecosystem.
*   **🌐 Network Topology (`app_network`)**: An isolated, private bridge network preventing outside exposure of the database engine port.
*   **💾 Volume Storage (`pg_prod_data`)**: A dedicated, named Docker volume ensuring total data persistence across container lifecycle teardowns.

---

## ⚙️ Environment Configurations

The system reads credentials from a local `.env` file sitting at the root directory level. Create a `.env` file before booting the stack:

```ini
POSTGRES_USER=app_admin
POSTGRES_PASSWORD=vault_secure_password_2026
POSTGRES_DB=telemetry_db
```

---

## 🛠️ Local Development Lifecycle

Follow this command sequence to build, orchestrate, and test the multi-container stack locally on your workstation.

### 1. Build and Launch the Architecture
Run the following command to compile your local multi-stage Dockerfile blueprints, provision volumes, configure network routing, and execute the processes in background (detached) mode:
```bash
docker compose up --build -d
```

### 2. Verify Infrastructure Health
Confirm that both container services are executing cleanly and that the database engine has successfully completed its initialization loops:
```bash
docker compose ps
```
*Your database container status should display `Up (healthy)` before the web service connects.*

### 3. Track Context Engine Logs
Stream real-time diagnostics from your Flask server execution stack:
```bash
docker compose logs -f web
```

### 4. Live Functional Validation
Verify data persistence and internal networking by hitting the mapped container port using `curl` or by visiting `http://localhost:5000` in your web browser:
```bash
curl http://localhost:5000
```
*Expected JSON structural payload response on Hit #1:*
```json
{
  "database_hits": 1,
  "message": "Hello from Flask inside a secure Docker container!",
  "status": "success"
}
```
*Refresh the endpoint. The `database_hits` tracker increments dynamically, validating live communication and disk persistence.*

---

## 🚢 Production Registry Shipping

To push your optimized application image up to your public registry hub for remote server deployment, use this sequence:

```bash
# 1. Log in securely to your public account registry
docker login

# 2. Tag your local image blueprint to map your target namespace
docker tag <local_project_web_image>:latest <your-dockerhub-username>/flask-db-app:latest

# 3. Ship the layers to Docker Hub
docker push <your-dockerhub-username>/flask-db-app:latest
```

---

## 🧪 Fresh Production Verification Flow

To simulate a clean, remote production deployment server that **only pulls from your public Docker Hub registry** without referencing local project source code or `Dockerfile` files, use the production override workflow.

### 1. Create a Production Compose Configuration
Create a separate file named `docker-compose.prod.yml` and paste the following code block (notice the `build:` block is completely absent):

```yaml
version: '3.8'

services:
  web:
    image: <your-dockerhub-username>/flask-db-app:latest
    ports:
      - "5000:5000"
    environment:
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
      - POSTGRES_DB=\${POSTGRES_DB}
      - DB_HOST=db
    depends_on:
      db:
        condition: service_healthy
    networks:
      - app_network

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
      - POSTGRES_DB=\${POSTGRES_DB}
    volumes:
      - pg_prod_data:/var/lib/postgresql/data
    networks:
      - app_network
    healthcheck:
      test:
        - "CMD-SHELL"
        - "pg_isready -U \({POSTGRES_USER} -d\){POSTGRES_DB}"
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 5s

networks:
  app_network:
    driver: bridge

volumes:
  pg_prod_data:
```

### 2. Execute the Clean Production Deployment
Wipe all local containers, caches, networks, and images completely to ensure a blank workspace, then point your launcher straight to your production blueprint:

```bash
# Wipe the local environment clean
docker compose down --volumes --rmi all

# Run deployment using only the production file template
docker compose -f docker-compose.prod.yml up -d
```
*Your Docker engine will pull down the layers over the internet directly from your remote registry registry hub before starting up the containers.*

---

## 🧹 Infrastructure Teardown
To safely tear down application operations while preserving your critical database records on disk for your next run cycle, execute:
```bash
docker compose down
```
*To completely wipe persistent volumes along with the containers, add the `-v` flag:*
```bash
docker compose down -v
```

