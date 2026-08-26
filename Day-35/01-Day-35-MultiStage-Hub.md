
# 🚀 Day 35: Multi-Stage Builds & Docker Hub Runbook

## 🏗️ Step 1: The Baseline Build (Single-Stage)
First, we create a traditional, unoptimized image to establish a size baseline for our Python web application.

*   Create a file named `Dockerfile.single` with standard instructions:
    ```dockerfile
    FROM python:3.9
    WORKDIR /app
    COPY requirements.txt .
    RUN pip install -r requirements.txt
    COPY app.py .
    CMD ["python", "app.py"]
    ```
*   Compile the baseline image:
    ```bash
    docker build -t sre-flask-app:fat -f Dockerfile.single .
    ```
*   Check the resulting image size (typically around 1GB):
    ```bash
    docker images | grep sre-flask-app
    ```
    <img width="2940" height="1524" alt="image" src="https://github.com/user-attachments/assets/79f2ee82-a1d2-458c-ab06-4b377bbbc925" />

---

## 🔪 Step 2: The Multi-Stage Optimization
Next, we separate the heavy build dependencies from the runtime environment. This drastically reduces both the attack surface and the final image size.

*   Overwrite your main `Dockerfile` with this multi-stage configuration:
    ```dockerfile
    # --- Stage 1: Builder ---
    FROM python:3.9 AS builder
    WORKDIR /app
    RUN python -m venv /opt/venv
    ENV PATH="/opt/venv/bin:$PATH"
    COPY requirements.txt .
    RUN pip install --no-cache-dir -r requirements.txt

    # --- Stage 2: Production ---
    FROM python:3.9-slim
    RUN addgroup --system sre_group && adduser --system --group nonroot_user
    WORKDIR /app
    COPY --from=builder /opt/venv /opt/venv
    ENV PATH="/opt/venv/bin:$PATH"
    COPY app.py .
    USER nonroot_user
    CMD ["python", "app.py"]
    ```
*   Compile the optimized image:
    ```bash
    docker build -t sre-flask-app:optimized .
    ```
*   Compare the sizes to observe an 85%+ reduction:
    ```bash
    docker images | grep sre-flask-app
    ```

    <img width="2936" height="1782" alt="image" src="https://github.com/user-attachments/assets/aef7fb00-1432-4c28-a59e-9bf6df769c58" />

---

## 🌍 Step 3: Pushing to Docker Hub
Once optimized, the image must be versioned and distributed via a remote registry for global access.

*   Authenticate with Docker Hub via terminal:
    ```bash
    docker login -u <user-name>
    ```
*   Tag the local image using your specific Docker Hub username and a semantic version:
    ```bash
    docker tag sre-flask-app:optimized <your-username>/sre-flask-app:v1.0.0
    ```
*   Push the tagged image to your remote repository:
    ```bash
    docker push <your-username>/sre-flask-app:v1.0.0
    ```

    <img width="2940" height="1850" alt="image" src="https://github.com/user-attachments/assets/7b647615-42f4-4ebe-9c58-8793b8fc2c41" />

---

## 🛡️ Step 4: Verification & SRE Best Practices
Finally, validate that the remote image functions correctly and adheres to security standards.

*   Remove the local copy to force Docker to pull from the remote registry:
    ```bash
    docker rmi <your-username>/sre-flask-app:v1.0.0
    ```
*   Run the container pulling directly from Docker Hub:
    ```bash
    docker run -d -p 5000:5000 --name test_pull <your-username>/sre-flask-app:v1.0.0
    ```
*   Verify the container is actively enforcing the non-root user policy:
    ```bash
    docker exec test_pull whoami
    ```

    <img width="2936" height="1420" alt="image" src="https://github.com/user-attachments/assets/c7cfd157-9ea1-42a3-a4de-4c0a5b12022a" />
---
