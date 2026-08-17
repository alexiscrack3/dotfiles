#!/bin/bash

# Use colors, but only if connected to a terminal, and that terminal supports them.
if command -v tput > /dev/null 2>&1; then
    ncolors=$(tput colors)
fi

if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
    BOLD="$(tput bold)"
    NORMAL="$(tput sgr0)"
else
    BOLD=""
    NORMAL=""
fi
