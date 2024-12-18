FROM debian:12.8-slim

ARG DEBIAN_FRONTEND=noninteractive

LABEL maintainer="Sasha Klepikov <kai@list.ru>"

WORKDIR /opt

# Common packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-utils lsb-release curl gnupg2 software-properties-common apt-transport-https ca-certificates locales locales-all git nano

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE 1
ENV LC_ALL en_GB.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB.UTF-8
ENV KUBE_EDITOR=nano

# Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt update \
    && apt --yes --no-install-recommends install terraform \
    && terraform -install-autocomplete

# Google Cloud SDK
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
    && apt-get update \
    && apt-get --yes --no-install-recommends install google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin

# Docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - \
    && add-apt-repository "deb [arch=$(dpkg --print-architecture) ] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get -y --no-install-recommends install docker-ce docker-ce-cli containerd.io

# kubectl
RUN echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list \
    && curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg \
    && apt-get update \
    && apt-get install --yes --no-install-recommends kubectl

# k9s
RUN curl --location --output k9s_Linux_amd64.tar.gz https://github.com/derailed/k9s/releases/download/v0.32.7/k9s_Linux_amd64.tar.gz \
    && mkdir /tmp/k9s \
    && tar xzf k9s_Linux_amd64.tar.gz -C /tmp/k9s \
    && rm k9s_Linux_amd64.tar.gz \
    && mv /tmp/k9s/k9s /usr/local/bin

# kubectx
RUN git clone https://github.com/ahmetb/kubectx /usr/local/src/kubectx \
    && ln -s /usr/local/src/kubectx/kubectx /usr/local/bin/kubectx \
    && ln -s /usr/local/src/kubectx/kubens /usr/local/bin/kubens

# sops
RUN curl --location --output sops_amd64.deb https://github.com/getsops/sops/releases/download/v3.8.1/sops_3.8.1_amd64.deb \
    && apt-get install --yes --no-install-recommends ./sops_amd64.deb \
    && rm sops_amd64.deb

# Helm
RUN curl https://baltocdn.com/helm/signing.asc | apt-key add - \
    && echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt-get update \
    && apt-get install --yes --no-install-recommends helm

# helm-secrets plugin
RUN helm plugin install https://github.com/jkroepke/helm-secrets
