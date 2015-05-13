function rts_updateConnStatusLbl(connected, hLbl, vesselName)
%rts_updateConnStatusLbl Summary of this function goes here
%   Detailed explanation goes here

    connStr = 'CONNECTED';
    disconnStr = 'DISCONNECTED';
    if(connected)
        preposition = ' to ';
        statusStr = formConnectedStatusString(connStr, vesselName, preposition);
        statusColor = 'green';
    else
        statusStr = formDisconnectedStatusString(disconnStr);
        statusColor = 'red';
    end
    
    if(ishandle(hLbl))
        set(hLbl, 'String', statusStr);
        set(hLbl, 'ForegroundColor', statusColor);
    end
end

function statusStr = formConnectedStatusString(status, vesselName, preposition)
%     statusStr = [status, preposition, vesselName];
    statusStr = status;
end

function statusStr = formDisconnectedStatusString(status)
    statusStr = status;
end

