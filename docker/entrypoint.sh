#!/bin/bash

# If we are pulling a world zip down, do it now
if [ -n "$WORLD_ZIP_URL" ]; then
    echo "INFO: WORLD_ZIP_URL as ${WORLD_ZIP_URL}"
    # Check for existing files
    if [ -d "${SE_PATH}/world/Saves" ]; then
        echo "INFO: Found existing world..."
        # Check if we overwrite existing
        if [[ "$OVERWRITE" == "true" ]]; then
            echo "INFO: OVERWRITE set true, overwritting"
            wget -O /home/steam/world.zip $WORLD_ZIP_URL
            unzip -o /home/steam/world.zip -d "${SE_PATH}/world"
            rm -f /home/steam/world.zip
        else
            echo "INFO: OVERWRITE not true, not overwritting"
        fi
    else
        echo "INFO: Downloading and extracting world to ${SE_PATH}/world"
        wget -O /home/steam/world.zip $WORLD_ZIP_URL
        unzip -o /home/steam/world.zip -d "${SE_PATH}/world"
        rm -f /home/steam/world.zip
    fi
fi

# Check that our SE config file exists
if ! [ -f "${SE_PATH}/world/SpaceEngineers-Dedicated.cfg" ]; then
    echo "ERROR: SpaceEngineers-Dedicated.cfg not present in /home/steam/space-engineers/world"
    exit 1
fi

# Check that our Saves directory exists
if ! [ -d "${SE_PATH}/world/Saves" ]; then
    echo "ERROR: Saves directory not present in /home/steam/space-engineers/world"
    exit 1
fi

# SE Config file path
CONFIG_PATH="${SE_PATH}/world/SpaceEngineers-Dedicated.cfg"

# Store directory name for the world save folder
SAVE_NAME="$(grep -oEi '<LoadWorld>(.*)</LoadWorld>' ${CONFIG_PATH} | sed -E "s=<LoadWorld>|</LoadWorld>==g" | rev | cut -d '\' -f2 | rev)"

# Reconstructed LoadWorld save path to match wine prefix on container
# Wine prefix uses double backslash so we need quad backslash to escape correctly
LOAD_WORLD_PATH="Z:\\\\home\\\\steam\\\\space-engineers\\\\world\\\\Saves\\\\${SAVE_NAME}"

echo "INFO: Updating SpaceEngineers-Dedicated.cfg"

# Update IP address in config file to match container IP address
sed -i "s=<IP>.*</IP>=<IP>$(hostname -I)</IP>=g" $CONFIG_PATH

# Update LoadWorld path to match Wine prefix path to save
sed -E -i "s=<LoadWorld />|<LoadWorld.*LoadWorld>=<LoadWorld>${LOAD_WORLD_PATH}</LoadWorld>=g" $CONFIG_PATH
echo "DEBUG: LoadWorld = ${LOAD_WORLD_PATH}"
echo "DEBUG: Saves directory Contents:"
ls -al /home/steam/space-engineers/world/Saves
echo ""
echo "INFO: Updating Space Engineers Dedicated Server"

# Install Space Engineers Dedicated Server
/home/steam/steamcmd/steamcmd.sh +@sSteamCmdForcePlatformType windows +force_install_dir "$SE_PATH" +login anonymous +app_update 298740 validate +quit

echo "INFO: Launching Space Engineers Dedicated Server"

# Wine talks too much and it's annoying
export WINEDEBUG=-all

# Launch Space Engineers
wine ${SE_PATH}/DedicatedServer64/SpaceEngineersDedicated.exe -noconsole -ignorelastsession -path Z:\\home\\steam\\space-engineers\\world
