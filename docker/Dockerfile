###############################################################################
# RHEL 9.3 DevOps Toolbox Container
# Complete DevOps toolkit for CI/CD pipelines
###############################################################################

FROM registry.access.redhat.com/ubi9/ubi:9.3

LABEL maintainer="DevOps Team" \
      description="RHEL 9.3 x86-64 DevOps Toolbox with all essential tools" \
      version="1.0.0"

# Environment variables
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TERM=xterm-256color \
    KUBECTL_VERSION=v1.28.4 \
    HELM_VERSION=v3.13.2 \
    K9S_VERSION=v0.29.1 \
    ARGOCD_VERSION=v2.9.3 \
    YQ_VERSION=v4.40.5 \
    JQ_VERSION=1.7 \
    HARBOR_CLI_VERSION=2.9.1 \
    RKE2_VERSION=v1.28.4+rke2r1 \
    ISTIO_VERSION=1.20.1 \
    KIALI_VERSION=v1.77.0 \
    PROMETHEUS_VERSION=2.48.0 \
    GRAFANA_VERSION=10.2.2 \
    CHARTMUSEUM_VERSION=v0.16.0

# Install base packages and update system
RUN dnf update -y && \
    dnf install -y \
    # Essential tools
    bash-completion \
    ca-certificates \
    curl \
    wget \
    git \
    vim \
    nano \
    jq \
    tar \
    gzip \
    unzip \
    openssl \
    openssh-clients \
    # Build tools
    gcc \
    make \
    python3 \
    python3-pip \
    python3-devel \
    # Networking tools
    bind-utils \
    iputils \
    net-tools \
    telnet \
    traceroute \
    # Monitoring & Debugging
    procps-ng \
    htop \
    strace \
    tcpdump \
    # NFS tools
    nfs-utils \
    # Additional utilities
    sudo \
    which && \
    dnf clean all && \
    rm -rf /var/cache/dnf

###############################################################################
# Install Docker CLI (for docker-compose support)
###############################################################################
RUN curl -fsSL https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo && \
    dnf install -y docker-ce-cli docker-compose-plugin && \
    dnf clean all

###############################################################################
# Install kubectl
###############################################################################
RUN curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256" && \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm -f kubectl kubectl.sha256 && \
    kubectl version --client

###############################################################################
# Install Helm
###############################################################################
RUN curl -fsSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -o helm.tar.gz && \
    tar -xzf helm.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf linux-amd64 helm.tar.gz && \
    helm version

###############################################################################
# Install k9s
###############################################################################
RUN curl -fsSL https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz -o k9s.tar.gz && \
    tar -xzf k9s.tar.gz && \
    mv k9s /usr/local/bin/k9s && \
    rm -f k9s.tar.gz README.md LICENSE && \
    k9s version

###############################################################################
# Install ArgoCD CLI
###############################################################################
RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64 && \
    chmod +x /usr/local/bin/argocd && \
    argocd version --client

###############################################################################
# Install yq (YAML processor)
###############################################################################
RUN curl -fsSL https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    yq --version

###############################################################################
# Install jq (JSON processor) - Latest version
###############################################################################
RUN curl -fsSL https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-amd64 -o /usr/local/bin/jq && \
    chmod +x /usr/local/bin/jq && \
    jq --version

###############################################################################
# Install Harbor CLI (optional - requires API access)
###############################################################################
# Note: Harbor CLI might need to be built from source or downloaded from releases
RUN echo "Harbor CLI setup placeholder - configure as needed"

###############################################################################
# Install RKE2 CLI tools
###############################################################################
RUN curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh - && \
    ln -s /usr/local/bin/rke2 /usr/local/bin/kubectl || true

###############################################################################
# Install Istio CLI (istioctl)
###############################################################################
RUN curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh - && \
    mv istio-${ISTIO_VERSION}/bin/istioctl /usr/local/bin/ && \
    rm -rf istio-${ISTIO_VERSION} && \
    istioctl version --remote=false

###############################################################################
# Install Kiali CLI (optional)
###############################################################################
RUN curl -L https://kiali.io/installer/latest/kiali-operator-installer.sh -o /usr/local/bin/kiali-installer.sh && \
    chmod +x /usr/local/bin/kiali-installer.sh

###############################################################################
# Install Prometheus CLI tools (promtool)
###############################################################################
RUN curl -fsSL https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz -o prometheus.tar.gz && \
    tar -xzf prometheus.tar.gz && \
    mv prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/ && \
    rm -rf prometheus-${PROMETHEUS_VERSION}.linux-amd64 prometheus.tar.gz && \
    promtool --version

###############################################################################
# Install Grafana CLI (grafana-cli)
###############################################################################
RUN curl -fsSL https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz -o grafana.tar.gz && \
    tar -xzf grafana.tar.gz && \
    mv grafana-${GRAFANA_VERSION}/bin/grafana-cli /usr/local/bin/ && \
    rm -rf grafana-${GRAFANA_VERSION} grafana.tar.gz

###############################################################################
# Install ChartMuseum
###############################################################################
RUN curl -fsSL https://get.helm.sh/chartmuseum-${CHARTMUSEUM_VERSION}-linux-amd64.tar.gz -o chartmuseum.tar.gz && \
    tar -xzf chartmuseum.tar.gz && \
    mv linux-amd64/chartmuseum /usr/local/bin/ && \
    rm -rf linux-amd64 chartmuseum.tar.gz && \
    chartmuseum --version

###############################################################################
# Install cert-manager CLI (cmctl)
###############################################################################
RUN curl -fsSL https://github.com/cert-manager/cert-manager/releases/latest/download/cmctl-linux-amd64.tar.gz -o cmctl.tar.gz && \
    tar -xzf cmctl.tar.gz && \
    mv cmctl /usr/local/bin/cmctl && \
    rm -f cmctl.tar.gz && \
    cmctl version --client

###############################################################################
# Install NFS provisioner tools (if needed)
###############################################################################
# NFS utils already installed above

###############################################################################
# Setup bash completion for all tools
###############################################################################
RUN kubectl completion bash > /etc/bash_completion.d/kubectl && \
    helm completion bash > /etc/bash_completion.d/helm && \
    argocd completion bash > /etc/bash_completion.d/argocd

###############################################################################
# Create user and workspace
###############################################################################
RUN useradd -m -s /bin/bash devops && \
    echo "devops ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /workspace && \
    chown -R devops:devops /workspace

# Copy scripts
COPY scripts/ /opt/scripts/
RUN chmod +x /opt/scripts/*.sh && \
    chown -R devops:devops /opt/scripts

# Copy tools
COPY tools/ /opt/tools/
RUN chmod +x /opt/tools/*.sh && \
    chown -R devops:devops /opt/tools

# Copy configuration files
COPY config/ /opt/config/

# Setup PATH
ENV PATH="/opt/scripts:/opt/tools:${PATH}"

# Switch to devops user
USER devops
WORKDIR /workspace

# Create kubeconfig directory
RUN mkdir -p ~/.kube ~/.config

###############################################################################
# Health check
###############################################################################
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /opt/scripts/healthcheck.sh || exit 1

###############################################################################
# Entry point
###############################################################################
COPY docker/entrypoint.sh /entrypoint.sh
USER root
RUN chmod +x /entrypoint.sh
USER devops

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
