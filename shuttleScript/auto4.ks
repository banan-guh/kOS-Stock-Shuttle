// this is a heavily modified version of drone V05 by JitteryJet or Patched Conics on Youtube
// Program Title: drone
// Author: JitteryJet
// Version: V07 or auto4

@lazyglobal off.

runoncepath("0:/shuttleScript/shuttleLib").

// Variables for the MFD and debugging.
local DiagnosticMsg is "".
local FlightStatus is "".

// Misc. globals.
//ocal DiagnosticMsg to "".
//local FlightStatus to "                  ".

// State change globals.
local FlightModeChangePending to false.
local LandAtKSCControlPending to true. // for the purposes of the space shuttle script
local QuitControlPending to false.

// Commanded by autopilot globals.
local CmdedX to 0.
local CmdedY to 0.
local CmdedZ to 0.
local CmdedVSpeed to 0.

// Waypoint globals.
local WaypointSelected to false.
local NextWPName to "".
local NextWPGeo to "".
local NextWPRunwayHeading to 0.
local NextWPRunwayAlt to 0.
local NextWPFlyoverAlt to 0.
local NextWPGreatCDist to 0.

// The Vertical Speed PID loop regulates the vertical speed of the vessel by controlling the X angle. Values are clamped to avoid the vessel becoming uncontrollable and/or potential gimbal lock.
local VSpeedPID is PIDLoop(0.5, 0.05, 0.2, -60, 60).

// The Heading PID loop regulates the heading of the vessel by controlling the bank angle. Values are clamped to avoid the vessel becoming uncontrollable and or potential gimbal lock.
local HeadingPID is PIDLoop(1.2, 0.01, 0.5, -45, 45).

local maxLandingAoA is 20.

ClearScreen.
DisplayMFDLabels().
SAS off.
unlock throttle.
unlock steering.
set steeringManager:maxstoppingtime to 0.5.

controlSurface("Canard", "authority", 15).
controlSurface("Canard", "deploy", true).
controlSurface("smallElevon", "authority", 15).
controlSurface("largeElevon", "authority", 25).
controlSurface("Rudder", "authority", 10).

controlSurface("largeElevon", "roll", true).
controlSurface("largeElevon", "pitch", false).
controlSurface("smallElevon", "pitch", false).
controlSurface("Canard", "pitch", false).

rcs off.
brakes off.

set ship:control:neutralize to false.
set LandAtKSCControlPending to true.
set FlightModeChangePending to true.

ControlAircraft().


// Control the vessel on script start, then handle any mode changes after the script has started.
function ControlAircraft
{
    local finished to false.
    until finished {
        set FlightModeChangePending to false.
        
        if (ship:status = "PRELAUNCH" or ship:status = "LANDED" or ship:status = "SPLASHED") and airspeed > 0.1 {
            landed().
        } else if LandAtKSCControlPending and airspeed > 0.1 {
            set LandAtKSCControlPending to false.
            set WaypointSelected to true.
            LandAtKSC().
        } else if QuitControlPending {
            set QuitControlPending to false.
            quit().
            set finished to true.
        }
    }
}


// Land on the runway marked by the waypoint selected.
function LandOnRunway
{
    local finished to false.
    local CurrentX to 0.
    local CurrentY to 0.
    local DeltaX to 0.
    local landing to false.
    local descent to false.
    local RelAng to 0.

    set FlightStatus to "Autopilot - Flying to runway.".
    set CmdedVSpeed to -20.
    set NextWPFlyoverAlt to NextWPRunwayAlt.

    lock steering to angleaxis(CmdedZ,ship:srfprograde:forevector) * angleaxis(DeltaX,ship:srfprograde:starvector) * ship:srfprograde.

    when alt:radar < 120 then {
        gear on.
    }

    until finished or FlightModeChangePending {
        set CurrentX to VecXAng(ship:srfprograde:forevector).
        set CurrentY to VecYAng(ship:srfprograde:forevector).
        set NextWPGreatCDist to GreatCircleDistance(ship:geoposition,NextWPGeo,NextWPGeo:terrainheight+ship:body:radius).
        
        if not landing and NextWPGreatCDist < 100 {
            set landing to true.
            set FlightStatus to ("                             ").
            set FlightStatus to "Autopilot - Landing NOW".
            set CmdedVSpeed to 0.
            set CmdedY to NextWPRunwayHeading.
        }
        
        if not landing and not descent and NextWPGreatCDist < 10000 {
            set descent to true.
            set FlightStatus to ("                            ").
            set FlightStatus to "Autopilot - Descent to runway".
        }
        
        if landing {
            if ship:status = "LANDED" or ship:status = "SPLASHED" {
                set FlightModeChangePending to true.
                set finished to true.
            }
        } else if descent {
            set RelAng to YAngRel(NextWPRunwayHeading,NextWPGeo:heading).
            if RelAng > -90 and RelAng < 90 {
                set CmdedVSpeed to VSpeedToWaypoint(NextWPGeo,NextWPFlyoverAlt).
                set CmdedY to ApproachAzimuth().
            }
        } else {
            set RelAng to YAngRel(NextWPRunwayHeading,NextWPGeo:heading).
            if RelAng > -90 and RelAng < 90 {
                set CmdedVSpeed to VSpeedToWaypoint(NextWPGeo,NextWPFlyoverAlt).
                set CmdedY to ApproachAzimuth().
            }
        }
        
        //set CmdedX to XSetting(CmdedVSpeed,ship:verticalspeed).
		local progradePitch is VecXAng(ship:srfprograde:forevector).
		set CmdedX to min(max(CmdedX, progradePitch - maxLandingAoA), progradePitch + maxLandingAoA).
        set CmdedZ to BankSetting(CmdedY,CurrentY).
        set DeltaX to CmdedX-CurrentX.
		//set DeltaX to min(max(DeltaX, -maxLandingAoA), maxLandingAoA).
        DisplayMFDData().
        wait 0.
    }
}


// Land at the Kerbal Space Centre.
function LandAtKSC
{
    set NextWPName to "Approach to KSC Runway 09 - Lining up".
    set NextWPFlyoverAlt to 150.
    set NextWPGeo to latlng(-0.04841539154982525,-74.81).

    //if abs(ship:obt:inclination) > 3 {
    //  set NextWPGeo to latlng(-0.04841539154982525,-74.9).
    //  set NextWPFlyoverAlt to 1000.
    //}
    FlyToWaypoint().

    set NextWPName to "KSC Runway 09 (Landing)".
    set NextWPGeo to latlng(-0.04841539154982525,-74.735).
    set NextWPRunwayHeading to 90.
    set NextWPRunwayAlt to 30.

    LandOnRunway().
}


// Fly to the next waypoint.
function FlyToWaypoint
{
    local CurrentX to 0.
    local CurrentY to 0.
    local DeltaX to 0.
    local finished to false.
	
    lock steering to angleaxis(CmdedZ,ship:srfprograde:forevector) * angleaxis(DeltaX,ship:srfprograde:starvector) * ship:srfprograde.

    until finished or FlightModeChangePending {
        set CurrentX to VecXAng(ship:srfprograde:forevector).
        set CurrentY to VecYAng(ship:srfprograde:forevector).
        set NextWPGreatCDist to GreatCircleDistance(ship:geoposition,NextWPGeo,NextWPGeo:terrainheight+ship:body:radius).
        set CmdedVSpeed to VSpeedToWaypoint(NextWPGeo,NextWPFlyoverAlt).
        set CmdedX to XSetting(CmdedVSpeed,ship:verticalspeed).
        set CmdedY to NextWPGeo:heading.
        set CmdedZ to BankSetting(CmdedY,CurrentY).
        set DeltaX to CmdedX-CurrentX.
        
        if NextWPGreatCDist < 350 {
            set finished to true.
        }
            
        DisplayMFDData().
        wait 0.
    }
}


// Landed.
function landed
{
    set FlightStatus to "Landed".
    lock throttle to 0.
    if airspeed > 2 {
        sas on.
    }
    unlock throttle.
    unlock steering.
    brakes on.
    stage.
    DisplayMFDData().
    wait until airspeed < 0.1.
    sas off.
    set DiagnosticMsg to "hi".
    rcs off.
    quit().
}


// Quit the program.
function quit
{
    set FlightStatus to "Program quit".
    DisplayMFDData().
    unlock throttle.
    unlock steering.
    set ship:control:pilotmainthrottle to 0.
    set ship:control:neutralize to true.
    set QuitControlPending to true.
}


// Create a vector that contains the vessel's pitch, yaw and roll values, as they would appear on the vessel's NavBall.
function NavBallValues
{
    parameter mainVessel.
    local vec to V(0,0,0).
    local NorthHorizonDir to lookdirup(mainVessel:north:forevector,mainVessel:up:forevector).
    local DifferenceDir to (mainVessel:facing:inverse*NorthHorizonDir):inverse.
    
    // Adjust the rotational angles into the conventions used by the NavBall.
    if DifferenceDir:pitch > 180 {
        set vec:x to 360 - DifferenceDir:pitch.
    } else {
        set vec:x to -DifferenceDir:pitch.
    }
        
    set vec:y to DifferenceDir:yaw.
    
    if DifferenceDir:roll > 180 {
        set vec:z to DifferenceDir:roll-360.
    } else {
        set vec:z to DifferenceDir:roll.
    }
        
    return vec.
}


// Return the X angle of a vector.
function VecXAng
{
    parameter vec.
    return(-(90-vang(ship:up:forevector,vec))).
}


// Return the Y angle of a vector.
function VecYAng
{
    parameter vec.
    local east to vcrs(ship:up:forevector,ship:north:forevector).
    local trig_x is vdot(ship:north:forevector,vec).
    local trig_y is vdot(east,vec).
    local result is arctan2(trig_y,trig_x).

    if result < 0 {
        return 360 + result.
    } else {
        return result.
    }
}


// Return the Z angle of a direction.
function DirZAng
{
    parameter dir.
    local ang is 0.
    
    if vang(dir:forevector,ship:up:forevector) < 0.2 {
        return 0.
    }
        
    set ang to vang(vxcl(dir:forevector,ship:up:forevector),dir:starvector).
    
    if vang(ship:up:forevector,dir:topvector) > 90 {
        if ang > 90 {
            return 270-ang.
        } else {
            return -(90+ang).
        }
    } else {
        return 90-ang.
    }
}


// Calculate the vessel X angle for a specified commanded vertical speed.
// Notes:
//      - this is goofy as hellllll
function XSetting
{
    parameter CommandedVSpeed.
    parameter CurrentVSpeed.

    local setting is 0.
    set setting to VSpeedPID:update(time:seconds, CommandedVSpeed - CurrentVSpeed).
    return setting.
}


// Calculate a bank turn angle used to bring about a change in heading.
function BankSetting
{
    parameter CommandedHeading.
    parameter CurrentHeading.

    local DeltaY to YAngRel(CurrentHeading,CommandedHeading).
    local Z to HeadingPID:update(time:seconds,DeltaY).

    return Z.
}


// Calculate the relative angle between initial and final compass angles.
function YAngRel
{
    parameter InitialAng.
    parameter FinalAng.

    local diff to FinalAng-InitialAng.

    if diff < -180 {
        set diff to diff + 360.
    } else if diff > 180 {
        set diff to diff - 360.
    }

    if abs(diff) > 180 {
        print 1/0. // Terminate. Angle difference is out of range.
    }

    return diff.
}


// Wrap an angle to the range 0 to 360.
function WrapTo360
{
    parameter ang.
    local wrapped to mod(ang,360).

    if wrapped < 0 {
        set wrapped to wrapped + 360.
    }

    return wrapped.
}


// Calculate the approach azimuth to the start of the runway.
function ApproachAzimuth
{
    local RelAng to YAngRel(NextWPRunwayHeading,NextWPGeo:heading).
    
    // If the vessel is not at the approach end of the runway, make it turn and head in that direction. This algorithm only works from the approach end.
    if RelAng < -90 or RelAng > 90 {
        return -NextWPRunwayHeading.
    }
        
    local theta to 90-abs(RelAng).
    local offset to 90-arccos(2*cos(theta)/sqrt((2*cos(theta))^2+(sin(theta))^2)).
	local azimuth to 0.

    if RelAng > 0 {
        set azimuth to WrapTo360(NextWPRunwayHeading+offset).
    } else {
        set azimuth to WrapTo360(NextWPRunwayHeading-offset).
    }

    //set DiagnosticMsg to NextWPGeo:heading + " " + offset + " " + RelAng.

    return azimuth.
}


// Calculate the Great Circle distance between two points at a given radius from a body's centre.
function GreatCircleDistance
{
    parameter p1.
    parameter p2.
    parameter radius.

    local a is sin((p1:lat - p2:lat) / 2)^2 + cos(p1:lat) * cos(p2:lat) * sin((p1:lng - p2:lng) / 2)^2.

    return radius*constant():PI*arctan2(sqrt(a),sqrt(1-a))/90.
}


// Calculate the vertical speed required to get from the vessel's current altitude to the flyover altitude of the waypoint.
function VSpeedToWaypoint
{
    parameter WP.
    parameter FlyoverAlt.

    local DeltaAlt is WP:terrainheight+FlyoverAlt - ship:altitude.
    local dist is GreatCircleDistance(ship:geoposition, WP, ship:altitude + ship:body:radius).
    local VSpeed is DeltaAlt / (dist / ship:groundspeed).

    return VSpeed.
}


// Display a Heads Up Display (HUD) message.
function DisplayHUDMessage
{
    parameter text.
    HUDText(text, 5, 2, 30, white, false).
}


// Display the Multi-function Display (MFD) labels.
// Abbreviations:
//      Ap      Orbit Apoapsis km
//      Pe      Orbit Periapsis km
//      Inc     Orbit Inclination deg
//      Ptch    Vessel Pitch Angle deg
//      HDG     Vessel Heading deg
//      Roll    Vessel Roll Angle degrees
//      Yaw     Vessel Yaw Angle deg
//      ASpd    Airspeed m/s
//      Vspd    Vertical Speed m/s
//      WLat    Next waypoint latitude deg
//      WLon    Next waypoint longitude deg
//      WDst    Next waypoint great circle distance km
// Notes:
//    -
// ToDo:
//    - Consider calling the MFD update during a physics click eg code a delegate function.
//
function DisplayMFDLabels
{
    set terminal:width to 50.
    set terminal:height to 22.
//         -123456789-123456789-123456789-123456789-1
//         XXXX XXXXXXXXXXXXX      XXXX XXXXXXXXXXXXX
    print "-----VESSEL-------      ------DESCENT-----" at (0,00).
    print "Ap                      WPtch             " at (0,01).
    print "Pe                      WHDG              " at (0,02).
    print "Inc                     WRoll             " at (0,03).
    print "Ptch                    WSpd              " at (0,04).
    print "HDG                     WVSpd             " at (0,05).
    print "Roll                    WLat              " at (0,06).
    print "Spd                     WLon              " at (0,07).
    print "VSpd                    WDst              " at (0,08).
    print "                                          " at (0,08).
    print "------------------STATUS------------------" at (0,09).
    print "                                          " at (0,10).
    print "                                          " at (0,11).
    print "                                          " at (0,12).
    print "                                          " at (0,13).
    print "                                          " at (0,14).
    print "                                          " at (0,15).
    print "-----------COMPUTER DIAGNOSTICS-----------" at (0,16).
    print "                                          " at (0,17).
}


// Display the Multi-function Display (MFD) data.
function DisplayMFDData
{
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

    // Autopilot info.
    print MFDVal(-round(CmdedX,1) + char(176)) at (29,01).
    print MFDVal(round(CmdedY,1) + char(176)) at (29,02).
    print MFDVal(round(CmdedZ,1) + char(176)) at (29,03).
    print MFDVal("--- m/s") at (29,04).
    print MFDVal(round(CmdedVSpeed,1) + " m/s") at (29,05). // the special one
    
    // Waypoint info.
    if WaypointSelected {
        print MFDVal(round(NextWPGeo:lat,8) + char(176)) at (29,06).
        print MFDVal(round(NextWPGeo:lng,8) + char(176)) at (29,07).
        print MFDVal(round(NextWPGreatCDist/1000,3) + " km") at (29,08).
    } else {
        print MFDVal("-") at (29,06).
        print MFDVal("-") at (29,07).
        print MFDVal("-") at (29,08).
    }

    // Status etc.
    print "":padleft(terminal:width) at (0,10).
    print FlightStatus at (0,10).
    print "":padleft(terminal:width) at (0,11).
    print "":padleft(terminal:width) at (0,12).
    
    if WaypointSelected {
        print "Next Waypoint: " + NextWPName at (0,11).
        print "Flyover Alt: " + round(NextWPFlyoverAlt,1) + " m" at (0,12).
    }

    // Diagnostic info.
    print "":padleft(terminal:width) at (0,17).
    print DiagnosticMsg at (0,17).
}