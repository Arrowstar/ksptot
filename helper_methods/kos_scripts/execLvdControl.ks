clearscreen.

set Config:IPU to 2000.

lock xq to time:seconds.

set fPath to "test.csv".
set parsedDataList to parseCsvFileToList(fPath).

set xArr to parsedDataList[0].
set yArr to parsedDataList:SUBLIST(1,parsedDataList:length - 1).

set headingRot to heading(0, 0, 0).
lock steering to headingRot.

set throtValue to 0.
lock throttle to throtValue.

set startInd to 0.

until xq > xArr[xArr:length - 1] {
	set interpOutput to interp1(xArr, yArr, xq, startInd).
	set yqList to interpData:yqList.
	set startInd to interpOutput:ind.

	set yaw to yqList[0].
	set pitch to yqList[1].
	set roll to yqList[2].
	set throtValue to yqList[3].

	print "time: " + time:seconds at (0,0).
	print "time: " + time:CALENDAR + " " + time:CLOCK at (0,1).
	print "yaw: " + yaw at (0,2).
	print "pitch: " + pitch at (0,3).
	print "roll: " + roll at (0,4).
	print "throttle: " + throtValue at (0,5).
	print "mass: " + ship:mass at (0,6).
	print "SMA: " + SHIP:ORBIT:SEMIMAJORAXIS at (0,7).
	print "ECC: " + SHIP:ORBIT:ECCENTRICITY at (0,8).
	print "TRU: " + SHIP:ORBIT:TRUEANOMALY at (0,9).
	print "Velocity: " + SHIP:ORBIT:VELOCITY:ORBIT:MAG / 1000 at (0,10).

	set headingRot to heading(yaw, pitch, roll).
}

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

	set csvData to OPEN(PATH(fPath)):READALL().
	set csvDataItr to csvData:ITERATOR.

	set parsedDataList to List().
	until not csvDataItr:next {
		set curLine to csvDataItr:value.
		set curLineValues to curLine:SPLIT(",").
		
		set dataSet to List().
		for value in curLineValues {
			dataSet:add(value:tonumber()).
		}
		parsedDataList:add(dataSet).
	}
	
	return parsedDataList.
}