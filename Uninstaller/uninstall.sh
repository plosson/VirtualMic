#!/bin/bash
# VirtualMic Uninstaller
# Removes the driver, app, shared memory segments, and restarts coreaudiod.

HAL_DIR="/Library/Audio/Plug-Ins/HAL"
DRIVER="$HAL_DIR/VirtualMic.driver"
APP="/Applications/VirtualMic.app"
UNINSTALLER="/Applications/Uninstall VirtualMic.app"

# Check if driver is installed
if [ ! -d "$DRIVER" ] && [ ! -d "$APP" ]; then
    osascript -e 'display dialog "VirtualMic is not installed." buttons {"OK"} default button "OK" with icon caution with title "VirtualMic Uninstaller"'
    exit 0
fi

# Confirm with user
RESPONSE=$(osascript -e 'display dialog "This will remove the VirtualMic driver, app, and shared memory segments.\n\nYour audio output selection will be preserved." buttons {"Cancel", "Uninstall"} default button "Cancel" cancel button "Cancel" with icon caution with title "VirtualMic Uninstaller"' 2>&1) || exit 0

# Quit VirtualMic app if running
killall VirtualMic 2>/dev/null || true
sleep 0.5

# Build the privileged commands
CMDS=""
[ -d "$DRIVER" ] && CMDS="$CMDS rm -rf '$DRIVER';"
[ -d "$APP" ] && CMDS="$CMDS rm -rf '$APP';"
[ -d "$UNINSTALLER" ] && CMDS="$CMDS rm -rf '$UNINSTALLER';"

# Clean up stale shared memory segments
CMDS="$CMDS cat > /tmp/_vm_shm_clean.c << 'SHM'
#include <sys/mman.h>
int main(void) { shm_unlink(\"/VirtualMicAudio\"); shm_unlink(\"/VirtualSpeakerAudio\"); shm_unlink(\"/VirtualMicInject\"); return 0; }
SHM
cc -o /tmp/_vm_shm_clean /tmp/_vm_shm_clean.c 2>/dev/null && /tmp/_vm_shm_clean 2>/dev/null; rm -f /tmp/_vm_shm_clean /tmp/_vm_shm_clean.c;"

# Restart coreaudiod
CMDS="$CMDS launchctl kickstart -kp system/com.apple.audio.coreaudiod 2>/dev/null || killall coreaudiod 2>/dev/null || true;"

# Run with admin privileges
osascript -e "do shell script \"$CMDS\" with administrator privileges" 2>/dev/null

if [ $? -eq 0 ]; then
    osascript -e 'display dialog "VirtualMic has been uninstalled successfully." buttons {"OK"} default button "OK" with title "VirtualMic Uninstaller"'
else
    osascript -e 'display dialog "Uninstall failed. Please try again." buttons {"OK"} default button "OK" with icon stop with title "VirtualMic Uninstaller"'
fi
