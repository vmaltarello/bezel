#!/usr/bin/env bash
# Dynamic text for hyprlock (fallback lock screen)
case "$1" in
  date)
    date +"%A %-d %B" ;;
  greet)
    h=$(date +%-H)
    if   [ "$h" -lt 5 ];  then s="good night"
    elif [ "$h" -lt 12 ]; then s="good morning"
    elif [ "$h" -lt 18 ]; then s="good afternoon"
    else s="good evening"; fi
    echo "$s, $USER" ;;
  battery)
    b=/sys/class/power_supply/BAT0
    c=$(<$b/capacity); st=$(<$b/status)
    i="󰁹"; [ "$c" -lt 80 ] && i="󰂀"; [ "$c" -lt 50 ] && i="󰁾"; [ "$c" -lt 25 ] && i="󰁼"; [ "$c" -lt 12 ] && i="󰁺"
    [ "$st" = Charging ] && i="󰂄"
    echo "$i  $c%" ;;
  media)
    t=$(playerctl metadata --format '{{artist}} — {{title}}' 2>/dev/null) || exit 0
    [ "$(playerctl status 2>/dev/null)" = Playing ] && echo "󰎈  ${t:0:60}" ;;
esac
