# Change Data Capture (CDC) System with Debezium and Kafka

This project sets up a Change Data Capture (CDC) system using Debezium and Kafka to capture user data from a PostgreSQL database. The setup uses Docker to containerize the services required.

## Prerequisites

- Docker and Docker Compose installed on your machine
- Basic understanding of Docker, Kafka, and Debezium

## Services

- **Zookeeper**: Coordinates and manages the Kafka cluster.
- **Kafka**: Message broker used for real-time data streaming.
- **PostgreSQL**: Source database from which data changes are captured.
- **Debezium Connect**: Connects to the PostgreSQL database and streams changes to Kafka.

## Setup

### Step 1: Clone the Repository

```sh
git clone https://github/menoc61/sai-i-lama-CDC
cd sai-i-lama-CDC
```

### Step 2: Configure Environment Variables

Create a .env file in the root directory of the project and add the following environment variables:

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=momeni@61
POSTGRES_DB=hrm
JWT_SECRET=your_jwt_secret
```

### Step 3: Docker Compose

Use Docker Compose to start all the required services:

```sh
docker-compose up -d
```

This command will start the following services:

Zookeeper on port 2181
Kafka on port 9092
PostgreSQL on port 5432
Debezium Connect on port 8083

### Monitoring and Troubleshooting: Docker Compose

Check service status:

```sh
docker-compose ps
```

View logs:

```sh
docker-compose logs zookeeper
docker-compose logs kafka
docker-compose logs postgres
docker-compose logs connect
```

### Step 4: Set Up Debezium Connector

After the services are up and running, set up the Debezium connector to capture changes from the PostgreSQL `user` table.

Run the `setup_connector.sh` script:

```sh
./setup_connector.sh
```

### Monitoring and Troubleshooting: Debezium Connector

1. Verify connector setup:

```sh
curl -X GET http://localhost:8083/connectors/hrm-connector/status
```

You should see a response indicating that the connector is running and capturing changes.

2. Check connector logs:

```sh
docker-compose logs connect
```

### Step 5: Verify Data Capture

To verify that data is being captured and streamed to Kafka, use a Kafka consumer to read messages from the topic:

Start a Kafka console consumer:

```sh
docker exec -it <kafka_container_id> kafka-console-consumer --bootstrap-server kafka:9092 --topic hrm.public.users --from-beginning
```

> Replace <kafka_container_id> with the actual container ID of the Kafka service.

### Explanation for Monitoring and Troubleshooting

1. **Docker Compose**:
   - **Service Status**: Use `docker-compose ps` to check if all services are up and running.
   - **Logs**: Use `docker-compose logs <service>` to view logs for a specific service. This helps in diagnosing issues related to service startup and configuration.

2. **Debezium Connector**:
   - **Verify Setup**: Use `curl` to check the status of the connector. This confirms whether the connector is running and actively capturing changes.
   - **Connector Logs**: View the logs of the Debezium Connect service to troubleshoot any issues with the connector configuration or operation.

3. **Kafka Topics**:
   - **Kafka Console Consumer**: Start a Kafka console consumer to read messages from the Kafka topic and verify that data is being streamed correctly.
   - **List Topics**: Use `kafka-topics --list` to list all topics and ensure that the expected topics are created.
   - **Describe Topic**: Use `kafka-topics --describe` to get details about a topic, which can help in understanding the topic configuration and data flow.

>Good to Know: [**Cleanup**] To stop and remove all the containers, networks, and volumes created by Docker Compose:

```sh
docker-compose down -v
```
