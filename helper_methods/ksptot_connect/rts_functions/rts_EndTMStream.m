function rts_EndTMStream(hRtsMainGUI, deleteObj, keepPingTimerAlive, endRemoteTMStream)
%rts_EndTMStream Summary of this function goes here
%   Detailed explanation goes here
    mainGUIHandles = guidata(hRtsMainGUI);
    timers = getappdata(hRtsMainGUI,'timers');
    tcpips = getappdata(hRtsMainGUI,'tcpip');
    
    pingTimers = {};
    if(keepPingTimerAlive)
%         pingTimers{1} = timerfind('Name','RTSMainGUIConnStatusUpdate');
%         pingTimers{2} = timerfind('Name','orbOpsConnStatusTimer');
%         pingTimers{3} = timerfind('Name','RTSDynConnStatusUpdate');
%         pingTimers{4} = timerfind('Name','UTUpdate');
    end
    
    try
        if(endRemoteTMStream)
            VesselGUID = getappdata(hRtsMainGUI,'VesselGUID');
            writeDataToKSPTOTConnect('EndVesselTMStream', VesselGUID, 't'); 
            pause(0.1);
        end
    catch ME
        disp(ME.stack(1));
    end
       
    if(~isempty(timers))
        for(i=1:length(timers))
            timerObj = timers(i);
            if(isvalid(timerObj))
                if(~keepPingTimerAlive)
                    stop(timerObj);
                else
                    if(~isTimerInCellArrayOfTimers(timerObj, pingTimers))
                        stop(timerObj);
                    end
                end
            end
            if(deleteObj)
                if(~keepPingTimerAlive)
                    delete(timerObj);
                else
                    for(i=1:length(pingTimers))
                        pingTimer = pingTimers{i};
                        if(~isequal(timerObj, pingTimer))
                            delete(timerObj);
                        end
                    end
                end
            end
        end
    end

    if(~isempty(tcpips))
        for(i=1:length(tcpips))
            conn = tcpips{i};
            if(isvalid(conn))
                fclose(conn);
            end
            if(deleteObj)
                delete(conn);
            end
        end
    end
    
    if(deleteObj)
        timers = timer.empty(1,0);
        tcpips = {};

        setappdata(hRtsMainGUI,'timers',timers);
        setappdata(hRtsMainGUI,'tcpip',tcpips);
    end
    
    rts_updateConnStatusLbl(false, mainGUIHandles.connStatusLabel, '');
end

function b = isTimerInCellArrayOfTimers(timerObj, timers)
    b = false;
    for(i=1:length(timers))
        timer = timers{i};
        if(isequal(timerObj,timer))
            b = true;
            break;
        end
    end
end

