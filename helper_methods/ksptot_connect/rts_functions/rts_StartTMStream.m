function rts_StartTMStream(hRtsMainGUI)
%rts_StartTMStream Summary of this function goes here
%   Detailed explanation goes here    

    connected = getappdata(hRtsMainGUI,'Connected');
    if(~isempty(connected) && connected==true)
        rts_EndTMStream(hRtsMainGUI, false, false, false);
    end
    
    timers = getappdata(hRtsMainGUI,'timers');
    tcpips = getappdata(hRtsMainGUI,'tcpip');
    
    if(~isempty(timers) && ~isempty(tcpips)) 
        try
            for(i=1:length(tcpips)) %#ok<*NO4LP>
                conn = tcpips{i};
                if(isvalid(conn))
                    if(strcmpi(get(conn,'Status'),'closed'))
                        fopen(conn);
                    end
                else
                    delete(conn);
                end
            end

            for(i=1:length(timers))
                timerObj = timers(i);
                if(isvalid(timerObj))
                    if(strcmpi(get(timerObj,'Running'),'off'))
                        start(timerObj);
                    end
                else
                    delete(timerObj);
                end
            end

            VesselGUID = getappdata(hRtsMainGUI,'VesselGUID');
            writeDataToKSPTOTConnect('StartVesselTMStream', VesselGUID, 't'); 
        catch ME
            hardStart(hRtsMainGUI)
        end
    else
        hardStart(hRtsMainGUI)
    end
end

function hardStart(hRtsMainGUI)
    timers = timer.empty(1,0);
    tcpips = {};
    
    rHost = getappdata(hRtsMainGUI,'RHost');
    mainGUIFig = getappdata(hRtsMainGUI,'mainGUIFig');
    
    rts_pageCloseStopTimers(hRtsMainGUI);
    mainGUIHandles = guidata(hRtsMainGUI);
    
    rtsOpts = getappdata(hRtsMainGUI,'RTSOptions');

    [vGUID, rHost] = rts_VesselSelectGUI(mainGUIFig, rHost);
    mainGUIHandles.vesselGUID = vGUID;
    setappdata(hRtsMainGUI,'VesselGUID',mainGUIHandles.vesselGUID);
    setappdata(hRtsMainGUI,'RHost',rHost);
    updateAppOptions(mainGUIFig, 'ksptot', 'rtshostname', rHost);
    
    guidata(hRtsMainGUI,mainGUIHandles);
    if(~isempty(mainGUIHandles.vesselGUID))
        try
            vesselName = readStringFromKSPTOTConnect('GetVesselNameByGUID', mainGUIHandles.vesselGUID, true);

            writeDataToKSPTOTConnect('StartVesselTMStream', mainGUIHandles.vesselGUID, 't');  
            pause(0.1);
            clearBuffFnc = @(obj, event) rts_clearInputBuffer(obj, event);
            
            tcpipClient0 = createTcpIpClient(8283,'Client', rHost);
            set(tcpipClient0, 'Name', 'TM_UT');
            set(tcpipClient0, 'BytesAvailableFcn', clearBuffFnc);
            
            tcpipClient1 = createTcpIpClient(8284,'Client', rHost);
            set(tcpipClient1, 'Name', 'TM_ORBIT');
            set(tcpipClient1, 'BytesAvailableFcn', clearBuffFnc);
            
            tcpipClient2 = createTcpIpClient(8285,'Client', rHost);
            set(tcpipClient2, 'Name', 'TM_MANEUVERS');
            set(tcpipClient2, 'BytesAvailableFcn', clearBuffFnc);
            
            tcpipClient3 = createTcpIpClient(8286,'Client', rHost);
            set(tcpipClient3, 'Name', 'TM_TARGET_ORBIT');
            set(tcpipClient3, 'BytesAvailableFcn', clearBuffFnc);
            
            tcpipClient4 = createTcpIpClient(8287,'Client', rHost);
            set(tcpipClient4, 'Name', 'TM_TARGET_DATA');
            set(tcpipClient4, 'BytesAvailableFcn', clearBuffFnc);
            
            tcpipClient5 = createTcpIpClient(8288,'Client', rHost);
            set(tcpipClient5, 'Name', 'TM_VESSEL_DYNAMICS');
            set(tcpipClient5, 'BytesAvailableFcn', clearBuffFnc);
            
            tcpipClient6 = createTcpIpClient(8289,'Client', rHost);
            set(tcpipClient6, 'Name', 'TM_VESSEL_RESOURCES');
            set(tcpipClient6, 'BytesAvailableFcn', clearBuffFnc);
            
            tcpipClient7 = createTcpIpClient(8290,'Client', rHost);
            set(tcpipClient7, 'Name', 'TM_VESSEL_SOLAR_PANELS');
            set(tcpipClient7, 'BytesAvailableFcn', clearBuffFnc);
            
            tcpipClient8 = createTcpIpClient(8291,'Client', rHost);
            set(tcpipClient8, 'Name', 'TM_VESSEL_TEMPERATURES');
            set(tcpipClient8, 'BytesAvailableFcn', clearBuffFnc);
            
            tcpipClient9 = createTcpIpClient(8292,'Client', rHost);
            set(tcpipClient9, 'Name', 'TM_VESSEL_MAIN_ENGINES');
            set(tcpipClient9, 'BytesAvailableFcn', clearBuffFnc);
            
            tcpipClient10 = createTcpIpClient(8293,'Client', rHost);
            set(tcpipClient10, 'Name', 'TM_VESSEL_RCS_ENGINES');
            set(tcpipClient10, 'BytesAvailableFcn', clearBuffFnc);
            
            tcpipClient11 = createTcpIpClient(8294,'Client', rHost);
            set(tcpipClient11, 'Name', 'TM_VESSEL_DBLS');
            set(tcpipClient11, 'BytesAvailableFcn', clearBuffFnc);
            
            tcpipClient12 = createTcpIpClient(8295,'Client', rHost);
            set(tcpipClient12, 'Name', 'TM_KILL');
            killTMStreamFnc = @(dummy) rts_killSwitch(dummy, hRtsMainGUI,tcpipClient12);
            set(tcpipClient12, 'BytesAvailableFcn', killTMStreamFnc);
            set(tcpipClient12, 'BytesAvailableFcnCount', 1);

            utUpdtFunc = @(obj, event) rts_retrieveUtAndStore(obj, event, tcpipClient0);
            utUpdtTimer = timer('Name', 'UTUpdate',...
                                            'ExecutionMode', rtsOpts.procExecMode, ...   % Run timer repeatedly
                                            'Period', 0.5, ...                % Initial period is 1 sec.
                                            'StartDelay',0.0, ...
                                            'TimerFcn', utUpdtFunc); % Specify callback
            set(utUpdtTimer,'UserData',{false}); %disallow user edits
            
            clockUpdtFunc = @(obj, event) rts_mainGUIClockUpdateFunc(obj, event, mainGUIHandles.clockLabel, tcpipClient0);
            mainRTSPageClockTimer = timer('Name', 'RTSMainGUIClockUpdate',...
                                            'ExecutionMode', rtsOpts.procExecMode, ...   % Run timer repeatedly
                                            'Period', 0.5, ...                % Initial period is 1 sec.
                                            'StartDelay',0.1, ...
                                            'TimerFcn', clockUpdtFunc); % Specify callback                        
            set(mainRTSPageClockTimer,'UserData',{false}); %disallow user edits
            
            connStatusUpdtFunc = @(obj, event) rts_mainGUIPingConnectionFunc(obj, event, vesselName, mainGUIHandles.rtsMainGUI, mainGUIHandles.connStatusLabel, tcpipClient0);
            mainRTSPageStatusTimer = timer('Name', 'RTSMainGUIConnStatusUpdate',...
                                            'ExecutionMode', rtsOpts.procExecMode, ...   % Run timer repeatedly
                                            'Period', 0.5, ...                % Initial period is 1 sec.
                                            'StartDelay',0.2, ...
                                            'TimerFcn', connStatusUpdtFunc); % Specify callback
            set(mainRTSPageStatusTimer,'UserData',{false}); %disallow user edits

            tmRetUpdtFuncs = {};
            numDblsUpdtFunc = @(obj, event) rts_retrieveNumDbls(obj, event, tcpipClient11);
            tmRetUpdtFuncs{end+1} = numDblsUpdtFunc;
            
            orbitUpdtFunc = @(obj, event) rts_retrieveOrbitAndStore(obj, event, tcpipClient1);
            tmRetUpdtFuncs{end+1} = orbitUpdtFunc;

            maneuversUpdtFunc = @(obj, event) rts_retrieveManeuversAndStore(obj, event, tcpipClient2, mainGUIHandles.vesselGUID, tcpipClient11);
            tmRetUpdtFuncs{end+1} = maneuversUpdtFunc;
            
            targetOrbitUpdtFunc = @(obj, event) rts_retrieveOrbitAndStore(obj, event, tcpipClient3);
            tmRetUpdtFuncs{end+1} = targetOrbitUpdtFunc;

            targetDataUpdtFunc = @(obj, event) rts_retrieveTargetDataAndStore(obj, event, tcpipClient4);
            tmRetUpdtFuncs{end+1} = targetDataUpdtFunc;

            vesselDynUpdtFunc = @(obj, event) rts_retrieveDynamicsAndStore(obj, event, tcpipClient5, mainGUIHandles.vesselGUID, tcpipClient11);
            tmRetUpdtFuncs{end+1} = vesselDynUpdtFunc;

            vesselResUpdtFunc = @(obj, event) rts_retrieveResourcesAndStore(obj, event, tcpipClient6, mainGUIHandles.vesselGUID, tcpipClient11);
            tmRetUpdtFuncs{end+1} = vesselResUpdtFunc;            

            vesselSolarPanelUpdtFunc = @(obj, event) rts_retrieveSolarPanelsAndStore(obj, event, tcpipClient7, mainGUIHandles.vesselGUID, tcpipClient11);
            tmRetUpdtFuncs{end+1} = vesselSolarPanelUpdtFunc;             

            vesselTempsUpdtFunc = @(obj, event) rts_retrievePartTempsAndStore(obj, event, tcpipClient8, mainGUIHandles.vesselGUID, tcpipClient11);
            tmRetUpdtFuncs{end+1} = vesselTempsUpdtFunc;    

            vesselMEnginesUpdtFunc = @(obj, event) rts_retrieveMainEngineDataAndStore(obj, event, tcpipClient9, mainGUIHandles.vesselGUID, tcpipClient11);
            tmRetUpdtFuncs{end+1} = vesselMEnginesUpdtFunc; 
            
            vesselRCSEnginesUpdtFunc = @(obj, event) rts_retrieveRCSEngineDataAndStore(obj, event, tcpipClient10, mainGUIHandles.vesselGUID, tcpipClient11);
            tmRetUpdtFuncs{end+1} = vesselRCSEnginesUpdtFunc; 
            
            vesselDataUpdtFunc = @(obj, event) rts_retrieveUpdtDataStore(obj, event, tmRetUpdtFuncs);
            vesselDataUpdtTimer = timer('Name', 'VesselTMDataUpdate',...
                                            'ExecutionMode', rtsOpts.procExecMode, ...   % Run timer repeatedly
                                            'Period', 1.0, ...                % Initial period is 1 sec.
                                            'StartDelay',0, ...
                                            'TimerFcn', vesselDataUpdtFunc); % Specify callback
            set(vesselDataUpdtTimer,'UserData',{false}); %allow user edits
            
            fopen(tcpipClient0);
            fopen(tcpipClient1);
            fopen(tcpipClient2);
            fopen(tcpipClient3);
            fopen(tcpipClient4);
            fopen(tcpipClient5);
            fopen(tcpipClient6);
            fopen(tcpipClient7);
            fopen(tcpipClient8);
            fopen(tcpipClient9);
            fopen(tcpipClient10);
            fopen(tcpipClient11);
            fopen(tcpipClient12);
            
            start(utUpdtTimer);
            start(mainRTSPageClockTimer);
            start(mainRTSPageStatusTimer);
            start(vesselDataUpdtTimer);

            timers(end+1) = utUpdtTimer;
            timers(end+1) = mainRTSPageClockTimer;
            timers(end+1) = mainRTSPageStatusTimer;
            timers(end+1) = vesselDataUpdtTimer;

            tcpips{end+1} = tcpipClient0;
            tcpips{end+1} = tcpipClient1;
            tcpips{end+1} = tcpipClient2;
            tcpips{end+1} = tcpipClient3;
            tcpips{end+1} = tcpipClient4;
            tcpips{end+1} = tcpipClient5;
            tcpips{end+1} = tcpipClient6;
            tcpips{end+1} = tcpipClient7;
            tcpips{end+1} = tcpipClient8;
            tcpips{end+1} = tcpipClient9;
            tcpips{end+1} = tcpipClient10;
            tcpips{end+1} = tcpipClient11;
            tcpips{end+1} = tcpipClient12;

            guidata(hRtsMainGUI,mainGUIHandles);
            setappdata(hRtsMainGUI,'timers',timers);
            setappdata(hRtsMainGUI,'tcpip',tcpips);

            rts_updateConnStatusLbl(true, mainGUIHandles.connStatusLabel, vesselName);            
        catch ME
            disp(ME.message);
            for k=1:length(ME.stack)
                ME.stack(k)
            end
            guidata(hRtsMainGUI,mainGUIHandles);
            rts_updateConnStatusLbl(false, mainGUIHandles.connStatusLabel, '');
        end
    else
        close(mainGUIHandles.rtsMainGUI);
    end
end


