lock xq to time:seconds.

set fPath to "test.csv".
set parsedDataList to parseCsvFileToList(fPath).

set xArr to parsedDataList[0].
set yArr to parsedDataList:SUBLIST(1,parsedDataList:length - 1).

lock a to interp1(xArr, yArr, xq).

set headingRot to heading(0, 0, 0).
lock steering to headingRot.

set throtValue to 0.
lock throttle to throtValue.

until xq > xArr[xArr:length - 1] {
	set yaw to a[0].
	set pitch to a[1].
	set roll to a[2].
	//set throtValue to a[3].

	print "yaw: " + yaw at (0,0).
	print "pitch: " + pitch at (0,1).
	print "roll: " + roll at (0,2).

	set headingRot to heading(yaw, pitch, roll).
}

function interp1 {
	parameter xArr. //must be a list of doubles
	parameter yArr. //must be a list of a list of doubles
	parameter xq.   //must be a scalar double
	
	set yqList to List().
	if xq <= xArr[0] {
		for ySubArr in yArr {
			yqList:add(ySubArr[0]).
		}
	
	} else if xq >= xArr[xArr:length - 1] {
		for ySubArr in yArr {
			yqList:add(ySubArr[ySubArr:length - 1]).
		}
	
	} else {
		set i to 0.
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
	
	return yqList.
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