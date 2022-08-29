// =================================================
// KSPTOT Launch Vehicle Designer (LVD)
// Control Execution Script
//
// Written By: Arrowstar
// 
//   lib_num_to_formatted_str.ks provided by KSLib 
//	 lib_navball.ks provided by KSLib 
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
//     4) Enter command "run exec_lvd_control.ks." to execute the attitude and throttle sequence in (3).
// =================================================

// =================================================
// INPUTS
// =================================================
	set fPath to "bigLauncher1.csv". //change "test.csv" to your CSV file name.  See step (4) above.
	set printOutput to true. //set to false to disable output display (time, steering, orbit, etc)

// =================================================
// EXECUTION CODE - DO NOT EDIT BELOW THIS LINE
// =================================================
clearscreen.

run once lib_num_to_formatted_str.ks.
run once  lib_navball.ks.
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
set stagingTimes to List().

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
	set y0List to interpData:y0List.
	set y1List to interpData:y1List.
	set startInd to interpOutput:ind.

	set yaw to yqList[0].
	set pitch to yqList[1].
	set roll to yqList[2].
	set throtValue to yqList[3].
	set timeToNextEvt to yqList[4].
	set stagingCue to yqList[5].
	set tgtSma to yqList[6].
	set tgtEcc to yqList[7].
	set tgtInc to yqList[8].
	set tgtRaan to yqList[9].
	set tgtArg to yqList[10].
	set tgtTru to yqList[11].
	set curEvtName to curEvtList[startInd].
	set nxtEvtName to nxtEvtList[startInd].
	
	set curSma to SHIP:ORBIT:SEMIMAJORAXIS/1000.
	set errSma to curSma - tgtSma.
	
	set curEcc to SHIP:ORBIT:ECCENTRICITY.
	set errEcc to curEcc - tgtEcc.
	
	set curInc to SHIP:ORBIT:INCLINATION.
	set errInc to curInc - tgtInc.
	
	set curRaan to SHIP:ORBIT:LAN.
	set errRaan to curRaan - tgtRaan.
	
	set curArg to SHIP:ORBIT:ARGUMENTOFPERIAPSIS.
	set errArg to curArg - tgtArg.
	
	set curTru to SHIP:ORBIT:TRUEANOMALY.
	set errtru to curTru - tgtTru.
	
	if y0List:length > 0 {
		set stagingCueInd0 to y0List[5].
	} else {
		set stagingCueInd0 to 0.
	}
	
	if y1List:length > 0 {
		set stagingCueInd1 to y1List[5].
	} else {
		set stagingCueInd1 to 0.
	}
	
	set headingRot to heading(yaw, pitch, roll).

	if nxtEvtName:length = 0 {
		set nxtEvtName to "N/A".
	}
	
	if stagingCue > 0 AND stagingCueInd0 = 1 {
		set x0 to xArr[ind].
		
		set doStaging to true.
		for stagingTime IN stagingTimes {
			if x0 = stagingTime {
				set doStaging to false.
				break.
			} 
		}
		
		if doStaging {
			stagingTimes:add(x0).
			STAGE.
		}
	}

	if printOutput {
		set l to 0.
		
		if time:seconds < xArr[0] {
			set timeToScriptStart to time:seconds - xArr[0].
			set timeToScriptStartStr to " (" + time_formatting(timeToScriptStart,0,2,true) + ")".
		} else {
			set timeToScriptStartStr to "".
		}
	
		horzLine(l). set l to l + 1.
		paddedPrintLine(" Current Time",0,l).  set l to l + 1.
		horzLine(l).  set l to l + 1.
		paddedPrintLine(time:CALENDAR + " " + time:CLOCK, dataPrintOffset, l).  set l to l + 1.
		paddedPrintLine("UT:         " + padding(time:seconds, 0, dataNumPlaces) + " sec", dataPrintOffset, l).  set l to l + 1.
		paddedPrintLine("Event:      " + curEvtName + timeToScriptStartStr, dataPrintOffset, l).  set l to l + 1.
		paddedPrintLine("Next Event: " + nxtEvtName + " (" + time_formatting(-1 * timeToNextEvt,0,2,true) + ")", dataPrintOffset, l).  set l to l + 1.
		
		horzLine(l).  set l to l + 1.
		paddedPrintLine(" Commanded Attitude",0,l).  set l to l + 1.
		horzLine(l).  set l to l + 1.
		paddedPrintLine("Yaw:        " + padding(yaw  , 0, dataNumPlaces) + " deg (Err: " + padding(STEERINGMANAGER:YAWERROR, 0, dataNumPlaces) + " deg)", dataPrintOffset, l).  set l to l + 1.
		paddedPrintLine("Pitch:      " + padding(pitch, 0, dataNumPlaces) + " deg (Err: " + padding(STEERINGMANAGER:PITCHERROR, 0, dataNumPlaces) + " deg)", dataPrintOffset, l).  set l to l + 1.
		paddedPrintLine("Roll:       " + padding(roll , 0, dataNumPlaces) + " deg (Err: " + padding(STEERINGMANAGER:ROLLERROR, 0, dataNumPlaces) + " deg)", dataPrintOffset, l).  set l to l + 1.
		
		horzLine(l).  set l to l + 1.
		paddedPrintLine(" Commanded Throttle",0,l).  set l to l + 1.
		horzLine(l).  set l to l + 1.
		paddedPrintLine("Throttle:   " + padding(throtValue*100, 3, dataNumPlaces) + "%", dataPrintOffset, l).  set l to l + 1.
				
		horzLine(l).  set l to l + 1.
		paddedPrintLine(" Current Orbit",0,l).  set l to l + 1.
		horzLine(l).  set l to l + 1.
		paddedPrintLine("SMA:        " + padding(curSma,0, dataNumPlaces) + " km (Err: " + padding(errSma,0,dataNumPlaces) + " km)", dataPrintOffset, l).  set l to l + 1.
		paddedPrintLine("ECC:        " + padding(curEcc,0, dataNumPlaces+2) + " (Err: " + padding(errEcc,0,dataNumPlaces) + ")", dataPrintOffset, l).  set l to l + 1.
		paddedPrintLine("INC:        " + padding(curInc, 0, dataNumPlaces) + " deg (Err: " + padding(errInc,0,dataNumPlaces) + " deg)", dataPrintOffset, l).  set l to l + 1.
		paddedPrintLine("RAAN:       " + padding(curRaan, 0, dataNumPlaces) + " deg (Err: " + padding(errRaan,0,dataNumPlaces) + " deg)", dataPrintOffset, l).  set l to l + 1.
		paddedPrintLine("AOP:        " + padding(curArg, 0, dataNumPlaces) + " deg (Err: " + padding(errArg,0,dataNumPlaces) + " deg)", dataPrintOffset, l).  set l to l + 1.
		paddedPrintLine("TRU:        " + padding(curTru, 0, dataNumPlaces) + " deg (Err: " + padding(errTru,0,dataNumPlaces) + " deg)", dataPrintOffset, l).  set l to l + 1.
		
		horzLine(l).  set l to l + 1.
		paddedPrintLine(" Vehicle Data",0,l).  set l to l + 1.
		horzLine(l).  set l to l + 1.
		paddedPrintLine("Tot. Mass:  " + padding(ship:mass, 0, dataNumPlaces) + " mT", dataPrintOffset, l).  set l to l + 1.
	}
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
	set y0List to List().
	set y1List to List().
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
			y0List:add(y0).
			y1List:add(y1).
		}
	}
	
	set interpData to lexicon("yqList",yqList, "ind",ind, "y0List",y0List, "y1List",y1List).
	
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