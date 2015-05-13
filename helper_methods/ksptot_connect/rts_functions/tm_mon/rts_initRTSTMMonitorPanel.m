function rts_initRTSTMMonitorPanel(hRtsMainGUI, hTMMonFig, hClockLabel, hConnStatusLabel, vesselGUID, hTMMonTable, hRtsProcessInfoTable, hRtsDataConnectionInfoTable)
%rts_initRTSTMMonitorPanel Summary of this function goes here
%   Detailed explanation goes here
    timers = getappdata(hRtsMainGUI,'timers');
    utTcpipClient = instrfind('Name','TM_UT');
    
    rtsOpts = getappdata(hRtsMainGUI,'RTSOptions');
    procExecPeriod = 1/str2double(rtsOpts.processFreq);
    procExecMode = rtsOpts.procExecMode;

    clockUpdtFunc = @(obj, event) rts_mainGUIClockUpdateFunc(obj, event, hClockLabel, utTcpipClient);
   	tmMonClockTimer = timer('Name', 'RTSTMMonClockUpdate',...
                                    'ExecutionMode', 'fixedRate', ...   % Run timer repeatedly
                                    'Period', 1, ...                % Initial period is 1 sec.
                                    'StartDelay',0.5, ...
                                    'TimerFcn', clockUpdtFunc); % Specify callback   
    set(tmMonClockTimer,'UserData',{false}); %disallow user edits 
                                
    connUpdtFunc = @(obj, event) rts_pageGetConnStatus(obj, event, vesselGUID, hRtsMainGUI, hConnStatusLabel);
    connStopFcn = @(obj, event) rts_pageGetConnStatus(obj, event, vesselGUID, hRtsMainGUI, hConnStatusLabel, false);
   	tmMonConnStatusTimer = timer('Name', 'RTSTMMonConnStatusUpdate',...
                                    'ExecutionMode', 'fixedRate', ...   % Run timer repeatedly
                                    'Period', 1, ...                % Initial period is 1 sec.
                                    'StartDelay',0.5, ...
                                    'StopFcn', connStopFcn, ...
                                    'TimerFcn', connUpdtFunc); % Specify callback 
    set(tmMonConnStatusTimer,'UserData',{false}); %disallow user edits 
                                
    tmInbndMonUpdtFunc = @(obj, event) rts_TMInboundMonitorUpdtFunc(obj, event, hRtsMainGUI, hTMMonTable);
   	tmInbndMonUpdtTimer = timer('Name', 'RTSTMMonInbdTMUpdate',...
                                    'ExecutionMode', procExecMode, ...   % Run timer repeatedly
                                    'Period', 2, ...                % Initial period is 1 sec.
                                    'StartDelay',0, ...
                                    'TimerFcn', tmInbndMonUpdtFunc); % Specify callback 
	set(tmInbndMonUpdtTimer,'UserData',{false}); %allow user edits
                                
    tmRtsProcInfoUpdtFunc = @(obj, event) rts_ProcInformationUpdtFunc(obj, event, hRtsMainGUI, hRtsProcessInfoTable);
   	tmRtsProcInfoUpdtTimer = timer('Name', 'RTSTMMonProcInfoUpdate',...
                                    'ExecutionMode', procExecMode, ...   % Run timer repeatedly
                                    'Period', 2, ...                % Initial period is 1 sec.
                                    'StartDelay',0.25, ...
                                    'TimerFcn', tmRtsProcInfoUpdtFunc); % Specify callback  
	set(tmRtsProcInfoUpdtTimer,'UserData',{false}); %allow user edits

    tmRtsConnInfoUpdtFunc = @(obj, event) rts_DataConnInfoUpdtFunc(obj, event, hRtsMainGUI, hRtsDataConnectionInfoTable);
   	tmRtsConnInfoUpdtTimer = timer('Name', 'RTSTMMonConnInfoUpdate',...
                                    'ExecutionMode', procExecMode, ...   % Run timer repeatedly
                                    'Period', 2, ...                % Initial period is 1 sec.
                                    'StartDelay',0.5, ...
                                    'TimerFcn', tmRtsConnInfoUpdtFunc); % Specify callback  
	set(tmRtsConnInfoUpdtTimer,'UserData',{false}); %allow user edits

	start(tmMonClockTimer);
    start(tmMonConnStatusTimer);
    start(tmInbndMonUpdtTimer);
    start(tmRtsProcInfoUpdtTimer);
    start(tmRtsConnInfoUpdtTimer);
    
    timers(end+1) = tmMonClockTimer;
    timers(end+1) = tmMonConnStatusTimer;
    timers(end+1) = tmInbndMonUpdtTimer;
    timers(end+1) = tmRtsProcInfoUpdtTimer;
    timers(end+1) = tmRtsConnInfoUpdtTimer;
    setappdata(hRtsMainGUI,'timers', timers);
    
    timersTMMon = timer.empty(1,0);
    timersTMMon(end+1) = tmMonClockTimer;
    timersTMMon(end+1) = tmMonConnStatusTimer;
    timersTMMon(end+1) = tmInbndMonUpdtTimer;
    timersTMMon(end+1) = tmRtsProcInfoUpdtTimer;
    timersTMMon(end+1) = tmRtsConnInfoUpdtTimer;
    setappdata(hTMMonFig,'timers', timersTMMon);
end