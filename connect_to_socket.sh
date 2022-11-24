#/bin/bash

trap "echo here" 2 


sudo socat file:`tty`,raw,echo=0 unix:$1
