# dockerfiles

A collection of reusable Dockerfile patterns for common infrastructure and service setups.

## Images

### collectd
System metrics collection daemon (collectd v5.7.1) compiled from source. Non-trivial patterns:
- **Source builds of the full dependency chain** -- protobuf-c and riemann-c-client compiled from upstream tarballs before collectd itself
- **Custom `rootfs_prefix` LD_PRELOAD module** prefixes `/proc` and `/sys` paths -- lets containerized collectd monitor the host filesystem
- **Pinned apt versions** for every build dependency for reproducible builds
- **Build-toolchain purge** removes `build-essential` and apt lists in the final layer

### elasticdump
Containerized [elasticdump](https://github.com/taskrabbit/elasticsearch-dump) for backing up and restoring Elasticsearch indices. Non-trivial patterns:
- **Version-locked toolchain** -- pinned node.js and `elasticdump@2.4.2` for reproducible backups
- **PPA-sourced node.js** via `apt-add-repository` on the legacy base
- **ENTRYPOINT as a CLI wrapper** so the image runs as the `elasticdump` binary directly

### riemann
[Riemann](http://riemann.io/) event stream processor on a minimal busybox+java base. Non-trivial patterns:
- **HTTPS workaround on busybox** -- busybox `wget` can't do TLS, so a static `curl` binary is dropped in to fetch the release
- **Pinned curl and Riemann versions** via build-time `ENV`
- **Shell compatibility patch** rewrites the launcher's `env bash` to `env sh`
- **Listen-on-all-interfaces patch** rewrites the default config from `127.0.0.1` to `0.0.0.0`

### statsd
[Etsy StatsD](https://github.com/statsd/statsd) v0.8.0 metrics aggregation daemon. Non-trivial patterns:
- **Version-pinned release** fetched via `ADD` from a tagged GitHub tarball
- **Pinned node.js** from NodeSource, with `curl` purged after setup to slim the image
- **Externalized config** -- `config.js` copied in and passed to the daemon for easy overrides
- **Default UDP listener** on `8125/udp`

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
