#!/usr/bin/env bash

# author: Gabriel Policeno Miranda <gabriel.policeno@outlook.com.br>
# describe: URL enumeration
# version: 0.1
# license: MIT License


# The function banner prints version and how to use ./url-enum

function banner(){
	printf "\e[34m
 _   _ ____  _       _____                       
| | | |  _ \| |     | ____|_ __  _   _ _ __ ___  
| | | | |_) | |     |  _| | '_ \| | | | '_   _ \ 
| |_| |  _ <| |___  | |___| | | | |_| | | | | | |
 \___/|_| \_\_____| |_____|_| |_|\__,_|_| |_| |_|\n
 \e[32mversion: 0.1
 usage: url-enum https://www.archlinux.org; url-enum http://www.archlinux.org\n"
}

# Print help options, to explain how to use each one

function full_help(){
	printf "
	h: Show full help
	o: Output to file
	O: Use together option -U to output one file for each URLs in file
	u: URL to scan
	U: File with many URLs
	v: Show version\n\n"
}

# under development...
#function output_file(){}

# under development...
#function output_files(){}


function get_urls(){
			wget --no-check-certificate "$2" -O /tmp/source_code

			printf "\e[33m <--- Found URL's --->\n"
	
			awk -F " " '{ for (i=0; i<=NF; i++) print $i }' /tmp/source_code | tr ' ' '\n' | tr '"' '\n' | tr "'" "\n" | grep \:// | sort | uniq
	
			rm -f /tmp/source_code

			return
			}

# under development
#function get_urls_from_file(){}

while getopts "u:hv" OPTION
do
	case "$OPTION" in
		h) full_help
			exit
			;;
		o) output_file
			;;
		O) output_files
			;;
		u) get_urls $@
			;;
		U) get_urls_from_file
			;;
		v) banner
			exit
			;;
		*) "Opção inválida"
			exit 1
			;;
	esac
done
shift "$((OPTIND-1))"
