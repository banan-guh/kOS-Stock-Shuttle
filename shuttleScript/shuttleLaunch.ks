@lazyGlobal off.

DisplayMFDLaunchLabels.

//edit maxQ.txt.
//log "--- START OF LOG ---" to maxQ.txt.

// so the external tank doesnt tilt up (transfer fuel)
local topEXT is ship:partsdubbed("topEXT").
local bottomEXT is ship:partsdubbed("bottomEXT").

// Variables for the MFD and debugging.
local DiagnosticMsg is "".
local FlightStatus is "".

// Processor declaration
local cpuMain is ship:partsdubbed("mainCPU")[0].
local cpu1 is processor("CPU1"):connection.
local cpu2 is processor("CPU2"):connection.
local cpu3 is processor("CPU3"):connection.

// Geocoordinate for KSC
local KSCPos is ship:geoposition.

// Changeable variables:
    // Target inclination
    local inputInclination is 0. // + = ^, - = \/
    // Target altitude:
    // Notes:
    // - Shuttle will overshoot this number by a small amount
    // - Value must be > 70000 (to not re-enter atmosphere) - preferably 100000
    local targetAltitude is 100000.

// Math to calculate the new angle which cancels out the angular momentum of kerbin.
local neededVelocity is sqrt(constant:G * kerbin:mass / (kerbin:radius + targetAltitude)).
local latNeededVelocity is (neededVelocity) * sin(inputInclination).
local longNeededVelocity is (neededVelocity) * cos(inputInclination).
local actualInclination is arcTan2((latNeededVelocity), (longNeededVelocity - KSCPos:altitudevelocity(altitude):orbit:mag)).

// Variable to be used in the code (don't worry about it!).
local inclinationLaunch is 90 - actualInclination.

    // rest of the math / PID loop - don't touch, it's radioactive.
local gForcePID is PIDLoop(0.1, 0.3, 0.005, 0, 1).
set gForcePID:setpoint to 2.
local lock gForceThrottle to gForcePID:update(time:seconds, getGForce()).

// cargo constants
local shipEmptyMass is 859.826. // tons
local shipMaxCargoMass is 18. // tons
local shipCargoMass is ship:mass - shipEmptyMass. // tons

set ship:control:pilotmainthrottle to 0.4.


// take this out later
set DiagnosticMsg to inclinationLaunch + " degrees".

sas off.
rcs off.

clearscreen.
print "Starting...".

wait 1.
clearscreen.

// To control the throttle and pitch before liftoff
lock throttle to 0.3.
wait 2.
set FlightStatus to ("Main Engines Start").
stage.
wait until stage:ready.
// Pitch up and throttle up until i is past 0.4
stage.

set gForcePID:setpoint to 1.3.
local currentPitchTwang is 0.

until currentPitchTwang > ship:facing:pitch {

    if currentPitchTwang < ship:facing:pitch {
        set currentPitchTwang to ship:facing:pitch.
    }
    clearscreen.
    print currentPitchTwang.
    wait 0.
}
lock throttle to 0.7.
//set ship:control:pitch to -0.2.

when gForceThrottle > 0.4 and altitude > 400 then {
    lock throttle to gForceThrottle. 
}

set FlightStatus to ("Launch!").
local i is 0.

// More abort code - just checking for engine failiure so it can abort!
local lock startLaunchTime to time.
local endLaunchTime is time + timespan(0, 0, 0, 0, 0.5).
until ship:facing:pitch < currentPitchTwang - 0.1 {// startLaunchTime > endLaunchTime and  {
    clearscreen.
    print "twang: " + ship:facing:pitch.
    print "max twang: " + currentPitchTwang.
    print "time: " + time.
    if time > (endLaunchTime + timespan(0, 0, 0, 0, 1)) and ship:facing:pitch > currentPitchTwang {
        lock throttle to 0.
        print 1 / 0.
    }
}
//lock throttle to 0.4.
SET ship:control:neutralize to true.
wait 0.05.
stage.
ship:partsdubbed("srbthrottle")[0]:getmodule("ModuleRoboticController"):setfield("play/pause", 0).

set FlightStatus to ("Launching").
DisplayMFDLaunchLabels.
local pitchSteer is 90.
lock steering to heading(180,89,180).

until altitude > 130 {
    DisplayMFDLaunchData.
}

// Roll program
set FlightStatus to ("Cleared Launch Tower").
set steeringManager:maxstoppingtime to 2.

changeEngineState("ssme", "unlockYawRoll").
//set lights to not lights.

lock orientationLaunch to heading(inclinationLaunch,pitchSteer,180).
lock steering to orientationLaunch.

until abs(steeringManager:rollerror) < 5 {
    DisplayMFDLaunchData.
}

set pitchSteer to 86.

until altitude > 300 and abs(steeringManager:rollerror) < 5 {
    DisplayMFDLaunchData.
}
set gForcePID:setpoint to 1.5.
// Fitting 0% throttle to engineDesiredThrottle - so it doesn't throttle all the
// way down on ascent.

when abs(steeringManager:angleerror) < 0.5 and abs(steeringManager:rollerror < 0.5) and steering = orientationLaunch then {
    changeEngineState("ssme", "lockYawRoll").
    controlSurface("Rudder", "yaw", false).
}

when airspeed > 100 then {
    set FlightStatus to ("Ascent").
    set gForcePID:setpoint to 2.
}

when ship:q > 0.14 then {
    set FlightStatus to ("Max Q").
    set gForcePID:setpoint to 1.3.
    controlSurface("Rudder", "yaw", true).
    local maxQSpeed is airspeed.

    when airspeed > maxQSpeed + 10 and ship:q < 0.14 then {
        set FlightStatus to ("Ascent").
        set gForcePID:setpoint to 2.
    }
}

local velocityStep is airspeed.

until false {
    DisplayMFDLaunchData.
        // This changes the pitch based on the airspeed change. Basically
        // a gravity turn based on the speed.
    if airspeed > velocityStep {
	    set velocityStep to velocityStep + 1.35.
	    set pitchSteer to pitchSteer - 0.1.
    }
    if stage:resourceslex:solidfuel:amount < 1000 {
        set FlightStatus to ("SRB Sep").
        break.
    }

}

ag6 off.
lock steering to "kill".
changeEngineState("ssme", "unlockYawRoll").

until stage:resourceslex:solidfuel:amount < 40 {
    DisplayMFDLaunchData.
}

until stage:resourceslex:solidfuel:amount < 1 {
    stage.
}

set FlightStatus to ("STAGING SRBS: MAINTAIN ALTITUDE").
set gForcePID:setpoint to 1.
DisplayMFDLaunchData.
wait 4.
ag6 on.
set SteeringManager:MAXSTOPPINGTIME to 0.5.

lock steering to srfprograde + r(0,0,180).
set gForcePID:setpoint to 1.3.

until NavBallValues(ship):x < 40 or apoapsis > 71000 {
    DisplayMFDLaunchData.
}

set FlightStatus to ("SRBs clear").

local altSteerPID is PIDLoop(0.3, 0.0015, 0.02, 0.2, 1).
set altSteerPID:setpoint to verticalSpeed.
lock throttle to altSteerPID:update(time:seconds, verticalSpeed).

until vang(ship:facing:vector, steering:vector) < 2 and steeringmanager:rollerror < 10 {
    DisplayMFDLaunchData.
}

lock steering to heading(inclinationLaunch,NavBallValues(ship):x,180).
set steeringManager:maxstoppingtime to 0.18.

set gForcePID:setpoint to 2.


until eta:apoapsis > 70 {
    DisplayMFDLaunchData.
}

set FlightStatus to ("Finishing ascent").

until apoapsis > 70000 {
    DisplayMFDLaunchData.
}

when gForceThrottle > altSteerPID:update(time:seconds, verticalSpeed) then {
    lock throttle to gForceThrottle.
}

local angleAllowed is -7.
local lock apoapsisPID to PIDLoop(2, 0.0015, 0.001, angleAllowed, 20).
set apoapsisPID:setpoint to 60.

local lock apSteer to apoapsisPID:UPDATE(time:seconds, eta:apoapsis).

lock steering to heading(inclinationLaunch,apSteer,0).

until apoapsis > 70000 or stage:resourceslex:liquidfuel:amount < 100 {
    DisplayMFDLaunchData.
}

//set FlightStatus to ("Finishing ascent").
when stage:resourceslex:liquidfuel:amount < 3000 then {
    if apoapsis < targetAltitude - 10000 {
        set angleAllowed to 0.
        set DiagnosticMsg to "angle!!!".
    }
}

when apoapsis > targetAltitude and periapsis > -15000 then {
    set angleAllowed to -11.
}

until (apoapsis > targetAltitude and periapsis > -15000) or stage:resourceslex:liquidfuel:amount < 100 or periapsis > 60000 {
    DisplayMFDLaunchData.
}

set FlightStatus to ("MECO - Seperating MAIN TANK"). // 17100 units in ex tank - current: 1500 units left lf when carrying 18 tons
set DiagnosticMsg to round((stage:resourceslex:liquidfuel:amount) / 171, 1) + "% H₂".
lock throttle to 0.

changeEngineState("ssme", "locked").
changeEngineState("ssme", "off").

local transferEXTlf is transferAll("liquidfuel", topEXT, bottomEXT).
local transferEXTox is transferAll("oxidizer", topEXT, bottomEXT).
set transferEXTlf:active to true.
set transferEXTox:active to true.

rcs on.
lock steering to "kill".
DisplayMFDLaunchData.
wait 10.
DisplayMFDLaunchData.

until ship:stagenum < 2 {
    stage.
}

ag8 on.
set ship:control:top to 1.
set FlightStatus to ("Staged").

DisplayMFDLaunchData.

wait 4.

set ship:control:top to 0.

DisplayMFDLaunchLabels.
DisplayMFDLaunchData.

wait 2.


// Orbit insertion


// v2 = GM((2/r) - (1/a))
local lock accelerationOMS to ship:maxthrust / ship:mass.

// math
local uncircularizedOrbitSpd is sqrt(constant:g * kerbin:mass * ((2 / (kerbin:radius + apoapsis)) - (1 / ((apoapsis + periapsis + 2 * (kerbin:radius)) / 2)))).
local circularizedOrbitSpd is sqrt(constant:g * kerbin:mass * ((2 / (kerbin:radius + apoapsis)) - (1 / (kerbin:radius + apoapsis)))).
local circularizationΔV is circularizedOrbitSpd - uncircularizedOrbitSpd.
local circularizationTime is circularizationΔV / accelerationOMS.

set DiagnosticMsg to circularizationTime.

if periapsis < apoapsis - 4000 or apoapsis < targetAltitude - 1000 or periapsis < 70000 {
    local steerAngle is 0.
    lock steering to prograde + r(steerAngle,0,0).
    set ag6 to not ag6.
    set FlightStatus to ("Waiting for apoapsis burn").

    if apoapsis < targetAltitude - 1000 {
        lock throttle to 1.
        until apoapsis > targetAltitude - 100 {
            DisplayMFDLaunchData.
        }
        lock throttle to 0.
    }

    DisplayMFDLaunchData.
    rcs off.

    wait 1.

    set kuniverse:timewarp:warp to 2.

    if altitude < 70000 {

        until altitude > 70000 {
            DisplayMFDLaunchData.
        }

        set kuniverse:timewarp:warp to 0.
        wait 2.
        set kuniverse:timewarp:warp to 2.
    }

    until eta:apoapsis < (120 + circularizationTime) {
        DisplayMFDLaunchData.
    }

    set kuniverse:timewarp:warp to 1.

    until eta:apoapsis < circularizationTime * 0.9 {
        DisplayMFDLaunchData.
    }

    set kuniverse:timewarp:warp to 0.
    rcs on.
    set steeringManager:maxstoppingtime to 1.

    until eta:apoapsis < (circularizationTime / 2) and vang(ship:facing:vector, steering:vector) < 3 {
        DisplayMFDLaunchData.
    }
    rcs off.
    lock throttle to 1.

    //if eta:apoapsis > 2 and eta:apoapsis < 80
    //{
    local oldAp is apoapsis.
    until (periapsis > oldAp - 1000 or apoapsis > oldAp + 2500) and airspeed > 2000 {
        DisplayMFDLaunchData.
        if apoapsis > oldAp + 1000 {
            set steerAngle to 10.
        }

        if eta:apoapsis > 1200 or eta:apoapsis < 0 // 20 mins (time to orbit)
        {
            until periapsis > 70000 {
                DisplayMFDLaunchData.
            }
        }
    }

    set FlightStatus to ("Circularization complete").
    wait 0.5.
}
else {
    print "wtf????".
    wait 5.
}

set ship:control:pilotmainthrottle to 0.
lock throttle to 0.
rcs on.
set FlightStatus to ("Orbit!").
wait 2.
set FlightStatus to ("Steering to backwards position").
lock steering to retrograde + r(0,0,180).
ag8 on.
ag8 off.

until steeringManager:rollerror < 1 and steeringManager:angleerror < 1 {
    DisplayMFDLaunchData.
}

set FlightStatus to ("Opening payload bay").
wait 2.
ag3 on.

until abs(steeringManager:angleerror) < 0.1 and abs(steeringManager:rollerror) < 0.1 {
    DisplayMFDLaunchData.
}

set FlightStatus to ("End of program").
unlock steering.
sas on.
rcs off.
DisplayMFDLaunchData.



// ALL FUNCTIONS ARE PAST THIS POINT!


// *******************************************************************************************************************************************************************


// ALL FUNCTIONS ARE PAST THIS POINT!





function runtime
// Communication - do more with this later
{
    parameter sendMsg.
    local msg is "".
    if core:messages:empty = false {
        set msg to core:messages:pop:content.
    }
    cpu2:sendmessage(lex("cpu", "cpuMain", "msg", sendMsg)).

    //log ship:q to maxQ.txt.
}
// ---------------------------------------------------------------------- (70)


function DisplayMFDLaunchLabels
// Display the Multi-function Display (MFD) labels.
// Abbreviations:
//		Ap		Orbit Apoapsis km
//		Pe		Orbit Periapsis km
//		Inc		Orbit Inclination deg
//		Ptch	Vessel Pitch Angle deg
//		HDG		Vessel Heading deg
//		Roll	Vessel Roll Angle degrees
//		Yaw		Vessel Yaw Angle deg
//		Spd	    Airspeed m/s
//		Vspd	Vertical Speed m/s
//      SldFl   Solid Fuel
//      H₂      Liquid Fuel     MMH
//      O₂      Oxidizer        N₂O₄
//      EC      Electric Charge
//		WLat	Next waypoint latitude deg
//		WLon	Next waypoint longitude deg
//		WDst	Next waypoint great circle distance km
// Notes:
//    -weight of shuttle: 805 tons
// weight of the payload: 832 tons total: 27t   << way to do it??? is ship:wetmass in tons - 805 tons >> round(ship:wetmass - 805)
// ToDo:
//    - Consider calling the MFD update during a physics click eg
//      code a delegate function.
//
{
    set terminal:width to 42.
    set terminal:height to 23.

//         -123456789-123456789-123456789-123456789-1
//         XXXX XXXXXXXXXXXXX      XXXX XXXXXXXXXXXXX
    print "-----VESSEL-------      ------ASCENT------" at (0,00).
    print "Ap                      SldFl             " at (0,01).
//  print "Pe                      H₂                " at (0,02).
//  print "Inc                     O₂                " at (0,03).
    print "Ptch                    EC                " at (0,04).
    print "HDG                     Mono              " at (0,05).
    print "Roll                    Thr               " at (0,06).
    print "Spd                     Stag              " at (0,07).
    print "VSpd                    Gs                " at (0,08).
//  print "                                          " at (0,08).
    print "------------------STATUS------------------" at (0,09).
    print "                                          " at (0,10).
    print "                                          " at (0,11).
    print "                                          " at (0,12).
    print "                                          " at (0,13).
    print "                                          " at (0,14).
    print "                                          " at (0,15).
    print "-----------COMPUTER DIAGNOSTICS-----------" at (0,16).
    print "                                          " at (0,17).
    print "                                          " at (0,18).

    if ship:resources[2]:amount <= 2790 {
        print "Pe                      MMH               " at (0,02).
        print "Inc                     N₂O₄              " at (0,03).
    }
    else {
        print "Pe                      H₂                " at (0,02).
        print "Inc                     O₂                " at (0,03).
    }
}

  function DisplayMFDLaunchData
// Display the Multi-function Display (MFD) data.
{
    runtime("hi").

        // Vessel info.
    local ShipPYRVec to NavBallValues(ship).

    print MFDVal(round(ship:obt:apoapsis/1000,3) + " km") at (5,01).
    print MFDVal(round(ship:obt:periapsis/1000,3) + " km") at (5,02).
    print MFDVal(round(ship:obt:inclination,1) + char(176)) at (5,03).
    print MFDVal(round(ShipPYRVec:x,1) + char(176)) at (5,04).
    print MFDVal(round(ShipPYRVec:y,1) + char(176)) at (5,05).
    print MFDVal(round(ShipPYRVec:z,1) + char(176)) at (5,06).
	print MFDVal(round(ship:airspeed,1) + " m/s") at (5,07).
    print MFDVal(round(ship:verticalspeed,1) + " m/s") at (5,08).

        // Launch info.
	if stage:resourceslex:solidfuel:amount > 0 {
        print MFDVal(round(ship:resources[4]:amount * 0.0075,1) + " t") at (29,01). //sld
    }
    else {
        print MFDVal(" - ") at (29,01).
    }

	print MFDVal(round(ship:resources[2]:amount * 0.005,1) + " t") at (29,02). //lqd
	print MFDVal(round(ship:resources[3]:amount * 0.005,1) + " t") at (29,03). //ox
	print MFDVal(round(ship:resources[0]:amount * 0.005,1) + " t") at (29,04). //ec
	print MFDVal(round(ship:resources[1]:amount * 0.005,1) + " t") at (29,05). //mono

    print MFDVal(round(throttle,1)) at (29,06).
    print MFDVal(ship:stagenum) at (29,07).
    print MFDVal(round(getGForce(), 2)) at (29,08).

        // Status etc.
  	print "":padleft(terminal:width) at (0,10).
  	print FlightStatus at (0,10).
		print "":padleft(terminal:width) at (0,11).
		print "":padleft(terminal:width) at (0,12).

        // Diagnostic info.
  	print "":padleft(terminal:width) at (0,17).
  	print DiagnosticMsg at (0,17).
    print MFDVal(round(ship:q,5)) at (0,18).
    print MFDVal(round(ship:q * airspeed,5)) at (20,18).
}