function rts_initRTSPropPanel(hRtsMainGUI, hPropFig, hClockLabel, connStatusLabel, vesselGUID, hResUITable1, hResSumLabel1, hResUITable2, hResSumLabel2, hResourceCombo1, hResourceCombo2, hMainEngineUITable, hRcsEngineUITable, resourcePanel1, resourcePanel2)
%rts_initRTSPropPanel Summary of this function goes here
%   Detailed explanation goes here

    hResSumProgBar1 = javacomponent('javax.swing.JProgressBar',get(hResSumLabel1,'Position'), resourcePanel1);
    hResSumProgBar2 = javacomponent('javax.swing.JProgressBar',get(hResSumLabel2,'Position'), resourcePanel2);
    
    hResSumProgBar1.setMinimum(0);
    hResSumProgBar1.setMaximum(100);
    hResSumProgBar2.setMinimum(0);
    hResSumProgBar2.setMaximum(100);
    
    delete(hResSumLabel1);
    delete(hResSumLabel2);

    timers = getappdata(hRtsMainGUI,'timers');
    utTcpipClient = instrfind('Name','TM_UT');
    resourcesTcpipClient = instrfind('Name','TM_VESSEL_RESOURCES');
    tcpipClientMainEng = instrfind('Name','TM_VESSEL_MAIN_ENGINES'); 
    tcpipClientRcsEng = instrfind('Name','TM_VESSEL_RCS_ENGINES');
    
    rtsOpts = getappdata(hRtsMainGUI,'RTSOptions');
    procExecPeriod = 1/str2double(rtsOpts.processFreq);
    procExecMode = rtsOpts.procExecMode;

    clockUpdtFunc = @(obj, event) rts_mainGUIClockUpdateFunc(obj, event, hClockLabel, utTcpipClient);
   	propClockTimer = timer('Name', 'RTSPropClockUpdate',...
                                    'ExecutionMode', 'fixedRate', ...   % Run timer repeatedly
                                    'Period', 1, ...                % Initial period is 1 sec.
                                    'StartDelay',0.1, ...
                                    'TimerFcn', clockUpdtFunc); % Specify callback 
	set(propClockTimer,'UserData',{false}); %disallow user edits    
                                
    connUpdtFunc = @(obj, event) rts_pageGetConnStatus(obj, event, vesselGUID, hRtsMainGUI, connStatusLabel);
    connStopFcn = @(obj, event) rts_pageGetConnStatus(obj, event, vesselGUID, hRtsMainGUI, connStatusLabel, false);
   	propConnStatusTimer = timer('Name', 'RTSPropConnStatusUpdate',...
                                    'ExecutionMode', 'fixedRate', ...   % Run timer repeatedly
                                    'Period', 1, ...                % Initial period is 1 sec.
                                    'StartDelay',0.3, ...
                                    'StopFcn', connStopFcn, ...
                                    'TimerFcn', connUpdtFunc); % Specify callback 
	set(propConnStatusTimer,'UserData',{false}); %disallow user edits 

    resUpdt1Func = @(obj, event) rts_propUpdateFunc(obj, event, hPropFig, resourcesTcpipClient, tcpipClientMainEng, tcpipClientRcsEng, hResUITable1, hResSumProgBar1, hResUITable2, hResSumProgBar2, hResourceCombo1, hResourceCombo2, hMainEngineUITable, hRcsEngineUITable);
   	resUpt1Timer = timer('Name', 'RTSPowerThermResourceUpdate',...
                                    'ExecutionMode', procExecMode, ...   % Run timer repeatedly
                                    'Period', procExecPeriod, ...                % Initial period is 1 sec.
                                    'StartDelay',0.0, ...
                                    'TimerFcn', resUpdt1Func); % Specify callback 
    set(resUpt1Timer,'UserData',{true}); %allow user edits   
    
    
    start(propClockTimer);
    start(propConnStatusTimer);
    start(resUpt1Timer);
    
    timers(end+1) = propClockTimer;
    timers(end+1) = propConnStatusTimer;
    timers(end+1) = resUpt1Timer;
    setappdata(hRtsMainGUI,'timers', timers);
    
    timersProp = timer.empty(1,0);
    timersProp(end+1) = propClockTimer;
    timersProp(end+1) = propConnStatusTimer;
    timersProp(end+1) = resUpt1Timer;
    setappdata(hPropFig,'timers', timersProp);
end

