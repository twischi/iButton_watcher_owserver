#!/bin/bash

# --- Configuration (overridable via docker run -e VAR=value) ---

# HOSTNAME of OWSERVER e.g. 'localhost', 'owserver' (real hostname), '192.168.1.100' (an IP).
OWSERVER_HOST=${OWSERVER_HOST:-localhost}
# PORT of OWSERVER
OWSERVER_PORT=${OWSERVER_PORT:-4304}         

# HOSTNAME of Home Assistant e.g. 'localhost', 'homeassistant' (real hostname),  '192.168.1.101' (an IP).
HA_HOST=${HA_HOST:-localhost}
# PORT of Home Assistant
HA_PORT=${HA_PORT:-8123}
# Webhook ID for Home Assistant
WEBHOOK_ID=${WEBHOOK_ID:-ibutton_detected}   

# Sleep time in ms - to set the poll interval
SLEEP_TIME_MS=${SLEEP_TIME_MS:-300}          
# Print a dot each poll cycle to show the script is alive (true/false)
ALIVE_SIGNAL=${ALIVE_SIGNAL:-true}
# Alive Signal roughly every X seconds
SIGNAL_EVERY_X_SEC=${SIGNAL_EVERY_X_SEC:-10} # Print a dot every 20 seconds (if ALIVE_SIGNAL is true)

# --- Configuration BLOCK END --------------------------------------

# Derived values form configuration
HA_URL="http://${HA_HOST}:${HA_PORT}" # Base URL for Home Assistant (used for Webhook)
SLEEP_TIME_S=$(awk "BEGIN {printf \"%.3f\", $SLEEP_TIME_MS/1000}") # Sleep time in seconds (converted from ms)

# Calculate how many cycles to print an alive signal (dot) based on desired time (SIGNAL_EVERY_X_SEC) and SLEEP_TIME_MS 
ALIVE_SIGNAL_AFTER_X_CYCLES=$(awk "BEGIN {printf \"%d\", $SIGNAL_EVERY_X_SEC / $SLEEP_TIME_S}") # Number of cycles after which to print a dot (alive signal)

# Variable to store the last detected iButton ID (to avoid duplicate announcements)
LAST_IBUTTON_ID=""
ALIVE_SIGNAL_CYCLE_COUNT=ALIVE_SIGNAL_AFTER_X_CYCLES-1 # Initialize to print a dot on the first cycle if enabled

# Command to query owserver (using owdir for uncached results)
OWFS="owdir -s ${OWSERVER_HOST}:${OWSERVER_PORT}"

# Info-Output befor starting the endloess loop.
[[ -t 1 ]] && clear  # only clear if stdout is a TTY (not in daemon mode)
echo "-------------------------------------------------------------"
echo "iButton watcher start:"
echo "-------------------------------------------------------------"
echo "* Searching for iButtons each:  ~(${SLEEP_TIME_MS}ms)"              # Sleep time between polls
echo "* with OWSERVER:                ${OWSERVER_HOST}:${OWSERVER_PORT}"  # OWSERVER connection info
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "... when find a iButton: Send ID via Webhook to" # What happens when an iButton is detected
echo "* Home Assistant:               ${HA_HOST}:${HA_PORT}"              # Home Assistant connection info
echo "* Webhook-ID:                   ${WEBHOOK_ID}"                      # Webhook ID for Home Assistant
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "* Alive signal (print dots):    ${ALIVE_SIGNAL}"                   # Whether alive signal is enabled
    if [[ "$ALIVE_SIGNAL" == "true" ]]; then
echo "* Signal every:                 ${SIGNAL_EVERY_X_SEC} seconds (every ${ALIVE_SIGNAL_AFTER_X_CYCLES} cycles)" # Print alive signal info to terminal
    fi
echo "-------------------------------------------------------------"



while true; do # Loop indefinitely

    # Query: Ask for all devices on 1wire but (UNCACHED for low latency)
    OWDIR_RESULT=$($OWFS /uncached 2>/dev/null)

    # Filter for iButton devices (family code 01)
    IBUTTON=$(echo "$OWDIR_RESULT" | grep '/01\.') # Example: /uncached/01.8B92BA150000

    if [[ -n "$IBUTTON" ]]; then
    # --> YES: iButton @ Reader, ---

        # Trim whitespace, strip path prefix & get only the iButton ID (remove 01. prefix if needed)
        IBUTTON=$(echo "$IBUTTON" | tr -d ' ' | sed 's|.*/||; s|^01\.||') # Example: 8B92BA150000

        # Check if iButton is NOT already announced (= different from the last detected one)
        if [[ "$IBUTTON" != "$LAST_IBUTTON_ID" ]]; then
        # --> NOT: announced yet ---

            # Announce new iButton ID
            echo && echo "iButton detected: $IBUTTON --> send to Webhook" # Print detected iButton ID to terminal
            LAST_IBUTTON_ID="$IBUTTON"                # Update last detected iButton ID

            # Send event to Home Assistant via Webhook
            curl -s -X POST "${HA_URL}/api/webhook/${WEBHOOK_ID}" \
                -H "Content-Type: application/json" \
                -d "{\"id\": \"${IBUTTON}\"}" 
        fi
    else
    # --> NO: iButton @ Reader ---
        LAST_IBUTTON_ID=""  # Reset so next insert is reported again
    fi
    if [[ "$ALIVE_SIGNAL" == "true" ]]; then
        (( ALIVE_SIGNAL_CYCLE_COUNT++ ))
        if (( ALIVE_SIGNAL_CYCLE_COUNT >= ALIVE_SIGNAL_AFTER_X_CYCLES )); then
            # TTY (foreground): rolling dots on one line
            # non-TTY (daemon): newline required so docker logs flushes immediately
            [[ -t 1 ]] && echo -n "." || echo "."
            ALIVE_SIGNAL_CYCLE_COUNT=0 # Reset counter 
        fi
    fi
    sleep $SLEEP_TIME_S # Sleep for the specified time before the next poll
done