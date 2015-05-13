function handleExecErrorsWarnings(varargin)
%handleExecErrors Summary of this function goes here
%   Detailed explanation goes here
    global warn_error_label_handles warn_error_slider_handle;
    warnErrorLbls = warn_error_label_handles;
    hSlider = warn_error_slider_handle;
    
    execErrors = getExecutionErrors();
    execWarns = getExecutionWarnings();
    
    numWarnError = length(execErrors) + length(execWarns);
    
    if(~isempty(varargin))
        updateSlider = varargin{1};
    else
        updateSlider = true;
    end
    
    if(numWarnError <= 6)
        set(hSlider,'Max',1.0);
        set(hSlider,'Min',0.0);
        set(hSlider,'Value',1.0);
        set(hSlider,'Enable','off');
    else
        if(updateSlider)
            set(hSlider,'Min',0.0);
            set(hSlider,'Max',numWarnError-6);
            set(hSlider,'Value',numWarnError-6);
            set(hSlider,'SliderStep',[1/(numWarnError-6),1.0]);
            set(hSlider,'Enable','on');
        end
    end
    
    lblOffset = round(get(hSlider,'Max') - get(hSlider,'Value'));
    set(hSlider,'Value',round(get(hSlider,'Value')));
    
    lblUseCnt = 0;
    for(i=1+lblOffset:length(execErrors))
        if(lblUseCnt>=6)
            break;
        end
        errorStr = execErrors{i};
        styleLabelAsError(warnErrorLbls(lblUseCnt+1), errorStr);
        drawnow;
        lblUseCnt = lblUseCnt+1;
    end
    
    if(lblOffset >= length(execErrors))
        lblOffset = lblOffset - length(execErrors);
    else
        lblOffset = 0;
    end
        
    for(i=1+lblOffset:length(execWarns)) %#ok<*NO4LP>
        if(lblUseCnt>=6)
            break;
        end
        warnStr = execWarns{i};
        styleLabelAsWarn(warnErrorLbls(lblUseCnt+1), warnStr);
        drawnow;
        lblUseCnt = lblUseCnt+1;
    end
    
    if(numWarnError == 0)
        styleLabelAsValid(warnErrorLbls(1), 'No errors or warnings found.');
        drawnow;
    end    
end

