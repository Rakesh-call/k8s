

---

# 🏆 Practical Lab: Enterprise Image Promotion, Content Verification, & Air-Gapped Migration

## 📋 The Business Scenario

> **The Situation:** You are a Lead DevOps Engineer for *SecureBank Global*. The security architecture of the company is strictly partitioned. Development happens on an internet-connected staging network, while production runs inside an isolated, highly secure **Air-Gapped Infrastructure Zone** with zero network access to the internet.
> 
> 
> 
> 
> 
> 
> 
> 
> **The Problem:** The QA team has approved a specific version of a custom web application image, but it currently exists under a mutable floating tag (`:staging`). You cannot pull this image directly inside the production zone because it has no internet connectivity. Furthermore, corporate audit compliance dictates that you must prove the image bytes were not modified during transit.
> 
> 
> 
> 
> 
> 
> 
> 
> **The Goal:** You must tag and push the image to a simulated staging repository, identify its unique immutable cryptographic hash (Digest), export it into an offline archive format, move it to the simulated air-gapped host, and restore it with absolute verification.

---

## 🛠️ Interactive Sandbox Environment

To complete this lab, you do not need to install anything locally. You can use the following cloud-based interactive terminal:

👉 **[Launch Interactive Ubuntu Sandbox on Killercoda](https://killercoda.com/playgrounds/scenario/ubuntu)**

---

## 🛠️ Lab Tasks & Complete Walkthrough Solution

### Phase 1: Image Setup & Simulating the Remote Tagging Workflow

We will use a lightweight Nginx web image to simulate our banking web application.

#### **Task 1.1:** Pull the official image `nginx:1.25.0` to your staging host cache.

```bash
docker pull nginx:1.25.0

```

* **Verification:** Run `docker images` to see `nginx` with the tag `1.25.0` listed in the local cache.





#### **Task 1.2:** Simulate corporate governance by re-tagging this image with an official internal namespace structure. Name the target image using a mock internal registry endpoint path: `internal-registry.local:5000/securebank/web-app:v1.25-staging`.

```bash
docker tag nginx:1.25.0 internal-registry.local:5000/securebank/web-app:v1.25-staging

```

#### **Task 1.3:** Display your local image list. Look closely at the **IMAGE ID** column for both `nginx:1.25.0` and your newly tagged image.

```bash
docker images

```

* **Expected Output Analysis:** You will notice that the Image ID for both rows is **identical**. This proves that running `docker tag` does not copy data or create a new file; it merely slaps an alternate text label onto the exact same underlying layers.

---

### Phase 2: Finding the Cryptographic Fingerprint (The Digest)

Before shipping the image to the production environment, the security auditor requires the cryptographic hash to cross-verify content integrity.

#### **Task 2.1:** Execute a command to find the precise, immutable SHA-256 content digest of the pulled `nginx:1.25.0` image.

```bash
docker inspect --format='{{index .RepoDigests 0}}' nginx:1.25.0

```

* **Expected Output format:** You will see a long alphanumeric string appended to the image name, such as `nginx@sha256:a63a5...`. Record this digest value for your final checkpoint report.

---

### Phase 3: Executing the Offline Air-Gapped Migration Loop

Now, simulate preparing the image for physical transfer into the secure zone on an offline storage drive.

#### **Task 3.1:** Export your custom tagged image `internal-registry.local:5000/securebank/web-app:v1.25-staging` out of the Docker engine cache and compress it into a raw tarball file named `secure-app.tar` inside your current directory.

```bash
docker save -o secure-app.tar internal-registry.local:5000/securebank/web-app:v1.25-staging

```

#### **Task 3.2:** Verify that the file was generated and inspect its size on disk to confirm it contains the full application layers.

```bash
ls -lh secure-app.tar

```

* **Expected Output:** You should see a file named `secure-app.tar` that is approximately 140MB+ in size, indicating it contains the complete base web environment.





#### **Task 3.3:** To simulate moving into the isolated air-gapped production host, completely purge the image from your local Docker daemon cache to guarantee it cannot be found anywhere in memory.

```bash
docker rmi internal-registry.local:5000/securebank/web-app:v1.25-staging
docker rmi nginx:1.25.0

```

* **Verification:** Run `docker images`. The local image cache should be entirely blank.

#### **Task 3.4:** Now, perform the secure import step. Restore the application image into your Docker engine cache using the offline `secure-app.tar` file.

```bash
docker load -i secure-app.tar

```

* **Expected Output:** The terminal logs the progressive extraction of the file layers, ending with the statement `Loaded image: internal-registry.local:5000/securebank/web-app:v1.25-staging`.

---

### Phase 4: Production Re-Tagging & Content Verification

Now that the image is inside the production zone cache, we must align it with production naming rules and verify it wasn't corrupted or altered.

#### **Task 4.1:** Re-tag the loaded image to its final production tag destination: `production-registry.local/securebank/web-app:v1.25-release`.

```bash
docker tag internal-registry.local:5000/securebank/web-app:v1.25-staging production-registry.local/securebank/web-app:v1.25-release

```

#### **Task 4.2:** Spin up a background production container named `prod-web` using the production release tag.

```bash
docker run -d --name prod-web production-registry.local/securebank/web-app:v1.25-release

```

#### **Task 4.3:** Verify the container is running and stream its HTTP headers to prove the container is functional.

```bash
docker ps
docker exec prod-web nginx -v

```

* **Expected Output:** The system confirms the container status is active and prints the operational web server version string (`nginx version: nginx/1.25.0`).

---

## 🔍 Interview Asking concepts questions

### 1. What is the fundamental difference between an Image Tag and an Image Digest? Why do production cloud environments prioritize deployment via Digests over Tags?

### 2. When you checked the Image ID of `nginx:1.25.0` and your custom tagged image in Phase 1, what did you observe? Explain the underlying mechanism of how Docker references multiple tags on a single host.

### 3. In Phase 3, if you had created a text file inside an active container instance of Nginx *before* executing `docker save`, would that text file be preserved inside the `secure-app.tar` file? Explain based on your knowledge of container layers.

---

### Ready for the next module?

