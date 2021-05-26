function txt = flybyPorkchopUpdateFcn(~, event_obj, xArr, yArr, zMat,inclDepartDV, inclArriveDV) 
%flybyPorkchopUpdateFcn Summary of this function goes here
%   Detailed explanation goes here

    [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();

    pos = get(event_obj,'Position');
    xpos = pos(1)*secInDay;
    ypos = pos(2)*secInDay;
    
    xind = find(abs(xArr-xpos)<1, 1);
    yind = find(abs(yArr-ypos)<1, 1);
    zMat = zMat';
    dv = zMat(xind,yind);
    
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(xpos);
    dateStrDept = formDateStr(year, day, hour, minute, sec);
    
    durationStr = getDurationStr(ypos);
    strLen = 15;
    
    if(isnan(dv))
        dvStr = '(no solution or above plot max)';
    else
        dvStr = [num2str(dv), ' km/s'];
    end
%     dvTypeIncl = 'Delta-V shown includes: powered flyby delta-v';
%     if(inclDepartDV)
%         dvTypeIncl = [dvTypeIncl, '\n',paddStrLeft('departure v_inf',39)];
%     end
%     if(inclArriveDV)
%         dvTypeIncl = [dvTypeIncl, '\n',paddStrLeft('arrival v_inf',37)];
%     end
    
%     txtDisclaimer = 'Delta-v shown is for entire trip, not just\n    this leg!';
    txt = sprintf([[paddStr('Departure: ', strLen), dateStrDept],'\n', [paddStr('Flight Time: ', strLen), durationStr], '\n', [paddStr('Est. Delta-V: ', strLen), dvStr]]);
    
%     txt = {[paddStr('Departure: ', strLen), dateStrDept], ...
%            [paddStr('Flight Time: ', strLen), durationStr], ...
%            [paddStr('Est. Delta-V: ', strLen), dvStr], ...
%            sprintf(dvTypeIncl)};
       
    set(0,'ShowHiddenHandles','on');                       
    hText = findobj('Type','text','Tag','DataTipMarker');  
    set(0,'ShowHiddenHandles','off');
    set(hText, 'FontName', 'fixedwidth');
    set(hText, 'FontSize', 8);
end

