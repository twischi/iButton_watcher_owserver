#!/bin/sh

# Show running script
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
echo "  $0"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" && echo 

# Load names to variable
. "$(dirname "$0")/names-docker.sh" && echo

# Stop Container if running
./stopContainerAndKill.sh

docker run -it \
--network host \
--name="$dockerContainerName" \
"$dockerImageName"
