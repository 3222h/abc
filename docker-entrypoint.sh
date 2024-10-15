#!/bin/bash

# Clean up any previous VNC sessions
rm -rf /tmp/.X* /tmp/.X11-unix /tmp/.X*-lock /home/ubuntu/.vnc/*.pid

# Generate machine-id
uuidgen > /etc/machine-id

# Execute the passed command
exec "$@"
