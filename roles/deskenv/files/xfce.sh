#!/usr/bin/env bash

# Change background picture.
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "file:///home/$1/Pictures/background/$2"

# Remove desktop icons by setting them to 0 size.
xfconf-query -c xfce4-desktop -np /desktop-icons/style -t int -s 0
