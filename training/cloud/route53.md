# 🌐 DNS & Amazon Route 53 — Complete Study Guide

> **How to use this guide:** Start from Part 1 and read sequentially. Each section builds on the previous one. By the end, you'll have a complete mental model from buying a domain all the way to routing traffic across AWS infrastructure.

---

## Table of Contents

1. [The Big Picture](#the-big-picture)
2. [How DNS Actually Works](#how-dns-actually-works)
3. [Core DNS Terminology](#core-dns-terminology)
4. [DNS Record Types](#dns-record-types)
5. [Amazon Route 53](#amazon-route-53)
6. [Hosted Zones](#hosted-zones)
7. [Alias Records](#alias-records)
8. [TTL — Time To Live](#ttl--time-to-live)
9. [Routing Policies](#routing-policies)
10. [Health Checks](#health-checks)
11. [Key Differences & Comparisons](#key-differences--comparisons)
12. [Real-World Architecture](#real-world-architecture)
13. [Interview Questions](#interview-questions)
14. [Quick Glossary](#quick-glossary)

---

## The Big Picture

Before diving into details, here is the complete flow from a domain purchase to a user hitting your application:

```
You buy domain on GoDaddy
         ↓
Point GoDaddy NS records → Route 53
         ↓
Route 53 Hosted Zone holds your DNS records
         ↓
User types your domain in browser
         ↓
DNS Resolution happens (browser → ISP → root → TLD → Route 53)
         ↓
Route 53 applies a Routing Policy
         ↓
Returns IP / Alias target
         ↓
User's request hits your AWS infrastructure (ALB / CloudFront / EC2)
```

Every concept in this guide fits somewhere in this chain.

---

## How DNS Actually Works

### The Problem DNS Solves

Computers talk to each other using **IP addresses** like `142.250.183.14`. Humans remember names like `google.com`. DNS is the system that bridges this gap — the **phonebook of the internet**.

| Human-Friendly | Computer-Friendly |
|----------------|-------------------|
| google.com | 142.250.183.14 |
| amazon.com | 54.x.x.x |
| netflix.com | 52.x.x.x |

### The DNS Resolution Journey

When you type `example.com` in your browser, this is exactly what happens — step by step:

```
Browser
  │
  ├─ 1. Check local cache → (found? done. not found? continue ↓)
  │
  ├─ 2. Ask Recursive Resolver (your ISP's DNS or 8.8.8.8)
  │
  ├─ 3. Resolver → Root Name Server
  │         "Who handles .com?"
  │         Root replies: "Ask the .com TLD server"
  │
  ├─ 4. Resolver → .com TLD Name Server
  │         "Who handles example.com?"
  │         TLD replies: "Ask ns-2048.awsdns-64.com"
  │
  ├─ 5. Resolver → Route 53 (Authoritative Name Server)
  │         "What is example.com?"
  │         Route 53 replies: "It's 1.2.3.4"
  │
  └─ 6. Browser connects to 1.2.3.4 ✓
```

This entire process typically takes **milliseconds**. Results are cached per the TTL to avoid repeating it on every request.

### The Key Players

| Component | Role | Example |
|-----------|------|---------|
| **Recursive Resolver** | Does all the legwork of finding the answer | Your ISP's DNS or `8.8.8.8` |
| **Root Name Server** | Knows where all TLD servers are | 13 root server clusters worldwide |
| **TLD Name Server** | Knows who manages each domain under a TLD | Handles all `.com`, `.org`, `.in` |
| **Authoritative Name Server** | Has the final, definitive answer | Route 53, Cloudflare |

> 💡 **Key Insight:** Route 53 acts as the **Authoritative Name Server**. It is the last stop in the chain and the one that actually holds your DNS records.

---

## Core DNS Terminology

### Domain Registrar

The company you **buy your domain from**. Examples: GoDaddy, Namecheap, Google Domains.

Buying a domain gives you ownership, but it does **not** automatically control where DNS is managed. You can register with GoDaddy and still point DNS to Route 53.

> Think of the registrar as: *"The company that officially registers ownership of your internet domain."*

### Name Server (NS)

The server that is authoritative for your domain — it holds and answers DNS queries.

```
ns-2048.awsdns-64.com   ← Route 53 name server
ns-512.awsdns-12.net    ← Route 53 name server
```

When you update your registrar (e.g., GoDaddy) to use Route 53's name servers, you hand over DNS authority to Route 53.

### Hosted Zone

Route 53's **container for DNS records**. Think of it as the DNS database for a domain.

```
Hosted Zone: example.com
│
├── A record       example.com → 1.2.3.4
├── CNAME          www → example.com
├── MX             example.com → mail server
└── TXT            example.com → "v=spf1 ..."
```

---

## DNS Record Types

DNS records are the mappings inside a hosted zone. Each type serves a specific purpose.

---

### `A` Record — IPv4 Address

Maps a domain name directly to an **IPv4 address**.

```
example.com  →  192.168.1.1
```

Used for: Any domain that needs to resolve to a server's IP.

---

### `AAAA` Record — IPv6 Address

Maps a domain name to an **IPv6 address**.

```
example.com  →  2001:0db8:85a3::8a2e:0370:7334
```

Used for: Modern IPv6-enabled infrastructure.

---

### `CNAME` Record — Canonical Name (Alias to another domain)

Maps one domain name to **another domain name**.

```
api.example.com  →  my-load-balancer.amazonaws.com
www.example.com  →  example.com
```

**Important limitations:**
- Cannot point to an IP address (use A record for that)
- **Cannot be used at the root domain** (`example.com`) — only subdomains

```
✅ www.example.com   → CNAME → something.amazonaws.com
❌ example.com       → CNAME → something.amazonaws.com  (invalid)
```

> This root-domain limitation is exactly why Route 53 introduced the **Alias record**.

---

### `MX` Record — Mail Exchange

Defines the **mail servers** responsible for receiving email for a domain. Includes a priority value.

```
example.com  →  10  mail.google.com
example.com  →  20  mail-backup.google.com
```

Lower priority number = higher preference.

Used for: Gmail, Microsoft 365, or any custom email setup.

---

### `TXT` Record — Text

Stores **arbitrary text data** associated with a domain. Primarily used for verification and email security.

Common uses:

| Purpose | Example Value |
|---------|---------------|
| Domain verification | `google-site-verification=abc123` |
| SPF (email sender policy) | `v=spf1 include:_spf.google.com ~all` |
| DKIM (email signing key) | `v=DKIM1; k=rsa; p=MIGf...` |
| DMARC (email policy) | `v=DMARC1; p=reject; rua=mailto:dmarc@...` |

---

### `NS` Record — Name Server

Declares which **name servers are authoritative** for the domain. These are the records you update in GoDaddy when pointing to Route 53.

```
example.com  NS  ns-2048.awsdns-64.com
example.com  NS  ns-512.awsdns-12.net
```

---

### `SOA` Record — Start of Authority

**Auto-created** by Route 53 for every hosted zone. Contains metadata about the DNS zone itself.

Includes:
- Primary name server
- DNS admin email
- Serial number (version)
- Refresh and retry timing

You rarely need to modify this manually.

---

### Record Types — Quick Reference

| Record | Maps | Example |
|--------|------|---------|
| `A` | Domain → IPv4 | `example.com → 1.2.3.4` |
| `AAAA` | Domain → IPv6 | `example.com → 2001:db8::1` |
| `CNAME` | Domain → Domain | `www → example.com` |
| `MX` | Domain → Mail server | `example.com → mail.google.com` |
| `TXT` | Domain → Text string | SPF, DKIM, verification |
| `NS` | Domain → Name servers | Points to Route 53 servers |
| `SOA` | Zone metadata | Auto-created, rarely edited |
| `Alias` *(Route 53 only)* | Root domain → AWS resource | `example.com → ALB` |

---

## Amazon Route 53

### What is Route 53?

Amazon Route 53 is AWS's fully managed **DNS service**. The name comes from **port 53** — the standard port for DNS.

It goes beyond basic DNS and provides:

- **DNS management** — host and manage DNS records
- **Domain registration** — buy domains directly in AWS
- **Health checks** — monitor endpoint availability
- **Traffic routing** — 8 different routing policies
- **Failover** — automatic disaster recovery via DNS
- **Latency optimization** — route users to the fastest region

### How GoDaddy + Route 53 Work Together

The most common real-world setup: **GoDaddy registers the domain, Route 53 manages DNS.**

```
Step 1: Buy domain on GoDaddy  →  example.com
         ↓
Step 2: Create Hosted Zone in Route 53
         ↓
Step 3: Route 53 provides 4 NS records
        ns-2048.awsdns-64.com
        ns-512.awsdns-12.net
        ns-1024.awsdns-00.org
        ns-768.awsdns-32.co.uk
         ↓
Step 4: Paste those NS records into GoDaddy's NS settings
         ↓
Step 5: Route 53 is now authoritative DNS for example.com ✓
```

This separation lets you use Route 53's advanced routing while keeping your domain registered anywhere you prefer.

---

## Hosted Zones

A **Hosted Zone** is the DNS container in Route 53. It holds all the DNS records for a domain.

### Public Hosted Zone

Accessible from the **open internet**. Anyone in the world can resolve these records.

```
example.com        →  Public
api.example.com    →  Public
cdn.example.com    →  Public
```

Used for: Websites, public APIs, public-facing services.

### Private Hosted Zone

Accessible **only from within a specified VPC**. External requests cannot resolve these names.

```
db.internal.local          →  Only resolvable inside VPC
payment.service.internal   →  Only resolvable inside VPC
auth.microservice.local    →  Only resolvable inside VPC
```

Used for: Internal microservices, databases, private APIs.

### Comparison

| Feature | Public Zone | Private Zone |
|---------|-------------|--------------|
| Internet accessible | ✅ Yes | ❌ No |
| Attached to VPC | ❌ No | ✅ Yes |
| Use case | Websites, public APIs | Internal services |
| Typical TLD | `.com`, `.io`, `.in` | `.local`, `.internal` |

---

## Alias Records

### The Problem Alias Solves

Standard DNS has two problems with AWS resources:

**Problem 1:** CNAME cannot be used at the root domain.
```
❌ example.com → CNAME → my-alb.amazonaws.com   (invalid)
```

**Problem 2:** AWS services (ALB, CloudFront) don't have **static IPs** — they change. You can't hardcode them in an A record.

```
❌ example.com → A → 54.x.x.x   (IP will change tomorrow)
```

### The Solution: Alias Record

Route 53's **Alias record** is an AWS extension to standard DNS. It solves both problems.

```
✅ example.com  →  ALIAS  →  my-alb.amazonaws.com
✅ example.com  →  ALIAS  →  d1234.cloudfront.net
✅ example.com  →  ALIAS  →  mybucket.s3-website.amazonaws.com
✅ example.com  →  ALIAS  →  another-r53-record.example.com
```

Route 53 automatically resolves the Alias target and returns the correct IPs — and it updates automatically when AWS changes them.

### Alias vs CNAME vs A Record

| Feature | A Record | CNAME | Alias |
|---------|----------|-------|-------|
| Works at root domain | ✅ (needs static IP) | ❌ | ✅ |
| Points to domain name | ❌ | ✅ | ✅ |
| Tracks IP changes automatically | ❌ | ❌ | ✅ |
| Works with AWS services | ❌ | Partially | ✅ |
| Route 53 query charges | Yes | Yes | **Free** (for AWS targets) |

---

## TTL — Time To Live

TTL defines **how long** (in seconds) a DNS resolver should cache a record before re-querying.

```
TTL = 60      →  Cache for 1 minute
TTL = 300     →  Cache for 5 minutes
TTL = 86400   →  Cache for 24 hours
```

### Low TTL vs High TTL

| | Low TTL (e.g., 60s) | High TTL (e.g., 86400s) |
|---|---|---|
| Propagation speed | ⚡ Fast | 🐢 Slow |
| DNS query volume | High | Low |
| Good for | Failover, migrations | Stable production records |
| Flexibility | High | Low |

> 🔑 **Migration tip:** Before making any DNS change, lower your TTL to `60` seconds and wait for the old TTL to expire. Then make your change. Traffic will shift much faster. Raise TTL back after the migration is stable.

---

## Routing Policies

Routing policies control **how Route 53 responds to DNS queries**. This is where Route 53 goes far beyond basic DNS.

---

### 1. Simple Routing

The **default**. One record maps to one resource. No logic, no conditions.

```
example.com  →  ALB
```

**Use when:** You have a single server or a single endpoint.

---

### 2. Weighted Routing

Distributes traffic across **multiple endpoints by percentage**.

```
example.com  →  Server A (weight: 80)  →  gets 80% of traffic
example.com  →  Server B (weight: 20)  →  gets 20% of traffic
```

Setting a weight to `0` removes a target from rotation without deleting it.

**Use for:**
- Canary deployments (send 5% to new version, 95% to old)
- A/B testing
- Gradual traffic migration between regions

---

### 3. Latency-Based Routing

Routes each user to the **AWS region with the lowest network latency** for them. Route 53 measures latency between the user's region and your configured regions.

| User Location | Routed To |
|---------------|-----------|
| India | ap-south-1 (Mumbai) |
| Europe | eu-central-1 (Frankfurt) |
| US East | us-east-1 (Virginia) |

**Use for:** Global applications where performance is critical.

> Note: This routes by **latency**, not by geography. A user in India might get routed to Singapore if latency there is lower.

---

### 4. Failover Routing

**Primary + secondary** setup. Route 53 uses health checks to determine when to failover.

| Role | Endpoint | Status |
|------|----------|--------|
| Primary | Main ALB — us-east-1 | Healthy → serves traffic |
| Secondary | DR ALB — us-west-2 | Standby → activates on failure |

When the primary fails its health check, Route 53 automatically starts returning the secondary's address.

**Use for:** Disaster recovery, high availability, business continuity.

---

### 5. Geolocation Routing

Routes based on the **country or continent** of the user. You define rules per location.

| User's Country | Destination |
|----------------|-------------|
| India | in.example.com |
| United States | us.example.com |
| Germany | eu.example.com |
| (Default) | global.example.com |

Always configure a **Default** record — it catches users from locations not explicitly mapped.

**Use for:** Legal compliance (GDPR), localization, language-specific content delivery.

---

### 6. Geoproximity Routing

Routes based on **physical distance** between the user and your resources. You can also apply a **bias** — a positive bias expands a region's coverage, a negative bias shrinks it.

```
Bias = +50 on Mumbai  →  Mumbai attracts more users (even from farther away)
Bias = -25 on Tokyo   →  Tokyo serves a smaller geographic area
```

Requires **Route 53 Traffic Flow** (the visual policy editor in the console).

**Use for:** Fine-grained geographic traffic shaping across many global regions.

> 🔑 **Geolocation vs Geoproximity:**
> - Geolocation: rule-based by **country/continent**
> - Geoproximity: distance-based with **adjustable bias**

---

### 7. Multi-Value Answer Routing

Returns **up to 8 healthy IP addresses** in response to a DNS query. The client picks one (usually at random). Unlike Simple routing, this integrates with health checks — unhealthy endpoints are excluded.

```
DNS response:
  1.1.1.1  ✓ healthy  →  included
  1.1.1.2  ✓ healthy  →  included
  1.1.1.3  ✗ unhealthy → excluded
```

**Use for:** Basic client-side load balancing without setting up an ELB.

> Note: This is **not** a true load balancer replacement — it's DNS-level distribution only.

---

### 8. IP-Based Routing

Routes based on the **source IP range (CIDR block)** of the client. You define CIDR-to-endpoint mappings.

| Client IP Range | Destination |
|-----------------|-------------|
| `10.0.0.0/8` (corporate network) | Internal app |
| `203.0.113.0/24` (ISP A) | ISP-optimized endpoint |
| All other IPs | Public app |

**Use for:** Enterprise traffic management, ISP-specific routing, on-prem to cloud setups.

---

### Routing Policies — Quick Reference

| Policy | Routes Based On | Best For |
|--------|-----------------|----------|
| **Simple** | Single record | One app, one server |
| **Weighted** | Traffic % split | Canary releases, A/B testing |
| **Latency** | Lowest latency to region | Global apps, performance |
| **Failover** | Health check status | Disaster recovery, HA |
| **Geolocation** | Country / continent | Compliance, localization |
| **Geoproximity** | Physical distance + bias | Advanced geo traffic shaping |
| **Multi-Value** | Multiple healthy IPs | Simple HA without ELB |
| **IP-Based** | Client IP / CIDR | Enterprise, ISP routing |

---

## Health Checks

Route 53 can **actively monitor your endpoints** and automatically remove unhealthy ones from DNS responses.

### Types of Health Checks

**1. Endpoint Health Check**
Monitors a URL, IP address, or domain on a schedule.
```
Monitor: https://example.com/health
Interval: every 30 seconds
Threshold: fail after 3 consecutive failures
```

**2. Calculated Health Check**
Combines the results of **multiple health checks** using AND / OR / NOT logic.
```
Healthy only if: check-A AND check-B AND check-C all pass
```

**3. CloudWatch Alarm Health Check**
Triggers based on a **CloudWatch metric or alarm** (e.g., CPU > 90%, error rate > 5%).

### Integration with Routing Policies

Health checks are used by:
- **Failover Routing** — triggers the switch to secondary
- **Multi-Value Routing** — excludes unhealthy IPs from the response
- **Weighted / Latency / Geolocation** — can be combined with health checks to skip unhealthy targets

---

## Key Differences & Comparisons

### CNAME vs Alias

| | CNAME | Alias |
|---|---|---|
| Works at root domain | ❌ No | ✅ Yes |
| Points to | Any domain | AWS resources only |
| Tracks IP changes | ❌ No | ✅ Automatically |
| Route 53 query charge | Yes | Free (for AWS targets) |
| Standard DNS? | Yes | AWS-specific extension |

---

### Geolocation vs Geoproximity

| | Geolocation | Geoproximity |
|---|---|---|
| Routes by | Country / continent | Physical distance |
| Logic type | Rule-based | Distance-based |
| Bias support | ❌ No | ✅ Yes |
| Complexity | Simpler | More advanced |
| Requires Traffic Flow | ❌ No | ✅ Yes |

---

### Public vs Private Hosted Zone

| | Public Zone | Private Zone |
|---|---|---|
| Resolvable from | Internet | Inside VPC only |
| Use case | Websites, APIs | Internal microservices |
| Typical domain | `.com`, `.io` | `.local`, `.internal` |
| VPC attachment required | ❌ No | ✅ Yes |

---

### Low TTL vs High TTL

| | Low TTL | High TTL |
|---|---|---|
| Value | 60s | 86400s |
| Propagation speed | Fast | Slow |
| Query load | High | Low |
| Best for | Migrations, failover | Stable records |

---

## Real-World Architecture

### Full AWS Setup

```
GoDaddy (Domain registrar)
    │
    │  NS records updated to Route 53
    ▼
Route 53 Name Servers
    │
    │  Authoritative for example.com
    ▼
Public Hosted Zone: example.com
    │
    ├── Alias A Record (root domain)
    │       │
    │       │  Latency Routing Policy
    │       ▼
    │   ┌─────────────────────────────┐
    │   │                             │
    │   ALB — ap-south-1 (Mumbai)    ALB — us-east-1 (Virginia)
    │   │                             │
    │   ECS Tasks                    ECS Tasks
    │
    ├── CNAME: www.example.com → example.com
    ├── MX: example.com → Google Workspace
    ├── TXT: example.com → SPF, DKIM, DMARC records
    │
    └── Private Hosted Zone: internal.local
            │
            ├── A: db.internal.local → 10.0.1.5 (RDS)
            └── A: cache.internal.local → 10.0.1.10 (ElastiCache)
```

---

## Interview Questions

**Q: Why use Route 53 instead of the registrar's built-in DNS?**

Route 53 offers advanced routing policies (latency, failover, geolocation), health checks, tight AWS integration, and high availability across a global anycast network. Registrar DNS is basic — it typically only supports simple A/CNAME records with no health checks or intelligent routing.

---

**Q: Why use Alias instead of CNAME?**

Alias works at the root domain (`example.com`) where CNAME is forbidden by DNS standards. It also automatically tracks IP changes in AWS resources (ALB, CloudFront, etc.) and is free for queries to AWS targets — CNAME is charged per query.

---

**Q: What is the difference between Geolocation and Geoproximity routing?**

Geolocation routes by **country or continent** using explicit rules — traffic from India goes to the Indian server regardless of distance. Geoproximity routes by **physical distance** and lets you apply a bias to shift traffic boundaries. Geoproximity requires Route 53 Traffic Flow and is more flexible but more complex.

---

**Q: Why lower TTL before a migration?**

Because resolvers cache DNS answers for the duration of the TTL. If TTL is 86400s (24 hours) and you change your A record, old traffic keeps hitting the old server for up to 24 hours. Lowering TTL to 60s first means the transition takes ~1 minute after the change.

---

**Q: What is the difference between Failover and Multi-Value routing?**

Failover is a strict primary/secondary setup — all traffic goes to primary, and only switches to secondary when the primary's health check fails. Multi-Value returns up to 8 healthy IPs and lets the client choose — it's more like simple load balancing. Failover is for DR; Multi-Value is for basic HA.

---

## Quick Glossary

| Term | Definition |
|------|------------|
| **DNS** | Domain Name System — translates domain names to IP addresses |
| **Registrar** | Company where you buy/register a domain (GoDaddy, Namecheap) |
| **Recursive Resolver** | DNS server that does the lookup work on behalf of clients |
| **Root Name Server** | Top of the DNS hierarchy, knows where all TLD servers are |
| **TLD** | Top-Level Domain — `.com`, `.org`, `.in`, `.io` |
| **Authoritative NS** | The final DNS server with the definitive answer for a domain |
| **Name Server** | Server that holds and answers DNS queries for a domain |
| **Hosted Zone** | Container for DNS records in Route 53 |
| **A Record** | Maps domain → IPv4 address |
| **AAAA Record** | Maps domain → IPv6 address |
| **CNAME** | Maps domain → another domain (not allowed at root) |
| **MX Record** | Defines mail servers for a domain |
| **TXT Record** | Stores text — used for SPF, DKIM, DMARC, verification |
| **NS Record** | Declares authoritative name servers for a domain |
| **SOA Record** | Start of Authority — zone metadata, auto-created |
| **Alias Record** | AWS-specific record — maps root domain to AWS resources |
| **TTL** | Time To Live — how long resolvers cache a DNS answer |
| **Public Hosted Zone** | DNS accessible from the internet |
| **Private Hosted Zone** | DNS accessible only inside a VPC |
| **Health Check** | Route 53 monitors an endpoint and marks it healthy/unhealthy |
| **Traffic Flow** | Route 53's visual editor for complex routing policies |
| **Geolocation** | Route by user's country/continent |
| **Geoproximity** | Route by physical distance with optional bias |
| **Weighted Routing** | Split traffic by percentage across endpoints |
| **Failover Routing** | Primary + secondary with automatic health-check-based switching |

---

*💡 **Study tip:** The DNS resolution chain is the foundation — understand it cold. Then every Route 53 feature is just an enhancement on top: hosted zones are the database, routing policies are the query logic, health checks are the safeguard, and alias records are the AWS-native shortcut.*
