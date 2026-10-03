#!/usr/bin/env bash
# Volume/brightness/mic keys: performs the action, then the Quickshell OSD shows the result.
# (The shell sees volume changes itself via PipeWire; brightness and mic are reported from here.)
shell() { quickshell ipc call shell "$@" >/dev/null 2>&1; }
case "$1" in
    vol-up)   wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    vol-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    vol-mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    mic-mute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; shell event mic ;;
    br-up)    brightnessctl -q -n2 set 5%+;  shell event brightness ;;
    br-down)  brightnessctl -q -n2 set 5%-;  shell event brightness ;;
esac
