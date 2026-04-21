@lazyGlobal off.

clearScreen.
set config:ipu to 1500.
switch to 0.
core:messages:clear.

wait until ship:unpacked.

runoncepath("0:/shuttleScript/shuttleLib").

if altitude > 5000 and altitude < 70000 {
    runoncepath("0:/shuttleScript/shuttleLand").
    runoncepath("0:/shuttleScript/auto4").
    print 1 / 0.
}
else if altitude > 500 and altitude < 5000 {
    runoncepath("0:/shuttleScript/auto4").
    print 1 / 0.
}

if altitude < 5000 {
    wait until core:messages:empty = false or altitude > 5000.
    wait until core:messages:pop:content = "opened GUI" or altitude > 5000.

    //"opened GUI"

    core:doevent("Open Terminal").

    // Launch
    print "Type any key to launch.".
    wait until terminal:input:haschar = true or core:messages:empty = false or altitude > 5000.

    if core:messages:empty = false {
        wait until core:messages:pop:content = "launch".
    }

    if alt:radar < 200 {
        local timeDiv is 2.
        terminal:input:clear.

        ship:partsdubbed("retract")[0]:getmodule("ModuleRoboticController"):setfield("play/pause", 0).

        print "retracting the beanie cap.".
        wait 8 / timeDiv.
        print "beanie cap retracted.".
        wait 2 / timeDiv.
        print "retracting the crew access point.".
        wait 10 / timeDiv.
        print "crew access point retracted.".
        wait 2 / timeDiv.

        clearScreen.
        print "water supression system: GO".
        stage.

        runoncepath("0:/shuttleScript/shuttleLaunch").
    }
    else if altitude < 70000 {
        print "Launch failed. Check for errors.".
}
}

// Landing
clearscreen.
print "do something ig".
terminal:input:clear.
wait until terminal:input:haschar = true.

if altitude > 5000 {
    runoncepath("0:/shuttleScript/shuttleLand").
    runoncepath("0:/shuttleScript/auto4").
}
else if altitude < 5000 and alt:radar > 300 {
    runoncepath("0:/shuttleScript/auto4").
}
else {
    print "PANIC!!!".
}
clearScreen.
print "This program was probably a success, but idk.".
print "If you are seeing this, no more loops in the boot".
print "program are waiting for completion.".