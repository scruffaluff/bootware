#!/usr/bin/env bash


gsettings set org.gnome.desktop.background picture-uri "file:///home/{{ user_account }}/Pictures/background/white_and_gray_mountains.jpg"
gsettings set org.gnome.desktop.interface gtk-theme Pop
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.desktop.notifications show-banners false
gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true


gsettings set org.gnome.nautilus.preferences show-hidden-files true

# Turn off automatic brightness
gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false
