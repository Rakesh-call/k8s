

---

# Docker Networking Actually Hai Kya?

जब हम container run करते हैं:

```bash
docker run nginx
```

तो एक सवाल आता है:

> Container internet से बात कैसे कर रहा है?
>
> Host machine से communicate कैसे कर रहा है?
>
> Container-1 Container-2 को कैसे ढूंढ रहा है?

इन सबका answer Docker Networking है।

लेकिन सबसे important बात:

👉 Docker ने कोई नया networking system नहीं बनाया।

Docker सिर्फ Linux Kernel के existing networking features का use करता है।

Mainly:

1. Network Namespace
2. Veth Pair
3. Linux Bridge
4. iptables
5. NAT

---

# Chapter 2: Network Namespace (netns)

सबसे पहले समझो:

एक Linux Machine में normally एक network stack होता है।

Example:

Laptop:

```text
IP Address
Routing Table
DNS
Firewall Rules
Network Interfaces
```

सब एक ही जगह होते हैं।

---

## Real Problem

मान लो एक machine पर 100 containers चल रहे हैं।

अगर सभी एक ही network stack use करेंगे तो:

```text
IP conflict
Port conflict
Security issue
```

आ जायेगा।

इसलिए Linux ने Network Namespace बनाया।

---

## Network Namespace Kya Hai?

Network Namespace एक virtual private network world है।

Imagine:

```text
Host Machine
|
|-- Namespace 1
|
|-- Namespace 2
|
|-- Namespace 3
```

हर namespace के पास अपना:

```text
IP Address
Routing Table
Firewall
DNS
Socket Table
```

होता है।

एक namespace दूसरे namespace को नहीं देख सकता।

---

## Real Life Example

जैसे Apartment Building में:

```text
Flat A
Flat B
Flat C
```

हर flat का:

```text
Door
Electricity
Water
```

अलग होता है।

वैसे ही:

```text
Container A
Container B
Container C
```

के network resources अलग होते हैं।

---

# Chapter 3: Docker Container Ka Network Namespace

जब Docker Container create करता है:

```bash
docker run nginx
```

Docker internally:

```text
1. New Process Create
2. New Network Namespace Create
```

करता है।

Container को लगता है:

```text
Main hi poori machine hoon
```

उसे host का:

```text
eth0
wlan0
```

कुछ नहीं दिखता।

---

# Chapter 4: Problem - Container Bahar Kaise Jayega?

अब issue आया।

Container isolated है।

तो:

```text
Google.com
Database
API
Internet
```

तक कैसे पहुँचेगा?

---

# Chapter 5: Veth Pair

Linux ने इसका solution दिया:

Virtual Ethernet Pair

---

## Simple Definition

Veth pair = Virtual Cable

---

Imagine:

```text
Container
|
|==== Cable ====|
|
Host
```

असल में यही Veth Pair है।

---

## Structure

```text
vethA <------> vethB
```

दो virtual interfaces होते हैं।

अगर:

```text
vethA
```

में packet भेजा

तो

```text
vethB
```

से निकलेगा।

---

## Docker Kya Karta Hai?

Docker:

```text
One End → Host
Second End → Container
```

में डाल देता है।

---

Diagram:

```text
Host Namespace

veth123
   |
   |
==========

eth0 (inside container)
```

Container के अंदर इसे rename कर दिया जाता है:

```text
eth0
```

इसलिए container के अंदर:

```bash
ip addr
```

चलाओ तो दिखेगा:

```text
eth0
```

लेकिन वास्तव में वह Veth Pair का दूसरा सिरा है।

---

# Chapter 6: Data Packet Journey

मान लो:

Container:

```text
172.18.0.2
```

Google:

```text
8.8.8.8
```

---

Container packet भेजता है:

```text
eth0
↓
Veth Pair
↓
Host Side Veth
↓
Linux Bridge
↓
Host Routing
↓
Internet
```

यही पूरा path है।

---

# Chapter 7: Bridge Network

Docker का default networking mode:

```bash
docker network create my-net
```

या

```text
bridge
```

---

## Real Life Analogy

Imagine Company Office Switch

```text
Laptop A
Laptop B
Laptop C
```

सभी switch से connected हैं।

---

Docker में:

```text
Container A
Container B
Container C
```

Linux Bridge से connected होते हैं।

---

Diagram

```text
Container A
    |
  veth
    |
------------------
Linux Bridge
------------------
    |
  veth
    |
Container B
```

Linux Bridge basically software switch है।

---

## Bridge Interface

Host पर:

```bash
ip link
```

चलाओ।

तुम्हें दिखेगा:

```text
docker0
```

या

```text
br-xxxxx
```

यही Docker Switch है।

---

# Chapter 8: Container to Container Communication

मान लो:

```text
Container A = 172.18.0.2

Container B = 172.18.0.3
```

A packet भेजता है।

Flow:

```text
Container A
↓
eth0
↓
veth
↓
Bridge
↓
veth
↓
Container B
```

ध्यान दो:

❌ Internet नहीं गया

❌ Physical NIC नहीं गया

सब host machine के अंदर हुआ।

इसलिए communication fast होती है।

---

# Chapter 9: Container To Internet Communication

अब container:

```text
8.8.8.8
```

को access करना चाहता है।

---

Flow:

```text
Container
↓
Bridge
↓
Routing Table
↓
iptables NAT
↓
Host Public IP
↓
Internet
```

---

# NAT Kya Hota Hai?

Container IP:

```text
172.18.0.2
```

Private IP है।

Internet इसको नहीं जानता।

इसलिए Host packet modify करता है।

---

Example:

Before NAT

```text
Source:
172.18.0.2
```

After NAT

```text
Source:
192.168.1.50
```

(Host IP)

अब internet reply भेज सकता है।

---

# Chapter 10: Host Network Driver

Command:

```bash
docker run --network host nginx
```

---

Normally:

```text
Container → Namespace → Veth → Bridge
```

होता था।

अब:

```text
Container
↓
Host Network Directly
```

---

Namespace Create Nahi Hota

Container directly host network use करता है।

---

Example

Host IP:

```text
192.168.1.50
```

Container भी वही use करेगा।

---

## Benefit

Fastest networking.

No:

```text
Bridge
Veth
NAT
```

---

## Drawback

Port Conflict

Example:

Container-1:

```text
Port 8080
```

use कर रहा है।

तो:

Container-2

```text
Port 8080
```

use नहीं कर सकता।

क्योंकि दोनों host network share कर रहे हैं।

---

# Chapter 11: None Network

Command:

```bash
docker run --network none nginx
```

---

Result:

```text
No Internet
No Bridge
No Veth
No Routing
```

सिर्फ:

```text
127.0.0.1
```

loopback रहेगा।

---

Use Cases

```text
Batch Jobs
Security Testing
Offline Processing
Highly Isolated Workloads
```

---

# Chapter 12: Overlay Network

यह Kubernetes और Docker Swarm समझने के लिए बहुत important concept है।

---

Imagine:

Server-1

```text
Container A
```

Server-2

```text
Container B
```

दोनों अलग machines पर हैं।

---

Question:

```text
A → B
```

communication कैसे होगी?

---

Answer:

Overlay Network

---

Container को ऐसा लगता है:

```text
Hum same network me hain
```

लेकिन reality में:

```text
Different Physical Servers
```

पर होते हैं।

---

# VXLAN Magic

Docker packet को wrap करता है।

Original:

```text
Container Packet
```

बन जाता है:

```text
UDP Packet
    |
    --> Original Packet Inside
```

इसे Encapsulation कहते हैं।

---

Flow:

```text
Container A
↓
Overlay Network
↓
VXLAN
↓
Internet / LAN
↓
Server 2
↓
Decapsulation
↓
Container B
```

---

# Chapter 13: Docker Internal DNS

यह interview में बहुत पूछा जाता है।

---

मान लो:

```text
frontend
backend
database
```

तीन containers हैं।

---

Frontend:

```python
db.connect("database")
```

लिखता है।

---

Question:

```text
database IP kaise mila?
```

---

Docker Internal DNS

Every custom network has:

```text
127.0.0.11
```

---

Container:

```text
database
```

पूछता है।

Docker DNS जवाब देता है:

```text
database = 172.18.0.5
```

---

इसलिए Docker Compose में हम लिख पाते हैं:

```yaml
DB_HOST=database
```

IP लिखने की जरूरत नहीं होती।

---

Docker के user-defined network में:

```text
127.0.0.11
```

एक **embedded internal DNS server** होता है, जो container names और network aliases को IP address में resolve करता है।

---

## Example

मान लो तुमने एक custom network बनाया:

```bash
docker network create app-net
```

और दो containers run किये:

```bash
docker run -d --name database --network app-net postgres

docker run -d --name frontend --network app-net nginx
```

Docker internally कुछ ऐसा maintain करता है:

```text
database  -> 172.18.0.2

frontend  -> 172.18.0.3
```

अब frontend container के अंदर:

```bash
ping database
```

चलाओ।

Frontend को database का IP नहीं पता।

तो process कुछ ऐसा होता है:

```text
frontend
    |
    | DNS Query: "database" ka IP kya hai?
    v
127.0.0.11
    |
    | Lookup Docker Network Database
    v
database = 172.18.0.2
    |
    v
Response Return
```

फिर frontend directly:

```text
172.18.0.2
```

से connect कर लेता है।

---

## Container के अंदर देख सकते हो

Container में enter करो:

```bash
docker exec -it frontend sh
```

फिर:

```bash
cat /etc/resolv.conf
```

Output कुछ ऐसा मिलेगा:

```text
nameserver 127.0.0.11
options ndots:0
```

यह बताता है कि container DNS queries किसे भेज रहा है।

---

## Real-World Docker Compose Example

मान लो:

```yaml
services:
  frontend:
    image: nginx

  database:
    image: postgres
```

Application code:

```python
db_host = "database"
```

या

```properties
DB_HOST=database
```

यह इसलिए काम करता है क्योंकि Docker DNS:

```text
database
```

को automatically resolve कर देता है।

तुम्हें कभी IP manually नहीं लिखना पड़ता।

---

## Important Interview Point

Docker DNS **सिर्फ उसी network के containers को resolve करता है।**

Example:

```text
Network-A
 ├── frontend
 └── database
```

तो:

```bash
ping database
```

काम करेगा।

लेकिन अगर database किसी दूसरे Docker network में है:

```text
Network-B
 └── database
```

तो:

```bash
ping database
```

fail होगा।

क्योंकि Docker DNS network-scoped होता है।

---

## Real Kubernetes Connection

Docker में:

```text
database
```

name resolve होता है।

Kubernetes में यही concept आगे बढ़कर:

```text
mysql-service.default.svc.cluster.local
```

जैसे Service DNS names में बदल जाता है।

इसलिए Docker Internal DNS समझना Kubernetes Service Discovery समझने की foundation है।


देखिये और बारीकी से देखे तों **127.0.0.11 Docker का internal DNS resolver है**, जो:

* Container names resolve करता है
* Network aliases resolve करता है
* Same Docker network के containers को discover करने में मदद करता है
* IP addresses dynamically return करता है
* Service discovery provide करता है

यही वजह है कि हम:

```bash
ping database
curl http://backend:8080
```



---

# Chapter 14: EXPOSE vs Port Mapping

Interview Favorite Question 🚀

---

## EXPOSE

Dockerfile:

```dockerfile
EXPOSE 80
```

इसका मतलब:

```text
Documentation Only
```

बस बताता है कि application port 80 पर सुन रही है।

कुछ open नहीं होता।

---

## Port Mapping

```bash
docker run -p 8080:80 nginx
```

अब सच में port open होगा।

---

Meaning

```text
Host Port 8080
↓
Container Port 80
```

---

Browser:

```text
http://host-ip:8080
```

↓

Container

```text
Port 80
```

---

Docker internally:

```text
iptables DNAT Rule
```

add करता है।

जिससे incoming traffic redirect होती है।

---

# Interview Summary (Must Remember)

### Docker Networking Actually Uses

* Network Namespace
* Veth Pair
* Linux Bridge
* Routing Table
* iptables
* NAT

### Bridge Network

* Default Mode
* Container ↔ Container Communication
* Linux Bridge Switch

### Host Network

* Fastest
* No Isolation
* Port Conflict Possible

### None Network

* Complete Isolation
* Only Loopback

### Overlay Network

* Multi-Host Communication
* VXLAN Encapsulation

### DNS

```text
127.0.0.11
```

Docker Internal DNS

### EXPOSE

```text
Documentation Only
```

### -p

```text
Actual Port Mapping
iptables DNAT Rule
```

# Real DevOps Engineer Perspective

जब कोई Senior DevOps Engineer Docker Networking की बात करता है, तो वह सिर्फ यह नहीं सोचता कि:

> "Container का IP क्या है?"

वह सोचता है:

```text
Packet कहाँ से निकला?
Namespace कौन सा है?
Veth Pair कौन सा है?
Bridge कौन सा है?
iptables NAT हो रहा है?
DNS Resolution कैसे हो रही है?
Packet Host से बाहर गया या नहीं?
```

अगर तुम इन concepts को समझ लेते हो, तो आगे Kubernetes Pod Networking, CNI Plugins (Calico, Flannel, Cilium), Services, Ingress, OpenShift SDN और Service Mesh समझना बहुत आसान हो जाएगा।




जैसी commands चला पाते हैं, बिना actual IP जाने। 🚀
