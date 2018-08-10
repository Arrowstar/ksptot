function rts_mainGUIPingConnectionFunc(~, ~, vesselName, hRtsMainGUI, connStatusLabel, tcpipClient)
%rts_mainGUIPingConnectionFunc Summary of this function goes here
%   Detailed explanation goes here
    persistent lastConnected errorCount;
    if(isempty(lastConnected))
        lastConnected = false;
    end
    if(isempty(errorCount))
        errorCount = 0;
    end
    
    lastUtRecvd = now;
    
    tcpipData = get(tcpipClient,'UserData');

    if(~isempty(tcpipData))
        recvdDate = tcpipData{5};
        recvdDateNum = datenum(recvdDate);
        
        if((lastUtRecvd - recvdDateNum)*86400 < 2)
            connected=true;
            errorCount = 0;
        else
            if(errorCount<2)
%                 pause(0.1);
                errorCount = errorCount+1;
                return;
            else
                connected=false;
                vesselName = '';
                errorCount=0;
            end
        end
    else
        connected=false;
        vesselName = '';
    end
    
    try
        setappdata(hRtsMainGUI,'Connected',connected);

        if(connected==false && lastConnected==true)
            rts_EndTMStream(hRtsMainGUI, false, true, false);
            lastConnected=false;
        elseif(connected==true && lastConnected==false)
%             vesselGUID = getappdata(hRtsMainGUI,'VesselGUID');
%             writeDataToKSPTOTConnect('StartVesselTMStream', vesselGUID, 't');
%             rts_StartTMStream(hRtsMainGUI);
%             lastConnected=true;
        end
    catch ME
        disp(ME.message);
        for k=1:length(ME.stack)
            ME.stack(k)
        end
    end
    
    rts_updateConnStatusLbl(connected, connStatusLabel, vesselName);
end

