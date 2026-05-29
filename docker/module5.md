# Module 5: Dockerfile and Custom Image Creation

This documentation covers how to write, optimize, secure, and build enterprise-grade Docker images from scratch. It explains the core mechanics of Dockerfile instructions, build cache caching behaviors, image size minimization, and advanced compilation patterns like multi-stage builds.

---

## 1. Introduction to Dockerfile

A **Dockerfile** is a text-based configuration script containing a sequential list of commands and arguments that the Docker Engine executes to build a custom Docker image automatically.




To understand Dockerfiles in the real world, think of them as an **automated recipe** or a "Configuration as Code" script. Instead of manually launching a container, installing packages, configuring files, and committing the state, you write a Dockerfile. The Docker client passes this file to the Docker Daemon via the `docker build` command, and the daemon builds each step into an unchangeable, reusable image layer.

---

<br>

```
                       +-----------------------------------+
                       |    DOCKERFILE INSTRUCTIONS MAP    |
                       +-----------------------------------+
                                         |
         +-------------------------------+-------------------------------+
         |                                                               |
         v                                                               v
+----------------------------------+                            +----------------------------------+
|      IMAGE BUILD PHASE           |                            |     CONTAINER RUNNING PHASE      |
|  (Executes once to create layer) |                            |  (Executes every time container) |
+----------------------------------+                            +----------------------------------+
         |                                                               |
         |---> FROM                                                      |---> CMD
         |     - Pulls base blueprint.                                   |     - Sets default arguments.
         |     - Becomes foundation layer.                               |     - Easily overwritten at runtime.
         |                                                               |
         |---> RUN                                                       |---> ENTRYPOINT
         |     - Executes compilation/installs.                          |     - Sets unchangeable executable.
         |     - Commits permanent layer to disk.                        |     - Treats container like a binary.
         |                                                               |
         |---> COPY / ADD                                                |---> EXPOSE
         |     - Ingests files from host disk.                           |     - Documents runtime network port.
         |     - ADD decompresses tars / URLs.                           |     - Requires '-p' flag to activate.
         |                                                               |
         |---> WORKDIR                                                   |---> HEALTHCHECK
         |     - Creates build directory wrapper.                        |     - Periodically tests process life.
         |     - Persists as execution target.                           |     - Changes state to (healthy).
         |                                                               |
         |---> ENV (Persisted State)                                     |---> USER
         |     - Injects build-time properties.  ====================>   |     - Drops root admin privileges.
         |                                                               |     - Implements runtime security.
         +---------------------------------------------------------------+

```

---

<br>
---


---

## 🏗️ Phase 1: The Image Build Phase

These instructions run **only once** (when you type `docker build`). Their job is to download software, copy files, and bake them permanently onto your hard drive as a read-only blueprint (the Image).

* **`FROM` (The Foundation):** This is always step one. It chooses your starting point, like a clean, blank slate of Linux (e.g., Ubuntu or Alpine).




* **`RUN` (The Installer):** This runs installation commands. If you need Python, Git, or updates, `RUN apt-get install` bakes them directly into the image. Once the build finishes, `RUN` never executes again.




* **`COPY` & `ADD` (The Shippers):** These take files (like your source code or configuration files) from your personal laptop and paste them inside the image template.




* **`WORKDIR` (The Anchor):** This sets the default folder inside the image where all your files will live. It stops you from getting lost in a mess of different folders.

---

## 🏃 Phase 2: The Container Running Phase

These instructions do **nothing** during the build phase. They are just written down like rules in a manual. They wake up only when you type `docker run` to turn your static image into a living, breathing application process in your computer's memory.

* **`ENTRYPOINT` & `CMD` (The Ignition System):** These define the exact command that starts up your application when the container turns on.
* `ENTRYPOINT` is the main software you want to run (e.g., `python`).
* `CMD` provides the default arguments for that software (e.g., `server.js`). You can easily change or override `CMD` from your computer's terminal when you boot the container.






* **`EXPOSE` (The Map):** This is just text documentation. It tells developers, "Hey, this app inside the container is listening for internet traffic on Port 3000." It doesn't actually open the port; you still have to open it yourself using the `-p` flag at runtime.




* **`USER` (The Security Guard):** By default, containers run as `root` (the supreme administrator). `USER` forces the container to run as a restricted, normal user profile so an external hacker can't take over your entire system if they find a loophole in your application.




* **`HEALTHCHECK` (The Heart Monitor):** Once your container is running, this instruction loops in the background every few seconds to ask the application, "Are you working properly?" If the application freezes, it alerts Docker so the system can restart it automatically.

---

## 🌉 The Bridge Instruction

* **`ENV` (Environment Variables):** This instruction works in **both phases**. You use it to define settings (like `DB_URL=my-database-link`).
* During the **Build Phase**, your compilers can look at this setting to build the app.
* During the **Running Phase**, your active application reads it from memory to know where to connect.



---


---

## 2. In-Depth Instruction Reference

Every line in a Dockerfile begins with an **Instruction** (written in UPPERCASE by convention), followed by its specific arguments.

### FROM

* **Purpose:** Sets the **Base Image** (Parent Image) upon which your customization will be built. Every valid Dockerfile must start with a `FROM` instruction.
* **Real-World Rule:** Always use specific version tags for your base image (e.g., `FROM node:20.11.0`) to avoid tracking a moving target like `:latest`.

### RUN

* **Purpose:** Executes a shell command *during the build phase* of the image. It is used to install software packages, create directories, or configure system settings.
* **Behavior:** Every single `RUN` instruction creates a permanent, read-only layer in the final image.

### CMD vs. ENTRYPOINT

This is one of the most heavily tested concepts in container orchestration. Both instructions define the command that executes when the container *starts running*, but they behave differently:

* **`CMD` (Default Arguments):** Sets a default command or default parameters that can be easily overwritten from the terminal at runtime.
* **`ENTRYPOINT` (The Executable):** Configures the container to run as an unchangeable executable. It forces a specific command to run, and any arguments passed at runtime are appended to it.

#### The Real-World Pattern: Combining Both

In enterprise environments, you combine them using the **Exec Form** (using JSON array syntax `["item1", "item2"]`). `ENTRYPOINT` defines the core executable, and `CMD` supplies the default, overridable flags:

```dockerfile
ENTRYPOINT ["python", "app.py"]
CMD ["--port", "8080"]

```

* If you run `docker run my-image`, it executes: `python app.py --port 8080`.
* If you run `docker run my-image --port 9000`, the `CMD` is overwritten, executing: `python app.py --port 9000`.

### COPY vs. ADD

Both instructions copy files from your host development machine into the container's file system, but they have distinct capabilities:

* **`COPY` (Recommended):** A straightforward, safe utility that copies local files or folders from your host directory directly into the container layer.
* **`ADD` (Advanced Features):** Has two extra features: it can fetch files from remote URLs, and it automatically extracts/decompresses local compressed archives (like `.tar.gz`, `.zip`) directly into the destination folder.
* **Real-World Rule:** Use `COPY` for 99% of tasks to avoid accidentally downloading insecure files or unpacking archives unexpectedly.

### ENV

* **Purpose:** Sets environment variables that persist both *during the build phase* and *inside the running container*.
* **Example:** `ENV NODE_ENV=production` allows your application code to read that state and optimize its internal performance automatically.

### EXPOSE

* **Purpose:** Acts as a piece of internal documentation. It informs the user or orchestration system which network port the application process listens on inside the container.
* **Real-World Trap:** `EXPOSE 80` **does not** open or publish the port to your host machine network. You must still use the `-p` or `-P` flag during `docker run` to bridge that port out to the physical world.

### WORKDIR

* **Purpose:** Sets the active working directory for any subsequent `RUN`, `CMD`, `ENTRYPOINT`, `COPY`, or `ADD` instructions that follow it.
* **Behavior:** If the specified directory does not exist, Docker creates it automatically. Never use `RUN cd /app` because directory changes do not persist across separate layers. Use `WORKDIR /app` instead.

### USER

* **Purpose:** Changes the active operating system user ID (UID) used to run any subsequent instructions and, crucially, the final container process.
* **Security Rule:** By default, Docker containers run as the Linux `root` (administrator) user. If an attacker exploits a code vulnerability inside your app, they instantly gain root control over the container. Always create a dedicated non-privileged user and switch to it using `USER`.

### HEALTHCHECK

* **Purpose:** Tells Docker how to test the container process periodically to ensure it is still alive and responding to actual traffic, not just sitting in a frozen, deadlocked state.
* **Example:**

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1

```

* **Behavior:** Changes the container status in `docker ps` from a generic `Up 2 hours` to `Up 2 hours (healthy)`.

---

## 3. Understanding the Docker Build Cache & Layer Optimization

When you run `docker build`, the Docker Engine steps through your Dockerfile from top to bottom. For each instruction, it checks if it has already executed that exact step in a previous build. If it has, it reuses the cached layer, speeding up subsequent builds dramatically.

### The Cache-Bust Chain Reaction

If an instruction's parameters change, or if a copied file has been modified since the last build, **that layer's cache is invalidated (busted)**. Crucially, once a single layer is busted, **every single cache layer that follows it in the Dockerfile is completely destroyed** and must be recompiled from scratch.

#### Bad Practice (Destroying the Cache Loop)

```dockerfile
FROM node:20
WORKDIR /app
COPY . .
RUN npm install

```

* **Why this is bad:** If you change a single line of your application code (e.g., editing a line of text in an HTML file), the `COPY . .` layer caches break. As a result, Docker is forced to run the heavy, time-consuming `RUN npm install` command again, even though your external dependencies didn't change.

#### Enterprise Practice (Leveraging Layer Order)

```dockerfile
FROM node:20
WORKDIR /app
# Copy ONLY dependency manifests first
COPY package*.json ./
# Install dependencies (This layer stays cached unless packages change)
RUN npm install
# Copy the volatile source code last
COPY . .

```

* **Why this is efficient:** Now, editing your application source code only breaks the final `COPY . .` layer. The dependencies remain safely cached, dropping build times from minutes down to seconds.

---

## 4. Multi-Stage Docker Builds

A standard Dockerfile includes development tools, compiler binaries, package managers, and testing utilities. However, these tools are completely useless once the application is compiled and running in production—they merely bloat your image size and expand your security vulnerability footprint.

**Multi-Stage Builds** solve this problem by allowing you to use multiple `FROM` statements in a single Dockerfile. Each `FROM` block represents a completely distinct, isolated **Stage**. You can build your app in a heavy environment, and then copy *only* the compiled assets into a tiny, bare-minimum production stage.

```dockerfile
# Stage 1: The Build Environment
FROM golang:1.22 AS builder
WORKDIR /src
COPY . .
RUN go build -o mybinary main.go

# Stage 2: The Tiny Production Runtime
FROM alpine:3.19
WORKDIR /app
# Copy the compiled binary from the builder stage
COPY --from=builder /src/mybinary .
CMD ["./mybinary"]

```

* **The Result:** The heavy Go compiler image (approx. 800MB) is completely thrown away at the end of the build. The final production image only contains Alpine and your compiled binary (approx. 20MB).

---

## 5. Shrinking Production Images: Alpine vs. Distroless

To optimize network distribution and clear security audits, production images must be kept as small as possible.

### Using Alpine Base Images

Alpine Linux is a security-oriented, lightweight Linux distribution based on `musl libc` and `busybox`.

* **The Advantage:** A raw Alpine base image is only **5MB** in size compared to an Ubuntu base image which sits around 75MB+.
* **The Caveat:** Because it uses `musl libc` instead of the traditional Linux `glibc`, certain Python, C++, or Node compiled libraries may throw compilation errors unless specific build-essential packages are explicitly installed.

Mindmap of (g libc & musl libc)

<div align="center">

```text
Application

      |
      v
Language Runtime
(Python/Node/Java/etc)
      |
      v
libc
(glibc or musl)

      |
      v
Linux Kernel
      |
      v
CPU + Memory + Disk
```

</div>


### Using Distroless Images

Distroless images, created by Google, take optimization to the extreme. They contain **only your application and its runtime dependencies**.

* **The Setup:** They do not contain a package manager (no `apt` or `apk`), system shells (no `bash` or `sh`), or core operating system utilities.
* **The Advantage:** If an attacker breaks into a container running a distroless image, they cannot run commands, download scripts, or pivot through your network because **there is no shell to execute commands**. This drops your image footprint down to the absolute bare minimum.

<br>
## Which image should I use?

<div align="center">

```text
Ubuntu  -> Development & Debugging

Alpine  -> Lightweight Production
           when shell access may be needed

Distroless -> Security-focused Production
              where only the application should run


---------------------------------------------------------------------------------


                 Development                Production
                       |                         |
                       v                         v

      Ubuntu/Debian  ──►  Alpine  ──►  Distroless
      (easy debug)       (small)       (smallest & most secure)

      bash, apt          sh, apk       no shell, no package manager
      curl, wget         lightweight   only app + runtime files

```

---

The Core Idea

Build with a large image that contains all development tools, then run with the smallest image possible that contains only what the application needs to execute. Alpine is often chosen for lightweight operations, while Distroless is chosen for maximum security and minimal footprint in production.

---

</div>

---

## 6. The Essential `.dockerignore` File

When you execute `docker build .`, the first message printed in your terminal is `"Sending build context to Docker daemon"`. This means the client copies **every file** in your local folder up to the daemon process.

If your local folder contains huge folders like `node_modules/`, `.git/`, compilation logs, or sensitive local API keys, your builds will become incredibly slow and insecure.

### The Solution

Create a file named `.dockerignore` in your root directory. It works exactly like a `.gitignore` file, forcing Docker to ignore specified paths entirely during development builds:

```text
.git
node_modules
npm-debug.log
Dockerfile
.env

```

---

## 7. Command Reference Table

| Objective | Command Syntax |
| --- | --- |
| Compile a custom Dockerfile into a local image | `docker build -t <repository_name>:<tag> .` |
| Force a build without using any historical cache layers | `docker build --no-cache -t <name> .` |
| Inspect the layer history and sizes of an image | `docker history <image_id_or_name>` |
| Pass dynamic build variables into a Dockerfile at build-time | `docker build --build-arg <VAR>=<VALUE> -t <name> .` |

---

e: Volumes & Bind Mounts**, **Docker Networking**, or **Docker Compose**) and we will generate the next complete learning guide and master lab!
