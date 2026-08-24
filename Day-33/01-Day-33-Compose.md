# 🐙 Day 33: Docker Compose – Multi-Container Basics

> **Part of the Production-Ready DevOps & SRE Journey**  
> *Evolving from manual container management to declarative, multi-container orchestration.*

---

## 📌 Overview

Yesterday, we manually created networks, volumes, and containers one by one using imperative CLI commands. In a production environment, this is error-prone and hard to version control. 

**Docker Compose** solves this. It allows us to define our entire multi-container application stack—including networking, storage, and runtime variables—inside a single declarative YAML file (`docker-compose.yml`). 

---

## 🎯 Task 1: Install & Verify

Modern Docker installations (Docker Desktop, updated Linux engines) come with Docker Compose V2 pre-installed as a CLI plugin. 

```bash
# Verify the installation and version
docker compose version

```

*(SRE Note: You might see older tutorials using the hyphenated `docker-compose` command. That is V1, which is now deprecated. Always use the space-separated `docker compose` for V2).*

---

## 🛠️ Task 2: Your First Compose File

**Objective:** Spin up a simple Nginx server using declarative code.

**1. Create `docker-compose.yml` in a folder called `compose-basics`:**

```yaml
services:
  web:
    image: nginx:alpine
    container_name: basic-nginx
    ports:
      - "8080:80"

```

**2. Manage the Lifecycle:**

```bash
# Start the container
docker compose up

# Stop and remove the container, network, and attached resources
docker compose down

```



*Verification: While it was running, the Nginx welcome page was accessible at `http://localhost:8080`.*

*Docker Compose Up*

<img width="2930" height="1658" alt="image" src="https://github.com/user-attachments/assets/ce4878f6-3e92-4da0-ad77-a978087caf35" />

*Docker Compose Down*

<img width="2940" height="1620" alt="image" src="https://github.com/user-attachments/assets/b5fd0295-9755-4eae-8943-edc80f19efc1" />


---

## 🚀 Task 3: Two-Container Setup (WordPress + MySQL)

**Objective:** Run a frontend application and a backend database that communicate seamlessly, with persistent storage.

**`docker-compose.yml`:**

```yaml
services:
  db:
    image: mysql:8.0
    container_name: wp_database
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootsecretpass
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wp_user
      MYSQL_PASSWORD: wp_password
    volumes:
      - db_data:/var/lib/mysql

  wordpress:
    image: wordpress:latest
    container_name: wp_frontend
    depends_on:
      - db
    ports:
      - "8000:80"
    restart: always
    environment:
      # Notice how WORDPRESS_DB_HOST uses the exact service name 'db' from above!
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wp_user
      WORDPRESS_DB_PASSWORD: wp_password
      WORDPRESS_DB_NAME: wordpress

volumes:
  db_data:

```

**Execution & Verification:**

1. Run `docker compose up -d`.
2. Visit `http://localhost:8000` to see the WordPress installation screen and set it up.
3. Run `docker compose down` to destroy the containers.
4. Run `docker compose up -d` again.
5. **Result:** Your WordPress site and setup are still there! The `db_data` named volume persisted the MySQL records securely on the host.

<img width="2928" height="1662" alt="image" src="https://github.com/user-attachments/assets/d622a9a5-b6dc-45a9-988c-143f06afbbcf" />


*(SRE Note: Notice we didn't declare a network? Docker Compose automatically creates a default bridge network for this stack and registers the service names (`db` and `wordpress`) as DNS records!)*

---

## ⚡ Task 4: Core Compose Commands

Here is the essential runbook for managing Compose stacks:

| Command | Action |
| --- | --- |
| `docker compose up -d` | **Start:** Builds, (re)creates, and starts containers in the background (detached mode). |
| `docker compose ps` | **Status:** Lists containers running specifically for this compose project. |
| `docker compose logs -f` | **Monitor:** Tails the combined logs of *all* services in the stack continuously. |
| `docker compose logs <service>` | **Debug:** Views logs for a single service (e.g., `docker compose logs db`). |
| `docker compose stop` | **Pause:** Stops the containers gracefully without destroying them or their network. |
| `docker compose down` | **Destroy:** Stops and removes containers, default networks, and temporary mounts. |
| `docker compose up --build` | **Rebuild:** Forces Docker to rebuild custom image layers before starting (used if you changed a `Dockerfile`). |

<img width="2188" height="1232" alt="image" src="https://github.com/user-attachments/assets/8f779095-d327-4c45-9561-0534e88c32ba" />


---

## 🔒 Task 5: Environment Variables (Security Best Practices)

Hardcoding passwords inside a `docker-compose.yml` file is a major security violation if committed to GitHub. Instead, we use `.env` files.

**1. Create a `.env` file in the same directory:**

```text
# .env file (Make sure to add this file to your .gitignore!)
DB_ROOT_PASS=secure_production_pass
WP_DB_USER=secure_user
WP_DB_PASS=secure_wp_pass

```

**2. Update your `docker-compose.yml` to reference it:**

```yaml
services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASS}
      MYSQL_DATABASE: wordpress
      MYSQL_USER: ${WP_DB_USER}
      MYSQL_PASSWORD: ${WP_DB_PASS}

```

*Verification: When you run `docker compose up`, Docker automatically detects the `.env` file in the directory, injects the variables, and starts the database securely.*

<img width="2936" height="1736" alt="image" src="https://github.com/user-attachments/assets/7629cef4-5189-4ea5-9477-93e48c339277" />

---
