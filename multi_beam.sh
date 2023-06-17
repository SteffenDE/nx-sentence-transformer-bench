#!/usr/bin/env bash

PORT=5001 elixir nx_serving.exs &
PORT=5002 elixir nx_serving.exs &

caddy run --adapter caddyfile --config - << EOF
:6000 {
    reverse_proxy * :5001 :5002
}
EOF

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
