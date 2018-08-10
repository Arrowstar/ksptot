function rts_orbOps_orbitUpdateFunc(~, ~, hFig, hOrbitLabel, hAxis, tcpipClient, celBodyData)
%rts_orbitPanelUpdateFunc Summary of this function goes here
%   Detailed explanation goes here

    try
        data = get(tcpipClient,'UserData');
        orbitData = data{1};
        if(~isempty(orbitData))
            %UPDATE ORBIT PANEL
            if(~isempty(hOrbitLabel))
                orbitStr = generateOrbitPanelStr(orbitData, celBodyData);
                set(hOrbitLabel,'String',orbitStr);
            end
            
            %UPDATE ORBIT PLOT
            if(~isempty(hAxis) && ~isempty(hFig))
                rts_orbOps_populateOrbitAxis(hFig,hAxis,orbitData,celBodyData);
            end
        end
    catch ME
%         disp(ME.message);
%         for k=1:length(ME.stack)
%             ME.stack(k)
%         end
%         disp('---');
%         a = 1;
    end    
end

function orbitStr = generateOrbitPanelStr(orbitData, celBodyData)
    sma = orbitData(1);
    ecc = orbitData(2);
    inc = orbitData(3);
    raan = orbitData(4);
    argPe = orbitData(5);
    meanAnom = orbitData(6);
    epoch = orbitData(7);
    
    period = orbitData(10);
    
    aboutBody = orbitData(13);
    
    apAlt = orbitData(14);
    apRad = orbitData(15);
    timeToAp = orbitData(16);
    
    peAlt = orbitData(17);
    peRad = orbitData(18);
    timeToPe = orbitData(19);
    
    if(aboutBody >= 0)
        bodyInfo = getBodyInfoByNumber(aboutBody, celBodyData);
        aboutBodyName = bodyInfo.name;
        radius = bodyInfo.radius;
        gm = bodyInfo.gm;
    else
        aboutBodyName = '';
        radius = 0.0;
        gm = 0.0;
    end
    
    orbitDescArr = {};
    orbitDescArr(end+1,:) = {'Semi-major Axis', sma, 'km'};
    orbitDescArr(end+1,:) = {'Eccentricity', ecc, ''};
    orbitDescArr(end+1,:) = {'Inclination', inc, 'deg'};
    orbitDescArr(end+1,:) = {'Rt. Asc. Node', raan, 'deg'};
    orbitDescArr(end+1,:) = {'Arg. of Peri.', argPe, 'deg'};
    orbitDescArr(end+1,:) = {'Mean Anomaly', rad2deg(meanAnom), 'deg'};
    
    orbitDescArr(end+1,:) = {'hrhrhr','hrhrhr','hrhrhr'};
    orbitDescArr(end+1,:) = {'Epoch', epoch, 'secUT'};
    orbitDescArr(end+1,:) = {'Period', period, 'sec'};
    orbitDescArr(end+1,:) = {'Period', period/3600, 'hr'};
    
    orbitDescArr(end+1,:) = {'hrhrhr','hrhrhr','hrhrhr'};
    orbitDescArr(end+1,:) = {'Apoapse Alt.', apAlt, 'km'};
    orbitDescArr(end+1,:) = {'Apoapse Rad.', apRad, 'km'};
    orbitDescArr(end+1,:) = {'Time to Apo.', timeToAp, 'sec'};
    
    orbitDescArr(end+1,:) = {'Periapse Alt.', peAlt, 'km'};
    orbitDescArr(end+1,:) = {'Periapse Rad.', peRad, 'km'};
    orbitDescArr(end+1,:) = {'Time to Pe.', timeToPe, 'sec'};
    
    orbitDescArr(end+1,:) = {'hrhrhr','hrhrhr','hrhrhr'};
    orbitDescArr(end+1,:) = {'Orbiting About', aboutBodyName, ''};
    orbitDescArr(end+1,:) = {'Radius', radius, 'km'};
    orbitDescArr(end+1,:) = {'Grav. Param.', gm, 'km³/s²'};
    
    orbitStr = formOrbitText(orbitDescArr);
end

function orbitText = formOrbitText(orbitDescArr) 
    padLengthQuant = 16;
    form = '%9.3f';
    formEcc = '%9.7f';
    orbitText = {};
    
    for(i=1:size(orbitDescArr,1))
        row = orbitDescArr(i,:);
        if(strcmpi(row{1},'hrhrhr'))
            orbitText{end+1} = '-------------------------------------';
            continue;
        end
        
        formToUse = form;
        if(strcmpi(row{1}, 'Eccentricity'))
            formToUse=formEcc;
        end
        
        quant = paddStr(row{1}, padLengthQuant);
        orbitText{i} = [quant, ' = ', num2str(row{2}, formToUse), ' ', row{3}];
    end
end
