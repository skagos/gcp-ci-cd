#!/bin/bash

CONTAINER_NAME="test-app"
IMAGE_NAME="yourusername/your-app-name:latest"

# Stop & remove if exists
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
  docker stop $CONTAINER_NAME
  docker rm $CONTAINER_NAME
fi

# Pull latest image
docker pull $IMAGE_NAME

# Run container
docker run -d --name $CONTAINER_NAME -p 80:80 $IMAGE_NAME


echo "==== Finished at $(date) ====" >> $LOG