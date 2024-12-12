#!/usr/bin/env bash

# author: Gabriel Policeno Miranda <gabriel.policeno@outlook.com.br>
# describe: URL enumeration
# version: 0.2
# license: MIT License

function banner(){
	printf "\e[34m
 _   _ ____  _       _____                       
| | | |  _ \| |     | ____|_ __  _   _ _ __ ___  
| | | | |_) | |     |  _| | '_ \| | | | '_   _ \ 
| |_| |  _ <| |___  | |___| | | | |_| | | | | | |
 \___/|_| \_\_____| |_____|_| |_|\__,_|_| |_| |_|\n
 \e[32mversion: 0.2
 usage: url-enum -u https://www.archlinux.org\n"
}

function full_help(){
	printf "
	Options:
	-h: Show full help
	-o: Output to file
	-O: Use together with -U to output one file for each URL in file
	-u: URL to scan
	-U: File with many URLs
	-v: Show version
	
	Examples:
	./url-enum -u https://example.com
	./url-enum -U urls.txt -O output_dir\n\n"
}

# Function to fetch URLs from a single URL
function get_urls(){
	local url=$1
	echo -e "\e[33m<--- Fetching URLs from: $url --->\e[0m"
	wget --no-check-certificate "$url" -O /tmp/source_code 2>/dev/null || {
		echo "Error: Unable to fetch $url"
		return 1
	}

	# Extract URLs and display them in the terminal
	grep -Eo '(http|https)://[^"]+' /tmp/source_code | sort -u
	rm -f /tmp/source_code
}

# Function to read URLs from a file and pass them to get_urls
function get_urls_from_file(){
	local file=$1
	if [[ ! -f "$file" ]]; then
		echo "Error: File $file not found."
		return 1
	fi

	# For each line in the file, call get_urls passing the URL
	while IFS= read -r url; do
		# Check if the line is not empty
		if [[ -n "$url" ]]; then
			get_urls "$url"
		fi
	done < "$file"
}

# Placeholder functions for future development
function output_file(){
	echo "Output to single file not implemented yet."
}

function output_files(){
	echo "Output to multiple files not implemented yet."
}

while getopts "u:U:hov" OPTION; do
	case "$OPTION" in
		h) full_help
			exit
			;;
		o) output_file
			;;
		O) output_files
			;;
		u) get_urls "$OPTARG"
			;;
		U) get_urls_from_file "$OPTARG"
			;;
		v) banner
			exit
			;;
		*) echo "Invalid option."
			exit 1
			;;
	esac
done
shift "$((OPTIND-1))"
