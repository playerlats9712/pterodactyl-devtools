FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium xvfb x11vnc fluxbox novnc websockify nginx openssl ca-certificates \
    fonts-liberation fonts-dejavu-core xauth procps tini \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/devtools /home/container && chmod 1777 /tmp && chmod 777 /home/container
COPY start.sh /opt/devtools/start.sh
RUN chmod 755 /opt/devtools/start.sh
WORKDIR /home/container
EXPOSE 8080
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/opt/devtools/start.sh"]
