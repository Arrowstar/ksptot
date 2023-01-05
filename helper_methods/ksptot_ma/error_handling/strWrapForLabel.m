function lblStr = strWrapForLabel(hLabel, str)
    splitStr = strsplit(str,'\n');
    try
        lblStrCell = textwrap(hLabel,splitStr(1));
    catch
        lblStrCell = splitStr(1);
    end
    if(length(lblStrCell) > 1)
        lblStr = sprintf('%s...',lblStrCell{1});
    else
        lblStr = sprintf('%s',lblStrCell{1});
    end
end