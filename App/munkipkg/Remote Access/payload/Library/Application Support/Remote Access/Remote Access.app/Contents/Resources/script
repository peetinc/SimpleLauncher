#!/bin/zsh

# Variables
#---Change these if app is renamed or to rebrand
#appName - full app bundle name, Remote Access.app
appName="Remote Access.app"
#machName - executable name in app/Contents/MacOS folder
machName="Remote Access"
#appDomain - LaunchAgent and app deploy preference
appDomain="com.github.remoteaccess"
#supportDirName - Name of /Library/Application Support folder and /Library/Logs Folder
supportDirName="Remote Access"
#logName - Logfile name
logName="RemoteAccess.log"
#installVers - "online" (stub installer) or "offline" (full installer) which version of Simple Help Access you'd like to download. 
installVers="offline"

#---These variables are concatenations of above or required information gathering
#installDir - where the Remote Access Launcher app will live
installDir="/Library/Application Support/$supportDirName"
#logPath and logPath where do you want to log to?
logDir="/Library/Logs/$supportDirName"
logPath="$logDir/$logName"
#SGpath - Since all instances of SimpleGateway are osxwrapper or osxlauncher, something unique to grep for in `ps -o command= PID`
SGpath=SimpleGatewayService
#consoleUSER - find the currently logged in user in order to ensure LaunchAgent is not loaded.
consoleUSER=`stat -f%Su /dev/console`
consoleUID=`id -u $consoleUSER`
#location for the Info.plist for running and installed app bundle once script is running as app, "../Info.plist"
infoLocation="../Info.plist"
	version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$infoLocation")
	versionInstalled=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$installDir/$appName/Contents/Info.plist")
#location for Deployment Variables .var.plist, once the script is running as app, "../../../.vars.plist" is in the same directory as the app bundle.
plistDir="/Library/Preferences"
plistPath="$plistDir/$appDomain.plist"

# Functions
#logIt- Simple Logging snipit, seems to work well.
function logIt {
    echo "[`date`][${USER}] - ${*}" >> "$logPath"
}

#initializeLogging - make sure logging is good to go
function initializeLogging {
if [ ! -f "$logPath" ]; then
	if [ ! -d "$logDir" ]; then
		mkdir -p "$logDir"
		chown root:wheel "$logDir"
		chmod 775 "$logDir"
	fi
	touch "$logPath"
	chown root:wheel "$logPath"
	chmod 664 "$logPath"
	logIt "init $logPath"
fi
}

#LaunchAgentSG - test if LaunchAgent exists, unload if loaded, delete ("launchctl asuser" is a joy here).
#   Also run in root context in case we're running at loginwindow after pkg deploy
function LaunchAgentSG {
	if [ -f /Library/LaunchAgents/com.simplehelp.simplegateway.plist ]; then
		logIt "SimpleGateway LaunchAgent found." 
		launchctl asuser $consoleUID launchctl list com.simplehelp.simplegateway > /dev/null 2>&1
		loadedSG=$?
		if [ $loadedSG = "0" ]; then
			logIt "SimpleGateway LaunchAgent is loaded as $consoleUSER." 
			logIt "Unload SimpleGateway LaunchAgent." 
			launchctl asuser $consoleUID launchctl unload /Library/LaunchAgents/com.simplehelp.simplegateway.plist 
		fi
		logIt "remove /Library/LaunchAgents/com.simplehelp.simplegateway.plist" 
		rm "/Library/LaunchAgents/com.simplehelp.simplegateway.plist"
	fi
	if [ -f /Library/LaunchAgents/com.simplehelp.simplegateway.plist ]; then
		logIt "SimpleGateway LaunchAgent found." 
		launchctl asuser root launchctl list com.simplehelp.simplegateway > /dev/null 2>&1
		loadedSG=$?
		if [ $loadedSG = "0" ]; then
			logIt "SimpleGateway LaunchAgent is loaded as root." 
			logIt "Unload SimpleGateway LaunchAgent." 
			launchctl asuser root launchctl unload /Library/LaunchAgents/com.simplehelp.simplegateway.plist 
		fi
		logIt "remove /Library/LaunchAgents/com.simplehelp.simplegateway.plist" 
		rm "/Library/LaunchAgents/com.simplehelp.simplegateway.plist"
	fi
	}

#LaunchAgentRA - test if our LaunchAgent exists, if not create it.
function LaunchAgentRA {
	if [ ! -f /Library/LaunchAgents/$appDomain.plist ]; then
		logIt "$appName LaunchAgent not found." 
		logIt "Creating /Library/LaunchAgents/$appDomain.plist" 
		defaults write /Library/LaunchAgents/$appDomain.plist Label $appDomain
		defaults write /Library/LaunchAgents/$appDomain.plist LimitLoadToSessionType -array LoginWindow
		defaults write /Library/LaunchAgents/$appDomain.plist RunAtLoad -bool TRUE
		defaults write /Library/LaunchAgents/$appDomain.plist ProgramArguments -array "$installDir/$appName/Contents/MacOS/$machName"
		defaults write /Library/LaunchAgents/$appDomain.plist AbandonProcessGroup -bool TRUE
		chown root:wheel /Library/LaunchAgents/$appDomain.plist
		chmod 644 /Library/LaunchAgents/$appDomain.plist
	fi
	}
	
#killUserSG - If SimpleGateway is running as user as osxwrapper or osxlauncher, kill all PID's.
function killUserSG {
	PROC=( `pgrep -d \  -u $consoleUSER osxwrapper`)  #spacing is correct
	for i in ${PROC[*]}; do
		ps -o command= $i | grep $SGpath > /dev/null 2>&1 
		isSG=$?
		if [ $isSG = "0" ]; then
			logIt "osxwrapper with PID $i is SimpleGateway running as $consoleUSER."  
			logIt "kill $i" 
			kill $i
		fi
	done

	PROC=( `pgrep -d \  -u $consoleUSER osxlauncher`) #spacing is correct
	for i in ${PROC[*]}; do
		ps -o command= $i | grep $SGpath > /dev/null 2>&1 
		isSG=$?
		if [ $isSG = "0" ]; then
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
		
		if [ $isSG = "0" ]; then
			logIt "osxlauncher with PID $i is SimpleGateway and running as root - exiting." 
			logIt "---- $appName v.$version exit 0 ----" 
			exit 0	
		fi	
	done
	
	PROC=( `pgrep -d \  -u root osxwrapper`)  #spacing is correct
	for i in ${PROC[*]}; do
		
		ps -o command= $i | grep $SGpath > /dev/null 2>&1 
		isSG=$?
		
		if [ $isSG = "0" ]; then
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
	[ -f "./Remote Access Service.app/Contents/MacOS/osxwrapper" ] && "./Remote Access Service.app/Contents/MacOS/osxwrapper" & 
	[ -f "./SimpleGatewayService.app/Contents/MacOS/osxwrapper" ] && "./SimpleGatewayService.app/Contents/MacOS/osxwrapper" & 
	
	PROC=( `pgrep -d \  -u root osxwrapper`)  #spacing is correct
	for i in ${PROC[*]}; do
		ps -o command= $i | grep $SGpath > /dev/null 2>&1 
		isSG=$?
		
		if [ $isSG = "0" ]; then
			
			logIt "Remote Access osxwrapper with PID $i is as root."
			logIt "---- $appName v.$version exit 0 ----"
			exit 0	
		fi	
	done
	}
	
# deploySG checks that SimpleHelp Gateway is installed and this app version is up to date, if either are not true we attempt a full reinstall
function deploySG {
	if [ ! -d "/Library/Application Support/JWrapper-Remote Access/JWAppsSharedConfig/SimpleGatewayService" ] || [ $version != $versionInstalled ]; then
		if [ -f $plistPath ]; then
		#ensure SimpleGateway launch agent is not deployed or running
		LaunchAgentSG
		#ensure SimpleGateway is not running as user
		killUserSG
		
		serverURL=$(/usr/libexec/PlistBuddy -c "Print :serverURL" "$plistPath")
		name=$(/usr/sbin/scutil --get ComputerName | /usr/bin/sed 's/ /-/g')
		group=$(/usr/libexec/PlistBuddy -c "Print :group" "$plistPath")
		password=$(/usr/libexec/PlistBuddy -c "Print :password" "$plistPath")
		servers=$(/usr/libexec/PlistBuddy -c "Print :servers" "$plistPath")
		monitor=$(/usr/libexec/PlistBuddy -c "Print :monitor" "$plistPath")
		script=$(/usr/libexec/PlistBuddy -c "Print :script" "$plistPath")
		confirm=$(/usr/libexec/PlistBuddy -c "Print :confirm" "$plistPath")
		proxy=$(/usr/libexec/PlistBuddy -c "Print :proxy" "$plistPath")
		silent=$(/usr/libexec/PlistBuddy -c "Print :silent" "$plistPath")
		shortcuts=$(/usr/libexec/PlistBuddy -c "Print :shortcuts" "$plistPath")
		
		downloadURL="$serverURL/access/Remote Access-macos64-$installVers.dmg?language=en&name=$name&group=$group&password=$password&servers=$servers&monitor=$monitor&script=$script&confirm=$confirm&proxy=$proxy&silent=$silent&shortcuts=$shortcuts&ie=ie.exe"
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
		SECONDS=0
		timeOut=5
		while ! [ -f /Library/LaunchAgents/com.simplehelp.simplegateway.plist ] && [ $SECONDS -lt $timeOut ]
		do
			logIt "LaunchAgents Comparison result is $?" 
			logIt "Checking for /Library/LaunchAgents/com.simplehelp.simplegateway.plist for $SECONDS seconds. $plistCheck"
			sleep 1
		done
		SECONDS=0		
		detach=$(hdiutil detach "$mountPoint" 2>&1)
		while [[ $detach != *ejected* ]] && [ $SECONDS -lt $timeOut ]
		do
			detach=$(hdiutil detach "$mountPoint" 2>&1)
			logIt "Waiting for $mountPoint to eject for $SECONDS seconds. - $detach"
			sleep 1
		done
		rm -rf $tmpDownload
		
		#ensure SimpleGateway launch agent is not deployed or running
		LaunchAgentSG
		
			else
			logIt "Cannot download and deploy $plistPath missing." 
		fi
		
		if [ $version -gt $versionInstalled ]; then
			logIt "Copying $appName to $installDir" 
			ditto "../../../$appName" "$installDir/$appName" 
			chown -R root:wheel "/Library/Application Support/$supportFolder"
			chmod -R 755 "/Library/Application Support/$supportFolder"
		fi
			else 
			logIt "$installDir$appName v.$versionInstalled."
			logIt "/Library/Application Support/JWrapper-Remote Access/JWAppsSharedConfig/SimpleGatewayService found." 
			logIt "No need to deploy or update."
	fi
	}
	
#----Main----
#Ensure logPath exists with correct folders and permissions
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
# testRootSG makes sure Simple Gateway is running as root if so ends the script
testRootSG
#Starts Simple Gateway as root regardless of v5.1.x or v5.2.x
startSG


logIt "---- $appName v.$version exit 0----" 
exit 0
