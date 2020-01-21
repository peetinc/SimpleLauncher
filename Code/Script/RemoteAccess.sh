#!/bin/zsh

# Variables
#appName - full app bundle name, Remote Access.app
appName="Remote Access.app"
#installLocation - where the Remote Access Launcher app will live
installLocation="/Library/Application Support/Artichoke/"
#logfolderPath and logfilePath where do you want to log to?
logfolderPath="/Library/Logs/Artichoke"
logfilePath="$logfolderPath"/RemoteAccessLauncher.log
#SGpath - Since all instances of SimpleGateway are osxwrapper or osxlauncher, something unique to grep for in `ps -o command= PID`
SGpath=SimpleGatewayService
#consoleUSER - find the currently logged in user in order to ensure LaunchAgent is not loaded.
consoleUSER=`stat -f%Su /dev/console`
consoleUID=`id -u $consoleUSER`
#location for the Info.plist for running and installed app bundle once script is running as app, "../Info.plist"
infoLocation="../Info.plist"
	version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$infoLocation")
	versionInstalled=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$installLocation$appName/Contents/Info.plist")
#location for Deployment Variables .var.plist, once the script is running as app, "../../../.vars.plist" is in the same directory as the app bundle.
varsLocation="../../../.vars.plist"
#LaunchAgent Domain 
LADomain=consulting.artichoke.RemoteAccess

# Functions
#logIt- Simple Logging snipit, seems to work well.
function  {
    echo "[`date`][${USER}] - ${*}" >> "$logfilePath"
}

#initializeLogging - make sure logging is good to go
function initializeLogging {
if [[ ! -f "$logfilePath" ]]; then
	if [[ ! -d "$logfolderPath" ]]; then
		mkdir -p "$logfolderPath"
		chown root:wheel "$logfolderPath"
		chmod 775 "$logfolderPath"
	fi
	touch "$logfilePath"
	chown root:wheel "$logfilePath"
	chmod 664 "$logfilePath"
	logIt "init "$logfolderPath"/RemoteAccessLaunch.log"
fi
}

#LaunchAgentSG - test if LaunchAgent exists, unload if loaded, delete ("launchctl asuser" is a joy here)
function LaunchAgentSG {
	if [[ -f /Library/LaunchAgents/com.simplehelp.simplegateway.plist ]]; then
		logIt "SimpleGateway LaunchAgent found." 
		launchctl asuser $consoleUID launchctl list com.simplehelp.simplegateway > /dev/null 2>&1
		loadedSG=$?
		if [[ $loadedSG = "0" ]]; then
			logIt "SimpleGateway LaunchAgent is loaded as $consoleUSER." 
			logIt "Unload SimpleGateway LaunchAgent." 
			launchctl asuser $consoleUID launchctl unload /Library/LaunchAgents/com.simplehelp.simplegateway.plist 
		fi
		logIt "remove /Library/LaunchAgents/com.simplehelp.simplegateway.plist" 
		rm "/Library/LaunchAgents/com.simplehelp.simplegateway.plist"
	fi
	}
	
#LaunchAgentRA - test if our LaunchAgent exists, if not create it.
function LaunchAgentRA {
	if [[ ! -f /Library/LaunchAgents/$LADomain.plist ]]; then
		logIt "Remote Access LaunchAgent not found." 
		logIt "Creating /Library/LaunchAgents/$LADomain.plist" 
		defaults write /Library/LaunchAgents/$LADomain.plist Label $LADomain
		defaults write /Library/LaunchAgents/$LADomain.plist LimitLoadToSessionType -array LoginWindow
		defaults write /Library/LaunchAgents/$LADomain.plist RunAtLoad -bool TRUE
		defaults write /Library/LaunchAgents/$LADomain.plist ProgramArguments -array "$installLocation$appName/Contents/MacOS/Remote Access"
		defaults write /Library/LaunchAgents/$LADomain.plist AbandonProcessGroup -bool TRUE
		chown root:wheel /Library/LaunchAgents/$LADomain.plist
		chmod 644 /Library/LaunchAgents/$LADomain.plist
	fi
	}
	
#killUserSG - If SimpleGateway is running as user as osxwrapper or osxlauncher, kill all PID's.
function killUserSG {
	PROC=( `pgrep -d \  -u $consoleUSER osxwrapper`)  #spacing is correct
	for i in ${PROC[*]}; do
		ps -o command= $i | grep $SGpath > /dev/null 2>&1 
		isSG=$?
		if [[ $isSG = "0" ]] && [[ $isUSER != "root" ]]; then
			logIt "osxwrapper with PID $i is SimpleGateway running as $consoleUSER."  
			logIt "kill $i" 
			kill $i
		fi
	done

	PROC=( `pgrep -d \  -u $consoleUSER osxlauncher`) #spacing is correct
	for i in ${PROC[*]}; do
		ps -o command= $i | grep $SGpath > /dev/null 2>&1 
		isSG=$?
		if [[ $isSG = "0" ]] && [[ $isUSER != "root" ]]; then
			logIt "osxlauncher with PID $i is SimpleGateway running as $consoleUSER." 
			logIt "kill $i" 
			kill $i
		fi
	done
	}
	
#testRootSG - If SimpleGateway is running as osxwrapper or osxlauncher as root, if so it really should be us, exit 0.
function testRootSG {
	PROC=( `pgrep -d \  -u root osxlauncher`)  #spacing is correct
	for i in ${PROC[*]}; do
		ps -o command= $i | grep $SGpath > /dev/null 2>&1 
		isSG=$?
		
		if [[ $isSG = "0" ]]; then
			logIt "osxlauncher with PID $i is SimpleGateway and running as root - exiting." 
			logIt "---- $appName v.$version exit 0 ----" 
			exit 0	
		fi	
	done
	
	PROC=( `pgrep -d \  -u root osxwrapper`)  #spacing is correct
	for i in ${PROC[*]}; do
		
		ps -o command= $i | grep $SGpath > /dev/null 2>&1 
		isSG=$?
		
		if [[ $isSG = "0" ]]; then
			logIt "osxwrapper with PID $i is SimpleGateway and running as root - exiting." 
			logIt "---- $appName v.$version exit 0 ----" 
			exit 0	
		fi	
	done
	}	
	
#startSG - start SimpleGateway backgrounded depending on version 5.1.x or 5.2
function startSG {
	logIt "Starting SimpleGateway as `whoami`" 
	cd "/Library/Application Support/JWrapper-Remote Access/JWAppsSharedConfig/SimpleGatewayService"
	[[ -f "./Remote Access Service.app/Contents/MacOS/osxwrapper" ]] && "./Remote Access Service.app/Contents/MacOS/osxwrapper" & 
	[[ -f "./SimpleGatewayService.app/Contents/MacOS/osxwrapper" ]] && "./SimpleGatewayService.app/Contents/MacOS/osxwrapper" & 
	
	PROC=( `pgrep -d \  -u root osxwrapper`)  #spacing is correct
	for i in ${PROC[*]}; do
		ps -o command= $i | grep $SGpath > /dev/null 2>&1 
		isSG=$?
		
		if [[ $isSG = "0" ]]; then
			logIt "Remote Access osxwrapper with PID $i is as root."
			logIt "---- $appName v.$version exit 0 ----"
			exit 0	
		fi	
	done
	}
	
# deploySG checks that 
function deploySG {
	if [[ ! -d "/Library/Application Support/JWrapper-Remote Access/JWAppsSharedConfig/SimpleGatewayService" || $version != $versionInstalled ]]; then
		if [[ -f $varsLocation ]]; then
		#ensure SimpleGateway launch agent is not deployed or running
		LaunchAgentSG
		#ensure SimpleGateway is not running as user
		killUserSG
		
		serverURL=$(/usr/libexec/PlistBuddy -c "Print :serverURL" "$varsLocation")
		name=$(/usr/sbin/scutil --get ComputerName | /usr/bin/sed 's/ /-/g')
		group=$(/usr/libexec/PlistBuddy -c "Print :group" "$varsLocation")
		password=$(/usr/libexec/PlistBuddy -c "Print :password" "$varsLocation")
		servers=$(/usr/libexec/PlistBuddy -c "Print :servers" "$varsLocation")
		monitor=$(/usr/libexec/PlistBuddy -c "Print :monitor" "$varsLocation")
		script=$(/usr/libexec/PlistBuddy -c "Print :script" "$varsLocation")
		confirm=$(/usr/libexec/PlistBuddy -c "Print :confirm" "$varsLocation")
		proxy=$(/usr/libexec/PlistBuddy -c "Print :proxy" "$varsLocation")
		silent=$(/usr/libexec/PlistBuddy -c "Print :silent" "$varsLocation")
		shortcuts=$(/usr/libexec/PlistBuddy -c "Print :shortcuts" "$varsLocation")
		
		downloadURL="$serverURL/access/Remote Access-macos64-online.dmg?language=en&name=$name&group=$group&password=$password&servers=$servers&monitor=$monitor&script=$script&confirm=$confirm&proxy=$proxy&silent=$silent&shortcuts=$shortcuts&ie=ie.exe"
		tmpDownload=`mktemp -d /tmp/RemoteAccess.XXXXX`
		mountPoint=`mktemp -d $tmpDownload/XXXXX`
		dmgPath=$tmpDownload/remote.dmg
		chmod 755 -R $tmpDownload
		logIt "List of install vars: serverURL-$serverURL name=$name group-$group password-* servers-$servers monitor-$monitor script-$script confirm-$confirm proxy-$proxy silent-$silent shortcuts-$shortcuts" 
		logIt "Downloading $downloadURL" 
		curl -o /$tmpDownload/remote.dmg $downloadURL 		
		logIt "Mounting installer dmg at $mountPoint."
		hdiutil attach "$dmgPath" -mountpoint "$mountPoint" -noverify -nobrowse -noautoopen
		logIt "Running $mountPoint/Remote\ Access.app/Contents/MacOS/osxwrapper."
		$mountPoint/Remote\ Access.app/Contents/MacOS/osxwrapper 
		while [ ! -f /Library/LaunchAgents/com.simplehelp.simplegateway.plist ]; do sleep 1; done
		detach=$(hdiutil detach "$mountPoint" 2>&1)
		while [[ $detach != *ejected* ]]; do detach=$(hdiutil detach "$mountPoint" 2>&1) && sleep 1 ;done
		rm -rf $tmpDownload
		
		#ensure SimpleGateway launch agent is not deployed or running
		LaunchAgentSG
		
			else
			logIt "Cannot deploy $varsLocation missing." 
		fi
		
		if [[ $version != $versionInstalled ]]; then
			logIt "Copying $appName to $installLocation" 
			ditto "../../../$appName" "$installLocation$appName" 
			chown -R root:wheel "/Library/Application Support/Artichoke"
			chmod -R 755 "/Library/Application Support/Artichoke"
		fi
			else 
			logIt "$installLocation$appName v.$versionInstalled."
			logIt "/Library/Application Support/JWrapper-Remote Access/JWAppsSharedConfig/SimpleGatewayService found." 
			logIt "No need to deploy or update."
	fi
	}
	
#----Main----
#Ensure logfilePath exists with correct folders and permissions
initializeLogging
#startLogging
logIt "---- $appName v.$version start ----"
#Test for Simple Gateway Running as user for
deploySG
#Ensure SimpleGatway LaunchAgent is not installed or running
LaunchAgentSG
#ensure SimpleGateway is not running as user
killUserSG
# Installs Remote Access LaunchAgent (kind of the whole point of this.)
LaunchAgentRA
#Checks for instance of SimpleGatway Running as root (that really should be us). If running exit 0
testRootSG
#Starts Simple Gateway as root regardless of v5.1.x or v5.2.x
startSG

logIt "---- $appName v.$version exit ----" 
exit 0
