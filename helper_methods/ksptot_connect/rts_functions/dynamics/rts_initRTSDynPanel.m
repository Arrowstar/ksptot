function rts_initRTSDynPanel(hRtsMainGUI, hDynFig, hClockLabel, connStatusLabel, vesselGUID, hAttPointingTextDispLabel, hAttRatesTextDispLabel, hAttCmdTextDispLabel, hAttDispAxes, hActStatusTextDispLabel, hRwaInfoUitable, hAttDerivedTextDispLabel)
%rts_initRTSDynPanel Summary of this function goes here
%   Detailed explanation goes here

    timers = getappdata(hRtsMainGUI,'timers');
    utTcpipClient = instrfind('Name','TM_UT');
    dynTcpipClient = instrfind('Name','TM_VESSEL_DYNAMICS');
    
    rtsOpts = getappdata(hRtsMainGUI,'RTSOptions');
    procExecPeriod = 1/str2double(rtsOpts.processFreq);
    procExecMode = rtsOpts.procExecMode;

    clockUpdtFunc = @(obj, event) rts_mainGUIClockUpdateFunc(obj, event, hClockLabel, utTcpipClient);
   	dynClockTimer = timer('Name', 'RTSDynClockUpdate',...
                                    'ExecutionMode', 'fixedRate', ...   % Run timer repeatedly
                                    'Period', 1, ...                % Initial period is 1 sec.
                                    'StartDelay',0.1, ...
                                    'TimerFcn', clockUpdtFunc); % Specify callback 
	set(dynClockTimer,'UserData',{false}); %disallow user edits    
                                
    connUpdtFunc = @(obj, event) rts_pageGetConnStatus(obj, event, vesselGUID, hRtsMainGUI, connStatusLabel);
    connStopFcn = @(obj, event) rts_pageGetConnStatus(obj, event, vesselGUID, hRtsMainGUI, connStatusLabel, false);
   	dynConnStatusTimer = timer('Name', 'RTSDynConnStatusUpdate',...
                                    'ExecutionMode', 'fixedRate', ...   % Run timer repeatedly
                                    'Period', 1, ...                % Initial period is 1 sec.
                                    'StartDelay',0.3, ...
                                    'StopFcn', connStopFcn, ...
                                    'TimerFcn', connUpdtFunc); % Specify callback 
	set(dynConnStatusTimer,'UserData',{false}); %disallow user edits  
                                
    attUpdtFunc = @(obj, event) rts_dynAttitudeUpdateFunc(obj, event, hDynFig, dynTcpipClient, hAttPointingTextDispLabel, hAttRatesTextDispLabel, hAttCmdTextDispLabel, hAttDispAxes, hActStatusTextDispLabel, hRwaInfoUitable, hAttDerivedTextDispLabel);
   	dynAttUptTimer = timer('Name', 'RTSDynAttUpdate',...
                                    'ExecutionMode', procExecMode, ...   % Run timer repeatedly
                                    'Period', procExecPeriod, ...                % Initial period is 1 sec.
                                    'StartDelay',0.1, ...
                                    'TimerFcn', attUpdtFunc); % Specify callback 
    set(dynAttUptTimer,'UserData',{true}); %allow user edits    
                                
                                
    start(dynClockTimer);
    start(dynConnStatusTimer);
    start(dynAttUptTimer);
    
    timers(end+1) = dynClockTimer;
    timers(end+1) = dynConnStatusTimer;
    timers(end+1) = dynAttUptTimer;
    setappdata(hRtsMainGUI,'timers', timers);
    
    timersDyn = timer.empty(1,0);
    timersDyn(end+1) = dynClockTimer;
    timersDyn(end+1) = dynConnStatusTimer;
    timersDyn(end+1) = dynAttUptTimer;
    setappdata(hDynFig,'timers', timersDyn);
end

