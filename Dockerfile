FROM debian:11.2-slim

ARG DEBIAN_FRONTEND=noninteractive

LABEL maintainer="Sasha Klepikov <kai@list.ru>"

WORKDIR /opt

# Common packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-utils lsb-release curl gnupg2 software-properties-common apt-transport-https ca-certificates locales locales-all git

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE 1
ENV LC_ALL en_GB.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB.UTF-8

# Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
    && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    && apt-get update \
    && apt-get --yes --no-install-recommends install terraform \
    && terraform -install-autocomplete

# Google Cloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
    && apt-get update \
    && apt-get --yes --no-install-recommends install google-cloud-sdk

# Docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get -y --no-install-recommends install docker-ce docker-ce-cli containerd.io

# kubectl
RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install --yes --no-install-recommends kubectl

# k9s
RUN curl --location --output k9s_Linux_x86_64.tar.gz `curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep "browser_download_url.*k9s_Linux_x86_64.tar.gz" | cut -d : -f 2,3 | tr -d \"` \
    && mkdir /tmp/k9s \
    && tar xzf k9s_Linux_x86_64.tar.gz -C /tmp/k9s \
    && rm k9s_Linux_x86_64.tar.gz \
    && mv /tmp/k9s/k9s /usr/local/bin

# kubectx
RUN git clone https://github.com/ahmetb/kubectx /usr/local/src/kubectx \
    && ln -s /usr/local/src/kubectx/kubectx /usr/local/bin/kubectx \
    && ln -s /usr/local/src/kubectx/kubens /usr/local/bin/kubens

# sops
RUN curl --location --output sops_amd64.deb `curl -s https://api.github.com/repos/mozilla/sops/releases/latest | grep "browser_download_url.*amd64.deb" | cut -d : -f 2,3 | tr -d \"` \
    && apt-get install --yes --no-install-recommends ./sops_amd64.deb \
    && rm sops_amd64.deb

# Helm
RUN curl https://baltocdn.com/helm/signing.asc | apt-key add - \
    && echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt-get update \
    && apt-get install --yes --no-install-recommends helm

# helm-secrets plugin
RUN helm plugin install https://github.com/jkroepke/helm-secrets
