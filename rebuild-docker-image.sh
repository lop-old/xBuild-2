#!/bin/bash
clear

# source /usr/bin/shellscripts/common.sh


# function docker_image_exists() {
#	image_and_tag_array=(${1//:/ })
#	# image
#	if [ -z ${image_and_tag_array[1]} ]; then
#		if [[ "$(docker images -q ${image_and_tag_array[0]} 2>/dev/null)" == "" ]]; then
#			return 1
#		else
#			return 0
#		fi
#		# image:tag
#	else
#		if [[ "$(docker images ${image_and_tag_array[0]} 2>/dev/null | tail -n +2 | grep ${image_and_tag_array[1]})" == "" ]]; then
#			return 1
#		else
#			return 0
#		fi
#	fi
# }


# build xBuild image
docker build -t poixson/xbuild:0.1.0 .
docker tag -f poixson/xbuild:0.1.0 poixson/xbuild:latest

