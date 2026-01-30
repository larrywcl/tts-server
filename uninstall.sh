#!/bin/bash
# Uninstall TTS server
# Usage: curl -fsSL https://raw.githubusercontent.com/larrywcl/tts-server/main/uninstall.sh | bash

set -e

TTS_DIR="$HOME/.tts-server"
PLIST="$HOME/Library/LaunchAgents/com.westcreeklabs.tts-server.plist"

echo "🗑️  TTS Server Uninstaller"
echo "========================="
echo ""

# Stop service if running
if launchctl list | grep -q "com.westcreeklabs.tts-server"; then
    echo "Stopping service..."
    launchctl unload "$PLIST" 2>/dev/null || true
fi

# Remove launchd plist
if [[ -f "$PLIST" ]]; then
    echo "Removing launch agent..."
    rm -f "$PLIST"
fi

# Remove install directory
if [[ -d "$TTS_DIR" ]]; then
    echo "Removing $TTS_DIR..."
    rm -rf "$TTS_DIR"
fi

# Remove HuggingFace model cache (optional - ask first if interactive)
HF_CACHE="$HOME/.cache/huggingface/hub/models--Qwen--Qwen3-TTS-12Hz-1.7B-CustomVoice"
if [[ -d "$HF_CACHE" ]]; then
    if [[ -t 0 ]]; then
        # Interactive mode - ask
        read -p "Remove cached model (~3GB)? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Removing model cache..."
            rm -rf "$HF_CACHE"
        fi
    else
        # Non-interactive - remove it
        echo "Removing model cache..."
        rm -rf "$HF_CACHE"
    fi
fi

# Clean up temp files
echo "Cleaning temp files..."
rm -rf /tmp/tts_output 2>/dev/null || true
rm -f /tmp/tts-server.log /tmp/tts-server.err 2>/dev/null || true

echo ""
echo "✅ TTS Server uninstalled"
