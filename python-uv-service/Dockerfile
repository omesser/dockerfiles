# syntax=docker/dockerfile:1.7
#
# Modern Python service image using uv for fast package management.
#
# Key patterns:
#   - uv copied from official ghcr.io image (no pip install needed)
#   - Non-root user with explicit UID/GID for k8s compatibility
#   - BuildKit cache mount for pip to speed up rebuilds
#   - Multi-arch AWS CLI install (works on both amd64 and arm64)
#   - Python env tuned for containers (no .pyc, unbuffered output)
#
# Usage:
#   docker build -t myservice .
#   docker build --build-arg PYTHON_VERSION=3.12 -t myservice .
#   docker build --build-arg PIP_EXTRA_INDEX_URL=https://my-index/simple -t myservice .

ARG PYTHON_VERSION=3.11

FROM python:${PYTHON_VERSION}-slim AS base

# Copy uv binary from the official image -- much faster than pip for installs
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ARG UID=10001
ARG GID=1001

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        curl \
        unzip && \
    rm -rf /var/lib/apt/lists/*

# Create a non-privileged user to run the container.
# Explicit UID/GID avoids permission issues with mounted volumes in k8s.
RUN addgroup \
        --gid "${GID}" \
        appgroup && \
    adduser \
        --disabled-password \
        --gecos "" \
        --home "/home/appuser" \
        --shell "/sbin/nologin" \
        --uid "${UID}" \
        appuser && \
    mkdir -p /home/appuser && \
    chown -R appuser:appgroup /home/appuser

# Multi-arch AWS CLI install (works on x86_64 and aarch64 / Apple Silicon)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -fsSL "$AWS_CLI_URL" -o "/tmp/awscliv2.zip" && \
    unzip -q /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    rm -rf /tmp/aws /tmp/awscliv2.zip

# Prevents Python from writing .pyc files (saves disk, avoids stale cache)
ENV PYTHONDONTWRITEBYTECODE=1
# Ensures logs appear immediately in docker logs (no buffering)
ENV PYTHONUNBUFFERED=1
# Suppresses pip's "running as root" warning
ENV PIP_ROOT_USER_ACTION=ignore

WORKDIR /app

# Copy dependency manifest first for better layer caching.
# Changes to source code won't invalidate the dependency install layer.
COPY pyproject.toml README.md /app/
COPY src /app/src

# BuildKit cache mount keeps the pip/uv cache across builds,
# dramatically speeding up rebuilds when dependencies haven't changed.
# Optional: add --build-arg PIP_EXTRA_INDEX_URL for private packages.
ARG PIP_EXTRA_INDEX_URL
RUN --mount=type=cache,target=/root/.cache/pip \
    uv pip install --system .

# Hand ownership to appuser (needed if the app creates temp files at runtime)
RUN chown -R appuser:appgroup /app

# Switch to non-privileged user
USER appuser

EXPOSE 8000

# Replace with your application's entrypoint
CMD ["python", "-m", "myapp"]
