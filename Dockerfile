FROM debian:13.3-slim

ARG DEBIAN_FRONTEND=noninteractive

LABEL maintainer="Sasha Klepikov <kai@list.ru>"

WORKDIR /opt

# Common packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-utils lsb-release curl gnupg2 apt-transport-https ca-certificates locales locales-all git nano

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
ENV LC_ALL=en_GB.UTF-8
ENV LANG=en_GB.UTF-8
ENV LANGUAGE=en_GB.UTF-8
ENV KUBE_EDITOR=nano

# Terraform
RUN curl https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt update && apt install terraform

# Google Cloud SDK
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt update \
    && apt --yes --no-install-recommends install google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin

# Docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee -a /etc/apt/sources.list.d/docker.list \
    && apt update \
    && apt --yes --no-install-recommends install docker-ce docker-ce-cli containerd.io

# kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" \
    && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# k9s
RUN curl --location --output k9s_linux_amd64.deb https://github.com/derailed/k9s/releases/download/v0.50.16/k9s_linux_amd64.deb \
    && apt --yes --no-install-recommends install ./k9s_linux_amd64.deb \
    && rm k9s_linux_amd64.deb

# kubectx
RUN git clone https://github.com/ahmetb/kubectx /usr/local/src/kubectx \
    && ln -s /usr/local/src/kubectx/kubectx /usr/local/bin/kubectx \
    && ln -s /usr/local/src/kubectx/kubens /usr/local/bin/kubens

# sops
RUN curl --location --output sops_amd64.deb https://github.com/getsops/sops/releases/download/v3.11.0/sops_3.11.0_amd64.deb \
    && apt --yes --no-install-recommends install ./sops_amd64.deb \
    && rm sops_amd64.deb

# Helm
RUN curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor -o /usr/share/keyrings/helm.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | tee -a /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt update \
    && apt --yes --no-install-recommends install helm

# helm-secrets plugin
RUN helm plugin install https://github.com/jkroepke/helm-secrets
