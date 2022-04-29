// =================================================
// KSPTOT Launch Vehicle Designer (LVD)
// Generate Drag Data (Cd*A)
// Description: This script uses Ren0k's "Project Atmospheric Data" kOS scripts to generate a scan of 
//              drag coefficient data as a function of Mach number, angle of attack, and sideslip angle.
//              The data produced can be used in Launch Vehicle Designer as a drag model.
//
// Written By: Arrowstar

// =================================================
//  HOW TO USE
// 1) Go to the github repository for "Project Atmospheric Data" and download the latest release: https://github.com/Ren0k/Project-Atmospheric-Drag
// 2) From the zip file downloaded in (1), put the "dragProfile" folder and the "atmoData" folder in your <KSP_root>\Ships\Script folder
// 3) Create a copy of your partdatabase.cfg file found in the KSP root folder and place it in <KSP_root>\Ships\Script\dragProfile\DATA\PartDatabase
// 4) Create a copy of your ship's .craft file (found in <KSP_root>\saves\savename\ships) in KSP\Ships\Script\dragProfile\DATA\Vessels.
// 5) Place this script in <KSP_root>\Ships\Script.
// 6) Start KSP and go to launch your ship whose craft file you copied in step (4).  You should be on the launchpad at this point.
// 7) Open up a kOS terminal.
// 8) If the file listed in the "dataFile" input exists, delete it.
// 9) Run this script by first executing: "switch to 0."  Then execute: "run createDragProfile.ks."
//10) Collect the data output file (see variable "dataFile" in the INPUTS section) and copy to a more appropriate location as desired.
//    Output data file gets written to <KSP_root>\Ships\Script.
// =================================================

// =================================================
// INPUTS
// =================================================
// This variable defines the name of the output data file
set dataFile to "dragData.csv".

//These variables define the range of angles of attack to be scanned over.
set aoaMin to -30.       //The minimum angle of attack angle to scan over.  Should probably be -20 deg or more negative.  Units: Degrees.
set aoaMax to  30.       //The maximum angle of attack angle to scan over.  Should probably be +20 deg or more negative.  Units: Degrees.
set aoaStep to  5.       //The step size in the range of angles of attack to scan over.  The (aoaMax - aoaMin)/aoaStep must be an integer.  Units: Degrees.

//These variables define the range of sideslip to be scanned over.
set sideslipMin to -30.  //The minimum sideslip angle to scan over.  Should probably be -20 deg or more negative.  Units: Degrees.
set sideslipMax to  30.  //The maximum sideslip angle to scan over.  Should probably be +20 deg or more negative.  Units: Degrees.
set sideSlipStep to  5.  //The step size in the range of sideslip angles to scan over.  The (sideslipMax - sideslipMin)/sideSlipStep must be an integer.  Units: Degrees.

//These variables define the range of Mach numbers to scan over.
set machStart to 0.      //The minimum Mach number.  Should almost always be 0.  Unitless.
set machEnd to 10.       //The maximum Mach number.  Should probably be >= 10.  Unitless.
set dT to 0.10.          //The step size in the range of Mach numbers to scan over.  The (machStart - machEnd)/dT must be an integer. Unitless. 
                         //The smaller this number is, the longer your scan will take and the bigger the resultant data file will be.

// =================================================
// PROCESSING - Do not edit below this line!
// =================================================
clearScreen.
set Config:IPU to 2000.

runpath("dragProfile/LIB/Analysis.ks").                                 // Ship Analysis Function
runpath("dragProfile/LIB/Profile.ks").                                  // Drag Profile Calculations.
runpath("dragProfile/LIB/Telemetry.ks").                                // Atmospheric Data and Telemetry
runpath("dragProfile/DATA/PartDatabase/ExtraDatabase.ks").              // Database for additional part information 

//if min is greater than max, flip them
IF aoaMin >= aoaMax {
	set tempAoA to aoaMax.
	set aoaMax to aoaMin.
	set aoaMin to tempAoA.
}

//if min is greater than max, flip them
IF sideslipMin >= sideslipMax {
	set tempSideslip to sideslipMax.
	set sideslipMax to sideslipMin.
	set sideslipMin to tempSideslip.
}

//delete existing data file if it exists
DELETEPATH(dataFile).

print "Running KSPTOT LVD drag profile scan.".
print "Please wait (this may take some times)...".
print "============================================".

FROM {local aoa is aoaMin.} UNTIL aoa > aoaMax STEP {set aoa to aoa+aoaStep.} DO { //loop over AoA
	FROM {local sideslip is sideslipMin.} UNTIL sideslip > sideslipMax STEP {set sideslip to sideslip+sideSlipStep.} DO { //loop over sideslip
		set Scan to True.
		set Gears to "Up".
		set Airbrakes to "Retracted".
		set Aerosurfaces to "Retracted".
		set Parachutes to "Idle".
		set CustomAoA to aoa.
		set CustomAoAYaw to sideslip.
		set Profile to "Posigrade".

		//create the Cd*A vs Mach number profile for the given AoA and sideslip angles.
		print "Creating Profile (AoA = " + aoa + " deg, Side Slip = " + sideslip + " deg)...".
		set profile to createProfile(Scan, machStart, machEnd, dT, Gears, Airbrakes, Aerosurfaces, Parachutes, CustomAoA, CustomAoAYaw, Profile).

		//Write the profile to the output file.
		//print "Writing profile to: " + dataFile.
		writeProfileToFile(profile, dataFile, aoa, sideslip).		
	}
}

function createProfile {
    // PUBLIC createProfile :: bool : float : float : float : string : string : string : string: float : float : string -> 2D Array
    // EXAMPLE -> createProfile(True, 0, 1, 0.01).
    parameter       Scan is True,
                    machStart is 0,
                    machEnd is 10,
                    dT is 0.01,
                    Gears is "Up",
                    Airbrakes is "Retracted",
                    Aerosurfaces is "Retracted",
                    Parachutes is "Idle",
                    CustomAoA is 0,
                    CustomAoAYaw is 0,
                    Profile is "Retrograde".

    local parametersCollection is lexicon(
        "Scan", Scan,
        "Gears", Gears,
        "Airbrakes", Airbrakes,
        "AeroSurfaces", Aerosurfaces,
        "Parachutes", Parachutes,
        "Custom AoA", CustomAoA,
        "Custom AoA Yaw", CustomAoAYaw,
        "Profile", Profile,
        "Mach Start", machStart,
        "Mach End", machEnd,
        "dT", dT
    ).   

    local vesselPartList is lib_getVesselAnalysis["executeAnalysis"](parametersCollection).
    local dragProfile is lib_DragProfile["createProfile"](vesselPartList, parametersCollection)["getDragProfile"](machStart, machEnd, dT).

    return dragProfile.
}

function writeProfileToFile {
    parameter       profile, logFileName, aoa, sideslip.
								  
	local startMach is profile["startMach"].                                  
	local endMach is profile["endMach"].                                       
	local dT is profile["dT"].  
	local numElem is (endMach - startMach)/dT + 1.

	FROM {local i is 0.} UNTIL i = numElem STEP {set i to i+1.} DO {
		set profileElement to profile[i].
		
		set machNum to profileElement[0][0].
		set CdACube to profileElement[0][1].
		set CdAOther to profileElement[1][1].
		
		set s to machNum + "," + aoa + "," + sideslip + "," + CdACube + "," + CdAOther.
		LOG s to logFileName.
	}
}