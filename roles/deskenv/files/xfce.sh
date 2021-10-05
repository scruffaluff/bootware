#!/usr/bin/env bash

# Remove desktop icons by setting them to 0 size.
xfconf-query -c xfce4-desktop -np /desktop-icons/style -t int -s 0
