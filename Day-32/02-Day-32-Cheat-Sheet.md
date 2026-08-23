# 📦 Day 32 Cheat Sheet: Docker Volumes & Networking

## 💾 Data Persistence Management

Containers are ephemeral; when they are deleted, their writable layer is destroyed. To persist data, Docker uses Volumes and Bind Mounts.

### Volume Commands
| Command | Action |
| :--- | :--- |
| `docker volume create <name>` | Creates a new Docker-managed named volume. |
| `docker volume ls` | Lists all volumes on the host machine. |
| `docker volume inspect <name>` | Shows detailed info, including where the data lives on the host. |
| `docker volume rm <name>` | Deletes a specific volume (cannot be in use by a container). |
| `docker volume prune` | ⚠️ Deletes **all** unused volumes to free up disk space. |

### Mounting Data to Containers
You use the `-v` (or `--mount`) flag during `docker run` to attach storage.

| Type | Syntax | Example |
| :--- | :--- | :--- |
| **Named Volume** | `-v <volume_name>:<container_path>` | `docker run -v db_data:/var/lib/mysql mysql:8.0` |
| **Bind Mount** | `-v <host_absolute_path>:<container_path>` | `docker run -v $(pwd):/usr/share/nginx/html nginx` |

### 💡 SRE Decision Matrix: Storage
*   **Use Named Volumes:** For database files, persistent application state, or sharing data securely between containers. (Docker manages the file permissions and location).
*   **Use Bind Mounts:** For local development (injecting your live source code into a container so you don't have to rebuild images on every code save).

---

## 🌐 Docker Networking

By default, containers cannot talk to each other by name. Custom networks solve this by providing internal DNS resolution.

### Networking Commands
| Command | Action |
| :--- | :--- |
| `docker network create <name>` | Creates a new custom bridge network. |
| `docker network ls` | Lists all networks (bridge, host, none, and customs). |
| `docker network inspect <name>` | Shows which containers are currently attached to the network. |
| `docker network rm <name>` | Deletes a custom network. |
| `docker network prune` | ⚠️ Deletes **all** unused networks. |

### Connecting Containers
| Action | Syntax | Example |
| :--- | :--- | :--- |
| **At Startup** | `--network <net_name>` | `docker run -d --name backend --network my-app-net nginx` |
| **While Running** | `docker network connect <net> <container>` | `docker network connect my-app-net existing_db` |

### 💡 SRE Decision Matrix: Networking
| Network Type | Built-in DNS? | Best Used For |
| :--- | :--- | :--- |
| **Default `bridge`** | ❌ No (IP only) | Legacy setups. Avoid in modern production. |
| **Custom `bridge`** | ✅ Yes (By container name) | **Standard choice.** Allows microservices to communicate securely by name (e.g., `ping database`). |
| **`host`** | N/A (Uses host's network) | High-performance apps where port-mapping overhead is unacceptable. |
| **`none`** | N/A (Completely isolated) | Maximum security, air-gapped containers. |

---
> **🔥 Production Golden Rule:** 
> Never rely on a container's IP address (they change on every restart). Always create a custom network and communicate using the Container Name!
