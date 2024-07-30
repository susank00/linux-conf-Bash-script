#!/bin/bash

# Find the container ID of the running MySQL container
container_id=$(docker ps --format "{{.ID}}" | head -n 1)

# Check if container_id is empty
if [ -z "$container_id" ]; then
  echo "No running MySQL container found."
  exit 1
else
  # Extract the first 12 characters of the container ID
  short_container_id=${container_id:0:12}
  echo "Short Container ID: $short_container_id"
fi

# Path to the general log file inside the container
LOG_FILE="/var/lib/mysql/$short_container_id.log"

# Start a bash session inside the container and run the commands
docker exec -it $container_id bash -c "
  # Enable general log in MySQL
  mysql mfin_db -e \"SET GLOBAL general_log = 1;\"
  
  # Check the general log file
  tail -f $LOG_FILE
"
