
# 🐳 Day 36 – Docker Project: Dockerize a Full Application End-to-End

## 🏗️ App Selection & Architecture

### What App I Chose & Why

I chose a **Python Flask API** coupled with a **PostgreSQL Database**. This architecture mimics common production workloads found in real-world environments. It requires managing multi-container networks, handling data persistence, ensuring proper boot order using health checks, and securely managing relational schemas.

### 📁 Project Layout

```text
2026/day-36/
├── .dockerignore
├── .env
├── app.py
├── day-36-docker-project.md
├── docker-compose.yml
├── Dockerfile
├── README.md
└── requirements.txt
```
---
## 🛠️ 1. Application Code & Dependencies

### 📄 requirements.txt

```text

Flask==3.0.3
Flask-SQLAlchemy==3.1.1
psycopg2-binary==2.9.9

```

### 🐍 `app.py`

```python
import os
import sys
from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)

# Fetch database environment variables
DB_USER = os.getenv("POSTGRES_USER")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD")
DB_NAME = os.getenv("POSTGRES_DB")
DB_HOST = os.getenv("DB_HOST", "db")

if not all([DB_USER, DB_PASSWORD, DB_NAME]):
    print("CRITICAL ERROR: Missing required database environment configurations.", file=sys.stderr)
    sys.exit(1)

# Configure PostgreSQL Database URI
app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:5432/{DB_NAME}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# Database Model Schema
class HitCounter(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    count = db.Column(db.Integer, nullable=False, default=0)

# Initialize schema immediately inside app context
with app.app_context():
    try:
        db.create_all()
        if not HitCounter.query.first():
            db.session.add(HitCounter(count=0))
            db.session.commit()
    except Exception as e:
        print(f"Database schema initialization deferred or failed: {e}", file=sys.stderr)

@app.route('/')
def home():
    try:
        hit = HitCounter.query.first()
        hit.count += 1
        db.session.commit()
        return jsonify({
            "status": "success",
            "message": "Hello from Flask inside a secure Docker container!",
            "database_hits": hit.count
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": "Database interaction failed",
            "details": str(e)
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```
---

## 📦 2. Dockerizing the Application

### 🚫 `.dockerignore`

```text
__pycache__/
*.pyc
*.pyo
*.pyd
.env
.git
.gitignore
```

### 🐳 `Dockerfile`

```dockerfile
# ==========================================
# 🏗️ Stage 1: Build & Dependency Wheels Compilation
# ==========================================
FROM python:3.11-slim AS builder

# Prevent Python from writing .pyc files to disk
ENV PYTHONDONTWRITEBYTECODE=1
# Prevent Python from buffering stdout/stderr for quick logging
ENV PYTHONUNBUFFERED=1

WORKDIR /build

# Build dependencies tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Compile Python dependencies to wheels to avoid build chains in production image
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /build/wheels -r requirements.txt


# ==========================================
# 🚀 Stage 2: Final Slim Lightweight Production Image
# ==========================================
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install runtime shared libraries required by psycopg2
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy pre-compiled wheels from builder stage
COPY --from=builder /build/wheels /images/wheels
COPY --from=builder /build/requirements.txt .

# Install wheels locally without searching internet indexes
RUN pip install --no-cache-dir --no-index --find-links=/images/wheels -r requirements.txt \
    && rm -rf /images

# Copy application source code
COPY . .

# Create a non-privileged dedicated service system user for runtime execution
RUN useradd -u 10001 webuser && chown -R webuser:webuser /app
USER webuser

EXPOSE 5000

CMD ["python", "app.py"]
```
---

## 🐙 3. Docker Compose Orchestration
### 🔑 `.env`

```ini
POSTGRES_USER=app_admin
POSTGRES_PASSWORD=vault_secure_password_2026
POSTGRES_DB=telemetry_db
```

### ⚙️ `docker-compose.yml`

```yaml
version: '3.8'

services:
  # 🌐 Web Application Container
  web:
    build:
      context: .
      dockerfile: Dockerfile
    image: yourdockerhubusername/flask-db-app:latest
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

  # 🗄️ PostgreSQL Database Container
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
      test: ["CMD-SHELL", "pg_isready -U \${POSTGRES_USER} -d \${POSTGRES_DB}"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 5s

# 🌐 Isolated Network Bridge
networks:
  app_network:
    driver: bridge

# 💾 Persistent Storage Volume
volumes:
  pg_prod_data:
```
---

## 🚀 4. Local Build, Execution & Verification Workflow

Before shipping the project, the entire multi-container stack must be built and tested locally to ensure the Flask application securely communicates with the PostgreSQL database container.

### 🛠️ Step 1: Build and Launch the Containers
Run the following command to read the configuration blueprints, build the multi-stage Flask image, create the isolated network bridge, and launch both containers in detached (background) mode:

```bash
docker compose up --build -d
```

### 📋 Step 2: Verify Container States & Process Isolation
Check the status of your services to confirm that both containers are running smoothly and that the database container has passed its health checks:

```bash
docker compose ps
```
*Expected Output:*
* `db` service status shows **`Up (healthy)`**
* `web` service status shows **`Up`** and maps port `5000->5000`

  <img width="2940" height="1728" alt="image" src="https://github.com/user-attachments/assets/2ace1410-1543-41e0-b79a-773e5591c74c" />


### 🪵 Step 3: Stream Runtime Application Logs
Inspect the live application logs to verify that the database schema initialized successfully and that the Flask application server is running under the non-root user account:

```bash
docker compose logs -f web
```

### 🧪 Step 4: Live Functional Testing
Test the working application stack by hitting the live API route via `curl` or opening `http://localhost:5000` in your web browser:

```bash
curl http://localhost:5000
```
*Expected JSON Response Output on First Hit:*
```json
{
  "database_hits": 1,
  "message": "Hello from Flask inside a secure Docker container!",
  "status": "success"
}
```

<img width="2940" height="1738" alt="image" src="https://github.com/user-attachments/assets/3825f93d-2872-4378-a89c-1e2be20e49ec" />


*Refresh or curl the endpoint again. The `database_hits` value will increment dynamically, proving that data persistence across the custom bridge network is fully functional.*


---
## ⚡ 5. Challenges Faced & Solutions

1. **Race Conditions During Initialization (`depends_on` failure)**: 
   * *Problem:* The web container started before PostgreSQL finished spinning up its storage system, causing database drop-outs immediately on execution.
   * *Solution:* Implemented a native Alpine `healthcheck` block inside `docker-compose.yml` tracking `pg_isready`, combined with structural `condition: service_healthy` rules inside `depends_on`.2. **Psycopg2 Binary Dependencies**:
   * *Problem:* Compiling database adapters natively requires bloated compilation software (`gcc`, `musl-dev`) which blows up the final container footprint size.
   * *Solution:* Split tasks via a **multi-stage build structure**. Compiled native dependency wheels within a temporary `builder` image, copying purely runtime artifacts forward into a bare production container.
---

## 📊 6. Final Analytics & Delivery Verification

### 📈 Image Optimization Performance
* **Raw Python Standard Image Base Size:** ~1.02 GB
* * **Optimized Production Multi-Stage Image Size:** **148 MB** 📉

### 🚢 Shipping & Deployment Lifecycle Verification

```bash
# Step 1: Log in securely to public Docker Registry registry hub
docker login -u <user-name>

# Step 2: Build production images from configuration blueprints
docker compose build

# Step 3: Explicitly push target production tag up to repository
docker push yourdockerhubusername/flask-db-app:latest
```

<img width="2940" height="1782" alt="image" src="https://github.com/user-attachments/assets/2a0e2928-ad21-4165-a8b5-610aa8b25d53" />


* **Docker Hub Link:** [https://docker.com](https://docker.com)
  
### 🧪 Step 7 Verification Execution Plan (Simulating a Clean Fresh Server Environment)

```bash
# 1. Clean environment teardown execution
docker compose down --volumes --rmi all

# 2. Confirm working environment state is absolutely clear
docker ps -a
docker images

# 3. Spin up environment pulling straight from Docker Hub images
docker compose up -d
```

<img width="2934" height="1738" alt="image" src="https://github.com/user-attachments/assets/aa5c1e1a-4fa5-4aed-a252-5a9025b456d6" />


All system networks automatically bound together successfully, healthcheck validations turned active-green within 8 seconds, and querying `http://localhost:5000` accurately reads persistent iterative state tracking from disk!

