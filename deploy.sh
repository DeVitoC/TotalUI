#!/bin/bash

# TotalUI Deployment Script
# Copies addon files to WoW AddOns directory

# --- CONFIGURATION ---
# Edit this path to match your WoW installation
WOW_ADDONS_DIR="/Applications/World of Warcraft/_retail_/Interface/AddOns"

# Source directories
SOURCE_DIR="/Users/christopherdevito/Development/totalUI"
TOTALUI_SOURCE="$SOURCE_DIR/TotalUI"
TOTALUI_OPTIONS_SOURCE="$SOURCE_DIR/TotalUI_Options"

# Destination directories
TOTALUI_DEST="$WOW_ADDONS_DIR/TotalUI"
TOTALUI_OPTIONS_DEST="$WOW_ADDONS_DIR/TotalUI_Options"

# --- SCRIPT ---
echo "================================================"
echo "TotalUI Deployment Script"
echo "================================================"
echo ""

# Check if WoW AddOns directory exists
if [ ! -d "$WOW_ADDONS_DIR" ]; then
    echo "ERROR: WoW AddOns directory not found at:"
    echo "  $WOW_ADDONS_DIR"
    echo ""
    echo "Please edit this script and set the correct path."
    exit 1
fi

# Remove old versions if they exist
echo "Removing old versions..."
if [ -d "$TOTALUI_DEST" ]; then
    rm -rf "$TOTALUI_DEST"
    echo "  Removed old TotalUI"
fi

if [ -d "$TOTALUI_OPTIONS_DEST" ]; then
    rm -rf "$TOTALUI_OPTIONS_DEST"
    echo "  Removed old TotalUI_Options"
fi

echo ""

# Copy new versions
echo "Copying new versions..."
cp -r "$TOTALUI_SOURCE" "$TOTALUI_DEST"
echo "  ✓ Copied TotalUI"

cp -r "$TOTALUI_OPTIONS_SOURCE" "$TOTALUI_OPTIONS_DEST"
echo "  ✓ Copied TotalUI_Options"

echo ""
echo "================================================"
echo "Deployment complete!"
echo "You can now /reload in WoW"
echo "================================================"
