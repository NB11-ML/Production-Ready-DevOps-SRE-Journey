# 🚀 Linux Networking & SRE Troubleshooting Cheat Sheet

## 🌐 1. OSI vs TCP/IP Quick Reference

| Layer | OSI Layer | TCP/IP Layer | Key Protocols / Tech | Focus Area |
| --- | --- | --- | --- | --- |
| **7** | Application | Application | HTTP/S, DNS, SSH, gRPC | App-level communication |
| **6** | Presentation | Application | TLS/SSL, JSON, Base64 | Data formatting & encryption |
| **5** | Session | Application | RPC, Sockets | Session management |
| **4** | Transport | Transport | TCP, UDP | Ports, Reliability, Traffic flow |
| **3** | Network | Internet | IP, ICMP, BGP, ARP | IP Routing, Packets |
| **2** | Data Link | Network Access | Ethernet, MAC, VLAN | Frames, Hardware addressing |
| **1** | Physical | Network Access | Cables, NIC, Fiber | Bits, Electrical signals |

---

## 🔑 2. Core Concepts at a Glance

* **IPv4 vs IPv6:** 32-bit (`192.168.1.1`) vs 128-bit (`fe80::1`).
* **Private IP Ranges (RFC 1918):**
* `10.0.0.0/8` (Class A)
* `172.16.0.0/12` (Class B)
* `192.168.0.0/16` (Class C)


* **CIDR Quick Reference:**
* `/32` = 1 IP (Single Host)
* `/24` = 256 IPs (254 Usable Hosts)
* `/16` = 65,536 IPs


* **Common DevOps Ports:**
* `22` (SSH) | `80` (HTTP) | `443` (HTTPS) | `53` (DNS)
* `3306` (MySQL) | `5432` (PostgreSQL) | `6379` (Redis) | `8080` (Alt HTTP/Jenkins)



---

## 🛠️ 3. Essential CLI Commands

### 📍 Interface & Routing (`ip`)

```bash
# Display IP addresses on all interfaces
ip addr show     # or: ip a

# Show link state (up/down)
ip link show

# Display routing table / Default gateway
ip route show

```

### 🔍 DNS Troubleshooting (`dig`, `nslookup`)

```bash
# Query A record for a domain
dig example.com

# Short output (Returns only IP)
dig example.com +short

# Query specific record type (MX, CNAME, TXT)
dig example.com MX

# Query using a specific DNS server (e.g., Google DNS 8.8.8.8)
dig @8.8.8.8 example.com

# Basic DNS lookup
nslookup example.com

```

### ⚡ Connectivity & Path Diagnostics (`ping`, `traceroute`, `tracepath`)

```bash
# Test basic reachability (4 packets)
ping -c 4 8.8.8.8

# Trace network hop path to destination
traceroute example.com

# Non-root path trace
tracepath example.com

```

### 🔌 Port & Socket Inspection (`ss`, `netstat`, `lsof`)

```bash
# Show listening TCP/UDP sockets with process info
ss -tulnp

# Legacy netstat command
netstat -tulnp

# Find process listening on a specific port (e.g., 80)
lsof -i :80

```

### 🌐 HTTP / API Testing (`curl`, `wget`)

```bash
# Inspect response headers only
curl -I https://example.com

# Include full response details & headers
curl -v https://example.com

# Send POST request with JSON payload
curl -X POST https://api.example.com/data \
  -H "Content-Type: application/json" \
  -d '{"key":"value"}'

# Download file
wget https://example.com/file.tar.gz

```

### 🔐 Port Probing & Connectivity (`nc`, `telnet`)

```bash
# Probe if a remote TCP port is open (Zero-I/O mode)
nc -zv example.com 443

# Test connectivity using telnet
telnet example.com 80

```

---

## 📋 4. SRE Troubleshooting Checklist

When an application cannot communicate with a service or database, follow this 5-step triage flow:

1. **Local Host Check:** Is the process running and listening?
`ss -tulnp | grep :<port>`
2. **DNS Check:** Can the hostname resolve to the correct IP?
`dig +short <hostname>`
3. **Layer 3 Check:** Is the remote server reachable at IP level?
`ping <remote-ip>`
4. **Layer 4 Check:** Is the target port reachable through firewalls / security groups?
`nc -zv <remote-ip> <port>`
5. **Layer 7 Check:** Does the application endpoint return the expected HTTP status?
`curl -iv
