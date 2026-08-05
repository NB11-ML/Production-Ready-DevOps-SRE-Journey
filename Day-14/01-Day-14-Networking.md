# 📡 Day 14: Networking Basics for DevOps Engineers

Welcome to ** Day 14 of the #Production-Ready-DevOps-SRE-Journey **! Today, we delve into the core concepts of **Linux Networking**. Networking is a foundational column of DevOps and Cloud Engineering. Whether you are troubleshooting container connectivity in Kubernetes, configuring AWS Security Groups, or routing traffic through a reverse proxy like Nginx, a solid grasp of networking is essential.

---

## 📌 Table of Contents
1. [Why Networking Matters in DevOps](#why-networking-matters-in-devops)
2. [OSI Model vs. TCP/IP Model](#osi-model-vs-tcpip-model)
3. [Key Networking Concepts](#key-networking-concepts)
   - [IP Addresses (IPv4 & IPv6)](#ip-addresses-ipv4--ipv6)
   - [Subnetting & CIDR Notation](#subnetting--cidr-notation)
   - [MAC Address](#mac-address)
   - [Domain Name System (DNS)](#domain-name-system-dns)
   - [Ports and Protocols](#ports-and-protocols)
4. [Essential Linux Networking Commands](#essential-linux-networking-commands)
   - [1. `ip` command (ip addr, ip link, ip route)](#1-ip-command)
   - [2. `ping`](#2-ping)
   - [3. `traceroute` / `tracepath`](#3-traceroute--tracepath)
   - [4. `netstat` & `ss`](#4-netstat--ss)
   - [5. `dig` & `nslookup`](#5-dig--nslookup)
   - [6. `curl` & `wget`](#6-curl--wget)
   - [7. `nc` (Netcat) & `telnet`](#7-nc-netcat--telnet)
   - [8. `hostname`](#8-hostname)
5. [Hands-On Tasks for Day 14](#hands-on-tasks-for-day-14)
6. [Conclusion & Next Steps](#conclusion--next-steps)

---

## 🚀 Why Networking Matters in DevOps

In modern cloud-native architectures, applications rarely run on a single machine. They consist of microservices, database clusters, load balancers, container registries, and external APIs communicating across internal and external networks.

As a DevOps Engineer, networking knowledge enables you to:
- **Troubleshoot connectivity issues** between microservices and databases.
- **Configure Firewalls & Security Groups** (e.g., AWS Security Groups, `iptables`, `ufw`).
- **Manage Container Networking** in Docker and Kubernetes (CNI plugins, overlay networks).
- **Setup Load Balancers & Reverse Proxies** (Nginx, HAProxy, AWS ALB/NLB).
- **Secure Communications** via TLS/SSL encryption and VPNs.

---

## 🌐 OSI Model vs. TCP/IP Model

To understand how data flows across networks, we use reference models.

### The 7 Layers of the OSI Model:
1. **Application (Layer 7):** HTTP, HTTPS, SSH, FTP, DNS (User-facing applications).
2. **Presentation (Layer 6):** Data translation, encryption, SSL/TLS, compression.
3. **Session (Layer 5):** Manages sessions between applications (RPC, NetBIOS).
4. **Transport (Layer 4):** Segmentation, flow control, error checking (**TCP, UDP**).
5. **Network (Layer 3):** IP routing, packet forwarding (**IPv4, IPv6, ICMP, Routers**).
6. **Data Link (Layer 2):** Framing, MAC addresses, physical addressing (**Switches, Ethernet**).
7. **Physical (Layer 1):** Physical signals, cables, fiber optics, network interface cards (NICs).

### The TCP/IP Model (4 Layers):
- **Application Layer:** (Combines OSI Layers 5, 6, 7) - HTTP, SSH, DNS.
- **Transport Layer:** (OSI Layer 4) - TCP, UDP.
- **Internet Layer:** (OSI Layer 3) - IP, ICMP, ARP.
- **Network Access / Link Layer:** (OSI Layers 1 & 2) - Ethernet, Wi-Fi.

---

## 🔑 Key Networking Concepts

### IP Addresses (IPv4 & IPv6)
An **IP Address** is a unique numerical label assigned to every device connected to a computer network.

- **IPv4:** 32-bit address represented in 4 octets (e.g., `192.168.1.1`). Total available addresses: ~4.3 billion.
- **IPv6:** 128-bit address represented in 8 groups of hexadecimal values (e.g., `fe80::1ff:fe18:8a3c`). Designed to replace IPv4.
- **Public IP:** Globally unique and reachable over the Internet.
- **Private IP:** Used within a private network (LAN/VPC) and not directly accessible from the public internet.
  - Private IPv4 Ranges (RFC 1918):
    - `10.0.0.0` – `10.255.255.255` (Class A)
    - `172.16.0.0` – `172.31.255.255` (Class B)
    - `192.168.0.0` – `192.168.255.255` (Class C)

### Subnetting & CIDR Notation
**CIDR (Classless Inter-Domain Routing)** is a method for allocating IP addresses and IP routing.
- Example: `192.168.1.0/24`
  - `/24` means the first 24 bits represent the network address, leaving 8 bits for host addresses.
  - Available host IPs: 254 usable IP addresses.

### MAC Address
A **Media Access Control (MAC) address** is a unique 48-bit hardware identifier assigned to a Network Interface Card (NIC) at the factory (e.g., `00:1A:2B:3C:4D:5E`).

### Domain Name System (DNS)
DNS translates human-readable domain names (e.g., `google.com`) into machine-readable IP addresses (e.g., `142.250.190.46`).
- **A Record:** Maps domain to IPv4 address.
- **AAAA Record:** Maps domain to IPv6 address.
- **CNAME Record:** Maps alias domain to another domain name.
- **MX Record:** Mail Exchange server.
- **PTR Record:** Reverse DNS lookup (IP to domain).

### Ports and Protocols
Ports allow multiple services to run on a single IP address (Port numbers range from `0` to `65535`).

| Port Number | Protocol / Service | Description |
| :--- | :--- | :--- |
| **20 / 21** | FTP | File Transfer Protocol |
| **22** | SSH / SFTP | Secure Shell |
| **23** | Telnet | Unencrypted text communications |
| **25** | SMTP | Simple Mail Transfer Protocol |
| **53** | DNS | Domain Name System |
| **80** | HTTP | Hypertext Transfer Protocol |
| **443** | HTTPS | HTTP Secure (SSL/TLS) |
| **3306** | MySQL | MySQL Database Server |
| **5432** | PostgreSQL | PostgreSQL Database Server |
| **6379** | Redis | In-Memory Data Store |
| **8080** | Alternative HTTP | Often used for Web Servers / Jenkins |

---

## 🛠️ Essential Linux Networking Commands

### 1. `ip` command
The modern replacement for `ifconfig` and `route`.

```bash
# Display all network interfaces and IP addresses
ip addr show
# or shorthand
ip a

# Display link status (up/down) of interfaces
ip link show

# Display routing table
ip route show

```

### 2. `ping`

Tests reachability of a host on an IP network and measures round-trip time (RTT) using ICMP ECHO packets.

```bash
# Ping a remote server
ping google.com

# Send only 4 ping requests
ping -c 4 8.8.8.8

```

### 3. `traceroute` / `tracepath`

Prints the route and hop count that packets take to reach a network host.

```bash
# Trace route to a remote host
traceroute google.com

# Tracepath (does not require root permissions)
tracepath google.com

```

### 4. `netstat` & `ss`

Investigate socket statistics, open ports, and listening services.

```bash
# List all active listening TCP and UDP ports with process names using 'ss' (modern)
ss -tulnp

# Using classic 'netstat'
netstat -tulnp

```

*Flags explained:*

* `-t`: TCP ports
* `-u`: UDP ports
* `-l`: Listening sockets
* `-n`: Show numeric IP/ports (don't resolve names)
* `-p`: Display PID and process name

### 5. `dig` & `nslookup`

Used for DNS query troubleshooting.

```bash
# Perform a DNS lookup using dig
dig google.com

# Get short answer (IP address only)
dig google.com +short

# Query specific record type (e.g., MX record)
dig google.com MX

# Perform DNS lookup using nslookup
nslookup google.com

```

### 6. `curl` & `wget`

Transfer data to or from a server using various protocols.

```bash
# Fetch web page headers using curl
curl -I [https://google.com](https://google.com)

# Download a file using wget
wget [https://example.com/file.zip](https://example.com/file.zip)

# Test API endpoint response
curl -X GET [https://jsonplaceholder.typicode.com/todos/1](https://jsonplaceholder.typicode.com/todos/1)

```

### 7. `nc` (Netcat) & `telnet`

Check TCP port connectivity to remote servers.

```bash
# Test if a specific port is open on a host using netcat
nc -zv google.com 443

# Test TCP port connectivity using telnet
telnet google.com 80

```

### 8. `hostname`

View or set the system's network hostname.

```bash
# View current hostname
hostname

# View IP address associated with the hostname
hostname -I

```

---

## 📋 Hands-On Tasks for Day 14

### Task 1: Inspect Your Local Network Configuration

1. Run `ip a` on your Linux instance/virtual machine.
Identify:
* Loopback interface (`lo`)
* Main network interface (e.g., `eth0`, `ens33`, or `wlan0`)
* Your private IPv4 address.


2. Check your default gateway route using `ip route`.

### Task 2: Analyze DNS Resolution

1. Perform a DNS lookup for `github.com` using both `dig` and `nslookup`.
2. Find the IP address resolved by your DNS server.
3. Test querying a specific DNS server directly (e.g., Google DNS `8.8.8.8`):
```bash
dig @8.8.8.8 github.com

```



### Task 3: Identify Open Ports and Running Services

1. Run `ss -tulnp` or `sudo netstat -tulnp` on your system.
2. List all active listening ports and note down which processes are using them (e.g., port 22 for SSH).
3. Test connecting to port 80 and 443 on `google.com` using `nc -zv google.com 80` and `nc -zv google.com 443`.

### Task 4: Trace Network Hop Paths

1. Run `traceroute google.com` or `tracepath google.com`.
2. Count how many network hops your traffic takes to reach the destination server.

---

## 🎯 Conclusion & Next Steps

Understanding Linux networking is an indispensable skill for DevOps engineers. Today, you learned about networking models, IP addressing, DNS, ports, and essential CLI diagnostic tools.
