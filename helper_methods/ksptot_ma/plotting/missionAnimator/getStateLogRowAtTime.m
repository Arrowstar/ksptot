function stateLogRow = getStateLogRowAtTime(stateLog, time)
    if(time <= min(stateLog(:,1)))
        stateLogRow = stateLog(1,:);
    elseif(time >= max(stateLog(:,1)))
        stateLogRow = stateLog(end,:);
    else
        frameTimeLwr = max(stateLog(stateLog(:,1)<=time,1));
        stateLogRowLwr = stateLog(stateLog(:,1)==frameTimeLwr,:);
        stateLogRowLwr = stateLogRowLwr(1,:);
        
        frameTimeUpr = min(stateLog(stateLog(:,1)>time,1));
        stateLogRowUpr = stateLog(stateLog(:,1)==frameTimeUpr,:);
        stateLogRowUpr = stateLogRowUpr(1,:);
        
        interpX = [stateLogRowLwr(1), stateLogRowUpr(1)];
        interpYx = [stateLogRowLwr(2), stateLogRowUpr(2)];
        interpYy = [stateLogRowLwr(3), stateLogRowUpr(3)];
        interpYz = [stateLogRowLwr(4), stateLogRowUpr(4)];
        interpYVx = [stateLogRowLwr(5), stateLogRowUpr(5)];
        interpYVy = [stateLogRowLwr(6), stateLogRowUpr(6)];
        interpYVz = [stateLogRowLwr(7), stateLogRowUpr(7)];
        
        posX = interp1(interpX,interpYx,time);
        posY = interp1(interpX,interpYy,time);
        posZ = interp1(interpX,interpYz,time);
        velX = interp1(interpX,interpYVx,time);
        velY = interp1(interpX,interpYVy,time);
        velZ = interp1(interpX,interpYVz,time);
        
        stateLogRow = stateLogRowLwr;
        stateLogRow(2:7) = [posX, posY, posZ, velX, velY, velZ];
    end 
end