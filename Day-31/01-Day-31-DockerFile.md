# 🐳 Day 31: Dockerfile – Build Your Own Images

Today's milestone shifts from merely *consuming* Docker images to *creating* them. Writing efficient, secure, and optimized Dockerfiles is a core competency for any DevOps or Site Reliability Engineer. 

---

## 🎯 Task 1: Your First Dockerfile

**Objective:** Create a basic image using Ubuntu, install `curl`, and set a default message.

**`Dockerfile` (inside `my-first-image/` directory):**
```dockerfile
# Use the official Ubuntu base image
FROM ubuntu:latest

# Update packages and install curl
RUN apt-get update && apt-get install -y curl

# Set the default command when the container starts
CMD ["echo", "Hello from my custom image!"]

```

**Build & Run Commands:**

```bash
# Build the image and tag it
docker build -t my-ubuntu:v1 .

# Run the container
docker run my-ubuntu:v1
# Output: Hello from my custom image!

```

<img width="1094" height="302" alt="image" src="https://github.com/user-attachments/assets/11a585fa-114e-447f-b92b-b2e174e9dc78" />


---

## 🛠️ Task 2: Dockerfile Instructions

**Objective:** Utilize core Dockerfile instructions (`FROM`, `RUN`, `COPY`, `WORKDIR`, `EXPOSE`, `CMD`).

**`Dockerfile`:**

```dockerfile
# FROM: Sets the base image
FROM python:3.9-slim

# WORKDIR: Sets the working directory inside the container
WORKDIR /app

# COPY: Copies files from the host (local machine) into the container
COPY requirements.txt .
COPY app.py .

# RUN: Executes commands during the BUILD process (creating a new layer)
RUN pip install -r requirements.txt

# EXPOSE: Documents the port the container listens on (purely informational)
EXPOSE 8080

# CMD: The default command executed when the container RUNS
CMD ["python", "app.py"]

```
### 1. Create `requirements.txt`

This file tells Python which dependencies to install (which the `RUN pip install` step will use).

```text
Flask==3.0.0

```

### 2. Create `app.py`

This is a very simple Python web server that will run on port 8080 (which matches the `EXPOSE 8080` and `CMD` steps in your Dockerfile).

```python
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    # We can return HTML directly from Flask!
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Task 2: Docker App</title>
        <style>
            /* This styles the whole page */
            body {
                background-color: #2b2b2b; /* Dark grey background */
                color: #ffffff; /* White text */
                font-family: 'Courier New', Courier, monospace; /* Terminal font */
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
            }
            
            /* This styles the box in the middle */
            .container {
                background-color: #1e1e1e; /* Darker grey for the box */
                padding: 40px 60px;
                border-radius: 12px;
                box-shadow: 0 10px 30px rgba(0, 0, 0, 0.7);
                border: 2px solid #0db7ed; /* Docker blue border */
                text-align: center;
            }

            /* This styles the graphics/emojis */
            .graphics {
                font-size: 60px;
                margin-bottom: 20px;
                letter-spacing: 15px;
            }

            h1 {
                color: #0db7ed; /* Docker blue text */
                margin-bottom: 10px;
            }

            p {
                font-size: 18px;
                color: #a9b7c6;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <!-- The Graphics -->
            <div class="graphics">🐳 ⚙️ 🚀</div>
            
            <!-- The Text -->
            <h1>Task 2 Complete!</h1>
            <p>Hello from Day 31! The Dockerfile instructions worked perfectly.</p>
        </div>
    </body>
    </html>
    """
    return html_content

if __name__ == '__main__':
    # Running on 0.0.0.0 ensures it is accessible from outside the container
    app.run(host='0.0.0.0', port=8080)
```

### 3. Build and Run!

Once you have those two files next to your Task 2 `Dockerfile`, you can run:

```bash
# Build the image
docker build -t my-python-app:v1 .

# Run the container (mapping your local port 8080 to the container's port 8080)
docker run -d -p 8080:8080 --name task2-app my-python-app:v1

```

If you go to `http://localhost:8080` in your browser, you should see your Python app running! Let me know if the build goes through successfully now.

<img width="1856" height="1050" alt="image" src="https://github.com/user-attachments/assets/6f10406b-a391-452e-a7de-cc915075ed78" />

---

## ⚖️ Task 3: CMD vs ENTRYPOINT

Understanding the distinction between `CMD` and `ENTRYPOINT` is essential for building flexible, predictable, and production-ready container images.

---

### Step 1: Testing `CMD` Behavior

`CMD` sets default commands or parameters that can be easily overridden from the command line during container startup.

#### 1. Create `Dockerfile.cmd`

```dockerfile
FROM alpine:latest
CMD ["echo", "hello"]

```

#### 2. Build the Image

```bash
docker build -f Dockerfile.cmd -t my-cmd-image .

```

#### 3. Test Execution & Override

* **Default execution:**
```bash
docker run my-cmd-image

```


* **Output:** `hello`


* **Overriding with a custom command:**
```bash
docker run my-cmd-image date

```


* **Output:** `Sat Aug 22 14:25:00 UTC 2026`
* **Analysis:** The `date` command completely replaces the default `echo hello` instruction.


<img width="1094" height="584" alt="image" src="https://github.com/user-attachments/assets/1b17b27f-de73-40cb-890e-b499345f4174" />


---

### Step 2: Testing `ENTRYPOINT` Behavior

`ENTRYPOINT` configures a container to run as an immutable executable. CLI arguments passed at startup are appended to the executable rather than replacing it.

#### 1. Create `Dockerfile.entrypoint`

```dockerfile
FROM alpine:latest
ENTRYPOINT ["echo"]

```

#### 2. Build the Image

```bash
docker build -f Dockerfile.entrypoint -t my-entrypoint-image .

```

#### 3. Test Execution & Argument Passing

* **Default execution:**
```bash
docker run my-entrypoint-image

```


* **Output:** *(blank line — `echo` runs without any trailing arguments)*


* **Passing arguments at startup:**
```bash
docker run my-entrypoint-image hello world

```


* **Output:** `hello world`
* **Analysis:** The arguments `hello world` were appended directly to `echo`, resulting in `echo hello world`.


<img width="2188" height="980" alt="image" src="https://github.com/user-attachments/assets/21709d37-fc54-424c-ad7f-d51dea736309" />


---

### Step 3: Comparative Breakdown

| Directive | Primary Purpose | CLI Override Behavior | Best Used For |
| --- | --- | --- | --- |
| **`CMD`** | Defines default command or arguments. | Fully replaced if flags/commands are provided to `docker run`. | Flexible containers, interactive shells, or replaceable run modes. |
| **`ENTRYPOINT`** | Converts the container into a fixed binary/executable. | Preserved; CLI inputs are appended as arguments. | Single-purpose CLI tools, microservices, or fixed binaries. |

---

### 💡 SRE Decision Guide: When to Use Which?

* **Use `CMD` when:**
* You want to provide a sensible default behavior, but allow developers to override it easily (e.g., launching an application vs. starting an interactive debugging shell).


* **Use `ENTRYPOINT` when:**
* The container has one specific purpose (e.g., a Database migration CLI tool or an Nginx web server) and should behave like a standalone binary.



> **🔥 Production Pattern (Combining Both):**
> Combine `ENTRYPOINT` and `CMD` to define an immutable binary alongside flexible default arguments.
> ```dockerfile
> ENTRYPOINT ["python3", "app.py"]
> CMD ["--port", "8080"]
> 
> ```
> 
> 
> * **Running `docker run my-app**` executes `python3 app.py --port 8080`.
> * **Running `docker run my-app --port 9090**` overrides only the `CMD` portion, executing `python3 app.py --port 9090`.
> 
>
---

## 🌐 Task 4: Build a Simple Web App Image

**Objective:** Package a static HTML site using an Nginx base image.

**1. Create `index.html`:**

```html
<!DOCTYPE html>
<html>
<head><title>Day 31 DevOps Web App</title></head>
<body>
    <h1>Production-Ready DevOps & SRE Journey 🚀</h1>
    <p>Serving custom static content from an Nginx container!</p>
</body>
</html>

```

**2. Create `Dockerfile`:**

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/

```

**3. Build and Run:**

```bash
docker build -t my-website:v1 .
docker run -d -p 8080:80 --name day31-web my-website:v1

```

*Verification: Navigate to `http://localhost:8080` in the browser.*

<img width="613" height="232" alt="image" src="https://github.com/user-attachments/assets/b19de737-d1c0-4f98-b7e2-505aedad2e75" />



---

## 🚫 Task 5: .dockerignore

Just like `.gitignore`, `.dockerignore` prevents unnecessary or sensitive files from being sent to the Docker daemon during the build process (the "build context").

**`.dockerignore`:**

```text
node_modules/
.git/
*.md
.env

```

*Why this matters:* It significantly speeds up build times, keeps the image size small, and prevents accidental leakage of secrets (like `.env` files) into the final Docker image.

---

## ⚡ Task 6: Build Optimization (Layer Caching)

**How Docker Caching Works:**
Docker builds images layer by layer (each `RUN`, `COPY`, and `ADD` creates a layer). If a layer's instruction and files haven't changed, Docker reuses the cached layer from the previous build instead of rebuilding it. However, **if one layer changes, all subsequent layers below it must be rebuilt.**

**Why Layer Order Matters for Build Speed:**
To optimize build times, you must order your Dockerfile from **least frequently changed** to **most frequently changed**.

*Bad Example:*

```dockerfile
COPY . .                   # Source code changes often (cache busts here!)
RUN npm install            # Dependencies reinstall every single time code changes. Slow!

```

*Optimized Example:*

```dockerfile
COPY package.json .        # Dependencies file rarely changes
RUN npm install            # Installs and caches dependencies
COPY . .                   # Source code copied LAST. Only this layer rebuilds when code changes!

```
