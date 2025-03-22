#!/usr/bin/env bash

# ======================================
# Advanced URL Enumeration
# Author: Gabriel Policeno
# License: MIT
# ======================================

set -euo pipefail

# =========[ Config ]=========
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"
TMP_DIR="$(mktemp -d)"
DEPTH=1
VISITED=()
OUTPUT_FILE=""
COLOR=true

# =========[ Utils ]=========
color() {
    [[ "$COLOR" == true ]] && echo -e "$1" || echo "$2"
}
log_info() {
    color "\e[34m[INFO]\e[0m $1" "[INFO] $1"
}
log_warn() {
    color "\e[33m[WARN]\e[0m $1" "[WARN] $1"
}
log_error() {
    color "\e[31m[ERROR]\e[0m $1" "[ERROR] $1"
}

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# =========[ HTML Parsing ]=========
extract_urls() {
    grep -Eo 'https?://[^"'"'"'\)\>\s]+' "$1" | sort -u
}

resolve_relative_urls() {
    local base_url="$1"
    local html_file="$2"
    pup 'a attr{href}' < "$html_file" | while read -r path; do
        [[ "$path" =~ ^https?:// ]] && echo "$path" || echo "$base_url/$path"
    done | sort -u
}

# =========[ Classification ]=========
classify_urls() {
    while read -r url; do
        if [[ "$url" =~ \.(jpg|png|js|css|ico|svg|woff|ttf)(\?|$) ]]; then
            echo -e "[STATIC] $url"
        elif [[ "$url" =~ \.(php|asp|aspx|jsp|cgi)(\?|$) ]]; then
            echo -e "[DYNAMIC] $url"
        elif [[ "$url" =~ \.(zip|tar|gz|rar|bak|old|backup) ]]; then
            echo -e "[POTENTIAL BACKUP] $url"
        elif [[ "$url" =~ \? ]]; then
            echo -e "[PARAM] $url"
        else
            echo -e "[OTHER] $url"
        fi
    done
}

# =========[ HTTP Status Checker ]=========
check_status_codes() {
    while read -r url; do
        code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
        echo -e "$code $url"
    done
}

# =========[ Main Enumerator ]=========
fetch_page() {
    local url="$1"
    local out_file="$2"
    curl -s -L -A "$USER_AGENT" --max-time 10 "$url" -o "$out_file"
}

enumerate() {
    local url="$1"
    local current_depth="$2"

    [[ " ${VISITED[*]} " =~ " $url " ]] && return
    VISITED+=("$url")

    log_info "Fetching: $url"
    local html_file="$TMP_DIR/page_${current_depth}.html"

    if ! fetch_page "$url" "$html_file"; then
        log_error "Failed to fetch $url"
        return
    fi

    local urls_file="$TMP_DIR/urls_${current_depth}.txt"
    resolve_relative_urls "$url" "$html_file" > "$urls_file"

    cat "$urls_file"

    if (( current_depth < DEPTH )); then
        while read -r next_url; do
            enumerate "$next_url" $((current_depth + 1))
        done < "$urls_file"
    fi
}
  
# =========[ Banner & Help ]=========
banner() {
    color "\e[36m
 _   _ ____  _     
| | | |  _ \| |    
| | | | |_) | |    
| |_| |  _ <| |___ 
 \___/|_| \_\_____|
                   
 _____                                      _   _             
| ____|_ __  _   _ _ __ ___   ___ _ __ __ _| |_(_) ___  _ __  
|  _| | '_ \| | | | '_ ` _ \ / _ \ '__/ _` | __| |/ _ \| '_ \ 
| |___| | | | |_| | | | | | |  __/ | | (_| | |_| | (_) | | | |
|_____|_| |_|\__,_|_| |_| |_|\___|_|  \__,_|\__|_|\___/|_| |_|
    \e[0m"
}

usage() {
    echo "Usage: $0 -u <URL> [-d depth] [-o output.txt]"
    echo
    echo "Options:"
    echo "  -u <url>      Root URL to scan"
    echo "  -d <depth>    Recursion depth (default: 1)"
    echo "  -o <file>     Output file (optional)"
    echo "  -n            Disable color output"
    echo "  -h            Show help"
    exit 1
}

# =========[ Main ]=========
while getopts ":u:d:o:nh" opt; do
    case $opt in
        u) ROOT_URL="$OPTARG" ;;
        d) DEPTH="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        n) COLOR=false ;;
        h) usage ;;
        *) usage ;;
    esac
done

[[ -z "${ROOT_URL:-}" ]] && usage

banner

RESULTS=$(enumerate "$ROOT_URL" 0 | sort -u)

log_info "\n[+] Classifying URLs..."
echo "$RESULTS" | classify_urls

log_info "\n[+] Checking HTTP Status Codes..."
echo "$RESULTS" | check_status_codes

if [[ -n "$OUTPUT_FILE" ]]; then
    log_info "\n[+] Saving to $OUTPUT_FILE"
    echo "$RESULTS" > "$OUTPUT_FILE"
fi

