
get_latest_selenoid() {
	git_login=$1
	git_password=$2
	url="https://"
	if [ -n "$git_login" ]; then
		url+="$git_login:$git_password@"
	else
		echo "Calling Github API without 'git-login' and 'git_password' can be limited, trying anyway.."
	fi
	url+="api.github.com/repos/aerokube/selenoid/releases/latest"
    echo "$(wget -qO- "$url" | jq -r '.tag_name')"
}

get_latest_geckodriver() {
	git_login=$1
	git_password=$2
	url="https://"
	if [ -n "$git_login" ]; then
		url+="$git_login:$git_password@"
	else
		echo "Calling Github API without 'git-login' and 'git_password' can be limited, trying anyway.."
	fi
	url+="api.github.com/repos/mozilla/geckodriver/releases/latest"
    echo "$(wget -qO- "$url" | jq -r '.tag_name' | awk -F 'v' '{print $2}')"
}

json_conf_file() {
	case $1 in
        -g | --get )
                 	echo $(jq ".$2 // empty" $conf_file | sed 's/\"//g')
                                ;;
        -a | --add | -m | --modify )    
					tmp=$(mktemp /tmp/tmp.XXXX) && jq ".$2 = \"$3\"" $conf_file > "$tmp" && mv "$tmp" $conf_file
                                ;;
        -d | --delete )
					tmp=$(mktemp /tmp/tmp.XXXX) && jq "del(.$2)" $conf_file > "$tmp" && mv "$tmp" $conf_file
                                ;;
    esac
}
