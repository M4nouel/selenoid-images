#!/bin/bash
set -e

require_command(){
    cmd_name=$1
    if [ -z $(command -v $1) ]; then
        echo "$1 command required for this script to run"
        exit 1
    fi
}

require_command "awk"
require_command "cut"
require_command "docker"
require_command "jq"
require_command "sed"
require_command "true"
require_command "wget"

conf_file=$1

[ "$#" -ne 1 ] && echo 'Usage: check_json_conf_file.sh <path_to_build_conf_file.json>' && exit 1
[ ! -f "$conf_file" ] && echo 'Configuration file "$conf_file" does not exists' && exit 2

set -x

############# import ###############
##### json_conf_file function ######
## get_latest_geckodriver function #
### get_latest_selenoid function ###
source ../utils/functions.sh
####################################


## BROWSER_LAYER : Checking method, channel and tag version
browser_version=$(json_conf_file -g 'browser_version')
browser_path=$(json_conf_file -g 'browser_path')
tag_version=""

# APT
if [ -n "$browser_version" -a -z "$browser_path" ]; then
	json_conf_file -a 'method' 'apt'
	json_conf_file -a 'cleanup' 'false'

	case $(json_conf_file -g 'channel') in
	    beta)
			json_conf_file -a 'package' 'firefox'
			json_conf_file -a 'ppa' 'ppa:mozillateam/firefox-next'
	        ;;
	    dev)
			json_conf_file -a 'package' 'firefox-trunk'
			json_conf_file -a 'ppa' 'ppa:ubuntu-mozilla-daily/ppa'
	        ;;
	    esr)
			json_conf_file -a 'package' 'firefox-esr'
			json_conf_file -a 'ppa' 'ppa:mozillateam/ppa'
	        ;;
	    *)
			echo "Using default channel"
			json_conf_file -a 'package' 'firefox'
			json_conf_file -d 'channel'
			json_conf_file -d 'ppa'
			;;
	esac

	tag_version=$(echo "$browser_version" | cut -c1-4)
	json_conf_file -a 'tag_version' "$tag_version"

# LOCAL
elif [ -z "$browser_version" -a -n "$browser_path" -a -f "$browser_path" ]; then
	json_conf_file -a 'method' 'local'
	json_conf_file -a 'cleanup' 'true'

	tag_version=$(echo "$browser_path" | awk -F '/' '{print $NF}' | sed 's/^[^_]*_//g' | awk -F '-' '{print $1}' | cut -c1-4)
	json_conf_file -a 'tag_version' "$tag_version"

else
	echo 'Minimal requirements (browser_version|browser_path) error in JSON configuration file'
	exit 3
fi


## DRIVER_LAYER : Checking runner and server
numeric_version=$(echo "$tag_version" | awk -F '.' '{print $1}')
if [ $numeric_version -lt 48 ]; then
	[ -z "$(json_conf_file -g 'sel_server_version')" ] && echo 'Selenium server version is required for older Firefox (<48)' && exit 4
	json_conf_file -a 'runner' 'selenium'
	json_conf_file -a 'requires_java' '_java'
else
	json_conf_file -a 'runner' 'selenoid'
	json_conf_file -d 'requires_java'

	gecko_version=$(json_conf_file -g 'geckodriver_version')
	server_version=$(json_conf_file -g 'sel_server_version')
	git_login=$(json_conf_file -g 'git_login')
	git_password=$(json_conf_file -g 'git_password')

    if [ "$gecko_version" == "latest" -o -z "$gecko_version" ]; then
        echo 'Finding Driver version for geckodriver:latest'
        json_conf_file -m 'geckodriver_version' "$(get_latest_geckodriver $git_login $git_password)"
    fi

    if [ "$server_version" == "latest" -o -z "$server_version" ]; then
    	echo "Finding server version number for selenoid:latest"
        json_conf_file -m 'sel_server_version' "$(get_latest_selenoid $git_login $git_password)"
    fi
fi

if [ "$DISABLE_DOCKER_CACHE" == "true" ]; then
    json_conf_file -a 'dck_extra_args' ' --no-cache'
fi
