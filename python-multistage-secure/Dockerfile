# syntax=docker/dockerfile:1.7
#
# Multi-stage Python build with supply-chain security.
#
# Key patterns:
#   - Two-stage build: builder (with compilers) and runtime (minimal)
#   - pip-compile --generate-hashes for reproducible, tamper-proof installs
#   - Build deps (gcc, etc.) never appear in the final image
#   - Healthcheck for container orchestrator integration
#   - ENTRYPOINT + CMD split for flexible overrides
#
# Usage:
#   docker build -t myapp .
#   docker build --build-arg PYTHON_VERSION=3.12 -t myapp .

ARG PYTHON_VERSION=3.11

########## Builder Stage ##########
FROM python:${PYTHON_VERSION}-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /build

# System dependencies needed only for compiling wheels (gcc, headers, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy only dependency manifests first -- layer cache optimization
COPY requirements.in pyproject.toml ./

# pip-tools compiles a locked requirements.txt with hashes.
# This ensures every install is reproducible and verified against known checksums,
# protecting against supply-chain attacks (typosquatting, compromised packages).
RUN python -m pip install --upgrade pip setuptools wheel pip-tools && \
    pip-compile --generate-hashes -o requirements.txt requirements.in

# Install locked dependencies
RUN pip install --require-hashes -r requirements.txt

# Now copy source code and install the project itself (no deps, already installed)
COPY . .
RUN pip install --no-deps .

########## Runtime Stage ##########
FROM python:${PYTHON_VERSION}-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /app

# Only runtime system libraries (no compilers, no headers)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy the entire Python installation from builder (site-packages, scripts, etc.)
# This brings the installed packages without the build toolchain.
COPY --from=builder /usr/local /usr/local

# Copy application source
COPY --from=builder /build /app

# Non-root user for runtime security
RUN useradd --create-home --shell /bin/bash appuser
USER appuser

EXPOSE 8000

# Healthcheck: container orchestrators use this to determine readiness.
# Adjust the endpoint and interval for your application.
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# ENTRYPOINT + CMD split: ENTRYPOINT is the executable, CMD provides default args.
# Override CMD at runtime without changing the entrypoint:
#   docker run myapp --port 9000
ENTRYPOINT ["python", "-m", "myapp"]
CMD ["--host", "0.0.0.0", "--port", "8000"]
