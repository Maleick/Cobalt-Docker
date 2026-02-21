FROM ubuntu:24.04

ENV APP_BIND_HOST=0.0.0.0 \
    APP_PORT=50051 \
    TS_ENABLE=false \
    TS_REQUIRED=false \
    TS_AUTHKEY= \
    TS_HOSTNAME=app-node \
    TS_TUN_MODE=userspace \
    TS_STATE_DIR=/var/lib/tailscale \
    TS_SERVE_ENABLE=false \
    TS_SERVE_TARGETS=

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      bash \
      ca-certificates \
      curl \
      python3 \
      tini && \
    curl -fsSL https://tailscale.com/install.sh | sh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/app

COPY app.py /opt/app/app.py
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 50051

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
