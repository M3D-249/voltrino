
#!/usr/bin/env bash

set -e

# ==========================================
# Project configuration
# ==========================================

MCU="atmega328p"

PORT="${PORT:-COM3}"
BAUD="${BAUD:-115200}"

# ==========================================
# Toolchain
# ==========================================

CC="avr-gcc"
OBJCOPY="avr-objcopy"
OBJDUMP="avr-objdump"
SIZE="avr-size"
AVRDUDE="avrdude"

# ==========================================
# Project files
# ==========================================

SRC=(
    src/main.c
    src/gpio.c
)

BUILD="build"
TARGET="$BUILD/firmware"

ELF="$TARGET.elf"
HEX="$TARGET.hex"
LIST="$TARGET.lst"

# ==========================================
# Compiler and linker options
# ==========================================

CFLAGS=(
    -mmcu="$MCU"
    -std=gnu11
    -Os
    -Wall
    -Wextra
    -ffunction-sections
    -fdata-sections
    -Iinclude
)

LDFLAGS=(
    -mmcu="$MCU"
    -Wl,--gc-sections
)

# ==========================================
# Utility functions
# ==========================================

pause() {
    echo
    read -rp "Press Enter to continue..."
}

check_tools() {
    local missing=0

    for tool in "$CC" "$OBJCOPY" "$OBJDUMP" "$SIZE"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "Missing tool: $tool"
            missing=1
        fi
    done

    if (( missing )); then
        echo "Please install/configure the AVR toolchain."
        return 1
    fi
}

build_firmware() {
    echo
    echo "=========================================="
    echo " Building firmware"
    echo "=========================================="

    check_tools || return 1

    if [[ ! -f "$SRC" ]]; then
        echo "Error: Source file not found: $SRC"
        return 1
    fi

    mkdir -p "$BUILD"

    echo "[1/3] Compiling source..."

    OBJECTS=()

    for file in "${SRC[@]}"; do
        object="$BUILD/$(basename "${file%.c}").o"

        echo "Compiling $file..."

        "$CC" "${CFLAGS[@]}" -c -l"$file" -o "$object" || return 1

        OBJECTS+=("$object")
    done

    echo "[2/3] Linking firmware..."

    "$CC" "${LDFLAGS[@]}" "${OBJECTS[@]}" -o "$ELF"

    echo "[3/3] Generating HEX file..."

    "$OBJCOPY" -O ihex -R .eeprom "$ELF" "$HEX" || return 1

    echo
    echo "Build successful!"
    echo "Output: $HEX"
}

upload_firmware() {
    echo
    echo "=========================================="
    echo " Uploading firmware"
    echo "=========================================="

    if [[ ! -f "$HEX" ]]; then
        echo "Firmware not found. Building first..."
        build_firmware || return 1
    fi

    if ! command -v "$AVRDUDE" >/dev/null 2>&1; then
        echo "Error: avrdude not found."
        return 1
    fi

    read -rp "Serial port [$PORT]: " input
    PORT="${input:-$PORT}"

    echo
    echo "Uploading to $MCU on $PORT..."

    "$AVRDUDE" -v \
        -p "$MCU" \
        -c arduino \
        -P "$PORT" \
        -b "$BAUD" \
        -D \
        -U "flash:w:$HEX:i" || return 1

    echo
    echo "Upload completed!"
}

inspect_firmware() {
    echo
    echo "=========================================="
    echo " Firmware inspection"
    echo "=========================================="

    if [[ ! -f "$ELF" ]]; then
        echo "No built firmware found."
        echo "Build the firmware first."
        return 1
    fi

    echo
    echo "1. Memory usage"
    echo "------------------------------------------"

    "$SIZE" --format=avr --mcu="$MCU" "$ELF"

    echo
    echo "2. Assembly listing"
    echo "------------------------------------------"

    "$OBJDUMP" -d -S "$ELF" > "$LIST"

    echo "Assembly listing generated: $LIST"

    echo
    echo "3. Firmware files"
    echo "------------------------------------------"

    ls -lh "$BUILD"
}

clean_build() {
    echo
    echo "Cleaning build directory..."
    rm -rf "$BUILD"
    echo "Clean completed."
}

# ==========================================
# Main menu
# ==========================================

while true; do

    clear

    echo "=========================================="
    echo "       AVR ATmega328P BUILD SYSTEM"
    echo "=========================================="
    echo
    echo " MCU:  $MCU"
    echo " PORT: $PORT"
    echo " BAUD: $BAUD"
    echo
    echo "------------------------------------------"
    echo " Select an operation:"
    echo "------------------------------------------"
    echo
    echo " 1. Build firmware"
    echo " 2. Upload firmware"
    echo " 3. Inspect firmware"
    echo " 4. Clean build files"
    echo " 0. Exit"
    echo

    read -rp "Select operation: " choice

    case "$choice" in

        1)
            build_firmware
            pause
            ;;

        2)
            upload_firmware
            pause
            ;;

        3)
            inspect_firmware
            pause
            ;;

        4)
            clean_build
            pause
            ;;

        0)
            echo "Exiting..."
            exit 0
            ;;

        *)
            echo "Invalid selection."
            pause
            ;;

    esac

done
