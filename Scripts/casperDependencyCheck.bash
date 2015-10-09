#!/bin/bash

checkCommand="/Users/erikberglund/GitHub/Scripts/sharedLibraryDependencyChecker.bash"
casperImaging="/Users/erikberglund/Desktop/Casper/CINew/Casper Imaging.app"

"${checkCommand}"	-t "${casperImaging}"\
					-t "${casperImaging}/Contents/Support/jamf"\
					-t "${casperImaging}/Contents/Support/jamfHelper.app/Contents/MacOS/jamfHelper"\
					-t "/System/Library/Frameworks/AppleScriptObjC.framework/Versions/A/AppleScriptObjC"\
					-t "/System/Library/Frameworks/OpenGL.framework/Versions/A/Libraries/libLLVMContainer.dylib"\
					-t "/System/Library/PrivateFrameworks/ViewBridge.framework/Versions/A/ViewBridge"\
					-t "/System/Library/Extensions/GeForceGLDriver.bundle/Contents/MacOS/libclh.dylib"\
					-t "/System/Library/Frameworks/OpenCL.framework/Versions/A/Libraries/libcldcpuengine.dylib"\
					-t "/System/Library/PrivateFrameworks/AppleGVA.framework/Versions/A/AppleGVA"\
					-t "/System/Library/QuickTime/QuickTimeComponents.component/Contents/MacOS/QuickTimeComponents"\
					-e ".*OpenGL.*"\
					-i ".*libCoreVMClient.dylib$"\
					-a\
					-X

exit 0