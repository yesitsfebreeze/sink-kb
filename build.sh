#!/bin/bash
# Build script for SHIKAKUI ZMK firmware using Docker

set -e

echo "Building SHIKAKUI firmware with Docker..."

# Create bin directory if it doesn't exist
mkdir -p bin


git pull

# Build and run the Docker container
docker-compose up --build --abort-on-container-exit
docker-compose down

echo ""
echo "✓ Build complete!"
echo "Firmware files are available in bin/"
echo ""
echo "To flash:"
echo "1. Put keyboard half into bootloader mode (double-tap reset)"
echo "2. Copy the appropriate .uf2 file to the keyboard drive"
echo "   - Left half: bin/shikakui_left.uf2"
echo "   - Right half: bin/shikakui_right.uf2"
echo "   - Settings reset: bin/settings_reset.uf2"
