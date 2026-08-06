# 🌐 Day 15: Networking Concepts – DNS, IP, Subnets & Ports

Welcome to **Day 15 of the #90DaysOfDevOps Challenge**! Today’s session builds directly on Day 14, focusing on the fundamental networking concepts that every DevOps and SRE engineer must master: **DNS resolution**, **IP Addressing**, **CIDR Subnetting**, and **Port multiplexing**.

---

## 📌 Table of Contents
- [Task 1: DNS – How Names Become IPs](#task-1-dns--how-names-become-ips)
- [Task 2: IP Addressing](#task-2-ip-addressing)
- [Task 3: CIDR & Subnetting](#task-3-cidr--subnetting)
- [Task 4: Ports – The Doors to Services](#task-4-ports--the-doors-to-services)
- [Task 5: Putting It Together](#task-5-putting-it-together)
- [Key Takeaways & What I Learned](#key-takeaways--what-i-learned)

---

## 🌐 Task 1: DNS – How Names Become IPs

### 1. What happens when you type `google.com` in a browser?
When you type `google.com`, your browser first checks its local cache and the OS cache for the IP address. If not found, a query is sent to a **Recursive DNS Resolver** (e.g., your ISP or `8.8.8.8`), which iteratively queries the **Root Name Servers** (`.`), **TLD Name Servers** (`.com`), and finally the **Authoritative Name Server** for `google.com`. The authoritative server returns the matching IPv4/IPv6 address to the browser, which then establishes a TCP handshake to load the website.

---

### 2. DNS Record Types Overview
- **`A` Record:** Maps a domain name directly to a 32-bit **IPv4 address** (e.g., `google.com` ➔ `142.250.190.46`).
- **`AAAA` Record:** Maps a domain name to a 128-bit **IPv6 address** (e.g., `google.com` ➔ `2404:6800:4009:808::200e`).
- **`CNAME` Record:** Alias record that points a domain or subdomain to another domain name instead of an IP address.
- **`MX` Record:** Mail Exchange record that specifies the mail servers responsible for accepting emails on behalf of the domain.
- **`NS` Record:** Name Server record that indicates which authoritative DNS servers are responsible for managing the domain's DNS records.

---

### 3. DNS Lookup (`dig google.com`) Output Analysis

Running the command:
```bash
dig google.com

```

**Output:**

```text
; <<>> DiG 9.18.28-1~deb12u2-Debian <<>> google.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 41205
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;google.com.			IN	A

;; ANSWER SECTION:
google.com.		300	IN	A	142.250.190.46

;; Query time: 18 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Thu Aug 06 17:00:00 IST 2026
;; MSG SIZE  rcvd: 55

```

**Identification:**

* **A Record:** `142.250.190.46`
* **TTL (Time to Live):** `300` seconds (5 minutes). This specifies how long local resolvers and caching servers can hold this DNS record in their cache before requesting a fresh update.

---

## 📡 Task 2: IP Addressing

### 1. What is an IPv4 Address?

An **IPv4 (Internet Protocol version 4) address** is a unique 32-bit numerical identifier assigned to a device on a TCP/IP network. It is structured into four 8-bit blocks (called **octets**) separated by dots in dotted-decimal format (e.g., `192.168.1.10`). Each octet ranges in value from `0` to `255` ($2^8 = 256$ values).

---

### 2. Public vs. Private IP Addresses

* **Public IP Address:** Globally unique and directly routable over the public Internet. Assigned by ISPs and Regional Internet Registries (RIRs).
* *Example:* `142.250.190.46` (Google's web server).


* **Private IP Address:** Used exclusively within internal private networks (LANs, Virtual Private Clouds / VPCs). Non-routable on the public internet.
* *Example:* `192.168.1.10` (Your home router / local workstation IP).



---

### 3. RFC 1918 Private IP Ranges

Standardized private IPv4 blocks set aside for local network usage:

* **`10.0.0.0/8`** Range: `10.0.0.0` – `10.255.255.255` (Class A - Large Enterprise Networks / Kubernetes Clusters)
* **`172.16.0.0/12`** Range: `172.16.0.0` – `172.31.255.255` (Class B - Medium Networks / Docker Bridge Networks)
* **`192.168.0.0/16`** Range: `192.168.0.0` – `192.168.255.255` (Class C - Home & Small Business Networks)

---

### 4. Identifying Private IPs (`ip addr show`)

Running the command:

```bash
ip addr show

```

**Output:**

```text
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever

```

**Identified Private IP:**

* **`172.17.0.2`** on interface `eth0` (falls within the RFC 1918 `172.16.0.0/12` private range).
* **`127.0.0.1`** on `lo` (Loopback interface reserved for local host communication).

---

## 🧮 Task 3: CIDR & Subnetting

### 1. What does `/24` mean in `192.168.1.0/24`?

The **`/24`** prefix length indicates that the first **24 bits** of the 32-bit IP address represent the **Network Identifier**, leaving the remaining **8 bits** for **Host Addresses**. In subnet mask notation, this corresponds to `255.255.255.0`.

---

### 2. Usable Hosts Calculation Formula

The total number of IP addresses in a prefix length $/n$ is $2^{(32 - n)}$.
Subtract **2 addresses** (1 for Network Address and 1 for Broadcast Address) to get the usable hosts count:

$$\text{Usable Hosts} = 2^{(32 - n)} - 2$$

* **`/24` Subnet:** $2^{(32 - 24)} - 2 = 256 - 2 =$ **254 usable hosts**
* **`/16` Subnet:** $2^{(32 - 16)} - 2 = 65,536 - 2 =$ **65,534 usable hosts**
* **`/28` Subnet:** $2^{(32 - 28)} - 2 = 16 - 2 =$ **14 usable hosts**

---

### 3. Why do we subnet?

Subnetting divides a large network into smaller, manageable sub-networks (subnets). We subnet to:

1. **Enhance Security & Isolation:** Separate public web servers, private backend application servers, and databases into isolated subnets (e.g., AWS Public vs Private Subnets).
2. **Reduce Network Traffic & Broadcast Storms:** Limit broadcast domain sizes to improve performance.
3. **Optimize IP Allocation:** Prevent IP waste by assigning smaller blocks (e.g., `/28` or `/30`) based on actual service requirements.

---

### 4. Completed CIDR Table

| CIDR | Subnet Mask | Total IPs | Usable Hosts |
| --- | --- | --- | --- |
| **`/24`** | `255.255.255.0` | **256** | **254** |
| **`/16`** | `255.255.0.0` | **65,536** | **65,534** |
| **`/28`** | `255.255.255.240` | **16** | **14** |

---

## 🚪 Task 4: Ports – The Doors to Services

### 1. What is a port and why do we need them?

A **Port** is a 16-bit numerical identifier (ranging from `0` to `65535`) assigned to network processes on an operating system. While an IP address identifies a specific **machine** on a network, a port identifies a specific **service or application** running on that machine. We need ports to allow multiplexing—enabling a single server to host multiple network services simultaneously (e.g., HTTP on port 80 and SSH on port 22).

---

### 2. Common Ports Reference

| Port | Service | Description |
| --- | --- | --- |
| **22** | **SSH** | Secure Shell (Remote Secure Administration) |
| **80** | **HTTP** | Hypertext Transfer Protocol (Unencrypted Web Traffic) |
| **443** | **HTTPS** | HTTP Secure (Encrypted Web Traffic via TLS/SSL) |
| **53** | **DNS** | Domain Name System (Name Resolution) |
| **3306** | **MySQL** | MySQL Database Server |
| **6379** | **Redis** | Redis In-Memory Data Store / Cache |
| **27017** | **MongoDB** | MongoDB NoSQL Database |

---

### 3. Socket Inspection (`ss -tulpn`)

Running the command:

```bash
sudo ss -tulpn

```

**Output:**

```text
Netid  State   Recv-Q  Send-Q   Local Address:Port   Peer Address:Port  Process
tcp    LISTEN  0       128            0.0.0.0:22          0.0.0.0:*      users:(("sshd",pid=812,fd=3))
tcp    LISTEN  0       511            0.0.0.0:80          0.0.0.0:*      users:(("nginx",pid=1204,fd=6))
tcp    LISTEN  0       70           127.0.0.1:3306        0.0.0.0:*      users:(("mariadbd",pid=1432,fd=12))

```

**Matched Listening Ports:**

1. **Port `22**` ➔ Bound to service **SSH (`sshd`)** listening on `0.0.0.0` (accepting connections from any IPv4 address).
2. **Port `80**` ➔ Bound to service **HTTP / Web Server (`nginx`)** listening on `0.0.0.0`.
3. **Port `3306**` ➔ Bound to service **MySQL/MariaDB (`mariadbd`)** listening locally on `127.0.0.1`.

---

## 🔗 Task 5: Putting It Together

### Scenario 1:

**Question:** You run `curl http://myapp.com:8080` — what networking concepts from today are involved?

**Answer:**
First, **DNS resolution** converts domain `myapp.com` to its target IPv4/IPv6 address. Next, packet routing uses **IP Addressing & Subnetting** to direct packets across the local/public network to the target machine. Finally, **Port Multiplexing** routes the request to port **`8080`** (an alternative HTTP/application port) where the backend service process (e.g., Node.js or Spring Boot) is listening.

---

### Scenario 2:

**Question:** Your app can't reach a database at `10.0.1.50:3306` — what would you check first?

**Answer:**
First, check if `10.0.1.50` is reachable via **Layer 3 ICMP ping** or route check (`ip route`). Second, test **Layer 4 TCP connectivity** to port `3306` using `nc -zv 10.0.1.50 3306` to verify whether firewall rules (Security Groups / `iptables`) allow traffic. Lastly, verify on the database host that the database service is running and listening on port `3306` using `ss -tulpn`.

---

## 🎓 Key Takeaways & What I Learned

1. **DNS is the Entry Point:** Understanding record types (`A`, `AAAA`, `CNAME`, `MX`, `NS`) and TTL is fundamental for managing web application routing and domain migrations smoothly.
2. **CIDR Subnetting Defines Cloud Security Boundaries:** Subnet masks govern network sizes ($2^{(32 - n)} - 2$). Designing AWS VPCs or Kubernetes CNI networks relies heavily on separating public and RFC 1918 private subnets.
3. **Ports Enable Process Separation:** IP addresses get traffic to the correct server, while ports route traffic to the exact application binary listening on that machine.

---
