#!/bin/bash
set -e

selenium_version=$1
url=""
case "$selenium_version" in
    "2.15.0" | "2.19.0" | "2.20.0" | "2.21.0" | "2.25.0" | "2.32.0" | "2.35.0" | "2.37.0" | "2.39.0" | "2.40.0" | "2.41.0" | "2.43.1" | "2.44.0" | "2.45.0" | "2.48.2")
        url="https://repo.jenkins-ci.org/releases/org/seleniumhq/selenium/selenium-server-standalone/$selenium_version/selenium-server-standalone-$selenium_version.jar"
        ;;
    "2.47.1")
        url="http://selenium-release.storage.googleapis.com/2.47/selenium-server-standalone-2.47.1.jar"
        ;;
    "2.53.1")
        url="http://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.1.jar"
        ;;
    "3.2.0")
        url="http://selenium-release.storage.googleapis.com/3.2/selenium-server-standalone-3.2.0.jar"
        ;;
    "3.3.1")
        url="http://selenium-release.storage.googleapis.com/3.3/selenium-server-standalone-3.3.1.jar"
        ;;
    "3.4.0")
        url="https://selenium-release.storage.googleapis.com/3.4/selenium-server-standalone-3.4.0.jar"
        ;;
    *)
        echo "Unsupported Selenium version: $selenium_version"
        exit 1
        ;;
esac
target_dir="/usr/share/selenium"
[ ! -d "$target_dir" ] && mkdir -p $target_dir
wget -O $target_dir/selenium-server-standalone.jar "$url"
