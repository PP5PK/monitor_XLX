#!/bin/bash
# Script for monitoring the xlxd service and sending Telegram notifications
# Monitors Gatekeeper block events, and connect/disconnect events for specific repeaters

# Check if curl is installed
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is not installed. Please install it to continue."
    exit 1
fi

# Load configuration
source /usr/local/bin/monitor_XLX_data

# Temporary file to store recent events and prevent duplicate messages
TEMP_FILE="/tmp/xlxd_last_events"
touch "$TEMP_FILE"

# Regexes for log parsing
REGEX_GATEKEEPER="^([A-Za-z]{3} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2}).*Gatekeeper blocking (linking|transmitting) of ([A-Za-z0-9]{3,8})([[:space:]]*/?[[:space:]]*[A-Za-z0-9/ ]{0,4})?[[:space:]]+@ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) using protocol (-?[0-9]+)"
REGEX_CONNECT="^([A-Za-z]{3} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2}).*New client ($REPEATER_LIST)([[:space:]]*[A-Za-z0-9]{0,4})? at ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) added with protocol ([A-Za-z]+)( on module ([A-Za-z]))?"
REGEX_DISCONNECT="^([A-Za-z]{3} [0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2}).*Client ($REPEATER_LIST)([[:space:]]*[A-Za-z0-9]{0,4})? at ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) removed with protocol ([A-Za-z]+)( on module ([A-Za-z]))?"

# Debug function
debug() {
    if [[ "$DEBUG" -eq 1 ]]; then
        echo "DEBUG: $@"
    fi
}

# Convert timestamp from syslog format "Feb 22 20:30:07" to "22/02/2025 20:30:07"
format_timestamp() {
    local TIMESTAMP_ORIGINAL="$1"
    MONTH=$(echo "$TIMESTAMP_ORIGINAL" | cut -d' ' -f1)
    DAY=$(echo "$TIMESTAMP_ORIGINAL" | cut -d' ' -f2)
    TIME=$(echo "$TIMESTAMP_ORIGINAL" | cut -d' ' -f3)
    YEAR=$(date +%Y)
    case "$MONTH" in
        Jan) MONTH_NUMBER="01" ;;
        Feb) MONTH_NUMBER="02" ;;
        Mar) MONTH_NUMBER="03" ;;
        Apr) MONTH_NUMBER="04" ;;
        May) MONTH_NUMBER="05" ;;
        Jun) MONTH_NUMBER="06" ;;
        Jul) MONTH_NUMBER="07" ;;
        Aug) MONTH_NUMBER="08" ;;
        Sep) MONTH_NUMBER="09" ;;
        Oct) MONTH_NUMBER="10" ;;
        Nov) MONTH_NUMBER="11" ;;
        Dec) MONTH_NUMBER="12" ;;
    esac
    echo "$DAY/$MONTH_NUMBER/$YEAR $TIME"
}

# Map protocol number to human-readable name
get_protocol_name() {
    local PROTOCOL="$1"
    case "$PROTOCOL" in
        "1") echo "DExtra" ;;
        "2") echo "DPlus" ;;
        "3") echo "DCS" ;;
        "4") echo "XLX Interlink" ;;
        "5") echo "DMR+" ;;
        "6") echo "DMR MMDVM" ;;
        "7") echo "YSF" ;;
        "8") echo "ICom G3" ;;
        "9") echo "IMRS" ;;
        *) echo "Unknown" ;;
    esac
}

# Format message with QRZ.com hyperlink
format_message() {
    local TIMESTAMP="$1" CALLSIGN="$2" SUFFIX="$3" IP="$4" PROTOCOL="$5" ACTION="$6" MODULE="$7"
    SUFFIX=$(echo "$SUFFIX" | sed 's/^\s*\/\s*//;s/^\s*//;s/\s*$//')
    if [ -z "$SUFFIX" ]; then
        echo "$TIMESTAMP - Repeater <a href=\"https://www.qrz.com/db/$CALLSIGN\">$CALLSIGN</a>, IP $IP ($PROTOCOL) - $ACTION${MODULE:+-}$MODULE"
    else
        echo "$TIMESTAMP - Repeater <a href=\"https://www.qrz.com/db/$CALLSIGN\">$CALLSIGN</a>/$SUFFIX, IP $IP ($PROTOCOL) - $ACTION${MODULE:+-}$MODULE"
    fi
}

# Send message to Telegram (receives CALLSIGN as second argument for the preview card, if enabled)
send_telegram_message() {
    local MESSAGE="$1"
    local CALLSIGN="$2"
    local PREVIEW_OPTIONS
    if [[ "$ENABLE_PREVIEW" -eq 1 ]]; then
        PREVIEW_OPTIONS='{"url": "https://www.qrz.com/db/'"$CALLSIGN"'", "is_disabled": false, "prefer_large_media": true}'
    else
        PREVIEW_OPTIONS='{"is_disabled": true}'
    fi
    debug "Sending message: $MESSAGE with preview options: $PREVIEW_OPTIONS"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_API/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$MESSAGE" \
        -d parse_mode=HTML \
        -d link_preview_options="$PREVIEW_OPTIONS"
}

# Continuously read lines from journalctl for the xlxd service
sudo journalctl -u xlxd.service -f | while read -r LINE; do
    debug "Captured line: $LINE"

    # Check for Gatekeeper block events
    if [[ "$LINE" =~ $REGEX_GATEKEEPER ]]; then
        TIMESTAMP_ORIGINAL="${BASH_REMATCH[1]}"
        ACTION="${BASH_REMATCH[2]}"
        CALLSIGN="${BASH_REMATCH[3]}"
        SUFFIX="${BASH_REMATCH[4]}"
        IP="${BASH_REMATCH[5]}"
        PROTOCOL="${BASH_REMATCH[6]}"

        debug "Gatekeeper: Timestamp: $TIMESTAMP_ORIGINAL, Action: $ACTION, Callsign: $CALLSIGN, Suffix: '$SUFFIX', IP: $IP, Protocol: $PROTOCOL"

        # Clean up the suffix
        SUFFIX=$(echo "$SUFFIX" | sed 's/^\s*\/\s*//;s/^\s*//;s/\s*$//')

        TIMESTAMP_FORMATTED=$(format_timestamp "$TIMESTAMP_ORIGINAL")
        PROTOCOL_NAME=$(get_protocol_name "$PROTOCOL")
        ACTION_LABEL=$([[ "$ACTION" == "linking" ]] && echo "Connection attempt on XLX300" || echo "Transmission attempt on XLX300")
        if [ -z "$SUFFIX" ]; then
            MESSAGE="$TIMESTAMP_FORMATTED - <a href=\"https://www.qrz.com/db/$CALLSIGN\">$CALLSIGN</a>, IP $IP ($PROTOCOL_NAME) - $ACTION_LABEL"
        else
            MESSAGE="$TIMESTAMP_FORMATTED - <a href=\"https://www.qrz.com/db/$CALLSIGN\">$CALLSIGN</a>/$SUFFIX, IP $IP ($PROTOCOL_NAME) - $ACTION_LABEL"
        fi

        CURRENT_TIME=$(date +%s)
        BLOCK_EVENT=false

        if [[ "$ACTION" == "transmitting" ]]; then
            LAST_EVENT=$(grep "^$CALLSIGN transmitting " "$TEMP_FILE" | awk '{print $3}' | tail -n1)
            if [[ -n "$LAST_EVENT" && $((CURRENT_TIME - LAST_EVENT)) -lt 30 ]]; then
                debug "Suppressing duplicate transmitting notification for $CALLSIGN (within 30 seconds)."
                BLOCK_EVENT=true
            else
                echo "$CALLSIGN transmitting $CURRENT_TIME" >> "$TEMP_FILE"
            fi
        fi

        if [[ "$ACTION" == "linking" ]]; then
            LAST_EVENT=$(grep "^$CALLSIGN linking $PROTOCOL_NAME" "$TEMP_FILE" | awk '{print $4}' | tail -n1)
            if [[ -n "$LAST_EVENT" && $((CURRENT_TIME - LAST_EVENT)) -lt 15 ]]; then
                debug "Suppressing duplicate linking notification for $CALLSIGN ($PROTOCOL_NAME) (within 15 seconds)."
                BLOCK_EVENT=true
            else
                echo "$CALLSIGN linking $PROTOCOL_NAME $CURRENT_TIME" >> "$TEMP_FILE"
            fi
        fi

        if [[ "$CALLSIGN" == "PP0AA" ]]; then
            debug "Ignoring event for PP0AA."
            continue
        fi

        if [[ "$BLOCK_EVENT" == false ]]; then
            send_telegram_message "$MESSAGE" "$CALLSIGN"
        fi

        tail -n 100 "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"

    # Check for repeater connect events
    elif [[ "$LINE" =~ $REGEX_CONNECT ]]; then
        TIMESTAMP_ORIGINAL="${BASH_REMATCH[1]}"
        CALLSIGN="${BASH_REMATCH[2]}"
        SUFFIX="${BASH_REMATCH[3]}"
        IP="${BASH_REMATCH[4]}"
        PROTOCOL="${BASH_REMATCH[5]}"
        MODULE="${BASH_REMATCH[7]:-}"

        debug "Connect: Timestamp: $TIMESTAMP_ORIGINAL, Callsign: $CALLSIGN, Suffix: '$SUFFIX', IP: $IP, Protocol: $PROTOCOL, Module: '$MODULE'"

        TIMESTAMP_FORMATTED=$(format_timestamp "$TIMESTAMP_ORIGINAL")
        MESSAGE=$(format_message "$TIMESTAMP_FORMATTED" "$CALLSIGN" "$SUFFIX" "$IP" "$PROTOCOL" "Connected to XLX300" "$MODULE")
        send_telegram_message "$MESSAGE" "$CALLSIGN"

    # Check for repeater disconnect events
    elif [[ "$LINE" =~ $REGEX_DISCONNECT ]]; then
        TIMESTAMP_ORIGINAL="${BASH_REMATCH[1]}"
        CALLSIGN="${BASH_REMATCH[2]}"
        SUFFIX="${BASH_REMATCH[3]}"
        IP="${BASH_REMATCH[4]}"
        PROTOCOL="${BASH_REMATCH[5]}"
        MODULE="${BASH_REMATCH[7]:-}"

        debug "Disconnect: Timestamp: $TIMESTAMP_ORIGINAL, Callsign: $CALLSIGN, Suffix: '$SUFFIX', IP: $IP, Protocol: $PROTOCOL, Module: '$MODULE'"

        TIMESTAMP_FORMATTED=$(format_timestamp "$TIMESTAMP_ORIGINAL")
        MESSAGE=$(format_message "$TIMESTAMP_FORMATTED" "$CALLSIGN" "$SUFFIX" "$IP" "$PROTOCOL" "Disconnected from XLX300" "$MODULE")
        send_telegram_message "$MESSAGE" "$CALLSIGN"

    else
        debug "Line did not match any regex."
    fi
done
