#!/usr/bin/env bash

###############################################################################
# Install and Configure Kafka Cluster
# Sets up multi-node Kafka cluster for event streaming
###############################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_section() { echo -e "\n${CYAN}═══════════════════════════════════════════════════${NC}"; echo -e "${CYAN}$1${NC}"; echo -e "${CYAN}═══════════════════════════════════════════════════${NC}\n"; }

# Configuration
KAFKA_VERSION="${KAFKA_VERSION:-3.6.0}"
SCALA_VERSION="2.13"
INSTALL_DIR="${INSTALL_DIR:-/opt/kafka}"
DEPLOYMENT_TYPE="${1:-standalone}"  # standalone, cluster, or kubernetes

log_section "Kafka Cluster Installation"

###############################################################################
# Install Kafka (Standalone or on VMs)
###############################################################################
install_kafka_binary() {
    log_step "Installing Kafka ${KAFKA_VERSION}..."
    
    # Download Kafka
    cd /tmp
    KAFKA_PACKAGE="kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
    
    if [ ! -f "$KAFKA_PACKAGE" ]; then
        log_info "Downloading Kafka..."
        curl -O "https://downloads.apache.org/kafka/${KAFKA_VERSION}/${KAFKA_PACKAGE}"
    fi
    
    # Extract
    log_info "Extracting Kafka..."
    sudo mkdir -p "$INSTALL_DIR"
    sudo tar -xzf "$KAFKA_PACKAGE" -C "$INSTALL_DIR" --strip-components=1
    
    # Create data directories
    sudo mkdir -p /var/lib/kafka/{data,logs}
    sudo mkdir -p /var/log/kafka
    
    # Set permissions
    sudo chown -R $USER:$USER "$INSTALL_DIR" /var/lib/kafka /var/log/kafka
    
    log_info "✅ Kafka installed to $INSTALL_DIR"
}

###############################################################################
# Configure Kafka Cluster (3 Brokers)
###############################################################################
configure_kafka_cluster() {
    log_step "Configuring Kafka cluster..."
    
    # Broker configurations
    BROKER_IDS=(1 2 3)
    BROKER_PORTS=(9092 9093 9094)
    
    for i in ${!BROKER_IDS[@]}; do
        BROKER_ID=${BROKER_IDS[$i]}
        PORT=${BROKER_PORTS[$i]}
        
        log_info "Configuring broker ${BROKER_ID}..."
        
        cat > "$INSTALL_DIR/config/server-${BROKER_ID}.properties" << EOF
# Broker ${BROKER_ID} Configuration
broker.id=${BROKER_ID}
listeners=PLAINTEXT://:${PORT}
advertised.listeners=PLAINTEXT://localhost:${PORT}

# Directories
log.dirs=/var/lib/kafka/data/broker-${BROKER_ID}
log.retention.hours=168
log.segment.bytes=1073741824

# Zookeeper
zookeeper.connect=localhost:2181

# Replication
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600

# Log Retention
log.retention.check.interval.ms=300000
log.cleaner.enable=true

# Replication factor
default.replication.factor=3
min.insync.replicas=2
num.partitions=3
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2

# Performance
compression.type=producer
auto.create.topics.enable=true
delete.topic.enable=true
EOF

        # Create data directory for this broker
        mkdir -p "/var/lib/kafka/data/broker-${BROKER_ID}"
    done
    
    log_info "✅ Kafka cluster configured (3 brokers)"
}

###############################################################################
# Start Kafka Cluster
###############################################################################
start_kafka_cluster() {
    log_step "Starting Kafka cluster..."
    
    # Start Zookeeper first
    log_info "Starting Zookeeper..."
    "$INSTALL_DIR/bin/zookeeper-server-start.sh" -daemon "$INSTALL_DIR/config/zookeeper.properties"
    sleep 10
    
    # Start all brokers
    for i in 1 2 3; do
        log_info "Starting Kafka broker ${i}..."
        "$INSTALL_DIR/bin/kafka-server-start.sh" -daemon "$INSTALL_DIR/config/server-${i}.properties"
        sleep 5
    done
    
    log_info "✅ Kafka cluster started"
    sleep 10
}

###############################################################################
# Deploy Kafka on Kubernetes
###############################################################################
deploy_kafka_kubernetes() {
    log_step "Deploying Kafka on Kubernetes..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Install it first."
        exit 1
    fi
    
    # Create namespace
    kubectl create namespace kafka --dry-run=client -o yaml | kubectl apply -f -
    
    # Add Bitnami Helm repo
    if ! command -v helm &> /dev/null; then
        log_error "helm not found. Install it first."
        exit 1
    fi
    
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    
    # Install Kafka with Helm
    log_info "Installing Kafka via Helm..."
    helm install kafka bitnami/kafka \
        --namespace kafka \
        --set replicaCount=3 \
        --set persistence.enabled=true \
        --set persistence.size=10Gi \
        --set zookeeper.replicaCount=3 \
        --set metrics.kafka.enabled=true \
        --set metrics.jmx.enabled=true
    
    log_info "✅ Kafka deployed on Kubernetes"
    
    # Wait for pods
    log_info "Waiting for Kafka pods to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kafka -n kafka --timeout=300s
    
    # Show status
    kubectl get pods -n kafka
}

###############################################################################
# Create systemd services
###############################################################################
create_systemd_services() {
    log_step "Creating systemd services..."
    
    # Zookeeper service
    sudo tee /etc/systemd/system/zookeeper.service > /dev/null << EOF
[Unit]
Description=Apache Zookeeper Server
Documentation=http://zookeeper.apache.org
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=$INSTALL_DIR/bin/zookeeper-server-start.sh $INSTALL_DIR/config/zookeeper.properties
ExecStop=$INSTALL_DIR/bin/zookeeper-server-stop.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # Kafka broker services
    for i in 1 2 3; do
        sudo tee "/etc/systemd/system/kafka-broker${i}.service" > /dev/null << EOF
[Unit]
Description=Apache Kafka Broker ${i}
Documentation=http://kafka.apache.org/documentation.html
After=zookeeper.service
Requires=zookeeper.service

[Service]
Type=simple
User=$USER
ExecStart=$INSTALL_DIR/bin/kafka-server-start.sh $INSTALL_DIR/config/server-${i}.properties
ExecStop=$INSTALL_DIR/bin/kafka-server-stop.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    done
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    log_info "✅ Systemd services created"
}

###############################################################################
# Test Kafka Cluster
###############################################################################
test_kafka_cluster() {
    log_step "Testing Kafka cluster..."
    
    # Create test topic
    log_info "Creating test topic..."
    "$INSTALL_DIR/bin/kafka-topics.sh" --create \
        --topic test-topic \
        --bootstrap-server localhost:9092,localhost:9093,localhost:9094 \
        --replication-factor 3 \
        --partitions 3
    
    # List topics
    log_info "Listing topics..."
    "$INSTALL_DIR/bin/kafka-topics.sh" --list \
        --bootstrap-server localhost:9092
    
    # Describe topic
    log_info "Describing test topic..."
    "$INSTALL_DIR/bin/kafka-topics.sh" --describe \
        --topic test-topic \
        --bootstrap-server localhost:9092
    
    log_info "✅ Kafka cluster test completed"
}

###############################################################################
# Install Kafka tools
###############################################################################
install_kafka_tools() {
    log_step "Installing Kafka management tools..."
    
    # Create aliases
    cat >> ~/.bashrc << 'EOF'

# Kafka aliases
alias kafka-topics='$KAFKA_HOME/bin/kafka-topics.sh'
alias kafka-console-producer='$KAFKA_HOME/bin/kafka-console-producer.sh'
alias kafka-console-consumer='$KAFKA_HOME/bin/kafka-console-consumer.sh'
alias kafka-consumer-groups='$KAFKA_HOME/bin/kafka-consumer-groups.sh'
export KAFKA_HOME=/opt/kafka
EOF
    
    log_info "✅ Kafka tools configured"
}

###############################################################################
# Main execution
###############################################################################
main() {
    case "$DEPLOYMENT_TYPE" in
        standalone)
            log_info "Installing Kafka in standalone mode..."
            install_kafka_binary
            configure_kafka_cluster
            create_systemd_services
            start_kafka_cluster
            test_kafka_cluster
            install_kafka_tools
            ;;
        cluster)
            log_info "Installing Kafka in cluster mode..."
            install_kafka_binary
            configure_kafka_cluster
            create_systemd_services
            start_kafka_cluster
            test_kafka_cluster
            install_kafka_tools
            ;;
        kubernetes)
            log_info "Deploying Kafka on Kubernetes..."
            deploy_kafka_kubernetes
            ;;
        *)
            log_error "Unknown deployment type: $DEPLOYMENT_TYPE"
            log_info "Usage: $0 [standalone|cluster|kubernetes]"
            exit 1
            ;;
    esac
    
    log_section "🎉 Kafka Installation Complete!"
    
    if [ "$DEPLOYMENT_TYPE" = "kubernetes" ]; then
        cat << EOF

Kafka Cluster deployed on Kubernetes!

Access Kafka:
  # Port forward to access from localhost
  kubectl port-forward -n kafka svc/kafka 9092:9092

  # Connect to Kafka broker
  kubectl exec -it kafka-0 -n kafka -- bash

Test Kafka:
  # Create topic
  kubectl exec -it kafka-0 -n kafka -- kafka-topics.sh \\
    --create --topic test \\
    --bootstrap-server kafka:9092 \\
    --partitions 3 --replication-factor 3

  # Produce messages
  kubectl exec -it kafka-0 -n kafka -- kafka-console-producer.sh \\
    --broker-list kafka:9092 --topic test

  # Consume messages
  kubectl exec -it kafka-0 -n kafka -- kafka-console-consumer.sh \\
    --bootstrap-server kafka:9092 --topic test --from-beginning

Monitor:
  kubectl get pods -n kafka
  kubectl logs -f kafka-0 -n kafka

EOF
    else
        cat << EOF

Kafka Cluster installed!

Kafka Brokers:
  Broker 1: localhost:9092
  Broker 2: localhost:9093
  Broker 3: localhost:9094

Kafka Home: $INSTALL_DIR

Start Services:
  sudo systemctl start zookeeper
  sudo systemctl start kafka-broker1
  sudo systemctl start kafka-broker2
  sudo systemctl start kafka-broker3

Enable on Boot:
  sudo systemctl enable zookeeper kafka-broker{1,2,3}

Test Commands:
  # Create topic
  kafka-topics --create --topic test --bootstrap-server localhost:9092 \\
    --replication-factor 3 --partitions 3

  # Produce messages
  kafka-console-producer --broker-list localhost:9092 --topic test

  # Consume messages
  kafka-console-consumer --bootstrap-server localhost:9092 --topic test --from-beginning

  # List consumer groups
  kafka-consumer-groups --bootstrap-server localhost:9092 --list

Monitor:
  tail -f /var/log/kafka/*.log
  systemctl status kafka-broker1

EOF
    fi
}

main
