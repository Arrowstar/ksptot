function rts_orbOps_TargetDataUpdateFunc(~, ~, tcpipClient, hRendInfoTextDispLabel)
%rts_orbOps_TargetDataUpdateFunc Summary of this function goes here
%   Detailed explanation goes here

    try
        data = get(tcpipClient,'UserData');
        targetData = data{1};
        if(~isempty(targetData))
            %UPDATE MANEUVER PANEL
            if(~isempty(hRendInfoTextDispLabel))
                targetDataStr = generateRendPanelStr(targetData);
                set(hRendInfoTextDispLabel,'String',targetDataStr);
            end
        end
    catch ME
        disp(ME.stack(1));
    end
end

function targetDataStr = generateRendPanelStr(targetData)
    relPosX = targetData(1);
    relPosY = targetData(2);
    relPosZ = targetData(3);
    relPosMag = norm([targetData(1) targetData(2) targetData(3)]);
    relVelX = targetData(4);
    relVelY = targetData(5);
    relVelZ = targetData(6);
    relVelMag = norm([targetData(4) targetData(5) targetData(6)]);

    rendDescArr = {};
    rendDescArr(end+1,:) = {'Relative Pos X', relPosX, 'km'};
    rendDescArr(end+1,:) = {'Relative Pos X', relPosY, 'km'};
    rendDescArr(end+1,:) = {'Relative Pos X', relPosZ, 'km'};
    rendDescArr(end+1,:) = {'Target Dist.', relPosMag, 'km'};
    
    rendDescArr(end+1,:) = {'hrhrhr','hrhrhr','hrhrhr'};
    rendDescArr(end+1,:) = {'Relative Vel X', relVelX, 'm/s'};
    rendDescArr(end+1,:) = {'Relative Vel Y', relVelY, 'm/s'};
    rendDescArr(end+1,:) = {'Relative Vel Z', relVelZ, 'm/s'};
    rendDescArr(end+1,:) = {'Rel. Velocity', relVelMag, 'm/s'};

    targetDataStr = formRendText(rendDescArr);
end

function rendText = formRendText(rendDescArr) 
    padLengthQuant = 11;
    form = '%9.3f';
    rendText = {};
    
    for(i=1:size(rendDescArr,1))
        row = rendDescArr(i,:);
        if(strcmpi(row{1},'hrhrhr'))
            rendText{end+1} = '-------------------------------------';
            continue;
        end
        
        formToUse = form;
        
        quant = paddStr(row{1}, padLengthQuant);
        rendText{i} = [quant, ' = ', num2str(row{2}, formToUse), ' ', row{3}];
    end
end
