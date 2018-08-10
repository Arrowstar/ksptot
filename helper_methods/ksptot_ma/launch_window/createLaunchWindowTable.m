function lwString = createLaunchWindowTable(x1, x2, fval1, fval2, beta1, beta2, bodyInfo, numWindows)
%createLaunchWindowTable Summary of this function goes here
%   Detailed explanation goes here
    rotPeriod = bodyInfo.rotperiod;

    if(x1 > x2)
        x1T = x1;
        x2T = x2;
        
        x1 = x2T;
        x2 = x1T;
        
        beta1T = beta1;
        beta2T = beta2;
        
        beta1 = beta2T;
        beta2 = beta1T;
    end
    
    lwString = {};
    lwString{end+1,1} = ' Lnch Wnd Ctr [UT sec] | Lnch Az. [deg] ';
    lwString{end+1,1} = '----------------------------------------';
    for(i=0:numWindows-1)
        win1Ctr = x1 + i*rotPeriod;
        win2Ctr = x2 + i*rotPeriod;
        
        azDeg1 = rad2deg(beta1);
        azDeg2 = rad2deg(beta2);
        
        win1CtrStr = strjust(sprintf('%23.3f',win1Ctr),'center');
        win2CtrStr = strjust(sprintf('%23.3f',win2Ctr),'center');
        azDeg1Str = strjust(sprintf('%15.3f',azDeg1),'center');
        azDeg2Str = strjust(sprintf('%15.3f',azDeg2),'center');
        
        lwString{end+1,1} = sprintf('%23s|%15s',win1CtrStr,azDeg1Str);
        lwString{end+1,1} = sprintf('%23s|%15s',win2CtrStr,azDeg2Str);
    end
    lwString{end+1,1} = '----------------------------------------';
end

