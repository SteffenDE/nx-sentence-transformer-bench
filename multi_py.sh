#!/usr/bin/env bash

FLASK_APP=simple flask run --port 5001 &
FLASK_APP=simple flask run --port 5002 &

caddy run --adapter caddyfile --config - << EOF
:6000 {
    reverse_proxy * :5001 :5002
}
EOF

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
