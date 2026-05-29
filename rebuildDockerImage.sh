#!/bin/bash

# Show running script
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
echo "  $0"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" && echo 

# Load names to variable
. "$(dirname "$0")/names-docker.sh" && echo

# Stop/kill the container in case it is  running 
docker kill $dockerContainerName
# Remove the container that it can be build again 
docker rm $dockerImageName

# Clear cache - ONLY needed when there are PROBLEMS with Docker@NAS
#docker system prune -af 

# Build the docker-container
docker build -t $dockerImageName .

read -p "Rebuild DONE - press <Enter> to proceed"
clear

echo "... the Container will be started 'once'"
# Start Once (run in Background)
./startContainerOnce.sh