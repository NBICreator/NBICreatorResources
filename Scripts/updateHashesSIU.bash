#!/bin/bash

### Version 1.0
### Created by Erik Berglund
### https://github.com/erikberglund

#//////////////////////////////////////////////////////////////////////////////////////////////////
###
### DESCRIPTION
###
#//////////////////////////////////////////////////////////////////////////////////////////////////

# This script is designed to create an md5 hashes for all scripts in SIUFoundation.framework

#//////////////////////////////////////////////////////////////////////////////////////////////////
###
### VARIABLES
###
#//////////////////////////////////////////////////////////////////////////////////////////////////

relativePath_SIUAgent="Versions/A/XPCServices/com.apple.SIUAgent.xpc"
relativePath_SIUAgentResources="${relativePath_SIUAgent}/Contents/Resources"

#//////////////////////////////////////////////////////////////////////////////////////////////////
###
### FUNCTIONS
###
#//////////////////////////////////////////////////////////////////////////////////////////////////

printError() {
	printf "\t%s\n" "${1}"
}

updateVariables() {
	
	# Verify that passed SIUFoundation root folder exists and is a folder
	if [[ -d ${path_SIUFoundation} ]]; then
		path_SIUAgent="${path_SIUFoundation}/${relativePath_SIUAgent}"
		path_SIUAgentResources="${path_SIUFoundation}/${relativePath_SIUAgentResources}"
	else
		printError "No such file or directory: ${path_SIUFoundation}"
		exit 1
	fi
}

updateVersions() {
	
	# Set path to SIUFoundation version.plist
	path_SIUFoundationVersionPlist="${path_SIUFoundation}/Resources/version.plist"
	
	if [[ -f ${path_SIUFoundationVersionPlist} ]]; then
	
		# Get SIUFoundation BundleVersion
		siuFoundationBundleVersion=$( /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${path_SIUFoundationVersionPlist}" 2>&1 )
		if (( ${?} != 0 )) || [[ ${siuFoundationBundleVersion} =~ "Does Not Exist" ]]; then
			printError "${siuFoundationBundleVersion}"
			exit 1
		fi
	
		# Get SIUFoundation BuildVersion
		siuFoundationBuildVersion=$( /usr/libexec/PlistBuddy -c "Print :BuildVersion" "${path_SIUFoundationVersionPlist}" 2>&1 )
		if (( ${?} != 0 )) || [[ ${siuFoundationBundleVersion} =~ "Does Not Exist" ]]; then
			printError "${siuFoundationBuildVersion}"
			exit 1
		fi
	
		# Set SIUFoundation Version to "BundleVersion-BuildVersion"
		siuFoundationVersion="${siuFoundationBundleVersion}-${siuFoundationBuildVersion}"
	else
		printError "No such file or directory: ${path_SIUFoundationVersionPlist}"
		exit 1
	fi
	
	# Set path to SIUAgent version.plist
	path_SIUAgentVersionPlist="${path_SIUAgent}/Contents/version.plist"

	if [[ -f ${path_SIUAgentVersionPlist} ]]; then
		
		# Get SIUAgent BundleVersion
		siuAgentBundleVersion=$( /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${path_SIUAgentVersionPlist}" 2>&1 )
		if (( ${?} != 0 )) || [[ ${siuAgentBundleVersion} =~ "Does Not Exist" ]]; then
			printError "${siuAgentBundleVersion}"
			exit 1
		fi
	
		# Get SIUAgent BuildVersion
		siuAgentBuildVersion=$( /usr/libexec/PlistBuddy -c "Print :BuildVersion" "${path_SIUAgentVersionPlist}" 2>&1 )
		if (( ${?} != 0 )) || [[ ${siuAgentBuildVersion} =~ "Does Not Exist" ]]; then
			printError "${siuAgentBuildVersion}"
			exit 1
		fi
	
		# Set SIUAgent Version to "BundleVersion-BuildVersion"
		siuAgentVersion="${siuAgentBundleVersion}-${siuAgentBuildVersion}"
	else
		printError "No such file or directory: ${path_SIUAgentVersionPlist}"
		exit 1
	fi

	if [[ -d /Users/Shared ]] && [[ -w /Users/Shared ]]; then
		path_hashPlist="/Users/Shared/siu_${osVersion}-${siuFoundationVersion}_hashes.plist"
	else
		printError "Neither ~/Desktop or /Users/Shared exists and/or is writeable!"
		exit 1
	fi
}

prepareHashPlist() {

	local plistBuddyOutput=$( /usr/libexec/PlistBuddy -c "Add :${osVersionMajorMinor} dict" "${path_hashPlist}" 2>&1 )
	if (( ${?} != 0 )); then
		printError "${plistBuddyOutput}"
		exit 1
	fi
	
	local plistBuddyOutput=$( /usr/libexec/PlistBuddy -c "Add :${osVersionMajorMinor}:${siuFoundationVersion} dict" "${path_hashPlist}" 2>&1 )
	if (( ${?} != 0 )); then
		printError "${plistBuddyOutput}"
		exit 1
	fi

}

md5HashOfFileAtPath() {

	# 1 - Path to file to hash
	# Verify passed file exist
	if [[ -f ${1} ]]; then
		local path_fileToHash="${1}"
	else
		printError "No such file or directory: ${1}"
		exit 1
	fi

	# Bash functions can only return exit status.
	# Therefore if it's echoed it can be assigned if used in a subshell.
	echo $( /sbin/md5 -q "${path_fileToHash}" )
}

updateHashForTool() {
	unset OPTIND;
	while getopts "n:5:" opt; do
		case ${opt} in
			5)	local _md5="${OPTARG}" ;;
			n)	local _name="${OPTARG}" ;;
			\?)	exit 1 ;;
			:) exit 1 ;;
		esac
	done
	
	# Verify a name was passed
	if [[ -z ${_name} ]]; then
		printError "No name passed to ${FUNCNAME}"
		exit 1
	fi
		
	# Create entry for executable in hashPlist if it doesn't exist
	if ! /usr/libexec/PlistBuddy -c "Print :${_name}" "${path_hashPlist}" >/dev/null 2>&1; then
		printf "%s\n" "Adding hash dict for: ${_name}"
		local plistBuddyOutput=$( /usr/libexec/PlistBuddy -c "Add :${osVersionMajorMinor}:${siuFoundationVersion}:${_name} dict" "${path_hashPlist}" 2>&1 )
		if (( ${?} != 0 )); then
			printError "${plistBuddyOutput}"
			exit 1
		fi
	fi
	
	# Check if an entry already exist for md5
	if [[ -n ${_md5} ]]; then
		local currentmd5=$( /usr/libexec/PlistBuddy -c "Print :${osVersionMajorMinor}:${siuFoundationVersion}:${_name}:md5" "${path_hashPlist}" 2>&1 )
		
		# If no current md5 hash exist, set it. Else only update if it has changed.
		if [[ ${currentmd5} =~ "Does Not Exist" ]]; then
			printf "%s\n" "Adding md5 hash for: ${_name} -> ${_md5}"
			local plistBuddyOutput=$( /usr/libexec/PlistBuddy -c "Add :${osVersionMajorMinor}:${siuFoundationVersion}:${_name}:md5 string ${_md5}" "${path_hashPlist}" 2>&1 )
			if (( ${?} != 0 )); then
				printError "${plistBuddyOutput}"
				exit 1
			fi
		elif [[ ${currentmd5} != ${_md5} ]]; then
			printf "%s\n" "Updating md5 hash for: ${_name} -> ${_md5}"
			local plistBuddyOutput=$( /usr/libexec/PlistBuddy -c "Set :${osVersionMajorMinor}:${siuFoundationVersion}:${_name}:md5 ${_md5}" "${path_hashPlist}" 2>&1 )
			if (( ${?} != 0 )); then
				printError "${plistBuddyOutput}"
				exit 1
			fi
		fi
	fi
}

#//////////////////////////////////////////////////////////////////////////////////////////////////
###
### MAIN SCRIPT
###
#//////////////////////////////////////////////////////////////////////////////////////////////////

# Get current os version
osVersion=$( /usr/bin/sw_vers -productVersion )
osVersionMajorMinor=$( /usr/bin/awk -F'.' '{ print $1"."$2 }' <<< ${osVersion} )

# Set SIUFoundation path for current os version
if [[ "${osVersion}" =~ ^10.11.* ]]; then
	path_SIUFoundation="/System/Library/PrivateFrameworks/SIUFoundation.framework"
elif [[ "${osVersion}" =~ ^10.10.* ]]; then
	path_SIUFoundation="/System/Library/CoreServices/Applications/System Image Utility.app/Contents/Frameworks/SIUFoundation.framework"
else
	path_SIUFoundation="/System/Library/CoreServices/System Image Utility.app/Contents/Frameworks/SIUFoundation.framework"
fi

# Set SIUAgentResources path
updateVariables

# Verify path to SIUAgentResources exist
if [[ ! -d ${path_SIUAgentResources} ]]; then
	printError "No such file or directory: ${path_SIUAgentResources}"
	exit 1
fi

# Set SIUFoundation and SIUAgent versuib
updateVersions

# Remove any previous hash-plist
if [[ -f ${path_hashPlist} ]] && [[ ${path_hashPlist} =~ ^/Users/Shared/.* ]]; then
	rm "${path_hashPlist}"
fi

# Setup hash plist for current SIUVersion
prepareHashPlist

# Loop through all items in SIUAgentResources
for item in "${path_SIUAgentResources}"/*; do
	
	# Verify item is a file and that it's a script ( end with .sh )
	if [[ -f ${item} ]] && [[ ${item} =~ .*\.sh ]]; then
		item_name=$( basename "${item}" )
		
		# Calculate item's md5 hash
		item_md5=$( md5HashOfFileAtPath "${item}" )
		
		# Update hashesPlist with item's hashes
		updateHashForTool -n "${item_name}" -5 "${item_md5}"
	fi
done