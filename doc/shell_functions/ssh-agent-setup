#!/bin/sh
# Luis Mondesi <lmondesi@bloomberg.net>
# 2012-07-30
#
# Note that this script should run on all sh-like shells,
# not only bash.
#
# . ssh-agent-setup # from ~/.profile
#
# License: GPL
# CHANGES:
#   2022-10-20 - simplify loading keys
#   2022-05-24 - adds logic to support Darwin

#!/usr/bin/env bash
echo "# running $0 (~/.ssh-agent-setup.bash)"

ENV_FILE="$HOME/.ssh-agent.env"

clean_old_sock() {
    pkill -u "$UID" ssh-agent
    rm -f "$ENV_FILE"
}

launch_agent() {
    echo "# launching new ssh-agent"
    ssh-agent -s > "$ENV_FILE"
    source "$ENV_FILE" >/dev/null
    echo "# ssh-agent started and environment saved to $ENV_FILE"
}

load_agent() {
    if [ -f "$ENV_FILE" ]; then
        echo "# loading ssh-agent from $ENV_FILE"
        source "$ENV_FILE"
        if ! ssh-add -l > /dev/null 2>&1; then
            echo "# agent not responding, launching new one"
            clean_old_sock
            launch_agent
        fi
    else
        echo "# no existing agent, launching new one"
        launch_agent
    fi
}

add_keys() {
    find ~/.ssh -type f \
        \( -name 'id_rsa*' -o -name 'id_dsa*' \) \
        ! -name '*.pub' | while read -r key; do

        if ssh-add -l 2>/dev/null | grep -q "$key"; then
            echo "# Key $key already loaded"
            continue
        fi

        echo "# Loading key $key"
        ssh-add "$key"
        rc=$?
        if [ "$rc" = 2 ]; then
            echo "# Repairing ssh-agent ($rc)"
            clean_old_sock
            launch_agent
            ssh-add "$key"
        elif [ "$rc" = 1 ]; then
            echo "# Your key $key could not be loaded"
        fi
    done
}

# Main execution
load_agent
add_keys

