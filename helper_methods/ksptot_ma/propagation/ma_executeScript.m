function stateLog = ma_executeScript(script,handles,celBodyData,varargin)
%ma_executeScript Summary of this function goes here
%   Detailed explanation goes here

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % State Log Format:
    % [UT rX rY rZ vX vY vZ centralBodyID dryMass fuelOxMass monoMass xenonMass eventNum]
    %
    % UNITS:
    %%%%%%
    % UT in seconds
    % R in km
    % V in km/s
    % centralBodyID is integer >= 0
    % dryMass in tons
    % fuelOxMass in tons
    % monoMass in tons
    % xenonMass in tons
    % eventNum is dimensionless
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
    maData      = getappdata(handles.ma_MainGUI,'ma_data');
    
    if(numel(varargin) >= 2)
        forcePropScript = varargin{2};
    else
        forcePropScript = false;
    end
    
    if(isempty(maData) || forcePropScript == true || maData.settings.autoPropScript == true)
        stateLog = propagateScript(script,handles,celBodyData,maData,writeOutput,varargin);
    else
        set(handles.scriptResultsOutOfDateLbl,'visible','on');
        
        stateLog = maData.stateLog;
    end
end

function stateLog = propagateScript(script,handles,celBodyData,maData,writeOutput,vInputs)
    if(isempty(maData))
        otherSCs = {};
    else
        otherSCs = maData.spacecraft.otherSC;
    end
    
    if(numel(vInputs) >= 1)
        hScriptWorkingLbl = vInputs{1};
    else
        hScriptWorkingLbl = [];
    end
    
    set(handles.scriptResultsOutOfDateLbl,'visible','off');
    if(ishandle(hScriptWorkingLbl))
        set(hScriptWorkingLbl,'visible','on');
        drawnow;
    end
    
    clearExecutionWarnings();
    clearExecutionErrors();
    clearWarningErrorLabels();

    tt = tic;
    [stateLog, errorStr, errorEventNum] = ma_produceStateLogFromScript(script,maData,celBodyData,false);
    execTime = toc(tt);
    writeOutput(sprintf('Executed mission script in %0.3f seconds.',execTime),'append');
    
    if(~isempty(errorStr))
        addToExecutionErrors(errorStr, errorEventNum, -1, celBodyData);
    end
        
    %%%%%%%%%%%
    % Find post-processed errors/warnings
    %%%%%%%%%%%
    checkPeriapsisWarningsErrors(stateLog, script, celBodyData);
    checkPropLevelsWarningsErrors(stateLog, celBodyData);
%     checkAerobrakingAltitude(stateLog, script, celBodyData);
    checkForNBodyMaxPropTime(stateLog, script, celBodyData);
    checkEventVariablesAndBounds(script, celBodyData);
    checkForNonZeroOptimVars(script, celBodyData);
    checkForFuncValCoastMaxPropTime(stateLog, script, celBodyData);
    try
        checkForOptimConstraintViolations(maData, celBodyData);
    catch ME
        %don't want anything to happen here...
    end
    
    %%%%%%%%%%%
    %handle errors/warnings
    %%%%%%%%%%%
    handleExecErrorsWarnings();
    drawnow;
    
    if(ishandle(hScriptWorkingLbl))
        set(hScriptWorkingLbl,'visible','off');
        drawnow;
    end
end
