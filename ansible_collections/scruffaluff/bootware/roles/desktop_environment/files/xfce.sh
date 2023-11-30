#!/usr/bin/env sh

# Remove desktop icons by setting them to 0 size.
xfconf-query --create --channel xfce4-desktop --property /desktop-icons/style --type int --set 0
