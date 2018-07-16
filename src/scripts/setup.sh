#!/bin/bash

set -o nounset # Fail when variable is used, but not initialized
set -o errexit # Fail on unhandled error exits
set -o pipefail # Fail when part of piped execution fails

pushd "$(dirname "$0")/../" > /dev/null
GESTURESRC_DIRECTORY=$(pwd -P)
popd > /dev/null

SCRIPT_DIRECTORY=GESTURESRC_DIRECTORY/scripts
GESTURESRC_DIRECTORY_CORRECT="/opt/GestureRecognition/src"
CONFIG_SYSTEM_DIRECTORY="/etc/opt/GestureRecognition"
CONFIG_FILENAME="config.yaml"
CONFIG_FILE_SYSTEM="${CONFIG_SYSTEM_DIRECTORY}/${CONFIG_FILENAME}"
CONFIG_FILE_LOCAL="./${CONFIG_FILENAME}"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
	exit
fi

echo "TIP: When there is a value in brackets like [default_value], hit Enter to use it."
echo ""


if [ "$GESTURESRC_DIRECTORY" != "$GESTURESRC_DIRECTORY_CORRECT" ]; then

    echo "You haven't downloaded GestureRecognition into /opt. As a result of that, you won't be able to run GestureRecognition on boot."
    echo "If you wish to be able to run GestureRecognition on boot, please interrupt this script and download into /opt."
    echo ""
    echo "Note: If you're an advanced user, you can install the init script manually and edit it to reflect your install path, but we don't provide any guarantees."
    read -r -p "Interrupt? (Y/n)? " interrupt_script

    case ${interrupt_script} in
            [nN] )
                echo "Carrying on ..."
            ;;
            * )
                echo "Script interrupted. Please download GestureRecognition into /opt as in project documentation."
                exit
            ;;
    esac

fi

cd "${SCRIPT_DIRECTORY}"

OS_default="debian"
DEVICE_default="raspberrypi"

echo "Which operating system are you using?"
printf "%15s - %s\n" "debian" "Debian, Raspbian, Armbian, Ubuntu or other Debian-based"
printf "%15s - %s\n" "archlinux" "Arch Linux or Arch Linux-based"
read -r -p "Your OS [${OS_default}]: " OS

if [ "${OS}" == "" ]; then
    OS=${OS_default}
elif [ ! -f "./inc/os/${OS}.sh" ]; then
    echo "Incorrect value. Exiting."
    exit
fi

echo "Which device are you using?"
cd inc/device
for deviceFile in *.sh; do
    deviceName="${deviceFile/.sh/}"
    deviceDescription=$(grep -P -o -e "(?<=DESCRIPTION=\")(.*)(?=\")" "${deviceFile}")

    printf "%15s - %s\n" "${deviceName}" "${deviceDescription}"
done
cd "${SCRIPT_DIRECTORY}"

read -r -p "Your device [${DEVICE_default}]: " DEVICE

if [ "${DEVICE}" == "" ]; then
    DEVICE=${DEVICE_default}
elif [ ! -f "./inc/device/${DEVICE}.sh" ]; then
    echo "Incorrect value. Exiting."
    exit
fi

source ./inc/common.sh

# shellcheck disable=SC1090
source ./inc/os/${OS}.sh

# shellcheck disable=SC1090
source ./inc/device/${DEVICE}.sh

if [ "$GESTURESRC_DIRECTORY" == "$GESTURESRC_DIRECTORY_CORRECT" ]; then

    echo "Do you want GestureRecognition to run on boot?"
	echo "You have these options: "
	echo "0 - NO"
	echo "1 - yes, use systemd (default, RECOMMENDED and awesome)"
	echo "2 - yes, use a classic init script (for a very old PC or an embedded system)"
	read -r -p "Which option do you prefer? [1]: " init_type

    if [ "${init_type// /}" != "0" ]; then

        if [ "${init_type}" == "" ]; then
            init_type="1"
        fi

        monitorGestures=false

        create_user
        gpio_permissions

        cd "${SCRIPT_DIRECTORY}"

        case ${init_type} in
            2 ) # classic
                init_classic ${monitorAlexa}
            ;;

            * ) # systemd
                init_systemd ${monitorAlexa}
            ;;
        esac

    fi

fi

install_os

cd "${GESTURESRC_DIRECTORY}"

# This is here because of https://github.com/pypa/pip/issues/2984
if run_pip --version | grep "pip 1.5"; then
    run_pip install -r ./requirements.txt
else
    run_pip install --no-cache-dir -r ./requirements.txt
fi

install_device

cd "${GESTURESRC_DIRECTORY}"
echo ""

if [ "${GESTURESRC_DIRECTORY}" == "${GESTURESRC_DIRECTORY_CORRECT}" ]; then
    mkdir -p ${CONFIG_SYSTEM_DIRECTORY}
    touch ${CONFIG_SYSTEM_DIRECTORY}/.keep
    CONFIG_FILE="${CONFIG_FILE_SYSTEM}"

    if [ -f ${CONFIG_FILE_LOCAL} ]; then
        echo "WARNING: You are installing GestureRecognition into system path (${GESTURESRC_DIRECTORY_CORRECT}), but local configuration file (${CONFIG_FILE_LOCAL}) exists and it will shadow the system one (the local will be used instead of the system one, which is ${CONFIG_FILE_SYSTEM}). If this is not what you want, rename, move or delete the local configuration."
    fi
else
    CONFIG_FILE="${CONFIG_FILE_LOCAL}"
fi

config_action=2
if [ -f $CONFIG_FILE ]; then
    echo "Configuration file $CONFIG_FILE exists already. What do you want to do?"
    echo "[0] Keep and use current configuration file."
    echo "[1] Edit existing configuration file."
    echo "[2] Delete the configuration file and start with a fresh one."
	read -r -p "Which option do you prefer? [hit Enter for 0]: " config_action
fi

case ${config_action} in

    1)
        echo "Editing existing configuration file ..."
    ;;
    2)
        echo "Creating configuration file ${CONFIG_FILE} ..."
        cp config.template.yaml ${CONFIG_FILE}
    ;;
    *)
        echo "Exiting ..."
        exit
    ;;

esac

install_device_config