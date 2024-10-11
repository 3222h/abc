# Base image
FROM ashu930559/nomachine-ubuntu-desktop:ch

# Remove NoMachine and clean up
RUN apt-get remove --purge -y nomachine && \
    rm -rf /usr/NX /etc/NXserver.cfg && \
    apt-get autoremove -y && \
    apt-get update -q && \
    apt-get upgrade -y

# Remove nxserver.sh
RUN rm -f /nxserver.sh

# Upgrade packages
RUN apt-get update -q \
    && apt-get upgrade -y \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# Add XFCE4
RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
        xfce4-session \
        xfce4-panel \
        xfdesktop4 \
        dbus-x11 \
        xterm \
        thunar \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# Add Packages (with dependencies)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        supervisor \
        python3-pip \
        xauth \
        gosu \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# Install TurboVNC
RUN wget -O turbovnc.deb https://jaist.dl.sourceforge.net/project/turbovnc/3.0/turbovnc_3.0_amd64.deb \
    && dpkg -i turbovnc.deb \
    && apt-get install -f -y  \
    && rm -rf turbovnc.deb

# Add User
ENV USER ubuntu
ENV PASSWORD 123456
ENV GID 1001
ENV UID 1001

# Create the group if it doesn't exist
RUN if ! getent group $USER; then \
        groupadd -g ${GID:-1001} ${USER:-ubuntu}; \
    fi && \
    useradd --home-dir /home/$USER --shell /bin/bash --create-home --uid ${UID:-1001} --gid ${GID:-1001} --groups adm,sudo $USER

# Set the user's password
RUN echo $USER:$PASSWORD | /usr/sbin/chpasswd

# Configure VNC
RUN mkdir -p /home/$USER/.vnc \
    && echo $PASSWORD | /opt/TurboVNC/bin/vncpasswd -f > /home/$USER/.vnc/passwd \
    && chmod 600 /home/$USER/.vnc/passwd \
    && chown -R $USER:$USER /home/$USER

# noVNC and Websockify
RUN git clone https://github.com/AtsushiSaito/noVNC.git -b add_clipboard_support /usr/lib/novnc \
    && pip install git+https://github.com/novnc/websockify.git@v0.10.0 \
    && sed -i "s/password = WebUtil.getConfigVar('password');/password = '$PASSWORD'/" /usr/lib/novnc/app/ui.js \
    && mv /usr/lib/novnc/vnc.html /usr/lib/novnc/index.html

# Disable Update and Crash Report
RUN if [ -f /etc/update-manager/release-upgrades ]; then \
        sed -i 's/Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades; \
    fi

RUN if [ -f /etc/default/apport ]; then \
        sed -i 's/enabled=1/enabled=0/g' /etc/default/apport; \
    fi

# Supervisor and VNC Config
ENV CONF_PATH /etc/supervisor/conf.d/supervisord.conf
RUN echo '[supervisord]' >> $CONF_PATH \
    && echo 'nodaemon=true' >> $CONF_PATH \
    && echo 'user=root' >> $CONF_PATH \
    && echo '[program:vnc]' >> $CONF_PATH \
    && echo 'command=gosu '$USER' /opt/TurboVNC/bin/vncserver :0 -fg -wm xfce4-session -geometry 1366x667 -depth 24' >> $CONF_PATH \
    && echo '[program:novnc]' >> $CONF_PATH \
    && echo 'command=gosu '$USER' bash -c "websockify --web=/usr/lib/novnc 3000 localhost:5900"' >> $CONF_PATH \
    && echo '[program:vnc-log]' >> $CONF_PATH \
    && echo 'command=tail -f /home/'$USER'/.vnc/localhost:0.log' >> $CONF_PATH

# Set entry point to supervisord
ENTRYPOINT ["/usr/bin/supervisord"]
