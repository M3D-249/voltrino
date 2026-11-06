
#!/usr/bin/env bash

# ==========================================
# VOLTRINO AVR BUILD SYSTEM
# ==========================================

set -o pipefail

# ==========================================
# Project configuration
# ==========================================

MCU="${MCU:-atmega328p}"
PORT="${PORT:-COM3}"
BAUD="${BAUD:-115200}"

# ==========================================
# Toolchain
# ==========================================

CC="${CC:-avr-gcc}"
OBJCOPY="${OBJCOPY:-avr-objcopy}"
OBJDUMP="${OBJDUMP:-avr-objdump}"
SIZE="${SIZE:-avr-size}"
AVRDUDE="${AVRDUDE:-avrdude}"

# ==========================================
# Project directories
# ==========================================

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EXAMPLES="$ROOT/examples"
SRC="$ROOT/src"
INCLUDE="$ROOT/include"
BUILD="$ROOT/build"

# ==========================================
# Compiler options
# ==========================================

CFLAGS=(
    -mmcu="$MCU"
    -std=gnu11
    -Os
    -Wall
    -Wextra
    -ffunction-sections
    -fdata-sections
    -I"$INCLUDE"
    -I"$SRC"
)

LDFLAGS=(
    -mmcu="$MCU"
    -Wl,--gc-sections
)

# ==========================================
# Selected example
# ==========================================

SELECTED_EXAMPLE=""
EXAMPLE_NAME=""

EXAMPLE_BUILD=""
ELF=""
HEX=""
LIST=""

HEX_REL=""

EXAMPLE_SOURCES=()
SHARED_SOURCES=()
SOURCES=()
OBJECTS=()

# ==========================================
# Utility functions
# ==========================================

pause() {
    echo
    read -rp "Press Enter to continue..."
}

check_tool() {

    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: Required tool '$1' not found."
        return 1
    fi

}

check_build_tools() {

    check_tool "$CC" &&
    check_tool "$OBJCOPY"

}

check_inspect_tools() {

    check_tool "$SIZE" &&
    check_tool "$OBJDUMP"

}

check_upload_tools() {

    check_tool "$AVRDUDE"

}

# ==========================================
# Discover examples
# ==========================================

discover_examples() {

    EXAMPLES_LIST=()

    if [[ ! -d "$EXAMPLES" ]]; then
        echo "Error: Examples directory not found."
        return 1
    fi

    while IFS= read -r -d '' directory; do

        if find "$directory" \
            -type f -name '*.c' -print -quit | grep -q .; then

            EXAMPLES_LIST+=("$directory")

        fi

    done < <(
        find "$EXAMPLES" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            -print0 | sort -z
    )

    if [[ ${#EXAMPLES_LIST[@]} -eq 0 ]]; then
        echo "No valid examples found."
        return 1
    fi

}

# ==========================================
# Select example
# ==========================================

select_example() {

    discover_examples || return 1

    echo
    echo "=========================================="
    echo "          AVAILABLE EXAMPLES"
    echo "=========================================="
    echo

    for i in "${!EXAMPLES_LIST[@]}"; do

        printf " %2d. %s\n" \
            "$((i + 1))" \
            "$(basename "${EXAMPLES_LIST[$i]}")"

    done

    echo
    echo "  0. Back to main menu"
    echo

    local choice

    read -rp "Select example: " choice

    if [[ "$choice" == "0" ]]; then
        return 1
    fi

    if [[ ! "$choice" =~ ^[0-9]+$ ]] ||
       (( choice < 1 || choice > ${#EXAMPLES_LIST[@]} )); then

        echo "Invalid selection."
        return 1

    fi

    SELECTED_EXAMPLE="${EXAMPLES_LIST[$((choice - 1))]}"

    EXAMPLE_NAME="$(basename "$SELECTED_EXAMPLE")"

    set_paths

    echo
    echo "Selected example: $EXAMPLE_NAME"

}

# ==========================================
# Configure output paths
# ==========================================

set_paths() {

    EXAMPLE_BUILD="$BUILD/$EXAMPLE_NAME"

    ELF="$EXAMPLE_BUILD/firmware.elf"
    HEX="$EXAMPLE_BUILD/firmware.hex"
    LIST="$EXAMPLE_BUILD/firmware.lst"

    # IMPORTANT:
    # AVRDude receives a relative path.
    # This avoids Windows drive-letter colon issues.

    HEX_REL="build/$EXAMPLE_NAME/firmware.hex"

}

# ==========================================
# Discover source files
# ==========================================

discover_sources() {

    EXAMPLE_SOURCES=()
    SHARED_SOURCES=()
    SOURCES=()

    # --------------------------------------
    # Selected example sources
    # --------------------------------------

    while IFS= read -r -d '' source; do

        EXAMPLE_SOURCES+=("$source")

    done < <(
        find "$SELECTED_EXAMPLE" \
            -type f -name '*.c' -print0 | sort -z
    )

    # --------------------------------------
    # Shared source files
    # --------------------------------------

    if [[ -d "$SRC" ]]; then

        while IFS= read -r -d '' source; do

            SHARED_SOURCES+=("$source")

        done < <(
            find "$SRC" \
                -type f -name '*.c' -print0 | sort -z
        )

    fi

    if [[ ${#EXAMPLE_SOURCES[@]} -eq 0 ]]; then
        echo "Error: No C files found in selected example."
        return 1
    fi

    SOURCES=(
        "${EXAMPLE_SOURCES[@]}"
        "${SHARED_SOURCES[@]}"
    )

}

# ==========================================
# Build firmware
# ==========================================

build_firmware() {

    echo
    echo "=========================================="
    echo " Building: $EXAMPLE_NAME"
    echo "=========================================="

    check_build_tools || return 1

    discover_sources || return 1

    mkdir -p "$EXAMPLE_BUILD"

    OBJECTS=()

    local count=0
    local total=${#SOURCES[@]}

    echo
    echo "Example sources: ${#EXAMPLE_SOURCES[@]}"
    echo "Shared sources:  ${#SHARED_SOURCES[@]}"
    echo "Total sources:   $total"

    # --------------------------------------
    # Compile source files
    # --------------------------------------

    for source in "${SOURCES[@]}"; do

        ((count+=1))

        local object="$EXAMPLE_BUILD/obj_$count.o"

        echo
        echo "[$count/$total] Compiling..."

        if [[ "$source" == "$SELECTED_EXAMPLE/"* ]]; then

            echo "Example: ${source#"$SELECTED_EXAMPLE"/}"

        else

            echo "Shared: ${source#"$SRC"/}"

        fi

        if ! "$CC" "${CFLAGS[@]}" \
            -c "$source" -o "$object"; then

            echo
            echo "Compilation failed!"
            return 1

        fi

        OBJECTS+=("$object")

    done

    # --------------------------------------
    # Link object files
    # --------------------------------------

    echo
    echo "Linking firmware..."

    if ! "$CC" "${LDFLAGS[@]}" \
        "${OBJECTS[@]}" -o "$ELF"; then

        echo "Linking failed!"
        return 1

    fi

    # --------------------------------------
    # Generate HEX
    # --------------------------------------

    echo
    echo "Generating HEX..."

    if ! "$OBJCOPY" \
        -O ihex \
        -R .eeprom \
        "$ELF" "$HEX"; then

        echo "HEX generation failed!"
        return 1

    fi

    # --------------------------------------
    # Verify output
    # --------------------------------------

    if [[ ! -s "$HEX" ]]; then
        echo "Error: HEX file was not generated correctly."
        return 1
    fi

    echo
    echo "=========================================="
    echo " BUILD SUCCESSFUL"
    echo "=========================================="

    echo "Example: $EXAMPLE_NAME"
    echo "MCU:     $MCU"
    echo
    echo "ELF: $ELF"
    echo "HEX: $HEX"

    return 0

}

# ==========================================
# Build operation
# ==========================================

build_action() {

    select_example || return

    build_firmware

    pause

}

# ==========================================
# Upload operation
# ==========================================

upload_action() {

    select_example || return

    check_upload_tools || {
        pause
        return
    }

    # --------------------------------------
    # Always rebuild before uploading
    # --------------------------------------

    echo
    echo "Preparing firmware..."

    if ! build_firmware; then

        echo
        echo "Build failed. Upload cancelled."

        pause
        return

    fi

    # --------------------------------------
    # Verify HEX file
    # --------------------------------------

    if [[ ! -s "$HEX" ]]; then

        echo "Error: Firmware HEX file not found!"
        echo "Expected: $HEX"

        pause
        return

    fi

    echo
    echo "Firmware found:"
    echo "$HEX_REL"

    # --------------------------------------
    # Select serial port
    # --------------------------------------

    local input

    echo
    read -rp "Serial port [$PORT]: " input

    PORT="${input:-$PORT}"

    # --------------------------------------
    # Upload firmware
    # --------------------------------------

    echo
    echo "=========================================="
    echo " Uploading: $EXAMPLE_NAME"
    echo "=========================================="

    echo
    echo "MCU:      $MCU"
    echo "PORT:     $PORT"
    echo "BAUD:     $BAUD"
    echo "Firmware: $HEX_REL"
    echo

    # IMPORTANT:
    # Execute AVRDude from the project root.
    # Use a relative path with forward slashes.
    # Do not pass an absolute C:/... path.

    if (
        cd "$ROOT" &&
        "$AVRDUDE" -v \
            -p "$MCU" \
            -c arduino \
            -P "$PORT" \
            -b "$BAUD" \
            -D \
            -U "flash:w:$HEX_REL:i"
    ); then

        echo
        echo "=========================================="
        echo " UPLOAD SUCCESSFUL"
        echo "=========================================="

    else

        echo
        echo "=========================================="
        echo " UPLOAD FAILED"
        echo "=========================================="

    fi

    pause

}

# ==========================================
# Inspect operation
# ==========================================

inspect_action() {

    select_example || return

    if [[ ! -f "$ELF" ]]; then

        echo
        echo "Firmware not built!"
        echo "Build this example first."

        pause
        return

    fi

    check_inspect_tools || {
        pause
        return
    }

    echo
    echo "=========================================="
    echo " Inspecting: $EXAMPLE_NAME"
    echo "=========================================="

    # --------------------------------------
    # Memory usage
    # --------------------------------------

    echo
    echo "[1] Memory usage"
    echo "------------------------------------------"

    "$SIZE" --format=avr --mcu="$MCU" "$ELF"

    # --------------------------------------
    # Assembly listing
    # --------------------------------------

    echo
    echo "[2] Assembly listing"
    echo "------------------------------------------"

    if "$OBJDUMP" -d -S "$ELF" > "$LIST"; then

        echo "Generated: $LIST"

    else

        echo "Failed to generate assembly listing."

    fi

    # --------------------------------------
    # Build files
    # --------------------------------------

    echo
    echo "[3] Build files"
    echo "------------------------------------------"

    ls -lh "$EXAMPLE_BUILD"

    pause

}

# ==========================================
# Clean build files
# ==========================================

clean_action() {

    echo
    echo "=========================================="
    echo " Cleaning build files"
    echo "=========================================="

    if [[ -d "$BUILD" ]]; then

        rm -rf "$BUILD"

        echo "Build directory removed."

    else

        echo "Nothing to clean."

    fi

    pause

}

# ==========================================
# Main menu
# ==========================================

main_menu() {

    while true; do

        clear

        echo "=========================================="
        echo "          VOLTRINO AVR BUILD SYSTEM"
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
        echo " 1. Build example"
        echo " 2. Upload example"
        echo " 3. Inspect example"
        echo " 4. Clean build files"
        echo " 0. Exit"
        echo

        local choice

        read -rp "Select operation: " choice

        case "$choice" in

            1) build_action ;;
            2) upload_action ;;
            3) inspect_action ;;
            4) clean_action ;;

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

}

# ==========================================
# Start
# ==========================================

main_menu
