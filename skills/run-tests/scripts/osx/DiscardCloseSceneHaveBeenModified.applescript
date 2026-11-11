property appName : "Unity"
property dialogTitle : "Scene(s) Have Been Modified"
property buttonLabel : "Don't Save"

on clickButtonIn(p)
    tell application "System Events"
        repeat with w in windows of p
            -- NSAlert windows often have an empty title and show the title as static text instead
            if name of w is dialogTitle or (exists (static text dialogTitle of w)) then
                click button buttonLabel of w
                return true
            end if
        end repeat
    end tell
    return false
end clickButtonIn

tell application "System Events"
    -- Several editors can run at once; `tell application "Unity" to activate` picks just one of them
    set unityProcesses to every process whose name is appName

    -- Bringing an editor forward takes the focus from the user's work, so look in the current Space as it is first
    repeat with p in unityProcesses
        if my clickButtonIn(p) then return "clicked (pid " & (unix id of p) & ")"
    end repeat

    repeat with p in unityProcesses
        -- Accessibility API lists only windows in the current Space, so bring the process forward to switch to its Space
        set frontmost of p to true
        delay 1
        if my clickButtonIn(p) then return "clicked (pid " & (unix id of p) & ")"
    end repeat
end tell
return "not found"
