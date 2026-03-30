FROM jenkins/jenkins:lts

USER root

RUN apt-get update && \
    apt-get install -y \
    python3 \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

USER jenkins
