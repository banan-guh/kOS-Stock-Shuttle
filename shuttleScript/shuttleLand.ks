CLEARSCREEN.

local AoA is 30.

local rollValue is 0.
local pitchValue is 0.
local yawValue is 0.

local impactzone is 0.

// changeable
//local landHeading is 0. deprecated
local rollReversalDistance is 250. // roughly 0.6 lat, i dont know bro get out
local landSpeed is 600.

sas off.

// Variables for the MFD and debugging.
local DiagnosticMsg is "".
local FlightStatus is "".

// global for stopping com balancing
global comBalanceId is 0. 

set steeringManager:rollcontrolanglerange to 180.

local lock shipLng to ship:geoposition:lng.
local kscLng is -74.72.
local kscLatLng is latlng(-0.04841539154982525,-74.734617905914533).
local kscLatLng2 is latlng(-0.04841539154982525,-75).

local lock shipPos to WrapTo360(shipLng - kscLng).

print "com: " + getCentreOfMass().
wait 0.1.

if periapsis > 70000 {
    local reenterLng is 195.

    set kuniverse:timewarp:mode to "rails".

    if shipPos < reenterLng or shipPos > reenterLng + 2 {
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
        wait 0.
    }

    set ag6 to not ag6.

    wait until vang(ship:facing:vector, steering:vector) < 1.
    wait 1.

    rcs off.

    lock throttle to 1. // needs 70m/s

    wait until addons:tr:hasimpact = true.
    wait 0.1.

    lock impactzone to addons:tr:impactpos.

    until periapsis < 60000 {
        print (impactzone:lng - kscLng).
        wait 0.01.
        clearScreen.
    }

    local lock impact to (impactzone:lng - kscLng).

    until impact < 26 {
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
lock steering to -up.
rcs on.
set ag6 to not ag6.
ag8 on.

wait until vang(ship:facing:vector, steering:vector) < 10 or altitude < 70000.

if altitude > 70000 {

    if kuniverse:timewarp:warp > 0 {
        set kuniverse:timewarp:warp to 0.
        wait 0.5.
    }

    set kuniverse:timewarp:warp to 3.
}

wait until altitude < 70000.

set target to "runway marker 09".

local initialShipPosition is ship:geoposition.

local lock energyOverWeight to altitude + (airspeed^2) / (2 * constant:g0).
local lock runwayAngle to arcSin(altitude / kscLatLng2:position:mag).

changeEngineState("oms", "off").
changeEngineState("oms", "locked").
// lower = less stable, higher = more stable

when altitude < 65000 then {
    startCOMBalancing(2.59, 30).
}

wait 0.1.
set kuniverse:timewarp:warp to 0.
local lock landLat to round(impactzone:lat,2).

//if landLat > 0.5 or airspeed < landSpeed {
    //wait 0.5.
    //set kuniverse:timewarp:warp to 2.
//}

controlSurface("smallElevon", "pitch", false).
controlSurface("smallElevon", "roll", false).

controlSurface("largeElevon", "pitch", false).
controlSurface("largeElevon", "roll", false).

controlSurface("Canard", "pitch", false).
controlSurface("Canard", "deploy", false).

controlSurface("Rudder", "yaw", true).

// disable front rcs // deprecated, disable ALL rcs except for yaw
ship:partsdubbed("rcsController")[0]:getmodule("ModuleRoboticController"):setfield("play/pause", 0).
//wait 0.1.
//ship:partsdubbed("rcsController")[0]:getmodule("ModuleRoboticController"):setfield("play/pause", 1).

when airspeed < landSpeed + 50 then {
    // disable pitch control
    //ship:partsdubbed("rcsController")[0]:getmodule("ModuleRoboticController"):setfield("play/pause", 0).
    
    startCOMBalancing(3, 30).
    ag9 on.
    wait 2.
}

local hinge is ship:partsdubbed("hinge")[0]:getmodule("ModuleRoboticServoHinge").
set ag6 to not ag6.
//lock steering to prograde + r(0,0,45).
set DiagnosticMsg to "hi saapoifkjapodkjsaoijesaoifj".

DisplayMFDReenterLabels().

set kuniverse:timewarp:warp to 0.
rcs on.

local rollConstant is 40. // wont be a constant in the future

local pitchLngPID is pidLoop(4,1,2,-7,7).
local lock pitchLngSetting to -pitchLngPID:update(time:seconds, impactZ + 1).
set pitchLngPID:setpoint to 0.
lock AoA to 36 + pitchLngSetting.
local lock hingeAngle to -(steeringManager:pitchpid:output * 50) + 160.

//until landLat > (rollReversalLat / 2) or airspeed < landSpeed {
//    DisplayMFDReenterData().
//}
set DiagnosticMsg to "WHAT THE HELl".

lock steering to prograde + r(pitchValue,yawValue,rollValue).
set ag8 to not ag8.

when altitude < 12000 and airspeed < 700 then {
    unlock AoA.
    set AoA to 20.
    hinge:setfield("target angle", 160).
}

local degrees is -rollConstant.

// ------------------------------------------------------------
// main reentry program
until airspeed < landSpeed {
    //local dist is getWeightedReversalNumber().

    calcReentry().
    DisplayMFDReenterData().
    set DiagnosticMsg to "bye".

    if airspeed > 700 {
        hinge:setfield("target angle", hingeAngle). //160
    }

    if isOutLateralRange() {
        setAttitude(sign(getWeightedReversalNumber())).
        set DiagnosticMsg to "waiting".
        until isInLateralRange() or airspeed < landSpeed {
            DisplayMFDReenterData().
        }
    }
}

set FlightStatus to "im out good luck".
controlSurface("largeElevon", "roll", true).
controlSurface("Canard", "deploy", true).
controlSurface("Rudder", "yaw", false).
set kuniverse:timewarp:warp to 0.
lock steering to "kill".
set steeringManager:maxstoppingtime to 0.3.
//wait 3.
ag8 on.
lock steering to srfprograde.
wait 1.
hinge:setfield("target angle", 155).
local steerPitch is 0.
local steerAngle is 270.
lock steering to lookdirup((kscLatLng2:position + r(0,steerPitch,0)), (up + r(steerAngle,0,0)):vector).
//kscLatLng2:position + r(0, steerPitch, 270).
//lookdirup((kscLatLng2:position + r(steerPitch,0,0):vector), (up + r(steerAngle,0,0)):vector).
// steerangle + = bank left, - = bank right
rcs off.

until altitude < 90000 {

    DisplayMFDReenterData().

    local bankAngle is 15.

    if ship:heading < 89 {
        set steerAngle to -bankAngle.
    }
    else if ship:heading > 91 {
        set steerAngle to bankAngle.
    }
    else {
        set steerAngle to 0.
    }

    //airbrake
    if (airspeed > 200 and altitude < 13000 and runwayAngle > 28) or (runwayAngle > 35 and airspeed > 100) {
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

    controlSurface("Rudder", "deploy", false).
    brakes off.
}

// End of code

FUNCTION sign {
  PARAMETER value.
  LOCAL result IS -1.
  IF value > 0 { SET result TO 1. }
  RETURN result.
}

function setAttitude
{
    parameter rollSign.
    set degrees to rollSign * rollConstant.

    until airspeed < landSpeed {

        local multiplier is 15.
        local stopTime is time + (0.01 * multiplier).
        
        local degrees2 is degrees.

        set degrees to degrees - (rollSign * 0.1 * multiplier).
        set DiagnosticMsg to "degrees before: " + round(degrees2) + ", after: " + round(degrees).
        DisplayMFDReenterData().

        if (degrees * rollSign) < -rollConstant {
            break.
        }

        calcReentry().

        wait until time > stopTime.
        
    }
    set degrees to -rollSign * rollConstant.
}

function calcReentry {
    local degree is degrees + 90.
    set rollValue to -(180 - degree - 90).
    set pitchValue to cos(degree) * AoA.
    set yawValue to sin(degree) * AoA.
}

function getDistanceFromRunwayPath {
    parameter initialPosition is initialShipPosition.
    local greatCirclePlanePole is vcrs(initialPosition:position, kscLatLng:position):normalized.
    local diff is vdot(greatCirclePlanePole, ship:geoposition:position).
    return diff.
}

function getLateralVelocity {
    parameter initialPosition is initialShipPosition.
    local greatCirclePlanePole is vcrs(initialPosition:position, kscLatLng:position):normalized.
    local shipVel is ship:velocity:orbit.
    local lateralVel is vdot(greatCirclePlanePole, shipVel).
    return lateralVel.
}

function getWeightedReversalNumber {
    return (getDistanceFromRunwayPath() * 1) + (getLateralVelocity() * 4).
}

function isOutLateralRange {
    return (getWeightedReversalNumber() > rollReversalDistance or getWeightedReversalNumber() < -rollReversalDistance).
}

function isInLateralRange {
    return (abs(getWeightedReversalNumber()) < rollReversalDistance).
}

function startCOMBalancing {
    parameter targetCOM.
    parameter timeoutSeconds.

    set comBalanceId to comBalanceId + 1.
    local myId is comBalanceId.
    local endTime is time:seconds + timeoutSeconds.

    // COM is too far one way
    when (time:seconds > endTime) or (myId <> comBalanceId) or (getCentreOfMass() > targetCOM + 0.01) then {
        if (time:seconds > endTime) or (myId <> comBalanceId) { return false. }
        
        shiftCOM(false, true).
        return true.
    }
    // COM is too far the other way
    when (time:seconds > endTime) or (myId <> comBalanceId) or (getCentreOfMass() < targetCOM) then {
        if (time:seconds > endTime) or (myId <> comBalanceId) { return false. }
        
        shiftCOM(false, false).
        return true.
    }
    // COM is balanced
    when (time:seconds > endTime) or (myId <> comBalanceId) or (getCentreOfMass() > targetCOM and getCentreOfMass() < targetCOM + 0.02) then {
        if (time:seconds > endTime) or (myId <> comBalanceId) { return false. }
        
        shiftCOM(true, false).
        return true.
    }
}

function stopCOMBalancing {
    set comBalanceId to comBalanceId + 1. 
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
    print isOutLateralRange() at (0,18).
    print MFDVal(round(getDistanceFromRunwayPath(),2)) at (20,18).
}