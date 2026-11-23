#!/bin/sh
set -eu
PORT="${SERVER_PORT:-${PORT:-8080}}"
case "$PORT" in ''|*[!0-9]*) echo 'Invalid SERVER_PORT' >&2; exit 1;; esac
if [ "$PORT" -lt 1024 ] || [ "$PORT" -gt 65535 ]; then echo 'Choose a port between 1024 and 65535' >&2; exit 1; fi
if [ -z "${DEVTOOLS_PASSWORD:-}" ] || [ "${#DEVTOOLS_PASSWORD}" -lt 12 ]; then
  echo 'Set DEVTOOLS_PASSWORD to a unique password of at least 12 characters before starting.' >&2
  exit 1
fi
umask 077
RUNDIR="/tmp/devtools-$(id -u)"
mkdir -p "$RUNDIR" /home/container/chromium-profile
chmod 700 "$RUNDIR"
# Apache MD5 hash for nginx basic authentication; credentials never inserted in page source.
HASH="$(openssl passwd -apr1 "$DEVTOOLS_PASSWORD")"
printf 'devtools:%s\n' "$HASH" > "$RUNDIR/htpasswd"
cat > "$RUNDIR/nginx.conf" <<CONFIG
worker_processes 1;
pid $RUNDIR/nginx.pid;
error_log /dev/stderr warn;
events { worker_connections 256; }
http {
    access_log off;
    client_body_temp_path $RUNDIR/client_body;
    proxy_temp_path $RUNDIR/proxy;
    fastcgi_temp_path $RUNDIR/fastcgi;
    uwsgi_temp_path $RUNDIR/uwsgi;
    scgi_temp_path $RUNDIR/scgi;
    server {
        listen 0.0.0.0:$PORT;
        server_name _;
        auth_basic "Private DevTools";
        auth_basic_user_file $RUNDIR/htpasswd;
        location / {
            proxy_pass http://127.0.0.1:6080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
            proxy_buffering off;
        }
    }
}
CONFIG
export DISPLAY=:99
export HOME=/home/container
export XDG_CONFIG_HOME=/home/container/.config
export XDG_CACHE_HOME=/home/container/.cache
mkdir -p "$HOME/.config" "$HOME/.cache"
Xvfb :99 -screen 0 1440x900x24 -nolisten tcp > "$RUNDIR/xvfb.log" 2>&1 &
XVFB_PID=$!
sleep 1
fluxbox > "$RUNDIR/fluxbox.log" 2>&1 &
FLUX_PID=$!
x11vnc -display :99 -localhost -rfbport 5900 -forever -shared -nopw -quiet > "$RUNDIR/x11vnc.log" 2>&1 &
VNC_PID=$!
websockify --web=/usr/share/novnc 127.0.0.1:6080 127.0.0.1:5900 > "$RUNDIR/websockify.log" 2>&1 &
WS_PID=$!
chromium --no-sandbox --disable-dev-shm-usage --disable-gpu --no-first-run --no-default-browser-check \
    --user-data-dir=/home/container/chromium-profile --window-size=1400,850 \
    'https://www.planspiel-boerse.de/' > "$RUNDIR/chromium.log" 2>&1 &
CHROME_PID=$!
cleanup() { kill "$CHROME_PID" "$WS_PID" "$VNC_PID" "$FLUX_PID" "$XVFB_PID" 2>/dev/null || true; }
trap cleanup INT TERM EXIT
echo "DevTools ready on port $PORT (use /vnc.html?autoconnect=1&resize=scale)"
nginx -c "$RUNDIR/nginx.conf" -g 'daemon off;'
