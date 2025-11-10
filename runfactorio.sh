#!/bin/bash
set -euo pipefail
#setting bash variables
FACTORIO_BIN="/opt/factorio/bin/x64/factorio"
SAVE_DIR="/opt/factorio/saves"
CONFIG_DIR="/opt/factorio/data"
MODS_DIR="/opt/factorio/mods"
LOG_DIR="/opt/factorio/log"
function initial_setup () {
echo "        ███████╗ █████╗  ██████╗████████╗ ██████╗ ██████╗ ██╗ ██████╗       ";
echo "        ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██║██╔═══██╗      ";
echo "        █████╗  ███████║██║        ██║   ██║   ██║██████╔╝██║██║   ██║      ";
echo "        ██╔══╝  ██╔══██║██║        ██║   ██║   ██║██╔══██╗██║██║   ██║      ";
echo "        ██║     ██║  ██║╚██████╗   ██║   ╚██████╔╝██║  ██║██║╚██████╔╝      ";
echo "        ╚═╝     ╚═╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝ ╚═════╝       ";
echo "                                                                            ";
echo "    ███████╗██████╗  █████╗  ██████╗███████╗     █████╗  ██████╗ ███████╗   ";
echo "    ██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝    ██╔══██╗██╔════╝ ██╔════╝   ";
echo "    ███████╗██████╔╝███████║██║     █████╗      ███████║██║  ███╗█████╗     ";
echo "    ╚════██║██╔═══╝ ██╔══██║██║     ██╔══╝      ██╔══██║██║   ██║██╔══╝     ";
echo "    ███████║██║     ██║  ██║╚██████╗███████╗    ██║  ██║╚██████╔╝███████╗   ";
echo "    ╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ";
echo "                                                                            ";
echo "    ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗     ██████╗ ██╗   ██╗  ";
echo "    ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗    ██╔══██╗╚██╗ ██╔╝  ";
echo "    ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝    ██████╔╝ ╚████╔╝   ";
echo "    ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗    ██╔══██╗  ╚██╔╝    ";
echo "    ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║    ██████╔╝   ██║     ";
echo "    ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝    ╚═════╝    ╚═╝     ";
echo "                                                                            ";
echo "███╗   ███╗██████╗        ███████╗██╗      █████╗ ██╗   ██╗████████╗██╗  ██╗";
echo "████╗ ████║██╔══██╗       ██╔════╝██║     ██╔══██╗██║   ██║╚══██╔══╝██║  ██║";
echo "██╔████╔██║██████╔╝       ███████╗██║     ███████║██║   ██║   ██║   ███████║";
echo "██║╚██╔╝██║██╔══██╗       ╚════██║██║     ██╔══██║██║   ██║   ██║   ██╔══██║";
echo "██║ ╚═╝ ██║██║  ██║██╗    ███████║███████╗██║  ██║╚██████╔╝   ██║   ██║  ██║";
echo "╚═╝     ╚═╝╚═╝  ╚═╝╚═╝    ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝";
echo "                                                                            ";
echo "============================================================================";  
echo Server Name: ${SERVER_NAME}
echo Description: ${SERVER_DESCRIPTION}
echo Tags: ${TAGS}
echo Ports: ${PORT}, ${RCON_PORT}
echo Host User ID: ${UID}
echo Host User Group ID: ${GID}
echo Version: ${FACTORIO_VERSION}
echo ""
groupmod -g ${GID} factorio \
&& usermod -u ${UID} -g ${GID} factorio

echo "Aligning container directory permissions to host user UID:GID ${UID}:${GID}..."
chown -R "${UID}:${GID}" /opt/factorio
echo "Permissions aligned."
echo "============================================================================"; 
}
# helper function to generate config.json based on runtime environment variables
function server_config () {
    echo "Begin generating configuration files..."
    # checks for config directory, creates if it doesn't exist
    echo "Checking for config directory..."
    if [ ! -e "/opt/factorio/data" ]; then
            mkdir -p /opt/factorio/data
    fi
    # load secrets from Docker Secrets if they exist
    echo "Loading Secrets..."
    if [ -f "/run/secrets/FACTORIO_TOKEN" ]; then
        FACTORIO_TOKEN=$(cat /run/secrets/FACTORIO_TOKEN)
        echo "FACTORIO_TOKEN loaded from Docker Secret."
    else
        FACTORIO_TOKEN=""
        echo "FACTORIO_TOKEN Docker Secret not found, using FACTORIO_PASSWORD."
    fi
    if [ -f "/run/secrets/FACTORIO_USERNAME" ]; then
        FACTORIO_USERNAME=$(cat /run/secrets/FACTORIO_USERNAME)
        echo "FACTORIO_USERNAME loaded from Docker Secret."
    else
        FACTORIO_USERNAME=""
        echo "FACTORIO_USERNAME Docker Secret not found, using default environment variable."
    fi
    # Using openssl to generate a random 32 character string if the password is empty
    # Base64 encoding ensures there is no weird characters in the password that could mess up this script
    if [ -f "/run/secrets/RCON_PASSWORD" ]; then
        RCON_PASSWORD=$(cat /run/secrets/RCON_PASSWORD)
        echo "RCON_PASSWORD loaded from Docker Secret."
    else
        echo "RCON_PASSWORD Docker Secret not found, setting default random password to ${RCON_PASSWORD:=$(openssl rand -base64 24)}."
    fi

    if [ -f "/run/secrets/FACTORIO_GAME_PASSWORD" ]; then
        FACTORIO_GAME_PASSWORD=$(cat /run/secrets/FACTORIO_GAME_PASSWORD)
        echo "FACTORIO_GAME_PASSWORD loaded from Docker Secret."
    else
        FACTORIO_GAME_PASSWORD=""
        echo "FACTORIO_GAME_PASSWORD Docker Secret not found, using default environment variable."
    fi
    # create server-settings.json file
    if [ -f "/opt/factorio/data/server-settings.json" ]; then
        echo "Overwriting PREVIOUS server-settings.json..."
    else
        echo "Creating NEW server-settings.json..."
    fi
    # The 'here document' '<<-' redirection deletes all leading tabs
    # Replacing the tabs with spaces will break the script.
    # fix for TAGS to be a proper JSON array
    TAGS_JSON=$(echo "${TAGS}" | sed 's/,/","/g')
    cat > /opt/factorio/data/server-settings.json <<- EOF
        {
            "name": "${SERVER_NAME}",
            "description": "${SERVER_DESCRIPTION}",
            "tags": ["${TAGS_JSON}"],
            "max_players": ${MAX_PLAYERS},
            "visibility": {
                "public": ${IS_PUBLIC},
                "lan": ${IS_LAN}
            },
            "require_user_verification": ${REQUIRE_USER_VERIFICATION},
            "allow_commands": "${ALLOW_COMMANDS}",
            "autosave_interval": ${AUTOSAVE_INTERVAL},
            "autosave_slots": ${AUTOSAVE_SLOTS},
            "autosave_only_on_server": ${AUTOSAVE_SERVER_ONLY},
            "afk_autokick_interval": ${AFK_AUTOKICK_INTERVAL},
            "auto_pause": ${AUTO_PAUSE},
            "auto_pause_when_players_connect": ${AUTO_PAUSE_WHEN_PLAYERS_CONNECT},
            "only_admins_can_pause_the_game": ${ONLY_ADMINS_CAN_PAUSE},
            "ignore_player_limit_for_returning_players": ${IGNORE_PLAYER_LIMIT_FOR_RETURNING_PLAYERS},
            "token": "${FACTORIO_TOKEN}",
            "username": "${FACTORIO_USERNAME}",
            "game_password": "${FACTORIO_GAME_PASSWORD}",
            "minimum_segment_size": 25,
            "minimum_segment_size_peer_count": 20,
            "maximum_segment_size": 100,
            "maximum_segment_size_peer_count": 10,
            "minimum_latency_in_ticks": 2,
            "max_heartbeat_per_second": 60,
            "max_upload_slots": 0,
            "max_upload_in_kilobytes_per_second": 0
        }
EOF
    echo "COMPLETED-Configuration JSON file created at /opt/factorio/data."
    echo "Aligning Factorio Config directory permissions to UID:GID ${UID}:${GID}..."
    chown -R "${UID}:${GID}" /opt/factorio/data
    echo "COMPLETED-Permissions aligned."
    echo "================================================================"
    echo "Begin save file handling..."
    echo "================================================================"
}
function save_file_handler () {
    LOAD_LATEST_SAVE=${LOAD_LATEST_SAVE:-true}
     # If SAVE_NAME isn't set or SAVE_DIR doesn't exist, create default save
    if [[ -z "${SAVE_NAME:-}" ]] || [[ ! -d "${SAVE_DIR}" ]]; then
        echo "SAVE_NAME or SAVE_DIR not specified, creating default save..."
        LOAD_SAVE="${SAVE_DIR}/_autosave1.zip"
        ${FACTORIO_BIN} --create "${LOAD_SAVE}"
        echo "Created new save at ${LOAD_SAVE}"
        return 0
    fi
    if [[ "${LOAD_LATEST_SAVE}" == "true" ]]; then
    LOAD_SAVE=$(ls -1t "${SAVE_DIR}"/"${SAVE_NAME}" 2>/dev/null | head -n 1)
        if [[ -z "${LOAD_SAVE}" ]]; then
            echo "No save found, creating new save..."
            ${FACTORIO_BIN} --create "${SAVE_DIR}/_autosave1.zip"
            LOAD_SAVE="${SAVE_DIR}/_autosave1.zip"
        fi
    else
    LOAD_SAVE="${SAVE_DIR}/_autosave1.zip"
        if [[ ! -f "${LOAD_SAVE}" ]]; then
            ${FACTORIO_BIN} --create "${LOAD_SAVE}"
        fi
    fi

echo "Aligning Factorio Saves directory permissions to UID:GID ${UID}:${GID}..."
chown -R "${UID}:${GID}" /opt/factorio/saves
echo "COMPLETED-Permissions aligned."
}

# function to build a complete the Factorio server command line argument and run it.
function rungame () {
    echo "Building command to start Factorio server..."
    SERVER_CMD=("${FACTORIO_BIN}" \
    "--start-server" "${LOAD_SAVE}" \
    "--server-settings" "${CONFIG_DIR}/server-settings.json" \
    "--port" "${PORT}" \
    "--rcon-port" "${RCON_PORT}" \
    "--rcon-password" "${RCON_PASSWORD}" \
    "--console-log" "${LOG_DIR}/console.log" 
)  # Close the array FIRST

# Then add conditional elements AFTER
if [[ -f "${CONFIG_DIR}/server-whitelist.json" ]]; then
    SERVER_CMD+=("--server-whitelist" "${CONFIG_DIR}/server-whitelist.json")
fi

if [[ -f "${CONFIG_DIR}/server-banlist.json" ]]; then
    SERVER_CMD+=("--server-banlist" "${CONFIG_DIR}/server-banlist.json")
fi

if [[ -f "${CONFIG_DIR}/server-adminlist.json" ]]; then
    SERVER_CMD+=("--server-adminlist" "${CONFIG_DIR}/server-adminlist.json")
fi
echo "Command built: ${SERVER_CMD[*]}"
echo "Starting Factorio server..."
nohup gosu factorio "${SERVER_CMD[@]}" > /opt/factorio/log/console.log 2>&1 &
echo "================================================================"
echo "Factorio Server Running."
echo "================================================================"
echo ░█▀▀░█░░░█▀█░█▀█░░░▀░█▀▀░█▄█░░░█░█░█▀█░█
echo ░▀▀█░█░░░█░█░█▀▀░░░░░█▀▀░█░█░░░█░█░█▀▀░▀
echo ░▀▀▀░▀▀▀░▀▀▀░▀░░░░░░░▀▀▀░▀░▀░░░▀▀▀░▀░░░▀  
echo "================================================================"
}
sleep 10
function log_mover() {
## Get the logs out of data folder.
if [[ -f "/opt/factorio/factorio-current.log" ]]; then
    mv /opt/factorio/factorio-current.log /opt/factorio/log/
fi
if [[ -f "/opt/factorio/factorio-previous.log" ]]; then
    mv /opt/factorio/factorio-previous.log /opt/factorio/log/
fi
ln -s /opt/factorio/log/factorio-current.log /opt/factorio/factorio-current.log
ln -s /opt/factorio/log/factorio-previous.log /opt/factorio/factorio-previous.log
echo "Aligning Factorio Log directory permissions to UID:GID ${UID}:${GID}..."
chown -R "${UID}:${GID}" /opt/factorio/log
echo "COMPLETED-Permissions aligned."
}
#================================
# Main script execution
initial_setup
server_config
save_file_handler
rungame
log_mover
#================================

