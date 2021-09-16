# SplitPacker
Bash script to combine split APKs (android app bundles) into a single APK on mac.

# Usage
`path/to/SplitPacker.sh <dir>`
- The directory should contain all the split APKs
- The base APK file should be named exactly 'base.apk'
- It will decompile the base APK with apktool
- Then it will process all the split APKs and add what's missing to the base APK. 
- Lastly, the decompiled base APK directory is then moved to where you call this script from.

# Info
- Handles `resources`, `assets` and `lib-config` split APKs.
- `apktool` is needed to decompile the base APK and resource-only split APKs as well as asset-based split APKs. 
- If you use `SplitPacker_AAPT`, then you must have a working aapt executable in the script's directory. It is much faster (around 3x) than the normal script when handling asset-only split APKs. (resources are not decompiled and `aapt` is used instead to get the asset's name)
- `lib-config` split APKs are handled using `unzip`, no other adjustments have to be made for those.
- The script is customized to my needs, which is combining the split APKs into a single decompiled folder, so I can mod the application and recompile it later.
- You can edit the script at the end and add an automatic call to `apktool b` and `apksigner` if you wish to do so.

# Working Video
Normal Script:


https://user-images.githubusercontent.com/41083078/133658087-87e49b8a-87da-48c3-ae84-7770f4d4b1bb.mp4




AAPT Script:


https://user-images.githubusercontent.com/41083078/133657765-482d6e22-b246-4844-b3c1-1ccbf8949c87.mp4


