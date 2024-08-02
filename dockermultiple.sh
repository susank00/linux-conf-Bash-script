#!/bin/bash

# Get the list of running containers along with their image IDs
containers=$(docker ps --format "{{.ID}} {{.Image}} {{.Names}}")

# Check if there are no running containers
if [ -z "$containers" ]; then
  echo "No running container found."
  exit 1
fi

# Get the list of images along with their IDs and tags
images=$(docker images --format "{{.ID}} {{.Tag}}")

# Display the list of running containers along with their image tags
echo "Running containers:"
index=1
declare -a container_ids
declare -a container_tags
declare -a container_names

while IFS= read -r line; do
  container_id=$(echo $line | awk '{print $1}')
  image_id=$(echo $line | awk '{print $2}')
  container_name=$(echo $line | awk '{print $3}')
  
  # Find the corresponding image tag for the image ID
  image_tag=$(echo "$images" | grep -w "$image_id" | awk '{print $2}')
  
  if [ -z "$image_tag" ]; then
    image_tag="Unknown (Image ID not found)"
  fi

  echo "$index) Container: $container_name, Image ID: $image_id, Image Tag: $image_tag, Container ID: $container_id"
  
  container_ids+=("$container_id")
  container_tags+=("$image_tag")
  container_names+=("$container_name")
  
  index=$((index + 1))
done <<< "$containers"

# Prompt the user to select a container
read -p "Enter the number of the container you want to interact with: " container_choice

# Validate the user's choice
if ! [[ "$container_choice" =~ ^[0-9]+$ ]] || [ "$container_choice" -lt 1 ] || [ "$container_choice" -gt ${#container_ids[@]} ]; then
  echo "Invalid choice. Please enter a valid number."
  exit 1
fi

# Get the selected container's ID, name, and tag
container_id=${container_ids[$((container_choice - 1))]}
container_name=${container_names[$((container_choice - 1))]}
image_tag=${container_tags[$((container_choice - 1))]}
short_container_id=${container_id:0:12}
echo "Selected Container ID: $short_container_id"

# Get the current timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")

# Create SQL dump filename with the image tag
dump_filename="susan_${image_tag}_${timestamp}.sql"

# Prompt the user to choose an action
echo "Choose an action:"
echo "1) Create SQL dump"
echo "2) Restore from SQL file"
read -p "Enter your choice (1 or 2): " user_choice

if [ "$user_choice" == "1" ]; then
  # Execute mysqldump inside the container and save to a timestamped SQL file with image tag
  docker exec -i $short_container_id mysqldump mfin_db > "$dump_filename"
  echo "Database dumped to $dump_filename"
elif [ "$user_choice" == "2" ]; then
  # Prompt the user for the full path of the SQL file to restore
  read -p "Enter the full path of the SQL file to restore (e.g., /home/susan/$dump_filename): " sql_file

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
