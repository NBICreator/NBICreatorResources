#!/bin/bash

checkCommand="/Users/erikberglund/GitHub/Scripts/Tools/sharedLibraryDependencyChecker.bash"
path_tmpCheckCommandVariables="/tmp/${0##*/}_variables"
path_output="/tmp/${0##*/}_out.txt"

fillVolume="/Users/erikberglund/Documents/NBICreator/DeployStudio/sysBuilder/1.6.16/sysBuilder/10.10/fill_volume.sh"
prefix="<string>.*"
suffix=".*</string>"


declare -ar dependencyVariables=( 'ETC_CONF' 'ROOT_BIN' 'USR_BIN' 'USR_SBIN' 'USR_LIB' 'USR_SHARE' 'USR_LIBEXEC' 'LIB_MISC' 'SYS_LIB_MISC' 'SYS_LIB_CORE' 'MENU_EXTRAS' 'GRAPHICS_EXT' 'SYS_LIB_EXT' 'SYS_LIB_EXT_PLUG' 'SYS_LIB_FRK' )

for variable in ${dependencyVariables[@]}; do
	all=$( /usr/bin/sed -nE "/^${variable}=(\"|\`.*-.)/,/add_files_at_path/p" "${fillVolume}" | /usr/bin/sed -E 's/([ ]{2,}|'"${variable}"'=("|`)|\*|ls -d|["`]$)//g' | /usr/bin/awk '{if (sub(/\\$/,"")) printf "%s", $0; else print $0}' )
	folder=$( /usr/bin/sed -nE 's/^add_files_at_path.*([ ]|")(\/[^.]*)([ ]\..*|$)/\2/p' <<< "${all}" )
	extension=$( /usr/bin/sed -nE 's/^add_files_at_path.*([ ]|")(\/[^.]*)[ ](\..*|$)/\3/p' <<< "${all}" )
	for item in $( /usr/bin/sed -n "1{p;q;}" <<< "${all}" ); do
		sharedLibraryDependencyCheckerArgs+=( "-t ${folder}/${item}${extension}" )
	done
done

"${checkCommand}" -a -X ${sharedLibraryDependencyCheckerArgs[*]} 2>&1 > "${path_output}"

for item in $( /usr/bin/sed -nE 's/^add_file_at_path\ ([^"].*)/\1/p' "${fillVolume}" | /usr/bin/awk '{ print $2$1 }' ); do
	printf "%s\n" "${prefix}${item}${suffix}" >> ${path_output}
done

for item in $( /usr/bin/sed -nE 's/.*(ditto|cp).*{BASE_SYSTEM_ROOT_PATH}["]([/][^ ].*) .*/\2/p' "${fillVolume}" ); do
	printf "%s\n" "${prefix}${item}${suffix}" >> ${path_output}
done

exit 0