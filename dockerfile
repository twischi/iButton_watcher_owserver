# Start with current Stable debian version
FROM debian:stable-slim AS temp_base

# Install Apps to access OWSREVER (that is running in an other container, same machine)

# - apt-get update: Updates the package lists for the apt package manager
# - owfs: The One-Wire File System, a software package that allows you to access 1-Wire devices as if they were part of the file system.
# - ow-shell: A command-line shell for interacting with 1-Wire devices, allowing
# - bash: The Bourne Again SHell, to run a shell script
RUN apt-get update && apt-get install -y \
    owfs \
    ow-shell \
    bash curl \
    && rm -rf /var/lib/apt/lists/*

# Start-Script to Image
COPY detect-ibuttons.sh /detect-ibuttons.sh

# Make executable 
RUN ["chmod", "+x", "/detect-ibuttons.sh"]

# Make one image > Collapse
FROM scratch
COPY --from=temp_base / /

ENTRYPOINT ["/detect-ibuttons.sh"]