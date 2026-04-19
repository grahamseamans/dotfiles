#!/bin/bash

OWN_TTY=$(tty)

FOCUSED_STATUS=$(osascript <<EOF
tell application "iTerm"
    if (count of every window) = 0 then
        return "no_windows"
    end if
    try
        set focusedTTY to TTY of (current session of current tab of current window)
        if focusedTTY = "$OWN_TTY" then
            return "focused"
        else
            return "not_focused"
        end if
    on error
        return "error"
    end try
end tell
EOF
)

sounds=(
    /System/Library/Sounds/Basso.aiff
    /System/Library/Sounds/Blow.aiff
    /System/Library/Sounds/Bottle.aiff
    /System/Library/Sounds/Frog.aiff
    /System/Library/Sounds/Funk.aiff
    /System/Library/Sounds/Glass.aiff
    /System/Library/Sounds/Hero.aiff
    /System/Library/Sounds/Morse.aiff
    /System/Library/Sounds/Ping.aiff
    /System/Library/Sounds/Pop.aiff
    /System/Library/Sounds/Purr.aiff
    /System/Library/Sounds/Sosumi.aiff
    /System/Library/Sounds/Submarine.aiff
    /System/Library/Sounds/Tink.aiff
)

if [[ "$FOCUSED_STATUS" != "focused" ]]; then
    random_sound=${sounds[$RANDOM % ${#sounds[@]}]}
    afplay "$random_sound" &
fi

exit 0
