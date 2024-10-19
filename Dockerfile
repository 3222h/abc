FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
CMD ["/bin/bash"]

# Install required packages
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
    dbus-x11 \
    git \
    locales \
    pavucontrol \
    sudo \
    x11-xserver-utils \
    xfce4 \
    xfce4-goodies \
    neofetch \
    python3 \
    nano \
    vim \
    htop \
    cups \
    wget \
    curl \
    software-properties-common \
    xubuntu-icon-theme \
    && echo Done



##
COPY /kali-undercover.deb /tmp/kali-undercover.deb
RUN apt update \
    && apt install -y /tmp/kali-undercover.deb \
    && rm -rf /tmp/kali-undercover.deb \
    && mv /usr/bin/kali-undercover /usr/bin/windows-10 \
    && rm -rf /usr/share/applications/kali-undercover.desktop

    
# Install wget and Kali Undercover (Windows 10 theme)
#RUN apt update \
    #&& apt install -y wget \
    #&& wget http://archive.kali.org/kali/pool/main/k/kali-undercover/kali-undercover_2023.4.2_all.deb \
    #&& apt install -y ./kali-undercover_2023.4.2_all.deb \
    #&& rm -rf kali-undercover_2023.4.2_all.deb \
    #&& mv /usr/bin/kali-undercover /usr/bin/windows-10 \
    #&& rm -rf /usr/share/applications/kali-undercover.desktop

# Copy the background image
COPY xfce-stripes.png /usr/share/backgrounds/xfce/xfce-stripes.png

COPY autostart /etc/xdg/autostart/

RUN apt-get update \
    && apt-get install -y dbus libsecret-1-0 libgbm1 \
    && apt-get clean \
    && apt --reinstall install -y fuse \
    && rm -rf /var/lib/apt/lists/*

# Install additional utilities
RUN apt-get update \
    && apt-get install -y \
        supervisor wget gosu git xauth sudo python3-pip \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# Install TurboVNC
RUN wget -O turbovnc.deb https://jaist.dl.sourceforge.net/project/turbovnc/3.0/turbovnc_3.0_amd64.deb \
    && dpkg -i turbovnc.deb && rm -rf turbovnc.deb

# User setup
ENV USER=ubuntu
ENV PASSWD=ubuntu
RUN useradd --home-dir /home/$USER --shell /bin/bash --create-home --user-group --groups adm,sudo $USER
RUN echo $USER:$USER | /usr/sbin/chpasswd
RUN mkdir -p /home/$USER/.vnc \
    && echo $PASSWD | /opt/TurboVNC/bin/vncpasswd -f > /home/$USER/.vnc/passwd \
    && chmod 600 /home/$USER/.vnc/passwd \
    && chown -R $USER:$USER /home/$USER

# noVNC setup
RUN git clone https://github.com/3222h/noVNC.git /usr/lib/novnc
RUN pip install git+https://github.com/novnc/websockify.git@v0.10.0
RUN sed -i "s/password = WebUtil.getConfigVar('password');/password = '$PASSWD'/" /usr/lib/novnc/app/ui.js
RUN mv /usr/lib/novnc/vnc.html /usr/lib/novnc/index.html

# System configurations
RUN if [ -f /etc/update-manager/release-upgrades ]; then \
        sed -i 's/Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades; \
    fi

RUN if [ -f /etc/default/apport ]; then \
        sed -i 's/enabled=1/enabled=0/g' /etc/default/apport; \
    fi


RUN mkdir -p /usr/local/bin
ENV CONF_PATH=/etc/supervisor/conf.d/supervisord.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
    
# Entrypoint and command
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
