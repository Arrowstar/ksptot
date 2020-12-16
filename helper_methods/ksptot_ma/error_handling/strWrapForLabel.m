function lblStr = strWrapForLabel(hLabel, str)
    splitStr = strsplit(str,'\n');
    lblStrCell = textwrap(hLabel,splitStr(1));
    if(length(lblStrCell) > 1)
        lblStr = sprintf('%s...',lblStrCell{1});
    else
        lblStr = sprintf('%s',lblStrCell{1});
    end
end