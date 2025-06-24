#!/bin/bash
xset s off
xset -dpms
xset s noblank
unclutter -idle 0 &
xbindkeys &
$HOME/launch_wrapper.sh

