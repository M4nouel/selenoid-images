#!/bin/bash
set -e

require_command(){
    cmd_name=$1
    if [ -z $(command -v $1) ]; then
        echo "$1 command required for this script to run"
        exit 1
    fi
}

require_command "docker"
require_command "sed"
require_command "jq"
require_command "true"
require_command "awk"
require_command "realpath"

conf_file=$1

[ "$#" -ne 1 ] && echo 'Usage: gen_Dockerfile.sh <path_to_build_conf_file.json>' && exit 1
[ ! -f "$conf_file" ] && echo 'Configuration file "$conf_file" does not exist' && exit 2

set -x


######### Checks conf file #########
######### AND COMPLETES IT #########
./check_json_conf_file.sh $conf_file
####################################

## import json_conf_file function ##
source ../utils/functions.sh
####################################


# Creates build diretory
[ -z "$(json_conf_file -g 'build_directory')" ] && json_conf_file -a 'build_directory' '../target/firefox'
build_directory=$(json_conf_file -g 'build_directory')

echo "Build diretory : $build_directory"
if [ -d "$build_directory" ]; then
    rm -Rf $build_directory/*
else
    mkdir -p $build_directory
fi

# Copies Dockerfile resources to build directory
if [ "$(json_conf_file -g 'runner')" == "selenoid" ]; then
    cp resources/browsers.json.j2 resources/selenoid_entrypoint.sh $build_directory
else
    cp resources/download_selenium_server.sh resources/selenium_entrypoint.sh $build_directory
fi

if [ "$(json_conf_file -g 'method')" == "local" ]; then
    browser_path=$(json_conf_file -g 'browser_path')
    cp $browser_path $build_directory
    json_conf_file -a 'browser_file_name' $(echo "$browser_path" | awk -F '/' '{print $NF}')
fi
cp $conf_file resources/Dockerfile.j2 $build_directory


# Templates Processing
if [ -z $(command -v j2) ]; then
    echo "Will run j2cli templating inside Docker container..."

    img_name="selenoid/utils:latest"
    docker build --build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy -t $img_name ../utils

    # Log the img built for later delete
    docker images $img_name --format "{{.ID}} {{.Repository}}:{{.Tag}}" >> $build_directory/docker_images_built.log

    build_directory_real_path=$(json_conf_file -g 'docker_nested_build_project_real_path')
    if [ -z "$build_directory_real_path" ]; then
        build_directory_real_path=$(realpath $build_directory)
    else
        build_directory_real_path+="/target/firefox"
    fi

    docker run --rm -v $build_directory_real_path:/tmp $img_name \
        j2 --undefined Dockerfile.j2 $conf_file -o Dockerfile
    [ "$(json_conf_file -g 'runner')" == "selenoid" ] && \
    docker run --rm -v $build_directory_real_path:/tmp $img_name \
        j2 --undefined browsers.json.j2 $conf_file -o browsers.json
else
    j2 --undefined $build_directory/Dockerfile.j2 $build_directory/$conf_file -o $build_directory/Dockerfile
    [ "$(json_conf_file -g 'runner')" == "selenoid" ] && \
    j2 --undefined $build_directory/browsers.json.j2 $build_directory/$conf_file -o $build_directory/browsers.json
fi
rm $build_directory/*.j2
