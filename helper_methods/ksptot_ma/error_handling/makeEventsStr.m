function str = makeEventsStr(bndWarns)
    eventNums = unique(bndWarns);
    str = '';
    for(i=1:length(eventNums))
        if(i==length(eventNums))
            endChar = '';
        else
            endChar = ', ';
        end
        
        str = [str, num2str(eventNums(i)),endChar];
    end
end