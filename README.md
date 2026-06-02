# dockerfiles

A collection of reusable Dockerfile patterns for common infrastructure and service setups.

## Images

### collectd
System metrics collection daemon (collectd v5.7.1) compiled from source with protobuf-c and riemann-c-client. Includes a custom `rootfs_prefix` LD_PRELOAD module for prefixing `/proc` and `/sys` paths -- useful when running collectd in a container to monitor the host.

### elasticdump
Containerized [elasticdump](https://github.com/taskrabbit/elasticsearch-dump) for backing up and restoring Elasticsearch indices.

### riemann
[Riemann](http://riemann.io/) event stream processor on a minimal busybox+java base. Includes a workaround for HTTPS downloads on busybox (compiled curl binary) and shell compatibility patches.

### statsd
[Etsy StatsD](https://github.com/statsd/statsd) v0.8.0 metrics aggregation daemon with a default UDP configuration.

### python-uv-service
Modern Python microservice base image using [uv](https://github.com/astral-sh/uv) for fast package management. Non-trivial patterns:
- **uv from ghcr.io** -- copied as a static binary, no pip install step needed
- **Non-root user** with explicit UID/GID (k8s `runAsNonRoot` compatible)
- **BuildKit cache mount** (`--mount=type=cache`) to persist pip/uv cache across builds
- **Multi-arch AWS CLI** install that auto-detects amd64 vs arm64
- **Container-tuned Python env** (`PYTHONDONTWRITEBYTECODE`, `PYTHONUNBUFFERED`)

### python-multistage-secure
Two-stage Python build focused on supply-chain security. Non-trivial patterns:
- **pip-compile --generate-hashes** locks every dependency with cryptographic checksums, protecting against tampered or typosquatted packages
- **Multi-stage build** keeps compilers (gcc, g++) out of the final image
- **HEALTHCHECK** directive for orchestrator liveness/readiness probes
- **ENTRYPOINT + CMD split** for flexible runtime overrides

### nginx-react-modules
Three-stage build that compiles nginx dynamic modules from source and bundles a React (or Next.js/Vite) frontend. Non-trivial patterns:
- **Official nginx pkg-oss build system** for compiling modules (headers-more, geoip2, etc.)
- **SHA-512 integrity check** on downloaded build scripts
- **Parameterized modules** via `ENABLED_MODULES` build arg
- **Clean final image** -- only the compiled `.so` and static assets, no build toolchain

### jenkins-cicd
Jenkins CI/CD image pre-loaded with Docker CLI, Ansible, and AWS CLI. Non-trivial patterns:
- **Docker CLI via socket mount** (not Docker-in-Docker) -- build images in pipelines by mounting `/var/run/docker.sock`
- **Setup wizard skip** for headless/automated provisioning
- **Plugin pinning** from a text file for reproducible Jenkins setups
