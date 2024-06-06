#!/bin/sh

# Wait for Kafka Connect to start listening on port 8083
while ! nc -z connect_hrm 8083; do
  sleep 1
done

# Register the HRM connector
curl -X POST -H "Content-Type: application/json" --data @/kafka/connect/hrm-connector.json http://connect_hrm:8083/connectors