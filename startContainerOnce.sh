#!/bin/sh

# Show running script
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
echo "  $0"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" && echo 

# Load names to variable
. "$(dirname "$0")/names-docker.sh" && echo

# Stop/kill the container in case it is  running 
docker kill $dockerContainerName
# Remove the container that it can be build again 
docker rm $dockerContainerName

# Start the container with right parameter	
docker run -d \
--restart unless-stopped \
--network host \
--name="$dockerContainerName" "$dockerImageName"

