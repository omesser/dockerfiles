# Jenkins CI/CD image with Docker CLI, Ansible, and AWS CLI.
#
# Key patterns:
#   - Docker CLI (not daemon) for building images from Jenkins pipelines
#     Mount the host Docker socket: -v /var/run/docker.sock:/var/run/docker.sock
#   - Ansible for infrastructure automation tasks
#   - AWS CLI for ECR push, S3 artifact storage, etc.
#   - Skips the setup wizard (headless provisioning)
#   - Plugins installed from a text file for reproducible builds
#
# Usage:
#   docker build -t my-jenkins .
#   docker run -d -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock my-jenkins

FROM jenkins/jenkins:lts

USER root

# Install Docker CLI (not the daemon -- we use the host's Docker via socket mount),
# plus Ansible for config management and AWS CLI for cloud operations.
RUN apt-get update && apt-get install -y --no-install-recommends \
        lsb-release \
        curl \
        gnupg2 \
        sshpass \
    && curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
        https://download.docker.com/linux/debian/gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
        https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        docker-ce-cli \
        ansible \
        awscli \
    && rm -rf /var/lib/apt/lists/*

USER jenkins

# Skip the interactive setup wizard for automated provisioning.
# The admin user/password should be set via environment variables or
# a groovy init script mounted into /usr/share/jenkins/ref/init.groovy.d/
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Install plugins from a pinned list for reproducible builds.
# Create plugins.txt with one plugin per line, e.g.:
#   git:latest
#   workflow-aggregator:latest
#   docker-workflow:latest
#   ansible:latest
#   credentials-binding:latest
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
