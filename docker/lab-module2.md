
---

# 🏆 Advanced Lab Architecture: The Enterprise Remote Ops Challenge

## 📋 The Business Scenario (Why this is critical)

> **The Situation:** You have just joined *GlobalOps Logistics* as a DevOps Engineer. The company has a centralized, highly secure **Core Infrastructure Server** running on Linux in a private data center. This server hosts all production application environments.

> **The Problem:** The deployment team works on different machines (some use Linux workstations, others use Windows laptops). If developers SSH directly into the core server to run Docker commands, they risk accidentally altering system configurations, seeing sensitive production keys, or crashing the host.

> **The Goal:** To secure the infrastructure, your team lead has tasked you with setting up a **Secure Distributed Docker Architecture**. Developers must use their *local* Docker Clients (on Windows or Linux) to securely build, deploy, and manage containers running *remotely* on the central Linux server, without ever opening an SSH terminal session on that server.

> **Why this matters to learn:** In the enterprise world, you almost *never* run production containers on your local machine. Understanding how the `docker` client communicates across networks to a remote `dockerd` daemon is fundamental to setting up modern CI/CD runners (like GitLab runners or GitHub Actions self-hosted agents) and secure cloud infrastructure.

---

## 🛠️ The Assignment: Multi-Client Remote Engine Setup

### Objective

Configure a central Linux machine as a dedicated **Docker Engine Host** and securely connect two separate external clients (a Local Linux Client and a Windows Client) to manage it remotely.

```
                  +----------------------------------+
                  |     Central Linux Server         |
                  |  (Runs Docker Daemon: dockerd)   |
                  +----------------------------------+
                                   ^
                                   | (Listens on TCP Port 2375)
                +------------------+------------------+
                |                                     |
+-------------------------------+     +-------------------------------+
|     External Client #1        |     |     External Client #2        |
| (Local Linux Engine/Terminal) |     | (Windows Host via WSL2/PS)   |
|     `docker -H tcp://...`     |     |     `docker -H tcp://...`     |
+-------------------------------+     +-------------------------------+

```

---

### Phase 1: Configuring the Central Engine (The Server Side)

By default, the Docker Daemon only listens to a local Unix socket (`/var/run/docker.sock`). You must configure it to listen to network requests.

* **Task 1.1:** Log into your primary Linux server and modify the Docker service configuration. Create or edit the systemd override file for Docker:
```bash
sudo systemctl edit docker.service

```


* **Task 1.2:** Configure the daemon to listen on both the default local socket and a specific TCP network port (**Port 2375**) by adding the following configuration lines:
```ini
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375

```


* **Task 1.3:** Apply the changes by reloading the systemd manager configuration and restarting the Docker daemon service.
* **Task 1.4:** Run a network utility command (like `netstat` or `ss`) on the server to verify that `dockerd` is actively listening on port 2375 across all interfaces (`0.0.0.0`).

---

### Phase 2: Remote Control via External Linux Client

Now, simulate a developer working from a separate Linux machine.

* **Task 2.1:** On a separate Linux machine (or a separate terminal environment/VM), install *only* the `docker-ce-cli` package (do not start a local Docker daemon service).
* **Task 2.2:** Execute a command using the standard client, but append the host flag (`-H`) pointing directly to your central server's IP address and port 2375 (e.g., `docker -H tcp://<SERVER_IP>:2375 info`). Verify that the information printed matches the central server, not your local machine.
* **Task 2.3:** To avoid typing the `-H` flag with every single command, set up a local environment variable named `DOCKER_HOST` in your current terminal session pointing to the remote server.
* **Task 2.4:** Run `docker run -d --name remote-web nginx` from this client. Verify that the Nginx container is created and actively running on the *central server*, not the client machine.

---

### Phase 3: Cross-Platform Control via Windows (WSL 2 / PowerShell)

Now, simulate a developer working on a Windows laptop.

* **Task 3.1:** Open Windows PowerShell or a WSL 2 terminal window. Ensure Docker Desktop is installed.
* **Task 3.2:** Instead of modifying your default Docker environment, use the **Docker Context** feature. Create a new context named `production-server` that targets your remote central Linux engine:
```powershell
docker context create production-server --description "Remote Linux Server" --docker "host=tcp://<SERVER_IP>:2375"

```


* **Task 3.3:** Switch your active client context to use the newly created profile:
```powershell
docker context use production-server

```


* **Task 3.4:** Execute `docker ps`. You should see the `remote-web` Nginx container created by the Linux client in Phase 2.
* **Task 3.5:** From Windows, stop and delete that container using standard `docker stop` and `docker rm` commands. Check the central server to confirm it has been successfully removed.

---

## 🔍 Validation & Verification Checkpoints

To consider this assignment complete, the candidate must document the following items in their GitHub submission:

1. **The Architecture Proof:** Execute `docker info` from both the Windows client and the external Linux client, and show that both outputs display the exact same **Server Version**, **Total Memory**, and **Operating System** of the central Linux engine.
2. **The Isolation Check:** Run a native command on the client machine to prove that no local containers are running, while showing that the client's `docker` CLI can see the remote tasks.

> ⚠️ **Production Security Note (Bonus Question for Candidates):** > Opening Port 2375 unencrypted over the public internet exposes the entire host system to root-level exploits, because anyone can send a `docker run` command to it. In a real corporate network, what protocol or mechanism should you configure alongside the TCP socket to ensure only authorized clients can talk to the daemon? *(Expected answer: TLS authentication with client certificates, or tunneling traffic via SSH).*

---

### Ready for the next module?
