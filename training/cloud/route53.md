# Introduction to DNS 🌐

## What is DNS?
DNS (Domain Name System) translates human-friendly domain names into machine-readable IP addresses.

Example:
- `www.google.com` → `172.217.18.36`

DNS acts like the internet’s phone book, allowing users to access websites using names instead of remembering IP addresses.

---

## Why DNS is Important
Without DNS, users would need to remember IP addresses for every website.

DNS provides:
- Easy-to-remember website names
- Stable access even if server IPs change
- Scalability for millions of websites

---

## DNS Hierarchy
DNS uses a hierarchical naming structure:

```text
.
└── .com
    └── example.com
        ├── www.example.com
        └── api.example.com
```

---

## How DNS Resolution Works 🔄

![DNS Resolution Flow](./images/how-dns-works.png)

### DNS Resolution Steps

When you enter `www.example.com` in a browser:

1. **Browser Cache Check**
   - Browser checks if the domain IP is already cached.

2. **OS Cache Check**
   - Operating system checks its DNS cache.

3. **Query Recursive Resolver**
   - Device sends the request to a recursive resolver (ISP, Google DNS `8.8.8.8`, Cloudflare `1.1.1.1`).

4. **Root DNS Server**
   - Resolver asks the Root Server for `.com` information.
   - Root Server points to the `.com` TLD server.

5. **TLD DNS Server**
   - Resolver asks the TLD server for `example.com`.
   - TLD server returns the Authoritative Name Server.

6. **Authoritative Name Server**
   - Returns the actual IP address of `www.example.com`.

7. **Browser Connects to Server**
   - Browser receives the IP and loads the website.

8. **Caching**
   - The result is cached for future requests based on TTL.

---

### Key DNS Components

| Component | Purpose |
|---|---|
| **Recursive Resolver** | Performs DNS lookup for the client |
| **Root Server** | Directs requests to TLD servers |
| **TLD Server** | Handles domains like `.com`, `.org` |
| **Authoritative Server** | Stores actual DNS records |
| **DNS Cache** | Speeds up future lookups |

---

### Important DNS Terms

| Term | Description |
|---|---|
| **Domain Name** | Human-readable website name |
| **IP Address** | Numerical server address |
| **TTL** | Cache duration of DNS records |
| **FQDN** | Fully Qualified Domain Name - Complete domain name (`www.example.com.`) |
| **TLD** | Top-Level Domain like `.com` |

---

## DNS Service Providers 🌐

### Popular DNS Providers

| Provider | Type | Features |
|---|---|---|
| **GoDaddy** | Registrar + DNS Hosting | Beginner-friendly, popular domain provider |
| **Namecheap** | Registrar + DNS Hosting | Affordable pricing, free Whois privacy |
| **Cloudflare** | DNS Hosting + CDN | Fast DNS, DDoS protection, free tier |
| **AWS Route 53** | Registrar + DNS Hosting | AWS integration, advanced routing |

---

### Domain Registrar vs DNS Hosting

#### Domain Registrar
- Lets you purchase and own a domain name
- Maintains domain ownership records

Examples:
- GoDaddy
- Namecheap
- Route 53

#### DNS Hosting Provider
- Hosts DNS records for your domain
- Responds to DNS queries

Examples:
- Cloudflare
- Route 53

---

### Simple Analogy
- **Domain Registrar** → Registers your house address
- **DNS Hosting Provider** → Delivers mail to your house

You can buy a domain from **GoDaddy** and use **Route 53** or **Cloudflare** for DNS hosting.

---

## AWS Route 53 🌐

![Route 53](./images/route53.png)

### What is Route 53?
Amazon Route 53 is a **highly available, scalable, fully managed, and authoritative DNS service** provided by AWS.

> **Authoritative DNS** means you can directly manage and update DNS records for your domain.

Route 53 also acts as:
- A **Domain Registrar**
- A **DNS Routing Service**
- A **Health Checking Service**

---

### Main Features

| Feature | Description |
|---|---|
| **Domain Registration** | Purchase and manage domains through AWS |
| **DNS Routing** | Routes traffic to resources like EC2, S3, ALB, CloudFront |
| **Health Checks** | Monitors application endpoints and routes traffic only to healthy resources |
| **High Availability** | AWS provides a **100% availability SLA** |

---

### Why is it Called Route 53?
The name has two meanings:

- **Route** → Routes internet/DNS traffic to the correct destination
- **53** → DNS uses **port 53** for queries and responses

Example:
- HTTP → Port 80
- HTTPS → Port 443
- DNS → Port 53

AWS named the service after the standard DNS port.

---

## Route 53 Core Components

### Hosted Zones 📂

A **Hosted Zone** is a container for DNS records of a domain.

Example:
- `example.com`
- `api.example.com`

Route 53 automatically creates:
- **NS Record** → Route 53 name servers
- **SOA Record** → Administrative metadata

![Hosted Zones](./images/hosted-zones.png)

---

### Public Hosted Zone 🌍

Used for routing traffic from the **public internet**.

---

### Private Hosted Zone 🔒

Used for routing traffic **inside VPCs only**.

> Public zones work on the internet.  
> Private zones work only inside AWS VPCs.

---

### Name Servers (NS) 🌐

Name Servers host DNS records and answer DNS queries.

Example Route 53 NS records:

```text
ns-123.awsdns-45.com
ns-678.awsdns-12.net
ns-901.awsdns-34.org
ns-234.awsdns-56.co.uk
```

AWS provides **4 name servers** for redundancy.

---

### DNS Delegation 🔀

To use Route 53 DNS:

1. Buy domain from registrar (GoDaddy, Namecheap)
2. Create Hosted Zone in Route 53
3. Copy Route 53 NS records
4. Update nameservers at registrar

```text
GoDaddy Domain
      │
      ▼
Update Nameservers
      │
      ▼
Route 53 Name Servers
```

Now DNS queries are handled by Route 53.

---

### SOA Record 🧾

SOA = **Start of Authority**

Contains administrative details about the hosted zone, such as the **Primary Name Server**, **Administrator Contact**, **Serial Number** (zone version), **Refresh** and **Retry** intervals for DNS synchronization, **Expire** duration, and the default **TTL (Time To Live)** used for DNS caching.

> Usually managed automatically by Route 53.

---

### TTL (Time To Live) ⏳

TTL defines how long DNS records stay cached.

| TTL Type | Effect |
|---|---|
| High TTL | Less DNS traffic, slower updates |
| Low TTL | Faster updates, more DNS queries |

Examples:
- `60 sec` → Fast updates
- `24 hr` → Better caching

> Alias records do not allow manual TTL configuration.

---

## DNS Record Types

```text
A Record       → Domain → IPv4 Address
AAAA Record    → Domain → IPv6 Address
CNAME          → Domain → Another Domain
MX Record      → Domain → Mail Server
TXT Record     → Text Metadata / Verification
NS Record      → Authoritative Name Servers
PTR Record     → IP Address → Domain
SRV Record     → Service Host + Port
Alias Record   → Domain → AWS Resource
```

### A Record

Maps domain → IPv4 address.

```text
example.com → 54.12.34.56
```

---

### AAAA Record

Maps domain → IPv6 address.

```text
example.com → 2001:db8::1
```

---

### CNAME Record

Maps one domain → another domain.

```text
www.example.com → example.com
```

| Feature | Details |
|---|---|
| **Limitation** | Cannot be used for the root domain (`example.com`) |
| **Common Use** | Creating subdomain aliases like `www.example.com`, `blog.example.com` |

---

### MX Record 📧

Defines mail servers for a domain.

```text
example.com → Priority 1 → aspmx.l.google.com
```

> When someone sends an email to `user@example.com`, the MX record tells the internet which mail server should receive that email.

---

### TXT Record

Stores text-based information for a domain.

Common uses:
- **Domain Verification** → Proves domain ownership to services like Google or Microsoft
- **SPF** → Specifies which mail servers are allowed to send emails for your domain
- **DKIM** → Helps verify that emails were not tampered with

> This SPF record allows Google mail servers to send emails on behalf of the domain.
---

### NS Record

Defines authoritative name servers. Automatically created in Route 53.

---

### PTR Record 🔁

Used for **reverse DNS lookup**, allowing systems to map an IP address back to its associated domain name. Commonly used in email verification, logging, and network troubleshooting.

Example:

```text
54.12.34.56 → example.com
```

---

### SRV Record

Used to define the **hostname and port number** for specific services, helping clients discover where a service is running.

Commonly used in:
- VoIP
- SIP
- XMPP
- Gaming services
---

## Alias Records ⭐

Alias records map domains directly to AWS resources such as:
- Load Balancers
- CloudFront
- API Gateway
- S3 Static Websites
- Global Accelerator

**Features:**
- Works at root domain (`example.com`)
- Automatically tracks AWS IP changes
- No extra DNS query
- Free for AWS targets
- Native health check support

Example:

```text
example.com → ALB.amazonaws.com
```

---

### CNAME vs Alias

| Feature | CNAME | Alias |
|---|---|---|
| Root Domain Support | ❌ No | ✅ Yes |
| AWS Native Integration | Partial | ✅ Native |
| Extra DNS Lookup | Yes | No |
| Automatic AWS IP Updates | ❌ No | ✅ Yes |
| Cost for AWS Targets | Standard | Free |

> Alias records are a Route 53 extension and automatically track AWS IP changes.

---

## Route 53 Routing Policies 🌐

> Routing Policies define how Route 53 responds to DNS queries.  
> DNS itself does **not route traffic** like a Load Balancer — it only decides which IP or resource to return.

---

### Routing Policies Overview

| Policy | Routes Based On | Health Checks | Common Use |
|---|---|---|---|
| **Simple** | Single resource | ❌ Limited | Basic websites |
| **Weighted** | Assigned weights | ✅ Yes | A/B testing, gradual rollout |
| **Latency** | Lowest network latency | ✅ Yes | Global low-latency apps |
| **Failover** | Primary / Secondary | ✅ Required | Disaster recovery |
| **Geolocation** | User location | ✅ Yes | Localization & compliance |
| **Geoproximity** | Geography + bias | ✅ Yes | Fine-grained traffic shaping |
| **Multi-Value** | Multiple healthy IPs | ✅ Yes | Basic load distribution |
| **IP-Based** | Client IP/CIDR | ✅ Yes | ISP/network-based routing |

---

## Simple Routing

Returns a single resource for a domain.

```text
example.com → 54.12.34.56
```

Features:
- Simplest routing policy
- Can return multiple IPs
- Browser chooses one randomly
- No proper health-check failover
- Best for small/simple applications

Use Case:
- Personal blog hosted on one EC2 instance

---

## Weighted Routing ⚖️

Splits traffic between resources using assigned weights.

```text
Server A → Weight 80
Server B → Weight 20
```

Result:
- 80% traffic → Server A
- 20% traffic → Server B

Features:
- Gradual deployments
- A/B testing
- Blue-Green deployments
- Weight range: `0–255`
- Weight `0` stops traffic to a resource
- If all weights are `0`, traffic is distributed equally

Use Case:
- Testing a new application version with limited users

---

### Latency Routing ⚡

Routes users to the AWS region with the **lowest network latency**, not necessarily the geographically closest region.

```text
India User  → Mumbai Region
US User     → Virginia Region
```

Features:
- Optimizes global application performance
- Based on latency between users and AWS Regions
- Can integrate with health checks

Use Case:
- Global applications requiring fast response times

> Unlike Geolocation Routing, Latency Routing does **not** route purely based on the user's country or location — it routes based on the fastest network path.

> **Germany users may be
directed to the US(if that’s the
lowest latency)**

---

## Geolocation Routing 📍

Routes traffic based on the user's geographic location.

Supported levels:
- Continent
- Country
- US State

Example:

```text
Germany Users → German Server
India Users   → India Server
Default       → Global Server
```

Features:
- Supports localization
- Useful for legal/compliance requirements
- Default record recommended

Use Case:
- Region-specific pricing, language, or media restrictions

---

## Geoproximity Routing 🗺️

Routes traffic based on:
- User location
- Resource location
- Configurable bias

Bias:
- `+1 to +99` → Expands traffic region
- `-1 to -99` → Shrinks traffic region

Example:

```text
US-East Bias +50 → Receives more traffic
```

Features:
- Fine-grained traffic control
- Requires **Route 53 Traffic Flow**

Use Case:
- Intentionally directing more users to a preferred region

---

## Multi-Value Routing 🔀

Returns multiple healthy IP addresses for a single DNS query.

```text
Healthy:
54.12.34.56
54.12.34.99

Unhealthy:
54.12.34.11 ❌
```

Features:
- Returns up to 8 healthy records
- Supports health checks
- Basic load distribution
- Not a replacement for ELB

Use Case:
- Multiple EC2 instances serving the same application

---

## IP-Based Routing 🌍

Routes traffic based on the client’s IP address or CIDR range.

Example:

```text
203.0.113.0/24 → Server A
198.51.100.0/24 → Server B
```

Features:
- ISP/network-specific routing
- CIDR-based mapping
- Optimizes enterprise/network traffic

Use Case:
- Directing branch offices or ISP users to optimized endpoints

---

## Failover Routing 🛡️

Routes traffic to a primary resource and switches to backup if the primary becomes unhealthy.

```text
Primary Server   → Active
Secondary Server → Standby
```

Features:
- Requires health checks
- Automatic disaster recovery
- Active-Passive setup

Use Case:
- High availability applications with backup regions

---

## Route 53 Health Checks ❤️

Route 53 Health Checks continuously monitor application endpoints and automatically stop routing traffic to unhealthy resources.

> Think of Health Checks as an automated monitoring and failover system for your infrastructure.

---

### Types of Health Checks

#### 1. Endpoint Health Check
Monitors a specific IP address, domain, or URL using **HTTP, HTTPS, or TCP** protocols.

Example:

```text
https://example.com/health → HTTP 200 OK
```

---

#### 2. Calculated Health Check
Combines multiple health checks into a single logical result using **AND, OR, or NOT** conditions.

Example:
- Healthy only if **2 out of 3** checks pass

---

#### 3. CloudWatch Alarm Health Check
Uses a **CloudWatch Alarm** instead of directly checking an endpoint, making it useful for monitoring private VPC resources or custom metrics.

> Route 53 health checkers are public and cannot directly access private VPC endpoints.

---

### Health Check Configuration

| Setting | Example |
|---|---|
| **Protocol** | HTTPS |
| **Port** | 443 |
| **Path** | `/health` |
| **Check Interval** | `30 sec` |
| **Failure Threshold** | `3 failed checks` |

---

### Key Behavior

- Around **15 global AWS health checkers** monitor endpoints continuously
- Only `2xx` and `3xx` HTTP responses are considered healthy
- Supports response text matching and CloudWatch integration

---

### Health Check + Failover 🔄

```text
Primary Healthy   → Traffic goes to Primary
Primary Unhealthy → Route 53 redirects to Backup
```

Use Cases:
- High availability
- Disaster recovery
- Automatic failover

---

# TASKS 👨‍💻

## Task 1 — Host a Website Using Simple Routing

### Objective
- Launch an EC2 instance
- Install a web server
- Configure a custom domain
- Point the domain to EC2 using Route 53
- Access the website publicly

---

## Architecture

```text
Internet User
     │
     ▼
www.yourdomain.com
     │
     ▼
Route 53 Hosted Zone
     │
     ▼
EC2 Instance (Apache/Nginx)
IP: 54.12.34.56
```

---

## Step 1 — Purchase a Domain

### GoDaddy / Namecheap
1. Purchase a domain
2. Route 53 will manage DNS later

### Route 53
1. Open AWS Console → Route 53
2. Register Domain
3. Hosted zone is created automatically

---

## Step 2 — Launch EC2 Instance

### EC2 Configuration

| Setting | Value |
|---|---|
| AMI | Amazon Linux 2023 |
| Instance Type | t2.micro |
| Public IP | Enabled |
| Security Group | Allow SSH (22) & HTTP (80) |

### Launch
1. Open EC2 → Launch Instance
2. Create or select key pair
3. Launch instance
4. Note Public IP

Example:
```text
54.12.34.56
```

---

## Step 3 — Install Apache2 Web Server (Ubuntu)

### Connect to EC2

```bash
ssh -i your-key.pem ubuntu@54.12.34.56
```

### Install Apache2

```bash
sudo apt update -y
sudo apt install apache2 -y

sudo systemctl start apache2
sudo systemctl enable apache2
```

### Create Sample Webpage

```bash
sudo bash -c 'cat > /var/www/html/index.html << EOF
<h1>Hello from AWS Route 53!</h1>
EOF'
```

### Verify Website

Open:

```text
http://54.12.34.56
```
---

## Step 4 — Create Route 53 Hosted Zone

1. Open Route 53
2. Hosted Zones → Create Hosted Zone

### Configuration

| Field | Value |
|---|---|
| Domain Name | yourdomain.com |
| Type | Public Hosted Zone |

3. Copy the generated NS records

Example:

```text
ns-123.awsdns-45.com
ns-678.awsdns-12.net
ns-901.awsdns-34.org
ns-234.awsdns-56.co.uk
```

---

## Step 5 — Update Nameservers

### GoDaddy
1. My Products → DNS
2. Nameservers → Change
3. Select Custom
4. Paste Route 53 NS records

### Namecheap
1. Domain List → Manage
2. Nameservers → Custom DNS
3. Paste Route 53 NS records

---

## Step 6 — Create A Record

1. Route 53 → Hosted Zone
2. Create Record

### Configuration

| Field | Value |
|---|---|
| Record Type | A |
| Routing Policy | Simple |
| Value | EC2 Public IP |
| TTL | 300 |

Example:

```text
54.12.34.56
```

---

## Step 7 — Validate DNS

### Check DNS

```bash
nslookup yourdomain.com
dig yourdomain.com
```

### Open Website

```text
http://yourdomain.com
```

---

# Routing Policies

## Weighted Routing

### Purpose
Split traffic between servers.

### Example

| Server | Weight |
|---|---|
| Server 1 | 80 |
| Server 2 | 20 |

### Configuration

| Field | Value |
|---|---|
| Routing Policy | Weighted |
| Weight | 80 / 20 |
| Record Type | A |

### Test

```bash
for i in {1..10}; do
  dig +short yourdomain.com
done
```

---

## Latency Routing

### Purpose
Route users to nearest AWS region.

### Regions
- ap-south-1 → Mumbai
- us-east-1 → Virginia
- eu-west-1 → Ireland

### Configuration

| Field | Value |
|---|---|
| Routing Policy | Latency |
| Region | AWS Region |
| Record Type | A |

---

## Failover Routing

### Purpose
Disaster recovery using primary and backup servers.

### Create Health Check

| Field | Value |
|---|---|
| Protocol | HTTP |
| Port | 80 |
| Path | /health |

### Primary Record

| Field | Value |
|---|---|
| Failover Type | Primary |
| Value | Primary Server IP |

### Secondary Record

| Field | Value |
|---|---|
| Failover Type | Secondary |
| Value | Backup Server IP |

### Test Failover

```bash
sudo systemctl stop httpd
```

Restart:

```bash
sudo systemctl start httpd
```

---

## Geolocation Routing

### Purpose
Route traffic based on user location.

### Example

| Location | Server |
|---|---|
| India | India Server |
| USA | US Server |
| Default | Global Server |

### Configuration

| Field | Value |
|---|---|
| Routing Policy | Geolocation |

---

## Multi-Value Routing

### Purpose
Return multiple healthy IP addresses.

### Configuration

| Field | Value |
|---|---|
| Routing Policy | Multivalue Answer |
| Health Check | Enabled |

---

# Route 53 Record Types

Explore different Route 53 DNS record types and their use cases.

- **A Record** → Maps domain to IPv4 address
- **AAAA Record** → Maps domain to IPv6 address
- **CNAME Record** → Maps one domain to another domain
- **MX Record** → Configures email routing
- **TXT Record** → Used for verification and email security
- **NS Record** → Defines authoritative nameservers
- **SOA Record** → Stores DNS zone information
- **PTR Record** → Used for reverse DNS lookup
- **Alias Record** → Points root domain to AWS resources like ALB or CloudFront

Explore and configure these record types in Route 53 to understand their practical use cases.

---

# Key Takeaways

- Route 53 provides DNS management, routing, and health monitoring
- Hosted Zones store DNS records
- Alias Records are preferred for AWS resources
- Routing Policies help control traffic intelligently
- Health checks improve availability and failover handling

---

# Explore Routing Policies

- Simple Routing
- Weighted Routing
- Latency Routing
- Failover Routing
- Geolocation Routing
- Geoproximity Routing
- Multi-Value Routing
- IP-Based Routing

Explore each policy and understand where it is best used in real-world architectures.
