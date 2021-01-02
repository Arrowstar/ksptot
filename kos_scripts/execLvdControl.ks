// =================================================
// KSPTOT Launch Vehicle Designer (LVD)
// Control Execution Script
//
// Written By: Arrowstar
// 
//   lib_num_to_formatted_str.ks provided by KSLib 
//   https://github.com/KSP-KOS/KSLib
// =================================================
//  HOW TO USE
//  1) Develop a mission plan in KSPTOT LVD
//  2) Create the control CSV file with attitude and throttle data:
//     Simulation -> "Create kOS Control CSV File"
//  3) Place the resulting CSV file into your <KSP_root>\Ships\Script folder
//  4) Edit this file by changing the "fPath" variable to the name of the CSV file in (3).
//  5) In KSP:
//     1) Enter the flight scene.
//     2) Start the kOS terminal.
//     3) Enter command "switch to 0." to switch to archive volume.
//     4) Enter command "run execLvdControl.ks." to execute the attitude and throttle sequence in (3).
// =================================================

// =================================================
// INPUTS
// =================================================
	set fPath to "test.csv". //change "test.csv" to your CSV file name.  See step (4) above.

// =================================================
// EXECUTION CODE - DO NOT EDIT BELOW THIS LINE
// =================================================
clearscreen.

run once lib_num_to_formatted_str.ks.
set Config:IPU to 1000.
SET SAS TO FALSE.

print "===================" at (0,0).
print "LVD Control Script " at (0,1).
print "===================" at (0,2).
set parsedDataList to parseCsvFileToList(fPath, 3).

clearscreen.

lock xq to time:seconds.

set xArr to parsedDataList[0].
set yArr to parsedDataList:SUBLIST(1,parsedDataList:length - 1).

set headingRot to heading(0, 0, 0).
lock steering to headingRot.

set throtValue to 0.
lock throttle to throtValue.

set startInd to 0.

set dataPrintOffset to 4.
set dataNumPlaces to 3.

	print "===================" at (0,0).
	print "   Current Time    " at (0,1).
	print "===================" at (0,2).

	print "===================" at (0,5).
	print "Commanded Attitude " at (0,6).
	print "===================" at (0,7).

	print "===================" at (0,11).
	print "Commanded Throttle " at (0,12).
	print "===================" at (0,13).

	print "===================" at (0,15).
	print "Current Orbit " at (0,16).
	print "===================" at (0,17).

	print "===================" at (0,24).
	print "Current Mass " at (0,25).
	print "===================" at (0,26).

until xq > xArr[xArr:length - 1] {
	set interpOutput to interp1(xArr, yArr, xq, startInd).
	set yqList to interpData:yqList.
	set startInd to interpOutput:ind.

	set yaw to yqList[0].
	set pitch to yqList[1].
	set roll to yqList[2].
	set throtValue to yqList[3].

	print time:CALENDAR + " " + time:CLOCK at (dataPrintOffset,3).
    print "UT:       " + padding(time:seconds, 0, dataNumPlaces) + " sec" at (dataPrintOffset,4).
	
	print "Yaw:      " + padding(yaw, 0, dataNumPlaces) + " deg" at (dataPrintOffset,8).
	print "Pitch:    " + padding(pitch, 0, dataNumPlaces) + " deg" at (dataPrintOffset,9).
	print "Roll:     " + padding(roll, 0, dataNumPlaces) + " deg" at (dataPrintOffset,10).
	
	print "Throttle: " + padding(throtValue*100, 3, dataNumPlaces) + "%" at (dataPrintOffset,14).
	
	print "SMA:      " + padding(SHIP:ORBIT:SEMIMAJORAXIS/1000,0, dataNumPlaces) + " km" at (dataPrintOffset,18).
	print "ECC:      " + padding(SHIP:ORBIT:ECCENTRICITY,0, dataNumPlaces+2) at (dataPrintOffset,19).
	print "INC:      " + padding(SHIP:ORBIT:INCLINATION, 0, dataNumPlaces) + " deg"  at (dataPrintOffset,20).
	print "RAAN:     " + padding(SHIP:ORBIT:LAN, 0, dataNumPlaces) + " deg"  at (dataPrintOffset,21).
	print "AOP:      " + padding(SHIP:ORBIT:ARGUMENTOFPERIAPSIS, 0, dataNumPlaces) + " deg"  at (dataPrintOffset,22).
	print "TRU:      " + padding(SHIP:ORBIT:TRUEANOMALY, 0, dataNumPlaces) + " deg"  at (dataPrintOffset,23).
	
	print "Tot. Mass: " + padding(ship:mass, 0, dataNumPlaces) + " mT" at (dataPrintOffset,27).

	set headingRot to heading(yaw, pitch, roll).
}

clearscreen.
print "LVD control sequence completed successfully.".
SET SAS TO TRUE.

function interp1 {
	parameter xArr. //must be a list of doubles
	parameter yArr. //must be a list of a list of doubles
	parameter xq.   //must be a scalar double
	parameter startInd is 0.
	
	set yqList to List().
	if xq <= xArr[0] {
		set ind to 0.
		for ySubArr in yArr {
			yqList:add(ySubArr[0]).
		}
	
	} else if xq >= xArr[xArr:length - 1] {
		set ind to xArr:length - 1.
		for ySubArr in yArr {
			yqList:add(ySubArr[ySubArr:length - 1]).
		}
	
	} else {
		set i to startInd.
		set ind to -1.
		until i >= xArr:length - 1 {
			if xArr[i] <= xq AND xArr[i+1] > xq {
				set ind to i.
				break.
			}
			
			set i to i + 1.
		}
		
		for ySubArr in yArr {
			set x0 to xArr[ind].
			set x1 to xArr[ind+1].
			set y0 to ySubArr[ind].
			set y1 to ySubArr[ind+1].
			
			set yq to (y0*(x1-xq) + y1*(xq-x0))/(x1-x0).	
			yqList:add(yq).
		}
	}
	
	set interpData to lexicon("yqList", yqList, "ind", ind).
	
	return interpData.
}

function parseCsvFileToList {
	parameter fPath.
	parameter printRowStart is 0.

	set csvData to OPEN(PATH(fPath)):READALL().
	set csvDataItr to csvData:ITERATOR.

	print "Reading control data from CSV..." at (0,printRowStart).

	set parsedDataList to List().
	until not csvDataItr:next {
		set curLine to csvDataItr:value.
		set curLineValues to curLine:SPLIT(",").
		
		set i to 0.
		set dataSet to List().
		for value in curLineValues {
			dataSet:add(value:tonumber()).
			
			set numEqSigns to round(((i / curLineValues:length)*100)/5).
			set eqSignStr to "".
			set eqSignStr to eqSignStr:padright(numEqSigns).
			set eqSignStr to eqSignStr:replace(" ", "=").			
			set eqSignStr to eqSignStr:padright(20).
			
			print "[" + eqSignStr + "]" at (0, printRowStart + 1).
			
			set i to i + 1.
		}
		parsedDataList:add(dataSet).
	}
	
	return parsedDataList.
}