#!/usr/bin/env bash
# Luis Mondesi <lmondesi@bloomberg.net>
# 2012-07-30
#
# Source this script to start an ssh-agent and load your keys, typically at login
#
# . ssh-agent-setup # from ~/.profile
#
# License: GPL
# CHANGES:
#   2025-09-05 - make it quieter. Use DEBUG env var for debug output
#   2025-05-22 - add support for ssh-agent
#   2022-10-20 - simplify loading keys
#   2022-05-24 - adds logic to support Darwin

if [[ $DEBUG ]]; then
    echo "# running $0 (~/.ssh-agent-setup.bash)"
fi

ENV_FILE="$HOME/.ssh-agent.env"

clean_old_sock() {
    pkill -u "$UID" ssh-agent
    rm -f "$ENV_FILE"
}

launch_agent() {
    if [[ $DEBUG ]]; then
        echo "# launching new ssh-agent"
    fi
    ssh-agent -s > "$ENV_FILE"
    source "$ENV_FILE" >/dev/null
    if [[ $DEBUG ]]; then
        echo "# ssh-agent started and environment saved to $ENV_FILE"
    fi
}

load_agent() {
    if [[ -f "$ENV_FILE" ]]; then
        if [[ $DEBUG ]]; then
            echo "# loading ssh-agent from $ENV_FILE"
        fi
        source "$ENV_FILE" >/dev/null
        if ! ssh-add -l > /dev/null 2>&1; then
            if [[ $DEBUG ]]; then
                echo "# agent not responding, launching new one"
            fi
            clean_old_sock
            launch_agent
        fi
    else
        if [[ $DEBUG ]]; then
            echo "# no existing agent, launching new one"
        fi
        launch_agent
    fi
}

add_keys() {
    find ~/.ssh -type f \
        \( -name 'id_rsa*' -o -name 'id_dsa*' \) \
        ! -name '*.pub' | while read -r key; do

        if ssh-add -l 2>/dev/null | grep -q "$key"; then
            if [[ $DEBUG ]]; then
                echo "# Key $key already loaded"
            fi
            continue
        fi

        if [[ $DEBUG ]]; then
            echo "# Loading key $key"
        fi
        ssh-add "$key"
        rc=$?
        if [[ "$rc" == 2 ]]; then
            echo "# Repairing ssh-agent ($rc)"
            clean_old_sock
            launch_agent
            ssh-add "$key"
        elif [[ "$rc" == 1 ]]; then
            echo "# Your key $key could not be loaded"
        fi
    done
}

# Main execution
load_agent
add_keys

