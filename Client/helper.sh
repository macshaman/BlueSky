#!/bin/bash

# c)2011-2014 Best Macs, Inc.
# c)2014-2015 Mac-MSP LLC
# Copyright 2016-2017 SolarWinds Worldwide, LLC

# Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# helper script performs privileged tasks for BlueSky, does initial client setup

ourHome="/var/bluesky"
bVer="2.1"

if [ -e "$ourHome/.debug" ]; then
  set -x
fi

function logMe {
  logMsg="$1"
  logFile="$ourHome/activity.txt"
  if [ ! -e "$logFile" ]; then
    touch "$logFile"
  fi
  dateStamp=`date '+%Y-%m-%d %H:%M:%S'`
  echo "$dateStamp - v$bVer - $logMsg" >> "$logFile"
  if [ -e "$ourHome/.debug" ]; then
    echo "$logMsg"
  fi
}

function killShells {
    kill -9 `ps -ax | grep "$ourHome/autossh" | grep -v grep | awk '{ print $1 }'`
    shellList=`ps -ax | grep ssh | grep 'bluesky\@' | awk '{ print $1 }'`
    for shellPid in $shellList; do
        kill -9 $shellPid
        logMe "Killed stale shell on $shellPid" 
    done
}

#if server.plist is not present, error and exit
if [ ! -e "$ourHome/server.plist" ]; then
	echo "server.plist is not installed. Please double-check your setup."
	exit 2
fi

if [ -e "$ourHome/.getHelp" ]; then
	helpWithWhat=`cat "$ourHome/.getHelp"`
	rm -f "$ourHome/.getHelp"
fi

# initiate self-destruct
if [ "$helpWithWhat" == "selfdestruct" ]; then
    rm -rf "$ourHome"
    dscl . -delete /Users/bluesky
    launchctl unload /Library/LaunchDaemons/com.solarwindsmsp.bluesky.*.plist && rm -f /Library/LaunchDaemons/com.solarwindsmsp.bluesky.*.plist
    exit 0
fi

#check if user exists and create if necessary
userCheck=`dscl . -read /Users/bluesky RealName`
if [ "$userCheck" == "" ]; then
    # user doesn't exist, lets try to set it up
    logMe "Creating our user account"
    dscl . -create /Users/bluesky

    #pick a good UID, we prefer 491 but it could conceivably be in use by someone else
    uidTest=491
    while :
    do
        uidCheck=`dscl . -search /Users UniqueID $uidTest`
        if [ "$uidCheck" == "" ]; then
            dscl . -create /Users/bluesky UniqueID $uidTest
            break
        else
            uidTest=`jot -r 1 400 490`
        fi
    done
    logMe "Created on UID $uidTest"

    dscl . -create /Users/bluesky UserShell /bin/bash
    dscl . -create /Users/bluesky PrimaryGroupID 20
    dscl . -create /Users/bluesky NFSHomeDirectory "$ourHome"
    dscl . -create /Users/bluesky RealName "BlueSky"
    dscl . -create /Users/bluesky Password "*"
    defaults write /Library/Preferences/com.apple.loginwindow HiddenUsersList -array-add bluesky
    defaults write /Library/Preferences/com.apple.loginwindow Hide500Users -bool TRUE
    chown -R bluesky "$ourHome" 
    dseditgroup -o edit -a bluesky -t user com.apple.access_ssh 2> /dev/null
    # kill any autossh and shells that may have belonged to the old user
    killShells  
fi

#help me help you.  help me... help you.
dseditgroup -o edit -a bluesky -t user com.apple.access_ssh 2> /dev/null
systemsetup -setremotelogin on &> /dev/null

# commenting out on 1.12
# re-intro when we can test a more reliable method of determining a VNC server
# vncOn=`ps -ax | grep ARDAgent | grep -v grep`
# if [ "$vncOn" == "" ]; then
#   logMe "Starting ARD agent"
#   /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -activate -access -on -privs -ControlObserve -allowAccessFor -allUsers -quiet
# fi

#if permissions are wrong on the home folder, this will fix
if [ "$helpWithWhat" == "fixPerms" ]; then
    logMe "Fixing permissions on our directory"
    chown -R bluesky "$ourHome"
    defaults write /Library/Preferences/com.apple.loginwindow HiddenUsersList -array-add bluesky  
fi

#sometimes bluesky user can't kill shells
if [ "$helpWithWhat" == "contractKiller" ]; then
	logMe "Helper was asked to kill connections"
    killShells
fi

#workaround for bug that is creating empty settings file
setCheck=`grep keytime "$ourHome/settings.plist"`
if [ "$setCheck" == "" ]; then
	logMe "Helper is resetting the settings plist"
	rm -f "$ourHome/settings.plist"
	/usr/libexec/PlistBuddy -c "Add :keytime integer 0" "$ourHome/settings.plist"
	# commenting these out for 1.5, creation of variables should be more robust now
#	/usr/libexec/PlistBuddy -c "Add :portcache integer -1" "$ourHome/settings.plist"
#	/usr/libexec/PlistBuddy -c "Add :serial string 0" "$ourHome/settings.plist"
	chown bluesky "$ourHome/settings.plist"
fi

# babysit the bluesky process
prevPid=`/usr/libexec/PlistBuddy -c "Print :pid" "$ourHome/settings.plist"  2> /dev/null`
currPid=`ps -ax | grep "$ourHome/bluesky.sh"$ | grep -v grep | awk '{ print $1 }' | head -n 1`
if [ "$currPid" != "" ]; then
    if [ "$currPid" == "$prevPid" ]; then
        # bluesky.sh must be stuck if it's still there 5 min later.  kill it.
        kill -9 $currPid
        logMe "Killed stale BlueSky process on $currPid"
    else
        /usr/libexec/PlistBuddy -c "Add :pid integer" "$ourHome/settings.plist" 2> /dev/null
        /usr/libexec/PlistBuddy -c "Set :pid $currPid" "$ourHome/settings.plist"
    fi
fi

# if main launchd is not running, let's check perms and start it
weLaunched=`launchctl list | grep com.solarwindsmsp.bluesky | wc -l`
if [ ${weLaunched:-0} -lt 2 ]; then
	logMe "LaunchDaemons don't appear to be loaded.  Fixing."
	if [ ! -e /Library/LaunchDaemons/com.solarwindsmsp.bluesky.plist ]; then
		cp /var/bluesky/com.solarwindsmsp.bluesky.plist /Library/LaunchDaemons/com.solarwindsmsp.bluesky.plist
	fi
	if [ ! -e /Library/LaunchDaemons/com.solarwindsmsp.bluesky.helper.plist ]; then
		cp /var/bluesky/com.solarwindsmsp.bluesky.helper.plist /Library/LaunchDaemons/com.solarwindsmsp.bluesky.helper.plist
	fi
	chmod 644 /Library/LaunchDaemons/com.solarwindsmsp.bluesky.*
	chown root:wheel /Library/LaunchDaemons/com.solarwindsmsp.bluesky.*
	launchctl load -w /Library/LaunchDaemons/com.solarwindsmsp.bluesky.*
fi

exit 0