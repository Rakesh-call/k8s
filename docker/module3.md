
---

# Module 3: Docker Images, Containers, & Lifecycle Management

This documentation covers how Docker handles data and applications under the hood, detailing the structural anatomy of image layers, standard lifecycle transitions, container runtime states, and data volatility.

---

## 1. Core Mechanics: Images vs. Containers

To master Docker, you must understand the explicit architectural relationship between an Image and a Container.

* **Docker Image:** A read-only, immutable template containing the application code, runtime environment, libraries, environment variables, and configuration files. It is stored on disk and cannot be modified once built. Think of it as the **Source Code/Blueprint**.
* **Docker Container:** A lightweight, runnable instance of a Docker Image. It instantiates the image into memory, adding an isolated process environment and a thin writeable storage layer on top. Think of it as the **Running Process**.

### Understanding Docker Layers & The Storage Driver

Docker images are built as a stack of distinct, read-only layers. Each layer represents an instruction in the image configuration (e.g., installing a package, copying source code).

```
+-----------------------------------+
|    Container Layer (Read/Write)   |  <-- Temporary layer added when container starts
+-----------------------------------+
|     Layer 3: App Code (Read-Only) |  \
+-----------------------------------+   \
|     Layer 2: Python (Read-Only)   |    >-- Shared Image Layers (Immutable)
+-----------------------------------+   /
|     Layer 1: Ubuntu (Read-Only)   |  /
+-----------------------------------+

```

When you instantiate a container from an image, the Docker Engine uses a **Storage Driver** (such as `overlay2`) to stack the immutable layers and place a thin **Read/Write Layer** (also known as the *Container Layer*) directly on top.

* All changes made to the running container—such as writing new files, modifying system configurations, or deleting data—are isolated entirely within this thin read/write layer.
* If multiple containers are spun up from the exact same image, they all safely share the underlying read-only image layers while maintaining their own unique, independent read/write layers. This layout maximizes storage efficiency.

---

## 2. The Docker Image Lifecycle

The journey of an image moves systematically across registries, local caches, and active runtime deployments:

```
[ Developer Local ]                 [ Remote Registry (Docker Hub) ]
       |                                           |
       | ------- (1) docker pull ----------------> | (Downloads image metadata & layers)
       |                                           |
       | <------ (2) Cached on Disk <-------------+ 
       |
       | ------- (3) docker run -----------------> [ Instantiates Container Process ]

```

1. **Pull:** The user requests an image. Docker Daemon checks the local host cache. If missing, it connects to a remote container registry (like Docker Hub) and downloads the compressed cryptographic layers.
2. **Store:** Layers are decompressed and safely cached in the host's internal storage directory (`/var/lib/docker/`).
3. **Execute:** The engine grabs the local layers, slaps on the read/write runtime layer, and starts the core execution process.

---

## 3. Container Runtime Configurations: Interactive vs. Detached

When initiating a containerized application, you must explicitly define how its standard Input/Output channels connect back to your system terminal.

### Interactive Mode (`-it`)

* **Flags:** `-i` (interactive, keeps STDIN open) and `-t` (allocates a pseudo-TTY/virtual terminal).
* **Behavior:** Connects your personal terminal shell directly inside the container process environment.
* **Primary Use Case:** Troubleshooting, running internal bash commands, or manual debugging.
* **Example:** `docker run -it ubuntu bash`

### Detached Mode (`-d`)

* **Flag:** `-d`
* **Behavior:** Runs the container in the background as an independent system daemon process. It starts up, yields control immediately back to your host terminal, and prints the long unique Container ID.
* **Primary Use Case:** Production servers, web applications, databases, and background API services.
* **Example:** `docker run -d nginx`

---

## 4. Container Lifecycle Management

A container transitions through distinct operational states during its lifespan. Managing these states efficiently is central to DevOps operations.

```
       +------------------ docker run / create -----------------+
       |                                                        |
       v                                                        |
  [ Created ] ---> docker start ---> [ Running ]                |
                                        |   ^                   |
                                        |   |                   |
                                   stop |   | start             |
                                        v   |                   |
                                     [ Stopped ] <--------------+
                                        |
                                        v
                                    docker rm
                                        |
                                        v
                                   [ Destroyed ]

```

### State Transitions & Associated Core Commands:

* **Created:** The container file system wrapper has been generated based on the image layers, but the primary process command has not yet executed.
* *Command:* `docker create <image>`


* **Running:** The primary process (PID 1) is active and executing within its isolated system namespaces.
* *Command:* `docker start <container_id>`


* **Stopped:** The primary process has been safely halted or exited. The container's internal read/write filesystem state is fully preserved on host storage, but it consumes zero CPU or RAM allocations.
* *Command:* `docker stop <container_id>` (Sends a graceful `SIGTERM` signal, followed by a forceful `SIGKILL` if it fails to shut down within 10 seconds).
* *Command:* `docker kill <container_id>` (Bypasses safety protocols and terminates the process instantly with a raw `SIGKILL`).


* **Restarting:** Forces the active primary process to cycle completely down and re-execute clean.
* *Command:* `docker restart <container_id>`


* **Destroyed:** The storage footprint, configuration profiles, and thin read/write layers are completely wiped off the host disk. You cannot remove a container while its state is actively set to "Running".
* *Command:* `docker rm <container_id>`



---

## 5. Docker Restart Policies

When a container's primary process crashes or the host operating system reboots unexpectedly, Docker relies on defined **Restart Policies** to automate recovery without manual human intervention.

You configure these by appending the `--restart` flag during creation:

| Policy | Behavior Description | Typical Production Use Case |
| --- | --- | --- |
| `no` | The default configuration. Do not automatically restart the container under any circumstance. | Local ad-hoc scripts, manual batch jobs, debugging sessions. |
| `on-failure[:max-retries]` | Restarts the container *only* if the primary process exits with a non-zero error code. Can limit retry loops. | Data migration tasks, transient background data workers. |
| `always` | Always restarts the container if it stops. If the host machine reboots, the daemon automatically restarts this container immediately. | Critical web servers, monitoring agents, reverse proxies. |
| `unless-stopped` | Always restarts the container *unless* it was explicitly stopped by an administrative user command prior to the reboot event. | Core databases or APIs where manual administrative control must be respected. |

---

## 6. Understanding Ephemeral Containers

The defining philosophy of cloud-native architecture is that **Containers are Ephemeral (Stateless / Disposable)**.

* **The Principle:** A container should be treated like cattle, not a pet. It should be easily stopped, destroyed, and replaced with an entirely new instance without requiring any reconfiguration or data recovery workflows.
* **The Core Trap:** Because all data created *during* runtime is written directly into that thin, temporary container read/write layer, **all of that data is instantly lost forever when the container is deleted (`docker rm`)**.
* **The Solution:** Persistent states, business-critical file records, transaction metrics, and production logs must never be saved inside a standard container layer. Instead, they must be safely externalized onto host storage via **Docker Volumes** or **Bind Mounts** (covered in depth in upcoming storage modules).

---

## 7. Command Reference Table

| Objective | Command Syntax |
| --- | --- |
| Fetch an image from registry to host cache | `docker pull <image_name>:<tag>` |
| List all locally cached images | `docker images` |
| Instantiate and execute a background container | `docker run -d --name <custom_name> <image>` |
| View currently active running containers | `docker ps` |
| View all containers on host (Running & Stopped) | `docker ps -a` |
| Stream realtime stdout/stderr console logs | `docker logs -f <container_id>` |
| Delete a cached image from host disk | `docker rmi <image_id>` |
| Wipe out all stopped containers, unused networks, and dangling build caches | `docker system prune -f` |

---

## 💡 Core Takeaways (Cheatsheet for Interviews)

* **Images are Read-Only; Containers are Read/Write.** The storage driver (`overlay2`) seamlessly layers them together at runtime.
* If you create a text file inside a container and run `docker rm`, **that data is gone forever** due to the ephemeral nature of the container layer.
* `docker stop` uses graceful termination (`SIGTERM`), while `docker kill` cuts power instantly (`SIGKILL`).
* The `always` restart policy spins a container up even if an administrator intentionally stopped it before a Docker daemon reboot; `unless-stopped` respects the manual stop action.

---

### Ready for the Combined Practical Assignment?
