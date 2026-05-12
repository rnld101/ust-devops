# 1. What is GoDaddy?

[GoDaddy](https://www.godaddy.com?utm_source=chatgpt.com) is primarily:

* A **domain registrar**
* A web hosting provider
* SSL/email/website services provider

When you buy a domain like:

```text
example.com
```

through GoDaddy, GoDaddy becomes the registrar responsible for that domain.

Think of a registrar as:

> “The company that officially registers ownership of your internet domain.”

---

# 2. What is DNS?

DNS = **Domain Name System**

DNS converts:

```text
google.com
```

into an IP address like:

```text
142.250.183.14
```

because computers communicate using IP addresses.

You can think of DNS as:

| Human Friendly | Computer Friendly |
| -------------- | ----------------- |
| amazon.com     | 54.x.x.x          |
| netflix.com    | 52.x.x.x          |

---

# 3. What is a Name Server?

A **Name Server (NS)** is the server that answers DNS queries for your domain.

Example:

```text
ns-2048.awsdns-64.com
ns-512.awsdns-12.net
```

These are Route 53 name servers.

When someone types:

```text
example.com
```

their ISP asks:

> “Which name server knows about example.com?”

The configured name server answers with DNS records.

---

# 4. How GoDaddy and Route 53 Work Together

A very common setup is:

| Component | Responsibility      |
| --------- | ------------------- |
| GoDaddy   | Domain registration |
| Route 53  | DNS management      |

Flow:

```text
User buys domain in GoDaddy
        ↓
Create Hosted Zone in Route 53
        ↓
Route 53 gives NS records
        ↓
Update NS records in GoDaddy
        ↓
Now Route 53 controls DNS
```

---

# 5. What is Route 53?

[Amazon Route 53](https://aws.amazon.com/route53/?utm_source=chatgpt.com) is AWS’s DNS service.

It provides:

* Domain registration
* DNS management
* Health checks
* Traffic routing
* Failover
* Latency optimization

The name “Route 53” comes from:

* Port **53**
* Standard DNS port

---

# 6. What is a Hosted Zone?

A **Hosted Zone** is a container for DNS records.

Example:

```text
example.com
```

Inside the hosted zone you store:

```text
A record
CNAME
MX
TXT
etc.
```

Think of it as:

> “The DNS database for a domain.”

---

# 7. Public Hosted Zone vs Private Hosted Zone

## Public Hosted Zone

Accessible from the internet.

Example:

```text
example.com
api.example.com
```

Anyone on the internet can resolve these.

Used for:

* Websites
* APIs
* Public applications

---

## Private Hosted Zone

Accessible only inside a VPC.

Example:

```text
db.internal.local
payment.service.local
```

Only EC2s/resources inside the VPC can resolve them.

Used for:

* Internal microservices
* Databases
* Internal APIs

---

## Comparison

| Feature             | Public Zone | Private Zone |
| ------------------- | ----------- | ------------ |
| Internet accessible | Yes         | No           |
| Used for websites   | Yes         | No           |
| Attached to VPC     | No          | Yes          |
| Internal DNS        | No          | Yes          |

---

# 8. What are DNS Records?

Records define how traffic should be handled.

Example:

```text
example.com → 1.2.3.4
```

This mapping is stored as a DNS record.

---

# 9. Important Record Types

## A Record

Maps domain → IPv4 address

Example:

```text
example.com → 192.168.1.1
```

---

## AAAA Record

Maps domain → IPv6 address

---

## CNAME Record

Maps one domain to another domain.

Example:

```text
api.example.com → my-load-balancer.amazonaws.com
```

Important:

* Cannot point to IP
* Cannot be used at root domain in standard DNS

---

## MX Record

Mail server record.

Example:

```text
example.com → Google Workspace mail server
```

---

## TXT Record

Stores text data.

Commonly used for:

* Domain verification
* SPF
* DKIM
* DMARC

---

## NS Record

Defines authoritative name servers.

---

## SOA Record

Start of Authority.

Contains:

* DNS admin info
* Serial number
* Refresh timing

Automatically created.

---

# 10. A Record vs Alias Record in Route 53

## Normal A Record

```text
example.com → 54.23.12.1
```

Direct IP mapping.

---

## Alias Record (AWS Feature)

AWS-specific feature.

Allows:

```text
example.com → ALB
example.com → CloudFront
example.com → S3 website
```

without needing IP addresses.

Advantages:

* Root domain support
* Automatic IP updates
* Free Route 53 queries for AWS targets

---

## Why Alias Exists

Normally root domains cannot use CNAME:

❌ Invalid:

```text
example.com → mylb.amazonaws.com
```

Alias solves this.

---

# 11. What is TTL?

TTL = **Time To Live**

Defines how long DNS responses are cached.

Example:

```text
TTL = 300 seconds
```

Resolvers cache the record for 5 minutes.

---

## Low TTL

Example:

```text
60 seconds
```

Advantages:

* Faster DNS updates
* Better for failover

Disadvantages:

* More DNS queries

---

## High TTL

Example:

```text
86400 seconds
```

Advantages:

* Reduced DNS queries
* Better performance

Disadvantages:

* Slow propagation after changes

---

# 12. Routing Policy in Route 53

Routing policies decide:

> “How Route 53 answers DNS queries.”

---

# 13. Simple Routing

Default routing.

One record → one resource.

Example:

```text
example.com → ALB
```

Used when:

* Single application/server

---

# 14. Weighted Routing

Distributes traffic by percentage.

Example:

| Server   | Weight |
| -------- | ------ |
| Server A | 80     |
| Server B | 20     |

Result:

* 80% traffic to A
* 20% to B

Used for:

* Canary deployment
* Gradual rollout
* A/B testing

---

# 15. Latency-Based Routing

Routes users to lowest latency region.

Example:

| User   | Region    |
| ------ | --------- |
| India  | Mumbai    |
| Europe | Frankfurt |
| US     | Virginia  |

Improves:

* User experience
* Response time

---

# 16. Failover Routing

Primary + backup setup.

Example:

| Role      | Endpoint |
| --------- | -------- |
| Primary   | Main ALB |
| Secondary | DR ALB   |

If health check fails:

* Route 53 switches traffic to backup.

Used for:

* Disaster recovery
* High availability

---

# 17. Geolocation Routing

Routes based on user location.

Example:

| Country | Destination   |
| ------- | ------------- |
| India   | Indian server |
| US      | US server     |
| Europe  | EU server     |

Use cases:

* Localization
* Legal compliance
* Language-specific apps

---

# 18. Geoproximity Routing

Routes based on geographic distance.

Different from geolocation.

Example:

* User near Singapore → Singapore region
* User near Tokyo → Tokyo region

Can also:

* Bias traffic
* Shift regional traffic intentionally

Requires:

* Route 53 Traffic Flow

---

# 19. Multi-Value Answer Routing

Returns multiple healthy IPs.

Example:

```text
1.1.1.1
1.1.1.2
1.1.1.3
```

Client picks one.

Benefits:

* Basic load balancing
* Health check integration
* Simpler than ELB sometimes

---

# 20. IP-Based Routing

Routes based on source IP ranges.

Example:

| Corporate IP Range | Destination  |
| ------------------ | ------------ |
| 10.x.x.x           | Internal app |
| Other IPs          | Public app   |

Useful for:

* Enterprise traffic management
* ISP-specific routing

---

# 21. Difference Between Routing Policies

| Policy       | Based On                 |
| ------------ | ------------------------ |
| Simple       | Single resource          |
| Weighted     | Traffic percentage       |
| Latency      | Lowest latency           |
| Failover     | Health status            |
| Geolocation  | User country/location    |
| Geoproximity | Physical distance        |
| Multi-value  | Multiple healthy answers |
| IP-based     | Client IP range          |

---

# 22. Real-World Example Architecture

Imagine:

```text
Domain bought in GoDaddy
DNS managed in Route 53
Application hosted in AWS
```

Setup:

```text
GoDaddy
   ↓
NS updated to Route 53
   ↓
Public Hosted Zone
   ↓
A Alias Record
   ↓
Application Load Balancer
   ↓
EC2 / ECS / Kubernetes
```

---

# 23. Common Interview Questions

## Why use Route 53 instead of registrar DNS?

Because Route 53 provides:

* Advanced routing
* Health checks
* AWS integration
* Failover
* Latency routing

---

## Why use Alias instead of CNAME?

Because:

* Works at root domain
* AWS optimized
* Automatically tracks AWS IP changes

---

## Difference between Geolocation and Geoproximity?

| Geolocation                | Geoproximity               |
| -------------------------- | -------------------------- |
| Based on country/continent | Based on physical distance |
| Rule-based                 | Distance-based             |
| Easier                     | More advanced              |

---

## Why lower TTL during migration?

To reduce cache duration so traffic shifts faster after DNS changes.

---

# 24. Mental Model (Very Important)

Think of the entire flow like this:

```text
Domain Registrar
    ↓
Name Servers
    ↓
Hosted Zone
    ↓
DNS Records
    ↓
Routing Policy
    ↓
Actual Infrastructure
```

Example:

```text
GoDaddy
    ↓
Route 53 Name Servers
    ↓
Hosted Zone
    ↓
A Alias Record
    ↓
Latency Routing
    ↓
ALB in Mumbai / Virginia
```

---

# 25. Final Summary

| Concept        | Purpose                |
| -------------- | ---------------------- |
| GoDaddy        | Buy/manage domains     |
| Name Server    | Answers DNS queries    |
| Route 53       | AWS DNS service        |
| Hosted Zone    | DNS record container   |
| Public Zone    | Internet DNS           |
| Private Zone   | Internal VPC DNS       |
| Record         | DNS mapping            |
| TTL            | Cache duration         |
| Alias          | AWS-aware DNS target   |
| Routing Policy | Traffic decision logic |

And the routing policies:

| Policy       | Best For               |
| ------------ | ---------------------- |
| Simple       | Single app             |
| Weighted     | Canary rollout         |
| Latency      | Global apps            |
| Failover     | Disaster recovery      |
| Geolocation  | Country-based routing  |
| Geoproximity | Distance-based routing |
| Multi-value  | Simple HA              |
| IP-based     | Enterprise routing     |

