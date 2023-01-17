function outStr = getPrettyStringForIntegerArray(arr)
    arguments
        arr double {mustBeVector(arr), mustBeInteger(arr)}
    end

    uniqueArr = unique(arr);
    if(numel(uniqueArr) ~= numel(arr))
        error('Input integer array must only contain unique values.');
    end

    arr = sort(arr);
    arr = arr(:)';

    diffArr = diff(arr);
    endInds = find(diffArr > 1);
    startInds = [1, endInds(:)'+1];
    endInds = [endInds(:)', numel(arr)];

    str = string.empty(1,0);
    for(i=1:length(startInds)) %#ok<*NO4LP> 
        startNum = arr(startInds(i));
        endNum = arr(endInds(i));

        if(startNum == endNum)
            str(i) = sprintf("%i", startNum);
        else
            str(i) = sprintf("%i-%i", startNum, endNum);
        end
    end

    outStr = strjoin(str, ", ");
end