#!/bin/bash

# Capture the container ID of the running container
container_id=$(docker ps --format "{{.ID}}" | head -n 1)

# Check if container_id is empty
if [ -z "$container_id" ]; then
  echo "No running container found."
  exit 1
fi

# Extract the first 9 characters of the container ID
short_container_id=${container_id:0:9}
echo "Short Container ID: $short_container_id"

# Get the current timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")

# Prompt the user to choose an action
echo "Choose an action:"
echo "1) Create SQL dump"
echo "2) Restore from SQL file"
read -p "Enter your choice (1 or 2): " user_choice

if [ "$user_choice" == "1" ]; then
  # Execute mysqldump inside the container and save to a timestamped SQL file
  docker exec -i $short_container_id mysqldump mfin_db > "susan_$timestamp.sql"
  echo "Database dumped to susan_$timestamp.sql"
elif [ "$user_choice" == "2" ]; then
  # Prompt the user for the full path of the SQL file to restore
  read -p "Enter the full path of the SQL file to restore (e.g., /home/susan/susan_$timestamp.sql): " sql_file

  # Check if the file exists
  if [ ! -f "$sql_file" ]; then
    echo "File $sql_file does not exist."
    exit 1
  fi

  # Restore the database inside the container
  docker exec -i $short_container_id mysql mfin_db < "$sql_file"
  echo "Database restored from $sql_file"
else
  echo "Invalid choice. Please enter 1 or 2."
  exit 1
fi
