function rts_initRTSOrbOpsPanel(hRtsMainGUI, hOrbOpsFig, hClockLabel, connStatusLabel, vesselGUID, orbitTextDispLabel, orbitDispAxes, ...
                                targetOrbitTextDispLabel, maneuversTextDispLabel, hRendInfoTextDispLabel)
%initRTSOrbOpsPanel Summary of this function goes here
%   Detailed explanation goes here
    
    timers = getappdata(hRtsMainGUI,'timers');
    utTcpipClient = instrfind('Name','TM_UT');
    orbitTcpipClient = instrfind('Name','TM_ORBIT');
    maneuverTcpipClient = instrfind('Name','TM_MANEUVERS');
    targetOrbitTcpipClient = instrfind('Name','TM_TARGET_ORBIT');
    targetDataTcpipClient = instrfind('Name','TM_TARGET_DATA');
    
    rtsOpts = getappdata(hRtsMainGUI,'RTSOptions');
    procExecPeriod = 1/str2double(rtsOpts.processFreq);
    procExecMode = rtsOpts.procExecMode;
    
    celBodyData = getappdata(hRtsMainGUI,'CelBodyData');

    clockUpdtFunc = @(obj, event) rts_mainGUIClockUpdateFunc(obj, event, hClockLabel, utTcpipClient);
   	orbOpsClockTimer = timer('Name', 'RTSOrbOpsClockUpdate',...
                                    'ExecutionMode', 'fixedRate', ...   % Run timer repeatedly
                                    'Period', 1, ...                % Initial period is 1 sec.
                                    'StartDelay',0.1, ...
                                    'TimerFcn', clockUpdtFunc); % Specify callback   
	set(orbOpsClockTimer,'UserData',{false}); %disallow user edits 
                                
    orbitUpdtFunc = @(obj, event) rts_orbOps_orbitUpdateFunc(obj, event, hOrbOpsFig, orbitTextDispLabel, orbitDispAxes, orbitTcpipClient, celBodyData);
   	orbOpsOrbitPanelTimer = timer('Name', 'RTSOrbOpsOrbitPanelUpdate',...
                                    'ExecutionMode', procExecMode, ...   % Run timer repeatedly
                                    'Period', procExecPeriod, ...                % Initial period is 1 sec.
                                    'StartDelay',0.2, ...
                                    'TimerFcn', orbitUpdtFunc); % Specify callback  
    set(orbOpsOrbitPanelTimer,'UserData',{true}); %allow user edits 
                                
    connUpdtFunc = @(obj, event) rts_pageGetConnStatus(obj, event, vesselGUID, hRtsMainGUI, connStatusLabel);
    connStopFcn = @(obj, event) rts_pageGetConnStatus(obj, event, vesselGUID, hRtsMainGUI, connStatusLabel, false);
   	orbOpsConnStatusTimer = timer('Name', 'RTSOrbOpsConnStatusUpdate',...
                                    'ExecutionMode', 'fixedRate', ...   % Run timer repeatedly
                                    'Period', 1, ...                % Initial period is 1 sec.
                                    'StartDelay',0.3, ...
                                    'StopFcn', connStopFcn, ...
                                    'TimerFcn', connUpdtFunc); % Specify callback 
	set(orbOpsConnStatusTimer,'UserData',{false}); %disallow user edits 
                                
    maneuversUpdtFunc = @(obj, event) rts_orbOps_ManueversUpdateFunc(obj, event, maneuverTcpipClient, maneuversTextDispLabel);
   	orbOpsManeuverPanelTimer = timer('Name', 'RTSOrbOpsManeuversPanelUpdate',...
                                    'ExecutionMode', procExecMode, ...   % Run timer repeatedly
                                    'Period', procExecPeriod, ...                % Initial period is 1 sec.
                                    'StartDelay',0.4, ...
                                    'TimerFcn', maneuversUpdtFunc); % Specify callback 
	set(maneuversTextDispLabel,'UserData',0); %sets the current maneuver number to use
    set(orbOpsManeuverPanelTimer,'UserData',{true}); %allow user edits
                                
    targetOrbitUpdtFunc = @(obj, event) rts_orbOps_orbitUpdateFunc(obj, event, hOrbOpsFig, targetOrbitTextDispLabel, [], targetOrbitTcpipClient, celBodyData);
   	orbOpsTargetOrbitPanelTimer = timer('Name', 'RTSOrbOpsOrbitPanelUpdate',...
                                    'ExecutionMode', procExecMode, ...   % Run timer repeatedly
                                    'Period', procExecPeriod, ...                % Initial period is 1 sec.
                                    'StartDelay',0.5, ...
                                    'TimerFcn', targetOrbitUpdtFunc); % Specify callback 
	set(orbOpsTargetOrbitPanelTimer,'UserData',{true}); %allow user edits
                                
    targetDataUpdtFunc = @(obj, event) rts_orbOps_TargetDataUpdateFunc(obj, event, targetDataTcpipClient, hRendInfoTextDispLabel);
   	orbOpsTargetDataPanelTimer = timer('Name', 'RTSOrbOpsTargetDataPanelUpdate',...
                                    'ExecutionMode', procExecMode, ...   % Run timer repeatedly
                                    'Period', procExecPeriod, ...                % Initial period is 1 sec.
                                    'StartDelay',0.6, ...
                                    'TimerFcn', targetDataUpdtFunc); % Specify callback 
	set(orbOpsTargetDataPanelTimer,'UserData',{true}); %allow user edits
                                
    
    start(orbOpsClockTimer);
    start(orbOpsOrbitPanelTimer);
    start(orbOpsConnStatusTimer);
    start(orbOpsManeuverPanelTimer);
    start(orbOpsTargetOrbitPanelTimer);
    start(orbOpsTargetDataPanelTimer);
    
    timers(end+1) = orbOpsClockTimer;
    timers(end+1) = orbOpsOrbitPanelTimer;
    timers(end+1) = orbOpsConnStatusTimer;
    timers(end+1) = orbOpsManeuverPanelTimer;
    timers(end+1) = orbOpsTargetOrbitPanelTimer;
    timers(end+1) = orbOpsTargetDataPanelTimer;
    setappdata(hRtsMainGUI,'timers', timers);
    
    timersOrbOps = timer.empty(1,0);
    timersOrbOps(end+1) = orbOpsClockTimer;
    timersOrbOps(end+1) = orbOpsOrbitPanelTimer;
    timersOrbOps(end+1) = orbOpsConnStatusTimer;
    timersOrbOps(end+1) = orbOpsManeuverPanelTimer;
    timersOrbOps(end+1) = orbOpsTargetOrbitPanelTimer;
    timersOrbOps(end+1) = orbOpsTargetDataPanelTimer;
    setappdata(hOrbOpsFig,'timers', timersOrbOps);
end
