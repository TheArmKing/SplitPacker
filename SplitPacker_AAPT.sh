#!/bin/bash
print_error(){
    echo -en "\x1B[0;49;91m==>\x1B[0m \x1B[1m${1}…\x1B[0m\n"
    exit
}
apktool_custom() {
    echo -en "\x1B[0;49;34m==>\x1B[0m \x1B[1mDecompiling $(basename "$1")…\x1B[0m\n"
    apktool d "${1}" > /dev/null 2>&1
}
recur_check() {
    if [ ! -d "./base/${1}" ]; then mkdir "./base/${1}"; fi
    for filename in "${1}"/*; do
        if [ -d "$filename" ]; then
            recur_check "$filename"
        elif [ -f "$filename" ]; then
            if [ -f "./base/${filename}" ]; then
                echo -en "\x1B[0;49;93m    > ${filename} already exists in base.apk, skipping…\x1B[0m\n"
            else
                echo -en "\x1B[0;49;92m    >\x1B[0m Adding ${filename}…\n"
                mv "./${filename}" "./base/${filename}"
            fi
        fi
    done
}
edit_manifest() {
    for arg in "$@"; do
        sed "$arg" "./base/AndroidManifest.xml" > tempManifest.xml
        mv tempManifest.xml "./base/AndroidManifest.xml"
    done
}
sourceDir="$(dirname "$0")"
start="$(date +%s%N)"
if ! type "apktool" > /dev/null 2>&1; then print_error "apktool is not installed"; fi
if [ ! -d "$1" ]; then print_error "Invalid directory"; fi
if [ ! -f "${1}/base.apk" ]; then print_error "base.apk is missing"; fi
if [ ! -f "${sourceDir}/aapt" ]; then print_error "aapt not found in ${sourceDir}"; fi
curDir="${PWD}"
cd /tmp
dirName="splitpacker_$(xxd -l2 -ps /dev/urandom)"
if [ -d "${dirName}" ]; then rm -rf "${dirName}"; fi
mkdir "${dirName}"
cd "${dirName}"
apktool_custom "${1}/base.apk"
echo -en "\x1B[0;49;34m==>\x1B[0m \x1B[1mFixing AndroidManifest.xml…\x1B[0m\n"
edit_manifest 's/ android:isSplitRequired="true"//g' '/com.android.vending.splits.required/d' 's/STAMP_TYPE_DISTRIBUTION_APK/STAMP_TYPE_STANDALONE_APK/g' 's/com.android.vending.derived.apk.id" android:value="2/com.android.vending.derived.apk.id" android:value="1/g'
assetList=""
for filename in "${1}"/*; do
    if [ "$(echo "$filename" | tail -c 5)" == ".apk" ]; then
        baseName="$(basename "$filename")"
        if [ "${baseName}" != "base.apk" ]; then
            apkInfo="$(zipinfo -1 "$filename")"
            if [ "$(echo "$apkInfo" | grep -m 1 "^lib/")" != "" ]; then
                echo -en "\x1B[0;49;34m==>\x1B[0m \x1B[1mUnzipping lib from ${baseName}…\x1B[0m\n"
                unzip "$filename" "lib/*" -d "./" > /dev/null 2>&1;
                recur_check "lib"
                rm -rf "lib"
            elif [ "$(echo "$apkInfo" | grep "^resources.arsc$")" != "" ]; then
                apktool_custom "$filename"
                mv "./${baseName%????}/res" ./
                recur_check "res"
                rm -rf "${baseName%????}"
                rm -rf res
            elif [ "$(echo "$apkInfo" | grep "^assets/")" != "" ]; then
                echo -en "\x1B[0;49;34m==>\x1B[0m \x1B[1mDecompiling $(basename "$filename")…\x1B[0m\n"
                apktool d -r -s "$filename" > /dev/null 2>&1
                mv "./${baseName%????}/assets" ./
                awk '/doNotCompress:/{flag=1; next} /isFrameworkApk:/{flag=0} flag' "./${baseName%????}/apktool.yml" > dncEntry
                lineNum="$(grep -n "isFrameworkApk:" ./base/apktool.yml | cut -f1 -d':')"
                assetName="$(${sourceDir}/aapt d xmltree "$filename" AndroidManifest.xml | grep "split=" | cut -f2 -d'"' )"
                if [ "$assetList" == "" ]; then
                    metaDataLine="$(grep -n 'com.android.vending.splits' ./base/AndroidManifest.xml)"
                    assetList="$(echo "$metaDataLine" | cut -f2 -d':' | cut -f1 -d'<' | sed 's/ /\\ /g')<meta-data android:name=\"com.android.dynamic.apk.fused.modules\" android:value=\"base,"
                fi
                assetList+="${assetName},"
                (( lineNum = lineNum - 1 ))
                sed -e "${lineNum}r dncEntry" "./base/apktool.yml" > temp.yml
                mv temp.yml ./base/apktool.yml
                recur_check "assets"
                rm -rf "${baseName%????}"
                rm -rf assets
            fi
        fi
    fi
done
if [ "$assetList" != "" ]; then
    edit_manifest "$(echo "$metaDataLine" | cut -f1 -d':') i ${assetList%?}\"/>"
fi
destDir="${curDir}/$(basename "$1")_packed/"
if [ -d "${destDir}" ]; then rm -rf "${destDir}"; fi
echo -en "\x1B[0;49;94m==>\x1B[0m \x1B[1mAll done, moving to ${destDir}…\x1B[0m\n"
mv "./base" "${destDir}"
rm -rf "/tmp/${dirName}"
end="$(date +%s%N)"
(( timeTaken = (end - start)/100000000 ))
ms=$(( timeTaken % 10 ))
(( timeTaken = timeTaken / 10 ))
echo -en "\x1B[0;49;94m==>\x1B[0m \x1B[1mFinished in ${timeTaken}.${ms}s…\x1B[0m\n"
