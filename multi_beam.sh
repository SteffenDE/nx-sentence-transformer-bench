#!/usr/bin/env bash

PORT=5001 elixir nx_serving.exs &
PORT=5002 elixir nx_serving.exs &
PORT=5003 elixir nx_serving.exs &
PORT=5004 elixir nx_serving.exs &
PORT=5005 elixir nx_serving.exs &
PORT=5006 elixir nx_serving.exs &

caddy run --adapter caddyfile --config - << EOF
:6000 {
    reverse_proxy * :5001 :5002 :5003 :5004 :5005 :5006
}
EOF

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
