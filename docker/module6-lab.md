---

# 🏆 Practical Lab: Multi-Tier Microservices Network Architecture & Troubleshooting

## 📋 The Business Scenario

> **The Situation:** You are a Cloud Infrastructure Engineer for *FinCart E-Commerce*. The company is deploying a standard web architecture: a public-facing Nginx web proxy backend, a core Python API worker application, and a private PostgreSQL database.
> 
> 
> 
> 
> 
> 
> 
> 
> **The Problem:** The current setup is a major security hazard. All components are lumped onto the default network bridge. This means if a hacker exploits a vulnerability in the public Nginx web server, they can scan, connect to, and potentially download data directly from the private PostgreSQL database port, failing compliance audits.
> 
> 
> 
> 
> 
> 
> 
> 
> **The Goal:** You must design a highly secure, isolated multi-tier network. The Nginx proxy must sit on a public network tier. The database must sit on an isolated database network tier. The API worker must act as the secure bridge in the middle, talking to both tiers while keeping the database completely invisible to the web proxy.

---

## 🛠️ Interactive Sandbox Environment

To complete this lab, you do not need to install anything locally. You can use the following cloud-based interactive terminal:

👉 **[Launch Interactive Ubuntu Sandbox on Killercoda](https://killercoda.com/playgrounds/scenario/ubuntu)**

---

## 🛠️ Lab Tasks & Complete Walkthrough Solution

### Phase 1: Building the Network Topology

We will isolate our architecture into two custom user-defined bridge networks.

```
[ public-net ]                                  [ private-net ]
      |                                               |
+-----------+           +-------------+         +--------------+
|   nginx   | <-------> |   api-app   | <-----> |   postgres   |
|  (Proxy)  |           |  (Bridge)   |         |  (Database)  |
+-----------+           +-------------+         +--------------+

```

#### **Task 1.1:** Create a custom user-defined network named `public-net` for web traffic, and a second network named `private-net` for database backend isolation.

```bash
docker network create public-net
docker network create private-net

```

* **Verification:** Run `docker network ls` to verify both networks appear in your database with the `bridge` driver assigned.





#### **Task 1.2:** Deploy the secure backend database. Spin up a container named `postgres-db` using the `alpine` image, attached strictly to the `private-net`, and configure it to simulate a background database server.

```bash
docker run -d --name postgres-db --network private-net alpine sh -c "while true; do nc -lp 5432; done"

```

#### **Task 1.3:** Deploy the API application server. Spin up a container named `api-app` attached strictly to the `public-net`.

```bash
docker run -d --name api-app --network public-net alpine sh -c "while true; do sleep 3600; done"

```

#### **Task 1.4:** Deploy the public gateway web proxy. Spin up a container named `web-proxy` attached to the `public-net`, routing host port `8080` to container port `80`.

```bash
docker run -d --name web-proxy --network public-net -p 8080:80 alpine sh -c "while true; do nc -lp 80; done"

```

---

### Phase 2: Wiring the Middle-Tier Bridge & Verifying DNS

Right now, our components are locked out of communication. We must connect the API application server to the database network tier.

#### **Task 2.1:** Connect the existing running `api-app` container into the `private-net` layout.

```bash
docker network connect private-net api-app

```

#### **Task 2.2:** Verify that the `api-app` container successfully holds an architectural footprint in both networks simultaneously.

```bash
docker network inspect private-net
docker network inspect public-net

```

* **Expected Output Verification:** Inspecting both networks will reveal that `api-app` is listed in both JSON blocks, holding a unique IP address on each network (e.g., `172.18.0.X` and `172.19.0.X`).

---

### Phase 3: Testing Network Discovery & Isolation Boundaries

Now, prove that your security boundaries work perfectly using Docker's automatic service discovery.

#### **Task 3.1:** Log inside the middle-tier `api-app` container and test if it can discover and reach the database server using its container name.

```bash
docker exec -it api-app ping -c 2 postgres-db

```

* **Expected Output:** The ping succeeds! Docker's built-in DNS engine resolves the name `postgres-db` to its private IP address because both containers share the `private-net` tier.





#### **Task 3.2:** Test if the public-facing `web-proxy` container can reach or discover the database.

```bash
docker exec -it web-proxy ping -c 2 postgres-db

```

* **Expected Output:** The ping fails immediately with an error like `ping: bad address 'postgres-db'`. Because the web proxy is completely excluded from the `private-net`, it cannot resolve the DNS name or send network packets to the database. Your data tier is now fully protected!

---

### Phase 4: Network Troubleshooting Diagnostics

Simulate a production network outage investigation using core network analysis utilities.

#### **Task 4.1:** Try running a networking diagnostics utility like `ip route` or `ping` inside your containers to inspect their interfaces.

```bash
docker exec -it web-proxy ip route

```

* **The Production Trap:** You will notice that many official minimized production base images (like Alpine or Distroless) strip away core diagnostic utilities to reduce image size, leaving you with errors like `executable not found`.





#### **Task 4.2:** To debug production networks without breaking the application image, use a specialized container injection technique. Run a temporary network diagnostic container that shares the exact same network namespace as your live `web-proxy` container:

```bash
docker run -it --rm --network container:web-proxy nicolaka/netshoot ip route

```

* **Expected Output Analysis:** The `netshoot` container opens an interactive terminal showcasing the exact network interfaces, routing tables, and socket states of the `web-proxy` container, allowing you to troubleshoot the network path without modifications to your app.

---

## 🔍 Interview Conceptual Questions

### 1. Why does the default network bridge (`bridge`) fail to resolve container names via DNS, while custom user-defined networks support it automatically?

### 2. Suppose a container runs an application listening internally on port 8080. If you launch the container using the flag `-p 9000:8080`, what port must an external user type into their web browser to access the application? What port do other containers sharing the same user-defined network use to talk to it?

### 3. What is the architectural advantage of using a shared container network namespace (`--network container:<name>`) for troubleshooting production containers over installing debugging tools (like `curl`, `tcpdump`, `ping`) inside your application's production Dockerfile?

---

### Ready for the next topic?
