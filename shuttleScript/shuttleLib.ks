// Engine declaration
    // OMS engines:
local OMS1 is ship:partsdubbed("oms1")[0].
local OMS2 is ship:partsdubbed("oms2")[0].

    // Main engines:
local SSME1 is ship:partsdubbed("ssme1")[0].
local SSME2 is ship:partsdubbed("ssme2")[0].
local SSME3 is ship:partsdubbed("ssme3")[0].

// Control Surface declaration
    // Elevon 1
local leftSmallElevon is ship:partsdubbed("elevonFarLeft")[0]:getmodule("ModuleControlSurface").
local rightSmallElevon is ship:partsdubbed("elevonFarRight")[0]:getmodule("ModuleControlSurface").

    // Elevon 2
local leftLargeElevon is ship:partsdubbed("elevonCentreLeft")[0]:getmodule("ModuleControlSurface").
local rightLargeElevon is ship:partsdubbed("elevonCentreRight")[0]:getmodule("ModuleControlSurface").

    // Canard
local leftCanard is ship:partsdubbed("canardLeft")[0]:getmodule("ModuleControlSurface").
local rightCanard is ship:partsdubbed("canardRight")[0]:getmodule("ModuleControlSurface").
    // Rudder
local leftRudder is ship:partsdubbed("rudderLeft")[0]:getmodule("ModuleControlSurface").
local rightRudder is ship:partsdubbed("rudderRight")[0]:getmodule("ModuleControlSurface").

// Fuel Tank declaration
local cockpitTank is ship:partsdubbed("cockpit")[0].
local largeMonoTank is ship:partsdubbed("monoTank")[0].

local OMSTankLowLeft is ship:partsdubbed("backOMStank3")[0].
local OMSTankLowRight is ship:partsdubbed("backOMStank1")[0].
local OMSTankHighLeft is ship:partsdubbed("backOMStank4")[0].
local OMSTankHighRight is ship:partsdubbed("backOMStank2")[0].
local OMSTankFront is ship:partsdubbed("frontOMStank")[0].

// ballast tanks
local leftNoseBallast is ship:partsdubbed("leftFrontOre")[0].
local rightNoseBallast is ship:partsdubbed("rightFrontOre")[0].
local leftTailBallast is ship:partsdubbed("leftOre")[0].
local rightTailBallast is ship:partsdubbed("rightOre")[0].

// Transfer constants
// BK = Back tanks --> Front tanks, FR = Front tanks --> Back tanks

// BACK TO FRONT
local BKmonoTransfer is transferAll("monopropellant", largeMonoTank, cockpitTank).

local BKleftTransfer is transferAll("liquidfuel", OMSTankLowLeft, OMSTankFront).
local BKrightTransfer is transferAll("liquidfuel", OMSTankLowRight, OMSTankFront).
local BKleftOxTransfer is transferAll("oxidizer", OMSTankLowLeft, OMSTankFront).
local BKrightOxTransfer is transferAll("oxidizer", OMSTankLowRight, OMSTankFront).

local BKtopLeftTransfer is transferAll("liquidfuel", OMSTankHighLeft, OMSTankFront).
local BKtopRightTransfer is transferAll("liquidfuel", OMSTankHighRight, OMSTankFront).
local BKtopLeftOxTransfer is transferAll("oxidizer", OMSTankHighLeft, OMSTankFront).
local BKtopRightOxTransfer is transferAll("oxidizer", OMSTankHighRight, OMSTankFront).

// FRONT TO BACK
local FRmonoTransfer is transferAll("monopropellant", cockpitTank, largeMonoTank).

local FRleftTransfer is transferAll("liquidfuel", OMSTankFront, OMSTankLowLeft).
local FRrightTransfer is transferAll("liquidfuel", OMSTankFront, OMSTankLowRight).
local FRleftOxTransfer is transferAll("oxidizer", OMSTankFront, OMSTankLowLeft).
local FRrightOxTransfer is transferAll("oxidizer", OMSTankFront, OMSTankLowRight).

local FRtopLeftTransfer is transferAll("liquidfuel", OMSTankFront, OMSTankHighLeft).
local FRtopRightTransfer is transferAll("liquidfuel", OMSTankFront, OMSTankHighRight).
local FRtopLeftOxTransfer is transferAll("oxidizer", OMSTankFront, OMSTankHighLeft).
local FRtopRightOxTransfer is transferAll("oxidizer", OMSTankFront, OMSTankHighRight).

local FRleftBallastTransfer is transferAll("ore", leftNoseBallast, leftTailBallast).
local FRrightBallastTransfer is transferAll("ore", rightNoseBallast, rightTailBallast).
local BKleftBallastTransfer is transferAll("ore", leftTailBallast, leftNoseBallast).
local BKrightBallastTransfer is transferAll("ore", rightTailBallast, rightNoseBallast).

// Math for abort modes and calculating percent thrust for
// compensating for failed engines.
local SSMEmaxThrust is (SSME1:maxthrust + SSME2:maxthrust + SSME3:maxthrust) / 3.
local lock SSMEavailableThrust to (SSME1:thrust + SSME2:thrust + SSME3:thrust) / 3.

// This is for the MFD, but
// TODO:
// - Use this for limiting the G's on takeoff.
local lock gForce to ((ship:sensors:acc - ship:sensors:grav):mag / 9.81).

function WrapTo360
// Wrap an angle to the range 0 to 360.
// Notes:
//		- Keeping the angle range wrapped and positive is usually the best
//			things to do. Sometimes it depends on the circumstances.
// ToDo:
//		- Try to understand the angle mathematics better.
{
    parameter ang.

    local wrapped to mod(ang,360).

    if wrapped < 0
        set wrapped to wrapped + 360.

    return wrapped.
}

function shiftCOM {
    parameter reset. // boolean
    parameter isFront.

    if reset {
        transferFuel(false, false).
    }
    else if isFront { // front to back
        transferFuel(true, false).
    }
    else if not isFront { // back to front
        transferFuel(false, true).
    }

    function transferFuel {

        // booleans
        parameter frActive.
        parameter bkActive.

        // FR
        set FRmonoTransfer:active to frActive.

        set FRleftTransfer:active to frActive.
        set FRrightTransfer:active to frActive.
        set FRleftOxTransfer:active to frActive.
        set FRrightOxTransfer:active to frActive.

        //set FRtopLeftTransfer:active to frActive.
        //set FRtopRightTransfer:active to frActive.
        //set FRtopLeftOxTransfer:active to frActive.
        //set FRtopRightOxTransfer:active to frActive.

        set FRleftBallastTransfer:active to frActive.
        set FRrightBallastTransfer:active to frActive.

        // BK
        set BKmonoTransfer:active to bkActive.

        set BKleftTransfer:active to bkActive.
        set BKrightTransfer:active to bkActive.
        set BKleftOxTransfer:active to bkActive.
        set BKrightOxTransfer:active to bkActive.

        //set FRtopLeftTransfer:active to bkActive.
        //set FRtopRightTransfer:active to bkActive.
        //set FRtopLeftOxTransfer:active to bkActive.
        //set FRtopRightOxTransfer:active to bkActive.

        set BKleftBallastTransfer:active to bkActive.
        set BKrightBallastTransfer:active to bkActive.
    }
}

function getCentreOfMass
// returns distance between mono tank and com
{
    return largeMonoTank:position:mag.
}

function getGForce
// self-explanatory
{
    return ((ship:sensors:acc - ship:sensors:grav):mag / 9.81).
}

function getAvailableThrust
// for ssme
{
    return (SSME1:thrust + SSME2:thrust + SSME3:thrust) / 3.
}

function getMaxThrust
// same but max
{
    return (SSME1:maxthrust + SSME2:maxthrust + SSME3:maxthrust) / 3.
}

function clamp
// Return an output number from an input number clamped to a specified
// range of number values.
// I don't see any active uses here but it's very useful so I'll keep it.
{
    parameter x.
    parameter minx.
    parameter maxx.

    if x < minx
        set x to minx.
    else
      if x > maxx
        set x to maxx.

    return x.
}

function MFDVal
// Format the Multi-function Display value.
// Pad the value from the left with spaces to right-align it.
// If the value is too large, truncate it from the left.
{
    parameter Val is "".

    local ValColSize is 13.
    local FmtVal is "".

    if Val:istype("Scalar") {
        set Val to Val:tostring().
    }

    if Val:length >= ValColSize {
        set FmtVal to Val:substring(Val:length-ValColSize,ValColSize).
    }
    else {
        set FmtVal to Val:padleft(ValColSize).
    }

    return FmtVal.
}

function NavBallValues
// Create a vector that contains the vessel's pitch, yaw and roll
// values, as they would appear on the vessel's NavBall.
{
    parameter mainVessel.
    local vec to V(0,0,0).
    local NorthHorizonDir to lookdirup(mainVessel:north:forevector,mainVessel:up:forevector).
    local DifferenceDir to (mainVessel:facing:inverse*NorthHorizonDir):inverse.

    // Adjust the rotational angles into the conventions used by the NavBall.

    if DifferenceDir:pitch > 180 {
        set vec:x to 360 - DifferenceDir:pitch.
    }
    else {
        set vec:x to -DifferenceDir:pitch.
    }

    set vec:y to DifferenceDir:yaw.

    if DifferenceDir:roll > 180 {
        set vec:z to DifferenceDir:roll-360.
    }
    else {
        set vec:z to DifferenceDir:roll.
    }

    return vec.
}

function controlSurface
// Allowed inputs:
// Surface: smallElevon, largeElevon, Canard, Rudder
// Action: authority, deploy (depends on amount type), pitch, yaw, roll
// Amount: Scalar, Boolean (Int32 is not used here)
// NOTE: true / false are reversed for enabling / disabling control surface pitch, yaw, roll
{
    parameter surface.
    parameter action.
    parameter amount.

    local translatedAction is 0.

    if action = "authority" {
        set translatedAction to "authority limiter".
    }
    else if action = "deploy" {
        if amount:typename = "Scalar" {
            set translatedAction to "deploy angle".
        }
        else {
            set translatedAction to "deploy".
        }
    }
    else {
        set translatedAction to action.
    }

    // ------------------------------------

    if surface = "smallElevon" {
        leftSmallElevon:setfield(translatedAction, amount).
        rightSmallElevon:setfield(translatedAction, amount).
    }
    if surface = "largeElevon" {
        leftLargeElevon:setfield(translatedAction, amount).
        rightLargeElevon:setfield(translatedAction, amount).
    }
    if surface = "Canard" {
        leftCanard:setfield(translatedAction, amount).
        rightCanard:setfield(translatedAction, amount).
    }
    if surface = "Rudder" {
        leftRudder:setfield(translatedAction, amount).
        rightRudder:setfield(translatedAction, amount).
    }
}

function changeEngineState
// changes an engine's state - takes which engine / what action
{
    parameter engineType.
    parameter engineAction.

    if engineType = "ssme" {
        if engineAction = "on" {
        SSME1:activate().
        SSME2:activate().
        SSME3:activate().
        }
        else if engineAction = "off" {
            SSME1:shutdown().
            SSME2:shutdown().
            SSME3:shutdown().
        }
        else if engineAction = "gimbal" {
            set SSME1:gimbal:lock to false.
            set SSME2:gimbal:lock to false.
            set SSME3:gimbal:lock to false.
        }
        else if engineAction = "locked" {
            set SSME1:gimbal:lock to true.
            set SSME2:gimbal:lock to true.
            set SSME3:gimbal:lock to true.
        }
        else if engineAction = "unlockYawRoll" {
            set SSME1:gimbal:yaw to true.
            //set SSME1:gimbal:roll to true.

            set SSME2:gimbal:yaw to true.
            //set SSME2:gimbal:roll to true. 

            set SSME3:gimbal:yaw to true.
            //set SSME3:gimbal:roll to true.
        }
        else if engineAction = "lockYawRoll" {
            set SSME1:gimbal:yaw to false.
            //set SSME1:gimbal:roll to false.

            set SSME2:gimbal:yaw to false.
            //set SSME2:gimbal:roll to false.

            set SSME3:gimbal:yaw to false.
            //set SSME3:gimbal:roll to false.
        }
        else if engineAction = "unlockRoll" {
            set SSME1:gimbal:roll to true.
            set SSME2:gimbal:roll to true. 
            set SSME3:gimbal:roll to true.
        }
    }
    else if engineType = "oms" {
        if engineAction = "on" {
            OMS1:activate().
            OMS2:activate().
        }
        else if engineAction = "off" {
            OMS1:shutdown().
            OMS2:shutdown().
        }
        else if engineAction = "gimbal" {
            set OMS1:gimbal:lock to false.
            set OMS2:gimbal:lock to false.
        }
        else if engineAction = "locked" {
            set OMS1:gimbal:lock to true.
            set OMS2:gimbal:lock to true.
        }
    }
}