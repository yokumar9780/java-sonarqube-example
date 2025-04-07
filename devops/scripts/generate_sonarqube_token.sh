#!/bin/bash

# Wait for SonarQube to be up and running
echo "Waiting for SonarQube to be available..."
MAX_WAIT_TIME=300  # Maximum wait time in seconds
WAIT_TIME=5        # Time between each check

elapsed=0
while true; do
  # Check if SonarQube is ready by hitting the login page (ensuring the web UI is up)
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9000/login)

  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "SonarQube is available!"
    break
  fi

  if [ $elapsed -ge $MAX_WAIT_TIME ]; then
    echo "SonarQube did not become available within the expected time."
    exit 1
  fi

  echo "Waiting... elapsed time: $elapsed seconds"
  sleep $WAIT_TIME
  elapsed=$((elapsed + WAIT_TIME))
done

# SonarQube Admin credentials
SONAR_ADMIN_USER="admin"
SONAR_ADMIN_PASSWORD="admin"

# API endpoint for token generation
TOKEN_NAME="java-example-token"

# Create token using the SonarQube API
echo "Creating a new SonarQube token..."
RESPONSE=$(curl -u "$SONAR_ADMIN_USER:$SONAR_ADMIN_PASSWORD" -X POST \
  "http://localhost:9000/api/user_tokens/generate?name=$TOKEN_NAME")

# Parse the token from the JSON response using grep and sed
TOKEN=$(echo $RESPONSE | grep -o '"token":"[^"]*' | sed 's/"token":"//')

# Check if the token was generated successfully
if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "Failed to generate token"
  exit 1
else
  echo "Token generated successfully: $TOKEN"
  # You can store the token as an environment variable or pass it to your application here
  export SONAR_TOKEN=$TOKEN
fi
