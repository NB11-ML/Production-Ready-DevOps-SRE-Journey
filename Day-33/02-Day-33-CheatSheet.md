# 🐙 Day 33 Cheat Sheet: Docker Compose

Docker Compose transforms imperative Docker CLI commands into declarative Infrastructure as Code (IaC) using a single `docker-compose.yml` file.

## 🛠️ Basic YAML Structure
Here is the skeleton of a standard multi-container stack:

```yaml
services:
  backend:
    image: python:3.9-slim
    ports:
      - "8080:80"
    environment:
      - DB_HOST=database
    depends_on:
      - database

  database:
    image: postgres:15
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data: # Declares the named volume used by the database

```

---

## ⚡ Core CLI Commands

*Note: Always run these commands from the directory containing your `docker-compose.yml` file.*

| Command | Action |
| --- | --- |
| `docker compose up -d` | **Launch:** Builds, creates, and starts all services in the background (detached). |
| `docker compose down` | **Destroy:** Stops and removes containers, default networks, and temporary mounts. |
| `docker compose down -v` | **Nuke:** Destroys containers, networks, AND **deletes named volumes** (causes data loss!). |
| `docker compose stop` | **Pause:** Halts containers without destroying them or losing the network state. |
| `docker compose ps` | **Status:** Lists the current running state of containers in this specific project. |
| `docker compose logs -f` | **Monitor:** Streams combined live logs for all services in the stack. |
| `docker compose logs <service>` | **Targeted Logs:** Views logs for one specific service (e.g., `docker compose logs database`). |
| `docker compose up --build` | **Rebuild:** Forces a fresh build of custom images before starting the stack. |

---

## 💡 SRE Best Practices & Core Behaviors

### 1. Automatic DNS Networking

You do not need to manually create networks or link IP addresses. Docker Compose automatically creates a default bridge network for the stack.

* **The Magic:** The `service` name defined in the YAML file automatically becomes the DNS hostname. (e.g., The `backend` container can communicate with the database simply by pinging `database`).

### 2. Startup Order (`depends_on`)

Use the `depends_on` directive to control the initialization sequence.

* **Example:** Ensuring the database container starts *before* the web application container tries to connect to it.

### 3. Security: The `.env` File

**Never** hardcode passwords, API keys, or secrets directly into `docker-compose.yml` if it will be committed to version control.

* Create a `.env` file in the same directory:
```text
DB_PASSWORD=super_secret_production_password

```


* Reference it in the `docker-compose.yml`:
```yaml
environment:
  MYSQL_ROOT_PASSWORD: ${DB_PASSWORD}

```


* **Crucial:** Always add `.env` to your `.gitignore` file so it never gets pushed to GitHub!
