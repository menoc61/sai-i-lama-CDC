#!/bin/bash

# Variables
SUB_VERSION="3.6.2"
KAFKA_VERSION="2.13-${SUB_VERSION}"
DEBEZIUM_VERSION="2.6"
KAFKA_DIR="kafka_${KAFKA_VERSION}"
CONNECTOR_DIR="kafka_connectors"
HRM_CONNECTOR_CONFIG="hrm-connector.json"
PMS_CONNECTOR_CONFIG="pms-connector.json"
KAFKA_CONNECTORS=("hrm-connector" "pms-connector")
LOG_FILES=("zookeeper.log" "kafka.log" "connect.log")

# Functions
download() {
    URL=$1
    OUTPUT=$2
    
    if command -v wget > /dev/null; then 
        wget -O "${OUTPUT}" "${URL}"
    elif command -v curl > /dev/null; then
        curl -o "${OUTPUT}" "${URL}"
    else
        echo "Error: Neither wget nor curl is installed on the system"
        exit 1
    fi
}

extract_kafka() {
    if [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ] || [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
        "C:\Program Files\WinRAR\WinRAR.exe" x kafka_${KAFKA_VERSION}.tgz kafka_${KAFKA_VERSION}
    else
        tar -xzf kafka_${KAFKA_VERSION}.tgz
    fi
}

install_kafka() {
    if [ ! -d "$KAFKA_DIR" ]; then
        echo "Installing Kafka..."
        download "https://downloads.apache.org/kafka/${SUB_VERSION}/kafka_${KAFKA_VERSION}.tgz" "kafka_${KAFKA_VERSION}.tgz"
        extract_kafka
        rm kafka_${KAFKA_VERSION}.tgz
        echo "Kafka installed."
    else
        echo "Kafka is already installed."
    fi
}

install_debezium() {
    if [ ! -d "${CONNECTOR_DIR}/debezium-connector-postgres" ]; then
        echo "Installing Debezium PostgreSQL connector..."
        mkdir -p ${CONNECTOR_DIR}
        download "https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/${DEBEZIUM_VERSION}/debezium-connector-postgres-${DEBEZIUM_VERSION}-plugin.tar.gz" "${CONNECTOR_DIR}/debezium-connector-postgres-${DEBEZIUM_VERSION}-plugin.tar.gz"
        tar -xzf ${CONNECTOR_DIR}/debezium-connector-postgres-${DEBEZIUM_VERSION}-plugin.tar.gz -C ${CONNECTOR_DIR}
        rm ${CONNECTOR_DIR}/debezium-connector-postgres-${DEBEZIUM_VERSION}-plugin.tar.gz
        echo "Debezium PostgreSQL connector installed."
    else
        echo "Debezium PostgreSQL connector is already installed."
    fi
}

start_kafka() {
    echo "Starting Kafka..."
    nohup $KAFKA_DIR/bin/zookeeper-server-start.sh $KAFKA_DIR/config/zookeeper.properties > >(log) 2> >(log_error) &
    sleep 5
    nohup $KAFKA_DIR/bin/kafka-server-start.sh $KAFKA_DIR/config/server.properties > >(log) 2> >(log_error) &
    sleep 5
    echo "Kafka started."
}

start_debezium() {
    echo "Starting Debezium..."
    nohup $KAFKA_DIR/bin/connect-distributed.sh $KAFKA_DIR/config/connect-distributed.properties > >(log) 2> >(log_error) &
    sleep 5
    echo "Debezium started."
}

stop_kafka() {
    echo "Stopping Kafka..."
    $KAFKA_DIR/bin/kafka-server-stop.sh
    $KAFKA_DIR/bin/zookeeper-server-stop.sh
    echo "Kafka stopped."
}

stop_debezium() {
    echo "Stopping Debezium..."
    pkill -f connect-distributed
    echo "Debezium stopped."
}

restart_kafka_debezium() {
    echo "Restarting Kafka and Debezium..."
    stop_kafka
    stop_debezium
    start_kafka
    start_debezium
    echo "Kafka and Debezium restarted."
}

create_topics() {
    echo "Creating Kafka topics..."
    $KAFKA_DIR/bin/kafka-topics.sh --create --topic hrm.user --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 || true
    $KAFKA_DIR/bin/kafka-topics.sh --create --topic pms.user --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 || true
    echo "Kafka topics created."
}

deploy_connectors() {
    echo "Deploying Debezium connectors..."
    for connector in "${KAFKA_CONNECTORS[@]}"; do
        if ! curl -s "http://localhost:8083/connectors/$connector" | grep -q $connector; then
            curl -X POST -H "Content-Type: application/json" --data @$connector.json http://localhost:8083/connectors
        else
            echo "$connector already deployed."
        fi
    done
    echo "Debezium connectors deployed."
}

log() {
    while IFS= read -r line; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $line"
    done
}

log_error() {
    while IFS= read -r line; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $line"
    done
}

reverse_logs() {
    for log_file in "${LOG_FILES[@]}"; do
        if [ -f "$log_file" ]; then
            tac "$log_file" > "$log_file.tmp" && mv "$log_file.tmp" "$log_file"
        fi
    done
}
check_java_home() {
    if [ -z "$JAVA_HOME" ]; then
        echo "JAVA_HOME is not set. Please set the JAVA_HOME environment variable to the path of your JDK."
        exit 1
    fi
    if [ ! -f "$JAVA_HOME/bin/java" ]; then
        echo "Java executable not found in JAVA_HOME. Please ensure JAVA_HOME is set correctly."
        exit 1
    fi
    echo "Using JAVA_HOME: $JAVA_HOME"
}

# Main switch-case logic
case "$1" in
    install)
        check_java_home
        install_kafka
        install_debezium
    ;;
    start)
        check_java_home
        start_kafka
        start_debezium
        create_topics
        deploy_connectors
        reverse_logs
    ;;
    stop)
        stop_kafka
        stop_debezium
    ;;
    restart)
        check_java_home
        restart_kafka_debezium
        reverse_logs
    ;;
    *)
        echo "Usage: $0 {install|start|stop|restart}"
    ;;
esac

# ======= END OF SCRIPT =======
# Make the script executable:
# chmod +x setup_kafka_debezium.sh

# Run the script with appropriate commands:
# ./setup_kafka_debezium.sh install
# ./setup_kafka_debezium.sh start
# ./setup_kafka_debezium.sh stop
# ./setup_kafka_debezium.sh restart