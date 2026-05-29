

---

# 🏆 Advanced Lab Architecture: Engineering secure Network Topologies and Core Packet Routing Verification

## 📋 The Business Scenario

> **The Situation:** You are a Senior Security DevSecOps Engineer for *FinTech Enterprise Solutions*. The company is deploying an internal banking transaction processor pipeline. The stack consists of a public API Gateway proxy, an internal Core Payment Engine application, and a sensitive Ledger Database holding financial records.
> 
> 
> 
> 
> 
> 
> 
> 
> **The Problem:** Corporate security compliance states that the Ledger Database must be physically incapable of routing packets to or from the public internet or the public API gateway tier. Furthermore, you cannot trust basic application configurations; you must verify that the underlying Linux network namespace boundaries are actively blocking packet traversal.
> 
> 
> 
> 
> 
> 
> 
> 
> **The Goal:** You must build an isolated, multi-tiered network bridge framework. The API Gateway will sit on a public tier. The Database will sit on a private tier. The Core Payment Engine will act as the protected network bridge in the middle. You will then use specialized network utilities to trace the exact path of the kernel packets to guarantee isolation.

---

## 🛠️ Interactive Sandbox Environment

To execute this production-grade verification workflow, launch the cloud sandbox terminal below:

👉 **[Launch Interactive Ubuntu Sandbox on Killercoda](https://killercoda.com/playgrounds/scenario/ubuntu)**

---

## 🛠️ Lab Tasks & Complete Walkthrough Solution

### Phase 1: Architectural Network Topology Provisioning

We will isolate our architecture into two entirely custom user-defined subnets using the `bridge` driver.

```
[ dmz-net ]  (Subnet: 10.10.10.0/24)             [ core-net ]  (Subnet: 10.20.20.0/24)
     |                                                |
+----------+            +----------------+      +------------+
| api-gw   | <--------> | payment-engine | <--->| ledger-db  |
| (Public) |            |    (Bridge)    |      | (Database) |
+----------+            +----------------+      +------------+

```

#### **Task 1.1:** Provision two explicit networks. Designate `dmz-net` with a defined subnet range of `10.10.10.0/24` and `core-net` with a subnet range of `10.20.20.0/24`.

```bash
docker network create --driver bridge --subnet 10.10.10.0/24 dmz-net
docker network create --driver bridge --subnet 10.20.20.0/24 core-net

```

#### **Task 1.2:** Deploy the isolated ledger database container named `ledger-db` straight onto the `core-net` tier using the specialized `netshoot` engine (this image comes packed with standard Linux networking binaries like `tcpdump`, `ip`, `route`, and `tshark`).

```bash
docker run -d --name ledger-db --network core-net nicolaka/netshoot sh -c "while true; do nc -lp 5432; done"

```

#### **Task 1.3:** Deploy the transactional core worker daemon container named `payment-engine` attached strictly to the `dmz-net` space.

```bash
docker run -d --name payment-engine --network dmz-net nicolaka/netshoot sh -c "while true; do sleep 3600; done"

```

#### **Task 1.4:** Deploy the public-facing API entryway container named `api-gw` attached to the `dmz-net`, mapping host port `8080` to container port `80`.

```bash
docker run -d --name api-gw --network dmz-net -p 8080:80 nicolaka/netshoot sh -c "while true; do nc -lp 80; done"

```

---

### Phase 2: Dual-NIC Bridging Realities

Right now, the `payment-engine` cannot speak to the database tier. We must bridge the gap by hot-plugging a secondary virtual Network Interface Card (NIC) into the middle container.

#### **Task 2.1:** Manually connect the running `payment-engine` container into the secure `core-net` subnet.

```bash
docker network connect core-net payment-engine

```

#### **Task 2.2:** Inspect the container network namespace interfaces from the host. Run a command inside the `payment-engine` container to view its active IP addresses.

```bash
docker exec payment-engine ip address show

```

* **Expected Output Verification:** You will notice that `payment-engine` now contains **two distinct virtual ethernet interfaces** (`eth0` and `eth1`). One interface holds an IP from the `10.10.10.0/24` subnet, and the other holds an IP from the `10.20.20.0/24` subnet. It acts as a multi-homed gateway bridging both network zones.

---

### Phase 3: Forensic Routing & Packet Sniffing Verification

Now, execute deep network verification to prove that the database layer is fully protected against external visibility.

#### **Task 3.1:** Verify that the built-in custom DNS discovery works flawlessly from the mid-tier processing container to the database.

```bash
docker exec payment-engine ping -c 2 ledger-db

```

* **Expected Output:** Packets traverse successfully over the internal virtual bridge.





#### **Task 3.2:** Execute a low-level routing path trace from the public `api-gw` to confirm it has no physical knowledge of how to reach the database namespace layer.

```bash
docker exec api-gw traceroute ledger-db

```

* **Expected Output:** The lookups fail completely with an error like `traceroute: bad address`. The public proxy container has no network card connected to the `core-net` subnet, and Docker's embedded DNS engine refuses to cross-resolve addresses across disconnected networks.





#### **Task 3.3:** Test if the database container can communicate with the outside internet. Attempt to force a routing pass from inside `ledger-db` out to a public DNS root server (`8.8.8.8`).

```bash
docker exec ledger-db ping -W 2 -c 2 8.8.8.8

```

* **The Security Trap Exploded:** In many basic setups, this ping will actually succeed because custom bridge networks default to setting the host machine as an outbound gateway route. This violates our strict corporate compliance requirement! We must fix this outbound data leak.

---

### Phase 4: Enforcing Hardened Network Isolation (Internal Networks)

To fix the security leak discovered in Task 3.3, we must recreate the core network using Docker's specialized internal isolation parameters.

#### **Task 4.1:** Purge the insecure database network tier and recreate the `core-net` using an explicit **`--internal`** structural security flag. This flag tells the host Linux kernel to completely drop any outbound NAT internet routing rules for this subnet block.

```bash
docker rm -f ledger-db
docker network rm core-net
docker network create --driver bridge --subnet 10.20.20.0/24 --internal core-net

```

#### **Task 4.2:** Re-deploy your database container and bridge your middle tier back into the new hardened network layout.

```bash
docker run -d --name ledger-db --network core-net nicolaka/netshoot sh -c "while true; do nc -lp 5432; done"
docker network connect core-net payment-engine

```

#### **Task 4.3:** Re-test outbound internet communication from inside the secure data tier.

```bash
docker exec ledger-db ping -W 2 -c 2 8.8.8.8

```

* **Expected Output Verification:** The ping now fails completely with **100% packet loss**. The Linux kernel is now actively blocking the data packets from passing out to the global internet gateway routing chain, fulfilling your compliance requirements.

---

## 🔍 Grading Key & Conceptual Answers

### 1. Explain how the Linux kernel keeps data traffic separated when two containers are deployed on the exact same physical host machine under a default configuration.

### 2. What exactly occurs inside the host's Linux networking kernel when a network is created using the `--internal` configuration parameter? How does this alter packet routing out to the public internet?

### 3. What is a multi-homed container setup? Why is this architectural layout preferred for middle-tier applications over simply running a single large network bridge across all deployment layers?
