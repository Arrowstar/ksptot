function pasteLossConvertFromClipboard(hFigWithLossConvertAppData)
%pasteLossConvertFromClipboard Summary of this function goes here
%   Detailed explanation goes here
    global GLOBAL_LossConvertClipboard;
    
    if(~isempty(GLOBAL_LossConvertClipboard))
        setappdata(hFigWithLossConvertAppData,'lossConverts',GLOBAL_LossConvertClipboard);
    else
        GLOBAL_LossConvertClipboard = [];
        warndlg('Could not paste Loss/Convert settings.  Clipboard contents are either empty or invalid.  Try copying mass loss/conversion settings to the clipboard first.','Could not paste loss/convert settings.');
    end
end

