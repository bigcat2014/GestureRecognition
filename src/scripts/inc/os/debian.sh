#!/bin/bash

function install_os {
    apt-get update
    apt-get install curl git build-essential python-dev python-setuptools swig libpulse-dev portaudio19-dev libportaudio2 vlc-nox sox libsox-fmt-mp3 -y
    apt-get -y remove python-pip
    run_python -m easy_install pip
}
