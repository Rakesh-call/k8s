
---

# 🏆 Practical Lab: The Automated Self-Healing Web App & Disaster Recovery Simulation

## 📋 The Business Scenario

> **The Situation:** You are the on-call DevOps Engineer for *FinTech FastPay*. The company runs a critical microservice that processes payment notifications as a background daemon process.
> 
> 
> 
> 
> 
> 
> 
> 
> **The Problem:** The application has a known memory leak that causes it to crash unexpectedly every few hours, killing the primary process. To make matters worse, the underlying cloud host server undergoes automated patch reboots at midnight. If the application crashes or the server reboots, payments fail, costing the company thousands of dollars per minute.
> 
> 
> 
> 
> 
> 
> 
> 
> **The Goal:** You need to deploy this application using a specific Docker container runtime configuration that guarantees high availability (self-healing). You must also prove that you can inspect the container's logs, extract data from its layers before it vanishes, and ensure it survives a full system failure.

---

## 🛠️ Interactive Sandbox Environment

To complete this lab, you do not need to install anything locally. You can use the following cloud-based interactive terminal:

👉 **[Launch Interactive Ubuntu Sandbox on Killercoda](https://killercoda.com/playgrounds/scenario/ubuntu)**

---

## 🛠️ Lab Tasks & Complete Walkthrough Solution

### Phase 1: Background Deployment & Interactive Testing

Before leaving the application to run in the background, you must verify its internal file structure using an interactive session.

#### **Task 1.1:** Pull the official lightweight `alpine:latest` image from Docker Hub to your local cache.

```bash
docker pull alpine:latest

```

* **Verification:** Running `docker images` shows `alpine` with the tag `latest`.





#### **Task 1.2 & 1.3:** Spin up a temporary **Interactive Container** using that image, overriding its default command to open a shell (`sh`). Inside the container shell, navigate to the `/etc` directory, view the contents of the `os-release` file to confirm it's Alpine, and then type `exit` to terminate and destroy the session.

```bash
docker run -it alpine sh

```

*Inside the container terminal prompt (`/ #`), execute:*

```bash
cat /etc/os-release
exit

```

* **Expected Output:** The system prints text containing `NAME="Alpine Linux"` and `ID=alpine`. Typing `exit` kills the container process and returns you to your host terminal.





#### **Task 1.4:** Now, deploy the actual payment processor simulation in **Detached Mode**. Name the container `payment-processor`, configure it to **always restart** automatically, and pass a shell script command that simulates a background worker writing timestamps to a log file every second:

```bash
docker run -d --name payment-processor --restart always alpine sh -c "mkdir /app; while true; do echo 'Processing payment at \$(date)' >> /app/payment.log; sleep 1; done"

```

* **Verification:** The terminal prints a long, unique 64-character alphanumeric string (the Container ID).





#### **Task 1.5:** Run a command to list only the *actively running* containers to verify that your background daemon is up and processing.

```bash
docker ps

```

* **Expected Output:** The `payment-processor` container is visible in the list, with a status showing `Up X seconds`.

---

### Phase 2: Live Log Tailing & Forensic Layer Investigation

The manager wants to see the transactions processing in real-time.

#### **Task 2.1:** Use the native Docker logging command to stream (tail) the container's standard output live to your screen. Watch it process for 5 seconds, then safely detach from the stream without stopping the container.

```bash
docker logs -f payment-processor

```

* **Expected Output:** The terminal constantly streams output text like:
```text
Processing payment at Thu May 28 20:22:01 UTC 2026
Processing payment at Thu May 28 20:22:02 UTC 2026

```



```
* **Action Required:** Press `Ctrl + C` to stop viewing the stream. (The container continues running safely in the background).
<br>

#### **Task 2.2:** Because the log file `/app/payment.log` is hidden deep inside the container's thin, writable layer, you need to extract a copy of it to your host machine's desktop for the finance audit team *without* stopping or logging into the container shell. Use the `docker cp` command to copy `/app/payment.log` from the running container straight to your host storage.
```bash
docker cp payment-processor:/app/payment.log ./Desktop/payment.log

```

* **Verification:** A file named `payment.log` appears on the host machine's desktop containing the timestamped lines.

---

### Phase 3: Simulating a Core Application Crash

Now, test the self-healing capability by manually killing the application's primary process.

#### **Task 3.1:** Execute a command that sends a forceful kill signal to the container's primary running process (PID 1) from the outside, or simulate a catastrophic failure by forcing it to stop instantly (`docker kill`).

```bash
docker kill payment-processor

```

#### **Task 3.2:** Immediately run `docker ps`. Look closely at the **STATUS** column. Document how Docker reacts when an `always` restart policy encounters a dead process.

```bash
docker ps

```

* **Expected Output:** The status column will state something like: `Up Less than a second (Restarting)` or `Up 2 seconds`. This proves the `--restart always` policy detected the sudden termination and instantly launched a fresh process instance.





#### **Task 3.3:** Inspect the container's metadata using `docker inspect` and locate the specific JSON block that tracks the container's internal state metrics (`State`). Find the count that shows how many times the container has restarted.

```bash
docker inspect --format='{{.State.RestartCount}}' payment-processor

```

* **Expected Output:** An integer value of `1` (or higher, depending on how long it has been running), showing that the engine tracked the crash event and auto-healed.

---

### Phase 4: Simulating a Total Host Failure (The Ephemeral Trap)

This phase proves the disposable, volatile nature of container storage.

#### **Task 4.1 & 4.2:** Simulate a physical server crash or a Docker engine crash by restarting your host machine, or by restarting the Docker daemon service directly. Once the service comes back online, run `docker ps` to verify the state.

```bash
sudo systemctl restart docker
docker ps

```

* **Expected Output:** The container `payment-processor` is immediately visible in `docker ps`. Because it was configured with `--restart always`, the Docker daemon automatically booted the container back up into memory the moment the service initialized.





#### **Task 4.3:** Now, simulate a software upgrade deployment where you must delete the old container. Force-stop and completely remove (`docker rm`) the `payment-processor` container.

```bash
docker rm -f payment-processor

```

* **Verification:** Running `docker ps -a` confirms the container is completely deleted from the system configuration.





#### **Task 4.4 & 4.5:** Spin up a brand new container using the exact same command from Task 1.4, naming it `payment-processor` again. Try to view or copy the file `/app/payment.log` from this new container.

```bash
docker run -d --name payment-processor --restart always alpine sh -c "mkdir /app; while true; do echo 'Processing payment at \$(date)' >> /app/payment.log; sleep 1; done"

docker exec payment-processor cat /app/payment.log

```

* **Expected Output:** The file exists, but it **only contains new timestamps** starting from the exact second the *new* container was created. All historical transaction entries from the previous container are gone.

---
