#!/bin/bash

export DISPLAY=:1


if [[ `ps aux | grep skype | grep "Xvfb :1" | grep -v grep | wc -l` == '0' ]]; then
  echo "starting Xvfb"
  Xvfb :1 -screen 0 800x600x16 &
else
  echo "Xvfb already running"
fi
if [[ `ps aux | grep skype | grep "fluxbox" | grep -v grep | wc -l` == '0' ]]; then
  echo "starting fluxbox"
  sleep 1
  fluxbox &
else
  echo "fluxbox already running"
fi
if [[ `ps -eo pid,user,args | grep skype | awk '{ print $1 " " $3; }' | grep skype | wc -l` == '0' ]]; then
  echo "starting skype"
  sleep 2
  skype &
else
  echo "skype already running"
fi

if [[ `ps aux | grep skype | grep "x11vnc -display :1" | grep -v grep | wc -l` == '0' ]]; then
  echo "Starting x11vnc"
  x11vnc -display :1 -bg -nopw -listen localhost -xkb
else
  echo "x11vnc is already running!"
fi

