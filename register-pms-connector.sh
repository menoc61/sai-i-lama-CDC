#!/bin/sh

# Wait for Kafka Connect to start listening on port 8084
while ! nc -z connect_pms 8084; do
  sleep 1
done

# Register the PMS connector
curl -X POST -H "Content-Type: application/json" --data @/kafka/connect/pms-connector.json http://connect_pms:8084/connectors