function rts_initRTSPowThermPanel(hRtsMainGUI, hPowThrmFig, hClockLabel, connStatusLabel, vesselGUID, hElecChargeUITable, hElecChargeSumLabel, hSolarPanelUITable, hTotECGenRateLabel, hPartTempUITable, resourcePanel1)
%rts_initRTSPowThermPanel Summary of this function goes here
%   Detailed explanation goes here

    hElecChargeSumProgBar1 = javacomponent('javax.swing.JProgressBar',get(hElecChargeSumLabel,'Position'), resourcePanel1);
    
    hElecChargeSumProgBar1.setMinimum(0);
    hElecChargeSumProgBar1.setMaximum(100);
    
    delete(hElecChargeSumLabel);

    timers = getappdata(hRtsMainGUI,'timers');
    utTcpipClient = instrfind('Name','TM_UT');
    resourcesTcpipClient = instrfind('Name','TM_VESSEL_RESOURCES');
    tcpipClientSP = instrfind('Name','TM_VESSEL_SOLAR_PANELS');
    tcpipClientTemps = instrfind('Name','TM_VESSEL_TEMPERATURES');
    
    rtsOpts = getappdata(hRtsMainGUI,'RTSOptions');
    procExecPeriod = 1/str2double(rtsOpts.processFreq);
    procExecMode = rtsOpts.procExecMode;

    clockUpdtFunc = @(obj, event) rts_mainGUIClockUpdateFunc(obj, event, hClockLabel, utTcpipClient);
   	powThmClockTimer = timer('Name', 'RTSPowerThermClockUpdate',...
                                    'ExecutionMode', 'fixedRate', ...   % Run timer repeatedly
                                    'Period', 1, ...                % Initial period is 1 sec.
                                    'StartDelay',0.1, ...
                                    'TimerFcn', clockUpdtFunc); % Specify callback 
	set(powThmClockTimer,'UserData',{false}); %disallow user edits    
                                
    connUpdtFunc = @(obj, event) rts_pageGetConnStatus(obj, event, vesselGUID, hRtsMainGUI, connStatusLabel);
    connStopFcn = @(obj, event) rts_pageGetConnStatus(obj, event, vesselGUID, hRtsMainGUI, connStatusLabel, false);
   	powThmConnStatusTimer = timer('Name', 'RTSPowerThermConnStatusUpdate',...
                                    'ExecutionMode', 'fixedRate', ...   % Run timer repeatedly
                                    'Period', 1, ...                % Initial period is 1 sec.
                                    'StartDelay',0.3, ...
                                    'StopFcn', connStopFcn, ...
                                    'TimerFcn', connUpdtFunc); % Specify callback 
	set(powThmConnStatusTimer,'UserData',{false}); %disallow user edits 
    
    resUpdtFunc = @(obj, event) rts_powThmUpdateFunc(obj, event, hPowThrmFig, resourcesTcpipClient, tcpipClientSP, tcpipClientTemps, hElecChargeUITable, hElecChargeSumLabel, hSolarPanelUITable, hTotECGenRateLabel, hPartTempUITable, hElecChargeSumProgBar1);
   	resUptTimer = timer('Name', 'RTSPowerThermResourceUpdate',...
                                    'ExecutionMode', procExecMode, ...   % Run timer repeatedly
                                    'Period', procExecPeriod, ...                % Initial period is 1 sec.
                                    'StartDelay',0.1, ...
                                    'TimerFcn', resUpdtFunc); % Specify callback 
    set(resUptTimer,'UserData',{true}); %allow user edits   

    start(powThmClockTimer);
    start(powThmConnStatusTimer);
    start(resUptTimer);
    
    timers(end+1) = powThmClockTimer;
    timers(end+1) = powThmConnStatusTimer;
    timers(end+1) = resUptTimer;
    setappdata(hRtsMainGUI,'timers', timers);
    
    timersRes = timer.empty(1,0);
    timersRes(end+1) = powThmClockTimer;
    timersRes(end+1) = powThmConnStatusTimer;
    timersRes(end+1) = resUptTimer;
    setappdata(hPowThrmFig,'timers', timersRes);
end

