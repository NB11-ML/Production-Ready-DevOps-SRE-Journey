# 🌐 Day 15: Networking Concepts Cheat Sheet

*DNS, IP Addressing, CIDR Subnetting, Ports & Diagnostic Commands*

---

## 🔍 1. DNS (Domain Name System) Quick Reference

### DNS Lookup Flow

`Browser Cache` ➔ `OS Cache` ➔ `Recursive Resolver` ➔ `Root Server (.)` ➔ `TLD Server (.com)` ➔ `Authoritative DNS` ➔ `IP returned`

### Common DNS Record Types

| Record | Full Name | Purpose | Example / Description |
| --- | --- | --- | --- |
| **`A`** | IPv4 Address | Maps domain to IPv4 address | `myapp.com ➔ 142.250.190.46` |
| **`AAAA`** | IPv6 Address | Maps domain to IPv6 address | `myapp.com ➔ 2404:6800:4009::200e` |
| **`CNAME`** | Canonical Name | Maps alias domain to another domain | `[www.myapp.com](https://www.myapp.com) ➔ myapp.com` |
| **`MX`** | Mail Exchange | Directs email to incoming mail servers | `myapp.com ➔ mail.google.com` |
| **`NS`** | Name Server | Delegates DNS zone to specific name server | `myapp.com ➔ ns1.cloudflare.com` |
| **`PTR`** | Pointer Record | Reverse DNS lookup (IP to domain mapping) | `142.250.190.46 ➔ google.com` |

### Essential DNS Commands

```bash
# Basic DNS lookup
dig example.com

# Extract IP address only (Short output)
dig example.com +short

# Query specific record type (e.g., MX, CNAME, TXT)
dig example.com MX

# Query directly against a specific DNS server (e.g., Google 8.8.8.8)
dig @8.8.8.8 example.com

```

---

## 📡 2. IP Addressing & RFC 1918 Private Ranges

### IPv4 Structure

* **32-Bit Decimal Address:** Composed of 4 octets (8 bits each) separated by dots.
* **Range:** `0.0.0.0` to `255.255.255.255` ($2^{32} \approx \text{4.3 Billion IPs}$).

### Public vs. Private IPs

* **Public IP:** Globally routable on the public Internet.
* **Private IP:** Reserved for local networks (LANs, AWS VPCs, Docker containers); non-routable on the public internet.

### RFC 1918 Reserved Private IP Ranges

| Class | CIDR Block | IP Range | Common Use Case |
| --- | --- | --- | --- |
| **Class A** | `10.0.0.0/8` | `10.0.0.0 – 10.255.255.255` | Large Enterprises, AWS VPCs, K8s Pod Networks |
| **Class B** | `172.16.0.0/12` | `172.16.0.0 – 172.31.255.255` | Medium Networks, Default Docker Bridge Networks |
| **Class C** | `192.168.0.0/16` | `192.168.0.0 – 192.168.255.255` | Home LANs, Small Office Networks |

---

## 🧮 3. CIDR Notation & Subnetting

### Subnet Calculation Formula

$$\text{Total IPs} = 2^{(32 - n)}$$

$$\text{Usable Hosts} = 2^{(32 - n)} - 2 \quad \text{(Excludes Network and Broadcast IPs)}$$

### CIDR Quick Reference Table

| CIDR | Subnet Mask | Total IPs | Usable Hosts | Common Deployment Area |
| --- | --- | --- | --- | --- |
| **`/32`** | `255.255.255.255` | 1 | **1** | Single Host IP / Specific Firewall Rule |
| **`/30`** | `255.255.255.252` | 4 | **2** | Point-to-Point Router Connections |
| **`/28`** | `255.255.255.240` | 16 | **14** | Small Microservice / Internal DB Clusters |
| **`/24`** | `255.255.255.0` | 256 | **254** | Standard VPC Subnet (K8s Node Pool) |
| **`/16`** | `255.255.0.0` | 65,536 | **65,534** | Entire Virtual Private Cloud (AWS VPC) |
| **`/8`** | `255.0.0.0` | 16,777,216 | **16,777,214** | Massive Carrier/Enterprise Backbone |

> **Note:** Reserved addresses in every subnet:
> 1. **First IP:** Network Address (e.g., `192.168.1.0`)
> 2. **Last IP:** Broadcast Address (e.g., `192.168.1.255`)
> 
> 

---

## 🚪 4. Standard DevOps & SRE Ports

| Port | Service | Protocol | Description |
| --- | --- | --- | --- |
| **`22`** | SSH | TCP | Secure Shell Remote Administration |
| **`53`** | DNS | UDP/TCP | Domain Name Resolution |
| **`80`** | HTTP | TCP | Unencrypted Web Traffic |
| **`443`** | HTTPS | TCP | Encrypted Web Traffic (TLS/SSL) |
| **`3306`** | MySQL | TCP | MySQL / MariaDB Relational Database |
| **`5432`** | PostgreSQL | TCP | PostgreSQL Database |
| **`6379`** | Redis | TCP | In-Memory Key-Value Data Store |
| **`8080`** | Alt-HTTP | TCP | Alternative Web Port / Jenkins / Tomcat |
| **`27017`** | MongoDB | TCP | MongoDB Document Database |

---

## 🛠️ 5. Practical Networking Commands

```bash
# ------------------------------------------------------------------
# INTERFACE & ROUTING INSPECTION
# ------------------------------------------------------------------
ip addr show                 # Display IP addresses on local interfaces
ip route show                # View default gateway and routing table

# ------------------------------------------------------------------
# SOCKET & PORT ANALYSIS
# ------------------------------------------------------------------
sudo ss -tulpn               # List listening TCP/UDP sockets with PIDs
lsof -i :8080                # Identify process bound to specific port

# ------------------------------------------------------------------
# CONNECTIVITY & PORT PROBING
# ------------------------------------------------------------------
ping -c 4 10.0.1.50          # Check L3 reachability
nc -zv 10.0.1.50 3306        # Probe remote L4 TCP port reachability
tracepath example.com        # Trace network path hops (non-root)

# ------------------------------------------------------------------
# HTTP / APPLICATION LEVEL CHECKS
# ------------------------------------------------------------------
curl -Iv https://example.com # Inspect HTTP response headers and SSL status

```

---

## 🚨 6. SRE Incident Triage Checklist

When Service A cannot reach Service B:

```
[Local Process] ➔ [DNS Resolution] ➔ [Layer 3 Route] ➔ [Layer 4 Firewall] ➔ [Layer 7 Application]

```

1. **Process Check:** Is the target service running and bound to the expected port?
`ss -tulpn | grep :<port>`
2. **DNS Check:** Does the target domain resolve to the correct IP?
`dig +short <hostname>`
3. **Layer 3 Check:** Is the host reachable over the network?
`ping -c 4 <ip>`
4. **Layer 4 Check:** Is the TCP port open through Security Groups / Firewalls?
`nc -zv <ip> <port>`
5. **Layer 7 Check:** Is the application returning valid HTTP status codes?
`curl -Iv
