function clearWarningErrorLabels()
%clearWarningErrorLabels Summary of this function goes here
%   Detailed explanation goes here
    global warn_error_label_handles;
    
    warnErrorLbls = warn_error_label_handles;
    for(i=1:length(warnErrorLbls)) %#ok<*NO4LP>
        h = warnErrorLbls(i);
        set(h,'Visible','off');
    end
end

