#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

#=======================================
# Functions
#=======================================

RESTORE='\033[0m'
RED='\033[00;31m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
GREEN='\033[00;32m'

function color_echo {
	color=$1
	msg=$2
	echo -e "${color}${msg}${RESTORE}"
}

function echo_fail {
	msg=$1
	echo
	color_echo "${RED}" "${msg}"
	exit 1
}

function echo_warn {
	msg=$1
	color_echo "${YELLOW}" "${msg}"
}

function echo_info {
	msg=$1
	echo
	color_echo "${BLUE}" "${msg}"
}

function echo_details {
	msg=$1
	echo "  ${msg}"
}

function echo_done {
	msg=$1
	color_echo "${GREEN}" "  ${msg}"
}

function validate_required_input {
	key=$1
	value=$2
	if [ -z "${value}" ] ; then
		echo_fail "[!] Missing required input: ${key}"
	fi
}

function validate_required_input_with_options {
	key=$1
	value=$2
	options=$3

	validate_required_input "${key}" "${value}"

	found="0"
	for option in "${options[@]}" ; do
		if [ "${option}" == "${value}" ] ; then
			found="1"
		fi
	done

	if [ "${found}" == "0" ] ; then
		echo_fail "Invalid input: (${key}) value: (${value}), valid options: ($( IFS=$", "; echo "${options[*]}" ))"
	fi
}

function validate_same_number_of_values {
  key1=$1
  key2=$2
  size1=$3
  size2=$4
  [ $size1 == $size2 ] || echo_fail "Invalid input: $key1 and $key2 must have the same number of values"
}

function trim_string {
  result=`echo -n $1 | xargs`
  echo $result
}

#=======================================
# Main
#=======================================

#
# Validate parameters
echo_info "Configs:"
echo_details "* target: $target"
echo_details "* configuration: $configuration"
echo_details "* xcode_setting_keys: $xcode_setting_keys"
echo_details "* new_values: $new_values"

validate_required_input "xcode_project_path" $xcode_project_path
validate_required_input "target" $target
validate_required_input "configuration" $configuration
validate_required_input "xcode_setting_keys" $xcode_setting_keys
validate_required_input "new_values" $new_values

IFS="|"
keys=($xcode_setting_keys)
values=($new_values)
unset IFS
validate_same_number_of_values "xcode_setting_keys" "new_values" ${#keys[@]} ${#values[@]}

# this expansion is required for paths with ~
#  more information: http://stackoverflow.com/questions/3963716/how-to-manually-expand-a-special-variable-ex-tilde-in-bash
eval expanded_xcode_project_path="${xcode_project_path}"

if [ ! -e "${expanded_xcode_project_path}/project.pbxproj" ]; then
  echo_fail "No valid Xcode project found at path: ${expanded_xcode_project_path}"
fi

echo_info "Preparing bundle environment"
bundle
echo_info "Installing required gem: xcodeproj"
bundle exec gem install xcodeproj

for (( i=0; i<${#keys[@]}; i++ )); do
  key=$(trim_string "${keys[i]}")
  value=$(trim_string "${values[i]}")
  bundle exec ruby "${THIS_SCRIPT_DIR}/xcodeproj_settings.rb" "$expanded_xcode_project_path" \
	"$target" \
	"$configuration" \
	"$key" \
	"$value"

  echo_info "Updated key '$key' to '$value'"
done
