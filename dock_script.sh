#!/bin/bash

# Add apps you'd like added to the dock below (replace example apps with your own)
appsToAdd=(
    "/Applications/Microsoft Word.app"
    "/Applications/Microsoft PowerPoint.app"
    "/Applications/Microsoft Excel.app"
    "/Applications/Microsoft Outlook.app"
    "/Applications/Microsoft OneNote.app"
    "/Applications/Microsoft Teams.app"
    "/Applications/OneDrive.app"
)

### Main Logic, do not edit below this line ###
if [[ ! -e "/usr/local/bin/dockutil" ]]; then
    echo "dockutil not found"
    exit 1
fi

appsInstalled=()
appsAdded=()
loggedInUserName=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
loggedInUserId=$(id -u "$loggedInUserName")

# Function to run commands as the logged in user
runAsUser() {
    launchctl asuser "$loggedInUserId" sudo -u "$loggedInUserName" "$@"
}

# Check if apps are installed and add them to the appsInstalled array
for app in "${appsToAdd[@]}"; do
    if [[ -d "$app" ]]; then
        appsInstalled+=("$app")
    else
        echo "$app not found, skipping..."
    fi
done

# Add apps to dock if they are not already there
for app in "${appsInstalled[@]}"; do
    if runAsUser /usr/local/bin/dockutil --find "$app" "/Users/$loggedInUserName" >/dev/null 2>&1; then
        echo "$app already exists in the dock, skipping..."
        continue
    fi

    if runAsUser /usr/local/bin/dockutil --add "$app" --no-restart "/Users/$loggedInUserName" >/dev/null; then
        echo "$app added to the dock"
        appsAdded+=("$app")
    else
        echo "Failed to add $app to the dock"
    fi
    sleep 1
done

# Restart Dock if apps were added
if [[ ${#appsAdded[@]} -gt 0 ]]; then
    sleep 2
    runAsUser killall Dock
else
    echo "No apps added to the dock, exiting..."
fi
