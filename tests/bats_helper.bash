#!/bin/bash


function append_project_configuration {
	if [ -z "$BATS_IMPORT_DEV_ORB" ]; then
		echo "#Using \`inline\` orb assembly, to test against published orb, set BATS_IMPORT_DEV_ORB to fully qualified path" >&3
		assemble_inline $1
	else
		echo "#BATS_IMPORT_DEV_ORB env var is set, all config will be tested against imported orb $BATS_IMPORT_DEV_ORB" >&3
		assemble_external $1
	fi
}

#
#  USes circleci config pack, but indents everything under an `orbs.ORBNAME` element so it may be inlined.
#
function assemble_inline {
	CONFIG=$1
	echo "version: 2.1" 
	echo "orbs:"
	echo "  ${INLINE_ORB_NAME}:"
	circleci config pack src | sed -e 's/^/    /'
	if [ -s $CONFIG ];then
		cat $CONFIG
	fi
}


#
#   Adds `orbs:` section referencing the provided dev orb
#
function assemble_external {
	CONFIG=$1
	echo "version: 2.1"
	echo "orbs:" 
	echo "  ${INLINE_ORB_NAME}: $BATS_IMPORT_DEV_ORB"  
	if [ -s $CONFIG ];then
		cat $CONFIG
	fi
}


#
#  Add assertions for use in BATS tests
#

function assert_contains_text {
	TEXT=$1
	if [[ "$output" != *"${TEXT}"* ]]; then
		echo "Expected text \`$TEXT\`, not found in output (printed below)"
		echo $output
		return 1
	fi		
}

function assert_text_not_found {
	TEXT=$1
	if [[ "$output" == *"${TEXT}"* ]]; then
		echo "Forbidden text \`$TEXT\`, was found in output.."
		echo $output
		return 1
	fi		
}

function assert_matches_file {
	FILE=$1

	echo "${output}" | sed '/# Original config.yml file:/q' | sed '$d' | diff -B $FILE -
	return $?
}


