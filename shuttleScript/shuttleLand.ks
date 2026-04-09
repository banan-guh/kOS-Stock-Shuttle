CLEARSCREEN.

local AoA is 30.

local rollValue is 0.
local pitchValue is 0.
local yawValue is 0.

local impactzone is 0.

// changeable
local landHeading is 0.
local rollReversalLat is 0.6.
local landSpeed is 950.

sas off.

// Variables for the MFD and debugging.
local DiagnosticMsg is "".
local FlightStatus is "".


set steeringManager:rollcontrolanglerange to 180.

local lock shipLng to ship:geoposition:lng.
local kscLng is -74.72.
local kscLatLng is latlng(-0.04841539154982525,-74.734617905914533).
local kscLatLng2 is latlng(-0.04841539154982525,-75).

local lock shipPos to WrapTo360(shipLng - kscLng).

print "com: " + getCentreOfMass().
wait 1.

if periapsis > 70000 {
    local reenterLng is 220.

    set kuniverse:timewarp:mode to "rails".

    if shipPos < reenterLng {
        set kuniverse:timewarp:warp to 4.
    }

    until shipPos > reenterLng and shipPos < reenterLng + 2 {
        print round(shipPos,2).
        wait 0.01.
        clearscreen.
    }

    set kuniverse:timewarp:warp to 0.
    set kuniverse:timewarp:warp to 0.
    
    lock steering to retrograde + r(0,0,180).

    rcs on.

    if bays = true {
        set bays to false.
        wait 5.
    }

    wait 1.

    until ship:maxthrust > 60 {
        stage.
        changeEngineState("ssme", "off").
        changeEngineState("ssme", "locked").
    }

    set ag6 to not ag6.

    wait until vang(ship:facing:vector, steering:vector) < 1.

    rcs off.

    lock throttle to 1. // needs 70m/s

    wait until addons:tr:hasimpact = true.

    lock impactzone to addons:tr:impactpos.

    until periapsis < 60000 {
        print (impactzone:lng - kscLng).
        wait 0.01.
        clearScreen.
    }

    local lock impact to (impactzone:lng - kscLng).

    until impact < 30 {
        clearScreen.
        print impact.
        wait 0.
    }
    lock throttle to 0.
}

set landHeading to kscLatLng2:heading.

lock throttle to 0.
lock impactzone to addons:tr:impactpos.

lock impactZ to (impactzone:lng - kscLng).
print (impactzone:lng - kscLng).
lock throttle to 0.
lock steering to prograde.
rcs on.
set ag6 to not ag6.
ag8 on.

wait until vang(ship:facing:vector, steering:vector) < 10.

if altitude > 70000 {

    if kuniverse:timewarp:warp > 0 {
        set kuniverse:timewarp:warp to 0.
        wait 0.5.
    }

    set kuniverse:timewarp:warp to 3.
}

wait until altitude < 70000.

set target to "runway marker 09".

local lock runwayAngle to arcSin(altitude/kscLatLng2:position:mag).

changeEngineState("oms", "off").
changeEngineState("oms", "locked").
// lower = less stable, higher = more stable

local keepBalancing is true.
local balance1 is 2.6.

when getCentreOfMass() > balance1 + 0.01 then {
    shiftCOM(false, true).

    return keepBalancing.
}

when getCentreOfMass() < balance1 then {
    shiftCOM(false, false).

    return keepBalancing.
}

when getCentreOfMass() > balance1 and getCentreOfMass() < balance1 + 0.02 then {
    shiftCOM(true, false).

    return keepBalancing.
}


wait 1.
set kuniverse:timewarp:warp to 0.
local lock landLat to round(impactzone:lat,2).

if landLat > rollReversalLat or airspeed < landSpeed {
    wait 0.5.
    set kuniverse:timewarp:warp to 2.
}

controlSurface("smallElevon", "pitch", false).
controlSurface("smallElevon", "roll", false).

controlSurface("largeElevon", "pitch", false).
controlSurface("largeElevon", "roll", false).

controlSurface("Canard", "pitch", false).
controlSurface("Canard", "deploy", false).

controlSurface("Rudder", "yaw", false).

// disable front rcs
ship:partsdubbed("rcsController")[0]:getmodule("ModuleRoboticController"):setfield("play/pause", 0).
wait 0.1.
ship:partsdubbed("rcsController")[0]:getmodule("ModuleRoboticController"):setfield("play/pause", 1).

when airspeed < landSpeed + 250 then {
    set keepBalancing to false.
    // disable pitch control
    ship:partsdubbed("rcsController")[0]:getmodule("ModuleRoboticController"):setfield("play/pause", 0).
    
    local com2 is 3.5.

    when getCentreOfMass() > com2 + 0.01 then {
        shiftCOM(false, true).

        return true.
    }

    when getCentreOfMass() < com2 then {
        shiftCOM(false, false).

        return true.
    }

    when getCentreOfMass() > com2 and getCentreOfMass() < com2 + 0.01 then {
        shiftCOM(true, false).

        return true.
    }
}

local hinge is ship:partsdubbed("hinge")[0]:getmodule("ModuleRoboticServoHinge").
set ag6 to not ag6.
lock steering to prograde + r(0,0,45).
set DiagnosticMsg to "hi saapoifkjapodkjsaoijesaoifj".

DisplayMFDReenterLabels().

set kuniverse:timewarp:warp to 0.
rcs on.

local rollConstant is 40. // wont be a constant in the future
local reversePending is false.

local pitchLngPID is pidLoop(4,1,2,-7,7).
local lock pitchLngSetting to -pitchLngPID:update(time:seconds, impactZ + 2.35).
set pitchLngPID:setpoint to 0.
lock AoA to 35 + pitchLngSetting.
local lock hingeAngle to -(steeringManager:pitchpid:output * 50) + 160.

until landLat > rollReversalLat or airspeed < landSpeed {
    DisplayMFDReenterData().
}
set DiagnosticMsg to "WHAT THE HELl".

lock steering to prograde + r(pitchValue,yawValue,rollValue).
set ag8 to not ag8.

when airspeed < 1000 then {
    unlock AoA.
    set AoA to 20.
    hinge:setfield("target angle", 160).
}

local degrees is -rollConstant.


// ------------------------------------------------------------
// main reentry program
until airspeed < landSpeed {

    calcReentry().
    DisplayMFDReenterData().
    set DiagnosticMsg to "bye".

    if airspeed > 1001 {
        hinge:setfield("target angle", hingeAngle). //160
    }

    if (landLat > rollReversalLat or landLat < -rollReversalLat) and not reversePending {
        doReversal().
    }

    function doReversal
    // you need rollcontrolanglerange to be 180
    {
        local isNegativeInstance is isNegative().
        set reversePending to true.
        set degrees to isNegativeInstance * rollConstant.
        calcReentry().

        until not reversePending or airspeed < landSpeed {

            local multiplier is 5.
            local stopTime is time + (0.01 * multiplier).

            set degrees to degrees - (isNegativeInstance * 0.1 * multiplier).
            set DiagnosticMsg to degrees.
            DisplayMFDReenterData().

            if (degrees + (rollConstant * isNegativeInstance)) * isNegativeInstance < 0 {
                set reversePending to false.
            }

            calcReentry().

            wait until time > stopTime.
        }

        set degrees to isNegativeInstance * -rollConstant.

        until landLat < rollReversalLat or airspeed < landSpeed {
            // idk put whatever here, maybe mfd data
        }
    }

    function isNegative
    // returns if shuttle is going in negative lat direction or not
    {
        if landLat > 0
            return 1.
        else
            return -1.
    }
}

set FlightStatus to "im out good luck".
controlSurface("largeElevon", "roll", true).
controlSurface("Canard", "deploy", true).
set kuniverse:timewarp:warp to 0.
lock steering to "kill".
set steeringManager:maxstoppingtime to 0.3.
wait 3.
ag8 on.
lock steering to srfprograde.
wait 5.
hinge:setfield("target angle", 155).
local steerPitch is 0.
local steerAngle is 270.
lock steering to kscLatLng2:position + r(0,steerPitch,steerAngle).
// steerangle + = bank left, - = bank right
rcs off.

until altitude < 5000 {

    DisplayMFDReenterData().

    local bankAngle is 15.

    if ship:heading < 88 {
        set steerAngle to -90 + bankAngle.
    }
    else if ship:heading > 92 {
        set steerAngle to -90 - bankAngle.
    }
    else {
        set steerAngle to -90.
    }

    //airbrake
    if (airspeed > 200 and altitude < 8000 and runwayAngle > 27) or (runwayAngle > 25 and airspeed > 100) {
        brakes on.
    }
    else {
        brakes off.
    }
    //glide further if distance is too far
    if kscLatLng2:position:mag > 18000 or runwayAngle < 21 {
        if runwayAngle < 17 {
            set steerPitch to 10.
        }
        else {
            set steerPitch to 6.
        }
    }
    else {
        set steerPitch to 1.
    }
    if runwayAngle > 29 {
        set steerPitch to -4.
    }
}

// End of code

function calcReentry {
    local degree is degrees + 90.
    set rollValue to -(180 - degree - 90).
    set pitchValue to cos(degree) * AoA.
    set yawValue to sin(degree) * AoA.
}

function DisplayMFDReenterLabels
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
    print "-----VESSEL-------      ------DESCENT-----" at (0,00).
    print "Ap                      Lng               " at (0,01).
    print "Pe                      Lat               " at (0,02).
    print "Inc                     Flap              " at (0,03).
    print "Ptch                    CoM               " at (0,04).
    print "HDG                     Glide             " at (0,05).
    print "Roll                    AoA               " at (0,06).
    print "Spd                     Bank              " at (0,07).
    print "Dist                    Gs                " at (0,08).
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
}

  function DisplayMFDReenterData
// Display the Multi-function Display (MFD) data.
{
        // Vessel info.
    local ShipPYRVec to NavBallValues(ship).

    print MFDVal(round(ship:obt:apoapsis/1000,3) + " km") at (5,01).
    print MFDVal(round(ship:obt:periapsis/1000,3) + " km") at (5,02).
    print MFDVal(round(ship:obt:inclination,3) + char(176)) at (5,03).
    print MFDVal(round(ShipPYRVec:x,1) + char(176)) at (5,04).
    print MFDVal(round(ShipPYRVec:y,1) + char(176)) at (5,05).
    print MFDVal(round(ShipPYRVec:z,1) + char(176)) at (5,06).
	print MFDVal(round(ship:airspeed,1) + " m/s") at (5,07).
    print MFDVal(round((kscLatLng2:position:mag/1000),1) + " km") at (5,08).

        // Land info.
    print MFDVal(round(impactZ,2)) at (29,01). //lng
	print MFDVal(round(landLat,2)) at (29,02). //lat
	print MFDVal(round(hingeAngle,2)) at (29,03). //flap
	print MFDVal(round(getCentreOfMass(),3)) at (29,04). //com
	print MFDVal(round(runwayAngle,1)) at (29,05). //glide
    print MFDVal(round(AoA,1)) at (29,06). //aoa
    print MFDVal(rollConstant) at (29,07). //bank
    print MFDVal(round(getGForce(), 2)) at (29,08). //gs

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