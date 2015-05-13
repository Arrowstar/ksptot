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
    if(~isempty(varargin))
        hScriptWorkingLbl = varargin{1};
    else
        hScriptWorkingLbl = [];
    end
    
    if(ishandle(hScriptWorkingLbl))
        set(hScriptWorkingLbl,'visible','on');
        drawnow;
    end
    
    clearExecutionWarnings();
    clearExecutionErrors();
    clearWarningErrorLabels();

    [stateLog, errorStr, errorEventNum] = ma_produceStateLogFromScript(script,celBodyData);
    
    if(~isempty(errorStr))
        addToExecutionErrors(errorStr, errorEventNum, -1, celBodyData);
    end
        
    %%%%%%%%%%%
    % Find post-processed errors/warnings
    %%%%%%%%%%%
    checkPeriapsisWarningsErrors(stateLog, celBodyData);
    checkPropLevelsWarningsErrors(stateLog, celBodyData);
%     checkAerobrakingAltitude(stateLog, script, celBodyData);
    checkEventVariablesAndBounds(script, celBodyData);
    checkForNonZeroOptimVars(script, celBodyData);
    
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

