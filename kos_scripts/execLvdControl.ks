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
	set printOutput to true. //set to false to disable output display (time, steering, orbit, etc)

// =================================================
// EXECUTION CODE - DO NOT EDIT BELOW THIS LINE
// =================================================
clearscreen.

run once lib_num_to_formatted_str.ks.
set Config:IPU to 2000.
SET SAS TO FALSE.

print "===================" at (0,0).
print "LVD Control Script " at (0,1).
print "===================" at (0,2).
set parsedDataList to parseCsvFileToList(fPath, 3).

clearscreen.
if printOutput = false {
	print "Output display disabled.".
	print "Set 'printOutput' to true to see time, commanded attitude, throttle, orbit, etc.".
}

lock xq to time:seconds.

set xArr to parsedDataList[0].
set yArr to parsedDataList:SUBLIST(1,parsedDataList:length - 3).
set curEvtList to parsedDataList[parsedDataList:length - 2].
set nxtEvtList to parsedDataList[parsedDataList:length - 1].

set headingRot to heading(0, 0, 0).
lock steering to headingRot.

set throtValue to 0.
lock throttle to throtValue.

set startInd to 0.

set dataPrintOffset to 4.
set dataNumPlaces to 3.

until xq > xArr[xArr:length - 1] {
	set interpOutput to interp1(xArr, yArr, xq, startInd).
	set yqList to interpData:yqList.
	set startInd to interpOutput:ind.

	set yaw to yqList[0].
	set pitch to yqList[1].
	set roll to yqList[2].
	set throtValue to yqList[3].
	set timeToNextEvt to yqList[4].
	set curEvtName to curEvtList[startInd].
	set nxtEvtName to nxtEvtList[startInd].

	if nxtEvtName:length = 0 {
		set nxtEvtName to "N/A".
	}

	if printOutput {
		horzLine(0).
		paddedPrintLine(" Current Time",0,1).
		horzLine(2).
		paddedPrintLine(time:CALENDAR + " " + time:CLOCK, dataPrintOffset, 3).
		paddedPrintLine("UT:         " + padding(time:seconds, 0, dataNumPlaces) + " sec", dataPrintOffset, 4).
		paddedPrintLine("Event:      " + curEvtName, dataPrintOffset, 5).
		paddedPrintLine("Next Event: " + nxtEvtName + " (" + time_formatting(-1 * timeToNextEvt,0,2,true) + ")", dataPrintOffset, 6).
		
		horzLine(7).
		paddedPrintLine(" Commanded Attitude",0,8).
		horzLine(9).
		paddedPrintLine("Yaw:        " + padding(yaw, 0, dataNumPlaces) + " deg", dataPrintOffset, 10).
		paddedPrintLine("Pitch:      " + padding(pitch, 0, dataNumPlaces) + " deg", dataPrintOffset, 11).
		paddedPrintLine("Roll:       " + padding(roll, 0, dataNumPlaces) + " deg", dataPrintOffset, 12).
		
		horzLine(13).
		paddedPrintLine(" Commanded Throttle",0,14).
		horzLine(15).
		paddedPrintLine("Throttle:   " + padding(throtValue*100, 3, dataNumPlaces) + "%", dataPrintOffset, 16).
		
		horzLine(17).
		paddedPrintLine(" Current Orbit",0,18).
		horzLine(19).
		paddedPrintLine("SMA:        " + padding(SHIP:ORBIT:SEMIMAJORAXIS/1000,0, dataNumPlaces) + " km    ", dataPrintOffset, 20).
		paddedPrintLine("ECC:        " + padding(SHIP:ORBIT:ECCENTRICITY,0, dataNumPlaces+2), dataPrintOffset, 21).
		paddedPrintLine("INC:        " + padding(SHIP:ORBIT:INCLINATION, 0, dataNumPlaces) + " deg", dataPrintOffset, 22).
		paddedPrintLine("RAAN:       " + padding(SHIP:ORBIT:LAN, 0, dataNumPlaces) + " deg", dataPrintOffset, 23).
		paddedPrintLine("AOP:        " + padding(SHIP:ORBIT:ARGUMENTOFPERIAPSIS, 0, dataNumPlaces) + " deg", dataPrintOffset, 24).
		paddedPrintLine("TRU:        " + padding(SHIP:ORBIT:TRUEANOMALY, 0, dataNumPlaces) + " deg", dataPrintOffset, 25).
		
		horzLine(26).
		paddedPrintLine(" Vehicle Data",0,27).
		horzLine(28).
		paddedPrintLine("Tot. Mass: " + padding(ship:mass, 0, dataNumPlaces) + " mT", dataPrintOffset, 29).
	}

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
			set valueToNumber to value:tonumber(-1E99).
			
			if(valueToNumber = -1E99) {
				set valueToNumber to value.
			}
			dataSet:add(valueToNumber).
			
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

function paddedPrintLine {
    parameter str.
	parameter colOffset.
	parameter lineNum.
	
	print str:padright(terminal:width-colOffset) at (colOffset,lineNum).
}

function horzLine {
	parameter lineNum.
	
	set hLineStr to "".
	set hLineStr to hLineStr:padright(terminal:width).
	set hLineStr to hLineStr:replace(" ", "=").
	
	paddedPrintLine(hLineStr,0,lineNum).
}