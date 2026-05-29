# iButton Watcher — Docker Container

## What is this container for?

This container watches a 1-Wire bus (via **owserver**) for **Dallas/Maxim iButton** devices (family code `01`).

When an iButton is placed on the reader, the container:
1. Detects the iButton ID via `owdir` (uncached, low latency)
2. Strips the family-code prefix → e.g. `8B92BA150000`
3. Posts the ID to a **Home Assistant Webhook** via HTTP POST

It polls in a tight loop (configurable interval) and only fires the webhook when a '**new**' iButton is detected (not on every poll while it remains on the reader). New is every iButton after at least one cycle no iButton is detected. 

## Source of Image at GitHub (with Dockerfile):

[https://github.com/twischi/iButton_watcher_owserver](https://github.com/twischi/iButton_watcher_owserver)

## Ready to use Image at Docker-Hub:
[https://hub.docker.com/r/twischi/ibutton_watcher_owserver](https://hub.docker.com/r/twischi/ibutton_watcher_owserver)

## Configuration Variables

All variables can be overridden at container start — the values below are the defaults.

| Variable           | Default              | Description                                                                 |
|--------------------|----------------------|-----------------------------------------------------------------------------|
| `OWSERVER_HOST`    | `localhost`          | Hostname or IP of the owserver (e.g. `owserver`, `192.168.1.100`)          |
| `OWSERVER_PORT`    | `4304`               | TCP port of owserver                                                         |
| `HA_HOST`          | `localhost`          | Hostname or IP of Home Assistant (e.g. `homeassistant`, `192.168.1.101`)   |
| `HA_PORT`          | `8123`               | HTTP port of Home Assistant                                                  |
| `WEBHOOK_ID`       | `ibutton_detected`   | Webhook ID configured in Home Assistant                                      |
| `SLEEP_TIME_MS`    | `300`                | Roughly to poll-interval in milliseconds (sleeping time)                                                |
| `ALIVE_SIGNAL`     | `true`               | Print a dot periodically to show the script is running (`true` / `false`)  |
| `SIGNAL_EVERY_X_SEC` | `10`               | How often (in seconds) to print the alive dot (only if `ALIVE_SIGNAL=true`) |

---

## Override variables with `docker run`

Pass a variable with `-e` (to override a default):

Option 1: **Start with docker run**

```bash
docker run \
  -e OWSERVER_HOST=owserver \
  -e OWSERVER_PORT=4304 \
  -e HA_HOST=homeassistant \
  -e HA_PORT=8123 \
  -e WEBHOOK_ID=my_ibutton_hook \
  -e SLEEP_TIME_MS=200 \
  -e ALIVE_SIGNAL=true \
  -e SIGNAL_EVERY_X_SEC=30 \
  ...
```

Or handover an env-file:

```bash
# ibutton.env
OWSERVER_HOST=owserver
HA_HOST=homeassistant
WEBHOOK_ID=my_ibutton_hook
```

```bash
docker run --env-file ibutton.env ibutton-watcher
```

Option 2: **docker-compose.yml**

```yaml
services:
  ibutton-watcher:
    image: ibutton-watcher
    environment:
      OWSERVER_HOST: owserver
      OWSERVER_PORT: 4304
      HA_HOST: homeassistant
      HA_PORT: 8123
      WEBHOOK_ID: my_ibutton_hook
      SLEEP_TIME_MS: 200
      ALIVE_SIGNAL: "true"
      SIGNAL_EVERY_X_SEC: 30
    restart: unless-stopped
```

Or reference an env-file in Compose:

```yaml
services:
  ibutton-watcher:
    image: ibutton-watcher
    env_file:
      - ibutton.env
    restart: unless-stopped
```
## Build for...

It is only built for this architectures `linux/arm64` (e.g. Raspberry Pi 5) and for `linux/amd64`.

If you need the Image/Container for other platforms you can just build it on your machine with docker installed. See the GitHub-Repository the `dockerfile` and other files to do so. See link to GitHub above. 
>    ```
>    docker build -t ibutton_watcher_owserver:latest   .
>    ```

## Use the provided Image

Option 1: **Start with docker run**

```
docker run -d \
--restart unless-stopped \
--network host \
--name=twischi/ibutton_watcher_owserver:latest  
```

Option 2: **docker-compose.yml**

```
services:
# iButton Watcher service using the OWSERVER 
  ibutton_watcher:
    image: twischi/ibutton_watcher_owserver:latest  
    container_name: ibutton_watcher  
    restart: unless-stopped
    network_mode: host
```