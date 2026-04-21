clearscreen.
clearGuis().

runoncepath("0:/shuttleScript/shuttleLib").

local mainCPU is processor("mainCPU"):connection.

// Engine declaration
    // OMS engines:
local OMS1 is ship:partsdubbed("oms1")[0].
local OMS2 is ship:partsdubbed("oms2")[0].

    // Main engines:
local SSME1 is ship:partsdubbed("ssme1")[0].
local SSME2 is ship:partsdubbed("ssme2")[0].
local SSME3 is ship:partsdubbed("ssme3")[0].

local exit is false.
local collapsed is false.

local guiWidth is 512. //px
local guiHeight is 256. //px

local collWidth is 250. //px
local collHeight is 50. //px

local guiX is 1300.
local guiY is 400.

local padAmount is 5.

    // engine texture types:
local engTex1 is ("shuttleScript/tex/eng1").
local engTex2 is ("shuttleScript/tex/eng2").
local engTex3 is ("shuttleScript/tex/eng3").
local engTex4 is ("shuttleScript/tex/eng4").

local omsTex1 is ("shuttleScript/tex/omsEng1").
local omsTex2 is ("shuttleScript/tex/omsEng2").

    // shuttle texture types:
local shuttleGearUp is ("shuttleScript/tex/engines").
local shuttleGearDown is ("shuttleScript/tex/enginesGear").

local lock isGearDown to gear.

// others are in the library
// airspeed is built in, don't need a variable for that
// throttle is built in, don't need a variable for that
// other: todo



    // declaring shuttle gui
local shuttleGUI is gui(guiWidth).
set shuttleGUI:style:height to guiHeight + (padAmount * 2).
set shuttleGUI:style:width to guiWidth + (padAmount * 2).

set shuttleGUI:x to guiX.
set shuttleGUI:y to guiY.
set shuttleGUI:style:padding:h to padAmount.
set shuttleGUI:style:padding:v to padAmount.

    // encloses exit and collapse
set buttonBox to shuttleGUI:addhlayout().

        // title
    set title to buttonBox:addlabel("<b>SPACE SHUTTLE ENGINE MONITOR</b>").
    set title:style:richtext to true.
    set title:style:fontsize to 18.
    set title:style:padding:v to 6.

        // collapse
    set collapseButton to buttonBox:addbutton(" Collapse ").
    set collapseButton:onclick to bigSmallWindow@.
    set collapseButton:style:hstretch to false.

        // exit
    set exitButton to buttonBox:addbutton("  X ").
    set exitButton:onclick to closeWindow@.
    set exitButton:style:hstretch to false.

    // background
set background to shuttleGUI:addhlayout().

local engineSize is 36.

    set shuttleBack to background:addvlayout().
    set shuttleBack:style:bg to ("shuttleScript/tex/engines").
    set shuttleBack:style:height to (384 * 0.5).
    set shuttleBack:style:width to shuttleBack:style:height * (4 / 3).

    local offsetX is shuttleBack:style:width / 2.48. //2.45
    local offsetY is shuttleBack:style:height / 13. //4.08
    set engineSize to shuttleBack:style:height * 0.11.

    print shuttleBack:style:height.
    print shuttleBack:style:width.
    print engineSize.
    print offsetX.
    print offsetY.

            // oms layer
        set OMSlayer to shuttleBack:addhlayout().
        set OMSlayer:style:height to engineSize / 3.
        set OMSlayer:style:width to shuttleBack:style:width / 2.
        set OMSlayer:style:padding:v to offsetY * 1.1.
        set OMSlayer:style:padding:h to offsetX * 1.01.

                // oms engines
            set OMSengine1 to OMSlayer:addlabel().
            set OMSengine1:image to engTex1.
            set OMSengine1:style:width to engineSize / 2.

            set OMSbuffer to OMSlayer:addlabel("").
            set OMSbuffer:style:width to engineSize * 0.87.//(engineSize * 1.08).

            set OMSengine2 to OMSlayer:addlabel().
            set OMSengine2:image to engTex1.
            set OMSengine2:style:width to engineSize / 2.

            // engine layer 1
        set mainEngineLayer1 to shuttleBack:addhlayout().
        set mainEngineLayer1:style:height to engineSize * 1.2.
        set mainEngineLayer1:style:width to shuttleBack:style:width / 2.
        set mainEngineLayer1:style:padding:v to offsetY.
        set mainEngineLayer1:style:padding:h to offsetX.

                // engine 1 picture
            set bufferEngine1 to mainEngineLayer1:addlabel("").
            set bufferEngine1:style:width to (engineSize / 2) - (engineSize / 32).

            set engine1 to mainEngineLayer1:addlabel().
            set engine1:image to engTex1.
            set engine1:style:width to engineSize.

            // engine layer 2
        set mainEngineLayer2 to shuttleBack:addhlayout().
        set mainEngineLayer2:style:height to engineSize.
        set mainEngineLayer2:style:width to shuttleBack:style:width / 2.
        set mainEngineLayer2:style:padding:v to offsetY.
        set mainEngineLayer2:style:padding:h to offsetX + 1.

                // engine 2 picture
            set engine2 to mainEngineLayer2:addlabel().
            set engine2:image to engTex1.
            set engine2:style:width to engineSize.

                // engine 3 picture
            set engine3 to mainEngineLayer2:addlabel().
            set engine3:image to engTex1.
            set engine3:style:width to engineSize.

        // side panel - for stats
    set statsPanel to background:addvbox().
    set statsPanel:style:height to shuttleBack:style:height.

        set gForceMonitor to statsPanel:addlabel("GFORCE: ").
        set speedMonitor to statsPanel:addlabel("AIRSPD: ").
        set accelMonitor to statsPanel:addlabel("THROTT: ").
        set otherMonitor to statsPanel:addlabel("OTHER: ").

            // telemetry button
        set telemetryButton to statsPanel:addbutton("RCD TLMTRY").
        set telemetryButton:toggle to true.
        //set telemetryButton:ontoggle to toggleTelemetry.


        // engines
    set engPanel to background:addvbox().
    set engPanel:style:height to shuttleBack:style:height.

        set SSME1Monitor to engPanel:addlabel("SSME1: ").
        set SSME2Monitor to engPanel:addlabel("SSME2: ").
        set SSME3Monitor to engPanel:addlabel("SSME3: ").
        set OMS1Monitor to engPanel:addlabel("OMS1: ").
        set OMS2Monitor to engPanel:addlabel("OMS2: ").

        // little thing for popup to launch button
    set launchGUI to gui(200).
        set launchLabel to launchGUI:addlabel("Press to launch!").
        set launchLabel:style:align to "center".
        set launchLabel:style:hstretch to true.
        set launchButton to launchGUI:addbutton("Launch").
        set launchButton2 to launchGUI:addbutton("Close").
        set launchButton:onclick to startLaunch@.
        set launchButton2:onclick to closeLaunch@.

        when throttle > 0 then {
            startLaunch().
        }

    launchGUI:show().


shuttleGUI:show().

    local OMS1thrott is 0.
    local OMS2thrott is 0.
    local SSME1thrott is 0.
    local SSME2thrott is 0.
    local SSME3thrott is 0.

    lock OMS1thrott to OMS1:thrust / (OMS1:availablethrust + 0.0001).
    lock OMS2thrott to OMS2:thrust / (OMS2:availablethrust + 0.0001).
    lock SSME1thrott to SSME1:thrust / (SSME1:availablethrust + 0.0001).
    lock SSME2thrott to SSME2:thrust / (SSME2:availablethrust + 0.0001).
    lock SSME3thrott to SSME3:thrust / (SSME3:availablethrust + 0.0001).

    mainCPU:sendmessage("opened GUI").

local time2 is time + 1.

until exit {
    setEngTex(OMS1thrott, OMSengine1).
    setEngTex(OMS2thrott, OMSengine2).
    setEngTex(SSME1thrott, engine1).
    setEngTex(SSME2thrott, engine2).
    setEngTex(SSME3thrott, engine3).

    if isGearDown {
        set shuttleBack:style:bg to ("shuttleScript/tex/enginesGear").
    }
    else {
        set shuttleBack:style:bg to ("shuttleScript/tex/engines").
    }

    set gForceMonitor:text to "GFORCE: " + (round(getGForce(), 2)) + "g".
    set speedMonitor:text to "AIRSPD: " + (round((airspeed))) + " m/s".
    set accelMonitor:text to "THROTT: " + (round((throttle * 104.5), 1)) + "%".
    set otherMonitor:text to "ALT: " + (round((altitude / 1000))) + " km".

    set SSME1Monitor:text to("SSME1: ") + round(SSME1:thrust) + "kN".
    set SSME2Monitor:text to("SSME2: ") + round(SSME2:thrust) + "kN".
    set SSME3Monitor:text to("SSME3: ") + round(SSME3:thrust) + "kN".
    set OMS1Monitor:text to ("OMS1: ") + round(OMS1:thrust) + "kN".
    set OMS2Monitor:text to ("OMS2: ") + round(OMS2:thrust) + "kN".

    if telemetryButton:pressed and time > time2 {
        set time2 to time + 1.
        log altitude to alti.txt.
        log airspeed to spd.txt.
        log getGForce() to gforce.txt.
        log time to tim.txt.
        log vessel("runway marker 09"):distance to dis.txt.
    }
}

    // exit button function
function closeWindow {
    clearGuis().
    set exit to true.
}

    // collapse button function
function bigSmallWindow {

    set collapsed to not collapsed.
    set collapseButton:pressed to false.

    if collapsed { // set to collapsed
        set shuttleGUI:style:height to collHeight.
        set shuttleGUI:style:width to collWidth.
        set shuttleGUI:x to shuttleGUI:x + guiWidth - collWidth.

        set collapseButton:text to ("Uncollapse").

        set title:style:fontsize to 14.
        set title:text to "<b>ENG MONITOR</b>".

        background:hide().
    }

    else { // set to not collapsed
        set shuttleGUI:style:height to guiHeight.
        set shuttleGUI:style:width to guiWidth.
        set shuttleGUI:x to shuttleGUI:x - guiWidth + collWidth.

        set collapseButton:text to (" Collapse ").
        set title:style:fontsize to 18.
        set title:text to ("<b>SPACE SHUTTLE ENGINE MONITOR</b>").

        background:show().
    }
}

function startLaunch {
    mainCPU:sendmessage("launch").
    launchGUI:hide().
}

function closeLaunch {
    launchGUI:hide().
}

function toggleTelemetry {
    if telemetryButton:pressed {
        set telemetryButton:text to ("STOP RCD").
    }
    else {
        set telemetryButton:text to ("RCD TLMTRY").
    }
}

function setEngTex {
    parameter engThrott.
    parameter engine.

    //print engThrott.

    if engThrott > 1.1 {
        set engThrott to 0.
    }

    if engine = OMSengine1 or engine = OMSengine2 {
        if engThrott < 0.01 {
            set engine:image to engTex1.
        }
        else if engThrott < 0.4 {
            set engine:image to omsTex2.
        }
        else {
            set engine:image to omsTex1.
        }
    }

    else {
    if engThrott < 0.01 {
        set engine:image to engTex1.
    }
    else if engThrott < 0.35 {
        set engine:image to engTex2.
    }
    else if engThrott < 0.75 {
        set engine:image to engTex3.
    }
    else {
        set engine:image to engTex4.
    }
    }
}