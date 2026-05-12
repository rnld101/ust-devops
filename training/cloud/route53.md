# 🌐 DNS & Amazon Route 53 — Complete Study Guide

> **How to use this guide:** Read sequentially — each section builds on the last. By the end you'll have a complete mental model from how DNS was invented, through buying a domain, all the way to routing traffic across AWS infrastructure.

---

## Table of Contents

1. [The Big Picture](#the-big-picture)
2. [Why DNS Was Created](#why-dns-was-created)
3. [How DNS Works](#how-dns-works)
4. [DNS Query Types](#dns-query-types)
5. [DNS Caching](#dns-caching)
6. [DNS Record Types](#dns-record-types)
7. [Amazon Route 53](#amazon-route-53)
8. [Hosted Zones](#hosted-zones)
9. [Alias Records](#alias-records)
10. [TTL — Time To Live](#ttl--time-to-live)
11. [Routing Policies](#routing-policies)
12. [Health Checks](#health-checks)
13. [Key Differences & Comparisons](#key-differences--comparisons)
14. [DNS in DevOps](#dns-in-devops)
15. [Troubleshooting DNS](#troubleshooting-dns)
16. [Real-World Architecture](#real-world-architecture)
17. [Interview Questions](#interview-questions)
18. [Quick Glossary](#quick-glossary)

---

## The Big Picture

The complete flow from buying a domain to serving a user:

```
You buy domain on GoDaddy
         ↓
Point GoDaddy NS records → Route 53
         ↓
Route 53 Hosted Zone holds your DNS records
         ↓
User types your domain in browser
         ↓
DNS Resolution: browser → ISP resolver → root → TLD → Route 53
         ↓
Route 53 applies a Routing Policy → returns IP / Alias target
         ↓
User's request hits your infrastructure (ALB / CloudFront / EC2)
```

Every concept in this guide fits somewhere in this chain.

---

## Why DNS Was Created

**Before DNS (pre-1983):** The entire internet ran on a single file called `HOSTS.TXT`, maintained by Stanford Research Institute. Every host downloaded it periodically. It mapped every hostname to an IP.

As the internet grew, this broke down:
- The file got too large
- Updates were too frequent
- Downloads caused network congestion
- No uniqueness guarantee across organizations

**DNS solved this by being:**

| Property | What it means |
|----------|---------------|
| Distributed | No single point of failure; millions of servers worldwide |
| Hierarchical | Tree-structured — root → TLD → domain |
| Cached | Faster responses, reduced load |
| Delegated | Each organization manages its own piece |

---

## How DNS Works

### The DNS Hierarchy

```
                     . (Root)
                      |
      ┌───────────────┼───────────────┐
    .com            .org            .net
      |
  example.com
      |
 ┌────┴────┐
www      api
```

### The Resolution Journey

When you type `www.example.com` in your browser:

```
1. Browser cache          → found? done. not found? ↓
2. OS cache               → found? done. not found? ↓
3. Router cache           → found? done. not found? ↓
4. ISP Recursive Resolver → found? done. not found? ↓

5. Resolver → Root Server
   "Who handles .com?"
   Root: "Ask the .com TLD server"

6. Resolver → .com TLD Server
   "Who handles example.com?"
   TLD: "Ask ns-2048.awsdns-64.com"

7. Resolver → Authoritative Name Server (Route 53)
   "What is www.example.com?"
   Route 53: "It's 93.184.216.34"

8. Resolver caches the answer, returns it to browser
9. Browser connects to 93.184.216.34 ✓
```

This entire process takes **milliseconds**.

### Key Players

| Component | Role | Example |
|-----------|------|---------|
| **Recursive Resolver** | Does the legwork for the client | ISP's DNS, `8.8.8.8` |
| **Root Name Server** | Knows where all TLD servers are | 13 clusters worldwide |
| **TLD Name Server** | Knows who manages each domain under a TLD | Handles all `.com`, `.org` |
| **Authoritative NS** | Has the final definitive answer | Route 53, Cloudflare |

> 💡 Route 53 acts as the **Authoritative Name Server** — the last stop, the one that stores your actual DNS records.

---

## DNS Query Types

### Recursive Query
Client asks the resolver: *"Give me the final answer."* The resolver does all the work and must return either an answer or an error. This is what your browser does.

### Iterative Query
Resolver asks other DNS servers: *"What do you know?"* Each server either answers or refers to another server. The resolver follows the chain itself. Used between resolvers and DNS servers.

### Non-Recursive Query
Server already has the answer cached — no further lookups needed. Returns immediately.

---

## DNS Caching

Caching happens at multiple layers, reducing load and speeding up responses.

### Cache Hierarchy

```
Browser Cache          → seconds to minutes (browser-controlled)
      ↓ (miss)
OS Cache               → respects TTL
      ↓ (miss)
Router Cache           → respects TTL
      ↓ (miss)
ISP Recursive Resolver → respects TTL, shared by all ISP customers
      ↓ (miss)
Authoritative Server   → source of truth
```

### Negative Caching

DNS also caches **negative responses** — when a domain doesn't exist (`NXDOMAIN`). This means if you query a non-existent subdomain and then create it, it may not be accessible until the negative cache TTL expires.

---

## DNS Record Types

### `A` — IPv4 Address
```
example.com  →  93.184.216.34
```

### `AAAA` — IPv6 Address
```
example.com  →  2606:2800:220:1:248:1893:25c8:1946
```

### `CNAME` — Alias to another domain
```
www.example.com      →  example.com
cdn.example.com      →  d111111abcdef8.cloudfront.net
```
**Limitations:**
- Cannot point to an IP — use A record for that
- **Cannot be used at the root domain** (`example.com`) — only subdomains

```
✅ www.example.com  →  CNAME  →  something.amazonaws.com
❌ example.com      →  CNAME  →  something.amazonaws.com  (invalid)
```

### `MX` — Mail Server
```
example.com  →  10  mail.google.com
example.com  →  20  mail-backup.google.com   (lower number = higher priority)
```

### `TXT` — Text / Verification
Stores free-form text. Used for:

| Purpose | Example value |
|---------|---------------|
| Domain verification | `google-site-verification=abc123` |
| SPF | `v=spf1 include:_spf.google.com ~all` |
| DKIM | `v=DKIM1; k=rsa; p=MIGf...` |
| DMARC | `v=DMARC1; p=reject;` |

### `NS` — Name Server
Declares which name servers are authoritative. These are what you update in GoDaddy when pointing to Route 53.
```
example.com  NS  ns-2048.awsdns-64.com
example.com  NS  ns-512.awsdns-12.net
```

### `PTR` — Reverse DNS
Maps IP address back to a domain (opposite of A record).
```
34.216.184.93  →  example.com
```
Used for: email server verification, security tools.

### `SOA` — Start of Authority
Auto-created by Route 53 for every hosted zone. Contains zone metadata: primary NS, admin email, serial number, refresh timing. Rarely edited manually.

### Quick Reference

| Record | Maps | Common Use |
|--------|------|------------|
| `A` | Domain → IPv4 | Web servers |
| `AAAA` | Domain → IPv6 | IPv6 infrastructure |
| `CNAME` | Domain → Domain | Subdomains, CDN |
| `MX` | Domain → Mail server | Email setup |
| `TXT` | Domain → Text | Verification, SPF/DKIM |
| `NS` | Domain → Name servers | Delegation |
| `PTR` | IP → Domain | Reverse lookup |
| `SOA` | Zone metadata | Auto-created |
| `Alias` *(Route 53 only)* | Root domain → AWS resource | ALB, CloudFront, S3 |

---

## Amazon Route 53

### What is Route 53?

AWS's fully managed DNS service. Named after **port 53** — the standard DNS port.

Capabilities beyond basic DNS:
- DNS record management
- Domain registration
- Health checks on endpoints
- 8 traffic routing policies
- Automatic failover
- Latency optimization across regions

### How GoDaddy + Route 53 Work Together

The most common real-world setup: **GoDaddy registers the domain, Route 53 manages DNS.**

```
Step 1: Buy domain on GoDaddy → example.com
         ↓
Step 2: Create Hosted Zone in Route 53
         ↓
Step 3: Route 53 gives you 4 NS records
        ns-2048.awsdns-64.com
        ns-512.awsdns-12.net
         ↓
Step 4: Paste those NS records into GoDaddy
         ↓
Step 5: Route 53 is now authoritative for example.com ✓
```

### Public DNS Servers (Common Resolvers)

| Provider | Primary | Secondary |
|----------|---------|-----------|
| Google | `8.8.8.8` | `8.8.4.4` |
| Cloudflare | `1.1.1.1` | `1.0.0.1` |
| OpenDNS | `208.67.222.222` | `208.67.220.220` |

---

## Hosted Zones

A **Hosted Zone** is Route 53's container for DNS records — the DNS database for your domain.

### Public Hosted Zone

Resolvable from the open internet. Used for websites, APIs, public services.

```
example.com        →  public
api.example.com    →  public
```

### Private Hosted Zone

Resolvable **only from within a specified VPC**. Used for internal services.

```
db.internal.local          →  VPC only
payment.service.internal   →  VPC only
```

### Comparison

| Feature | Public Zone | Private Zone |
|---------|-------------|--------------|
| Internet accessible | ✅ Yes | ❌ No |
| Attached to VPC | ❌ No | ✅ Yes |
| Typical use | Websites, public APIs | Databases, internal services |
| Typical TLD | `.com`, `.io` | `.local`, `.internal` |

---

## Alias Records

### The Problem

Standard DNS has two issues with AWS resources:

**1.** CNAME is forbidden at the root domain:
```
❌ example.com → CNAME → my-alb.amazonaws.com
```

**2.** AWS services (ALB, CloudFront) have no static IPs — they change. A raw A record breaks.

### The Solution

Route 53's **Alias record** — an AWS-only DNS extension.

```
✅ example.com  →  ALIAS  →  my-alb.amazonaws.com
✅ example.com  →  ALIAS  →  d1234.cloudfront.net
✅ example.com  →  ALIAS  →  mybucket.s3-website.amazonaws.com
```

Route 53 automatically tracks the target's IPs and updates them — you never need to touch it.

### Comparison

| Feature | A Record | CNAME | Alias |
|---------|----------|-------|-------|
| Works at root domain | ✅ (needs static IP) | ❌ | ✅ |
| Points to domain name | ❌ | ✅ | ✅ |
| Tracks IP changes | ❌ | ❌ | ✅ |
| Works with AWS services | ❌ | Partially | ✅ |
| Route 53 query charge | Yes | Yes | **Free** (for AWS targets) |

---

## TTL — Time To Live

TTL defines **how long (in seconds)** resolvers cache a DNS record before re-querying.

```
example.com.    300    A    93.184.216.34
                ^^^
                TTL = 5 minutes
```

### TTL Trade-offs

| | Low TTL (60s) | High TTL (86400s) |
|---|---|---|
| Propagation speed | ⚡ Fast | 🐢 Slow |
| DNS query volume | High | Low |
| Best for | Migrations, failover | Stable production records |

### Migration Best Practice

```
1 week before  → Reduce TTL to 300s (5 min)
During change  → Update DNS records
After change   → Propagation takes ~5 minutes
1 day after    → Raise TTL back to 86400s
```

---

## Routing Policies

Routing policies control **how Route 53 answers DNS queries**. This is what makes Route 53 far more powerful than basic DNS.

---

### 1. Simple Routing

One record, one resource. The default. No logic.

```
example.com  →  ALB
```

**Use when:** Single server or single endpoint.

---

### 2. Weighted Routing

Split traffic across endpoints by percentage.

```
example.com  →  Server A  (weight 80)  →  80% of traffic
example.com  →  Server B  (weight 20)  →  20% of traffic
```

Setting weight to `0` removes a target without deleting it.

**Use for:** Canary deployments, A/B testing, gradual migrations.

---

### 3. Latency-Based Routing

Routes each user to the AWS region with the **lowest network latency** for them.

| User Location | Routed To |
|---------------|-----------|
| India | ap-south-1 (Mumbai) |
| Europe | eu-central-1 (Frankfurt) |
| US East | us-east-1 (Virginia) |

> Note: Routes by latency, not geography. A user in India could hit Singapore if it's faster.

**Use for:** Global apps where response time matters.

---

### 4. Failover Routing

Primary + secondary with health-check-based automatic switching.

| Role | Endpoint |
|------|----------|
| Primary | Main ALB — us-east-1 |
| Secondary | DR ALB — us-west-2 |

When primary fails its health check, Route 53 automatically returns the secondary's address.

**Use for:** Disaster recovery, high availability.

---

### 5. Geolocation Routing

Routes based on the **country or continent** of the user — explicit rules.

| User's Country | Destination |
|----------------|-------------|
| India | in.example.com |
| United States | us.example.com |
| Germany | eu.example.com |
| (Default) | global.example.com |

Always set a **Default** record to catch unmapped locations.

**Use for:** GDPR compliance, localization, language-specific content.

---

### 6. Geoproximity Routing

Routes by **physical distance**. Supports a **bias** — positive expands a region's reach, negative shrinks it.

```
Mumbai bias = +50  →  Mumbai attracts users from farther away
Tokyo  bias = -25  →  Tokyo serves a smaller area
```

Requires **Route 53 Traffic Flow** (visual editor).

**Use for:** Fine-grained multi-region traffic shaping.

---

### 7. Multi-Value Answer Routing

Returns **up to 8 healthy IPs**. Client picks one. Unhealthy endpoints are excluded automatically via health checks.

```
DNS response:
  1.1.1.1  ✓  included
  1.1.1.2  ✓  included
  1.1.1.3  ✗  excluded (failed health check)
```

**Use for:** Simple client-side load balancing without an ELB.

---

### 8. IP-Based Routing

Routes based on the **source IP range (CIDR)** of the client.

| Client CIDR | Destination |
|-------------|-------------|
| `10.0.0.0/8` | Internal app |
| All other IPs | Public app |

**Use for:** Enterprise networks, ISP-specific routing, on-prem to cloud.

---

### Routing Policies — Quick Reference

| Policy | Routes By | Best For |
|--------|-----------|----------|
| Simple | — | Single resource |
| Weighted | Traffic % | Canary, A/B testing |
| Latency | Lowest latency | Global apps |
| Failover | Health check | Disaster recovery |
| Geolocation | Country / continent | Compliance, localization |
| Geoproximity | Distance + bias | Advanced geo balancing |
| Multi-Value | Multiple healthy IPs | Simple HA without ELB |
| IP-Based | Client IP / CIDR | Enterprise routing |

---

## Health Checks

Route 53 monitors endpoints and removes unhealthy ones from DNS responses.

### Types

**Endpoint health check** — polls a URL, IP, or domain on a schedule.
```
Monitor: https://example.com/health
Interval: 30 seconds
Threshold: fail after 3 consecutive failures
```

**Calculated health check** — combines multiple checks with AND / OR / NOT logic.

**CloudWatch alarm health check** — triggers based on a CloudWatch metric (e.g., CPU > 90%).

### Integrates with
- **Failover** routing — triggers the switch to secondary
- **Multi-Value** routing — excludes unhealthy IPs from responses
- **Weighted / Latency / Geolocation** — skips unhealthy targets

---

## Key Differences & Comparisons

### CNAME vs Alias

| | CNAME | Alias |
|---|---|---|
| Works at root domain | ❌ | ✅ |
| Points to | Any domain | AWS resources only |
| Tracks IP changes | ❌ | ✅ |
| Query charge | Yes | Free (AWS targets) |
| Standard DNS | ✅ | AWS-specific |

### Geolocation vs Geoproximity

| | Geolocation | Geoproximity |
|---|---|---|
| Routes by | Country / continent | Physical distance |
| Logic | Rule-based | Distance + optional bias |
| Complexity | Simple | Advanced |
| Requires Traffic Flow | ❌ | ✅ |

### Public vs Private Hosted Zone

| | Public | Private |
|---|---|---|
| Resolves from | Internet | VPC only |
| Use case | Websites, APIs | Internal services |
| VPC required | ❌ | ✅ |

### Failover vs Multi-Value

| | Failover | Multi-Value |
|---|---|---|
| Setup | Primary + Secondary | Up to 8 IPs |
| Switching | Auto on health-check fail | Client picks from healthy set |
| Use for | DR / HA | Simple load distribution |

---

## DNS in DevOps

### Internal DNS (Private Hosted Zone)
```
database.internal     →  10.0.2.15
redis.internal        →  10.0.2.20
api.internal          →  10.0.1.10
```

### Kubernetes Service Discovery
Kubernetes uses DNS internally for service resolution:
```
my-service.default.svc.cluster.local  →  10.96.0.10
```

### Blue-Green Deployment via DNS
```
# Before:  api.example.com → 1.2.3.4  (Blue)
# After:   api.example.com → 5.6.7.8  (Green)

Lower TTL before the switch → near-instant propagation
```

### Weighted Routing for Canary
```
example.com  →  v1 (weight 95)  →  95% traffic
example.com  →  v2 (weight 5)   →  5% traffic

Gradually shift: 95/5 → 80/20 → 50/50 → 0/100
```

---

## Troubleshooting DNS

### Common Issues

**DNS Propagation Delay** — changes take time (up to 48h globally).
Fix: Lower TTL before making changes.

**Cached Negative Response** — created a new subdomain but it's not resolving.
Fix: Wait for the negative TTL to expire, or flush caches.

**DNS Cache Poisoning** — attackers inject fake records.
Fix: Use DNSSEC (DNS Security Extensions).

**Wrong record after deployment** — website not loading.
Fix: Use `dig` to inspect what DNS is returning (see commands below).

### DNS Commands

```bash
# Basic lookup
nslookup example.com

# Detailed lookup (preferred)
dig example.com

# Query specific record type
dig example.com MX
dig example.com TXT
dig example.com NS

# Query a specific DNS server
dig @8.8.8.8 example.com
dig @1.1.1.1 example.com

# Reverse DNS (IP → domain)
dig -x 8.8.8.8

# Check propagation across resolvers
dig @8.8.8.8 example.com        # Google
dig @1.1.1.1 example.com        # Cloudflare
dig @208.67.222.222 example.com # OpenDNS
```

### Flush DNS Cache

```bash
# macOS
sudo dscacheutil -flushcache

# Linux
sudo systemd-resolve --flush-caches

# Windows
ipconfig /flushdns
```

---

## Real-World Architecture

```
GoDaddy (registrar)
    │  NS records → Route 53
    ▼
Route 53 Name Servers (authoritative)
    │
    ▼
Public Hosted Zone: example.com
    │
    ├── Alias A (root domain) + Latency Routing
    │       ├── ALB ap-south-1 (Mumbai)   → ECS Tasks
    │       └── ALB us-east-1 (Virginia)  → ECS Tasks
    │
    ├── CNAME: www → example.com
    ├── MX: → Google Workspace
    ├── TXT: SPF, DKIM, DMARC records
    │
    └── Private Hosted Zone: internal.local (VPC only)
            ├── A: db.internal.local      → 10.0.1.5  (RDS)
            └── A: cache.internal.local   → 10.0.1.10 (ElastiCache)
```

---

## Interview Questions

**Q: Why use Route 53 instead of the registrar's built-in DNS?**
Route 53 offers advanced routing (latency, failover, geo), health checks, AWS service integration, and global anycast availability. Registrar DNS is basic — typically just A and CNAME with no routing logic.

**Q: Why use Alias instead of CNAME?**
CNAME is forbidden at the root domain by DNS standards. Alias works at the root, automatically tracks IP changes in AWS resources, and is free for queries to AWS targets.

**Q: Geolocation vs Geoproximity?**
Geolocation uses explicit country/continent rules. Geoproximity uses physical distance with an optional bias to expand or shrink a region's coverage. Geoproximity is more flexible but requires Traffic Flow.

**Q: Why lower TTL before a migration?**
Resolvers cache DNS answers for the TTL duration. A 24h TTL means old traffic continues hitting the old server for up to 24 hours after a change. Lower it to 60s first so the transition is near-instant.

**Q: Failover vs Multi-Value routing?**
Failover is strict primary/secondary — all traffic goes to primary, switches only when health check fails. Multi-Value returns up to 8 healthy IPs and lets the client choose. Failover is for DR; Multi-Value is for simple load distribution.

**Q: What is negative caching and why does it matter?**
DNS caches not-found responses (`NXDOMAIN`) too. If you query a non-existent subdomain and then create it, it may not be accessible until the negative TTL expires. Relevant when creating new subdomains.

---

## Quick Glossary

| Term | Definition |
|------|------------|
| DNS | Domain Name System — translates names to IPs |
| HOSTS.TXT | Pre-DNS single file mapping all hostnames; replaced by DNS in 1983 |
| Registrar | Company where you buy/register a domain |
| Recursive Resolver | DNS server that does lookup work on behalf of clients |
| Root Name Server | Top of hierarchy; knows all TLD server locations |
| TLD | Top-Level Domain — `.com`, `.org`, `.in` |
| Authoritative NS | Final DNS server with the definitive answer for a domain |
| Hosted Zone | Container for DNS records in Route 53 |
| A Record | Domain → IPv4 |
| AAAA Record | Domain → IPv6 |
| CNAME | Domain → another domain (not at root) |
| MX | Mail server record |
| TXT | Text record — SPF, DKIM, verification |
| PTR | Reverse DNS — IP → domain |
| NS | Name server record — declares authority |
| SOA | Start of Authority — zone metadata, auto-created |
| Alias | AWS extension — root domain to AWS resource |
| TTL | How long resolvers cache a DNS answer |
| Negative Cache | Cached NXDOMAIN (not-found) responses |
| Public Hosted Zone | DNS resolvable from the internet |
| Private Hosted Zone | DNS resolvable only inside a VPC |
| Health Check | Route 53 actively monitors endpoint availability |
| Traffic Flow | Route 53 visual editor for complex routing |
| DNSSEC | DNS Security Extensions — prevents cache poisoning |

---

*💡 Study tip: The DNS resolution chain is the foundation — understand it cold first. Every Route 53 feature is an enhancement on top: hosted zones are the record store, routing policies are the query logic, health checks are the safeguard, and alias records are the AWS-native shortcut.*
