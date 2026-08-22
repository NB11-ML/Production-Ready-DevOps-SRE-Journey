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

<img width="1856" height="1050" alt="image" src="https://github.com/user-attachments/assets/6f10406b-a391-452e-a7de-cc915075ed78" />


### 3. Build and Run!

Once you have those two files next to your Task 2 `Dockerfile`, you can run:

```bash
# Build the image
docker build -t my-python-app:v1 .

# Run the container (mapping your local port 8080 to the container's port 8080)
docker run -d -p 8080:8080 --name task2-app my-python-app:v1

```

If you go to `http://localhost:8080` in your browser, you should see your Python app running! Let me know if the build goes through successfully now.

---

## ⚖️ Task 3: CMD vs ENTRYPOINT

**The Experiment:**

1. **Using `CMD ["echo", "hello"]`:**
* Running `docker run my-cmd-image` outputs `hello`.
* Running `docker run my-cmd-image date` outputs the current date. The `date` command completely overrides `echo hello`.


2. **Using `ENTRYPOINT ["echo"]`:**
* Running `docker run my-entrypoint-image` outputs a blank line (echoes nothing).
* Running `docker run my-entrypoint-image hello world` outputs `hello world`. The arguments are appended to the ENTRYPOINT command.



**SRE Notes: When to use which?**

* **`CMD`:** Use when you want to provide a *default* command or arguments that the user can easily override from the command line (e.g., launching a bash shell or a default web server).
* **`ENTRYPOINT`:** Use when you want the container to act as a dedicated executable. The user cannot easily override the core command, but they can pass arguments to it.
* *(Pro-tip: They are often used together! `ENTRYPOINT` defines the executable, and `CMD` provides the default flags/arguments).*

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

```

Let me know when you are ready to set up the LinkedIn post for Day 31!

```
