function rts_dynAttitudeUpdateFunc(~, ~, hFig, tcpipClient, hAttPointingTextDispLabel, hAttRatesTextDispLabel, hAttCmdTextDispLabel, hAttDispAxes, hActStatusTextDispLabel, hRwaInfoUitable, hAttDerivedTextDispLabel)
%rts_dynAttitudeUpdateFunc Summary of this function goes here
%   Detailed explanation goes here
    numStaticElem = 27;
    numDataPerRWA = 4;
    
    try
        data = get(tcpipClient,'UserData');
        attData = data{1};
        if(~isempty(attData))
            %UPDATE ATT POINTING PANEL
            if(~isempty(hAttPointingTextDispLabel))
                attPointingDataStr = generateAttPointingPanel(attData);
                set(hAttPointingTextDispLabel,'String',attPointingDataStr);
            end
            
            %UPDATE ATT RATES PANEL
            if(~isempty(hAttRatesTextDispLabel))
                attRatesDataStr = generateAttRatesPanel(attData);
                set(hAttRatesTextDispLabel,'String',attRatesDataStr);
            end
            
            %UPDATE ATT CMD PANEL
            if(~isempty(hAttCmdTextDispLabel))
                attCmdDataStr = generateAttCmdPanel(attData);
                set(hAttCmdTextDispLabel,'String',attCmdDataStr);
            end
            
            %UPDATE ATT DISPLAY AXES
            if(~isempty(hAttDispAxes))
                rts_Dyn_populateAttAxis(hFig, hAttDispAxes,attData)
            end
            
            %UPDATE ACTUATOR STATUS PANEL
            if(~isempty(hActStatusTextDispLabel))
                attActuatorStatusStr = generateActStatPanel(attData);
                set(hActStatusTextDispLabel,'String',attActuatorStatusStr);
            end
            
            %UPDATE RWA TABLE PANEL
            if(~isempty(hRwaInfoUitable))
                generateRWAStatusPanel(hRwaInfoUitable, attData, numStaticElem, numDataPerRWA)
            end
            
            if(~isempty(hAttDerivedTextDispLabel))
                attDerivedStr = generateAttDerivedPanel(attData);
                set(hAttDerivedTextDispLabel,'String',attDerivedStr);
            end
        end
    catch ME
        disp('----');
        disp(ME.message);
        disp(ME.stack(1));
        disp(ME.stack(2));
        disp('----');
    end
end

function attDerivedStr = generateAttDerivedPanel(attData)
    e1 = attData(16);
    e2 = attData(17);
    e3 = attData(18);
    e4 = attData(19);
    
    rendDescArr = {};
    rendDescArr(end+1,:) = {'Quat X', e1, ''};
    rendDescArr(end+1,:) = {'Quat Y', e2, ''};
    rendDescArr(end+1,:) = {'Quat Z', e3, ''};
    rendDescArr(end+1,:) = {'Quat Scalar', e4, ''};

    attDerivedStr = formRendText(rendDescArr);
end

function generateRWAStatusPanel(hRwaInfoUitable, attData, numStaticElem, numDataPerRWA)
    rollCmd = (attData(10));
    pitchCmd = (attData(11));
    yawCmd = (attData(12));
    
    rwaInfoArr = attData(numStaticElem+1:end);
    
    tableData = {};
    for(i=1:length(rwaInfoArr)/numDataPerRWA)
        j=4*(i-1)+1;
        for(k=1:4)
            if(k==2)
                factor = abs(rollCmd);
            elseif(k==3)
                factor = abs(pitchCmd);
            elseif(k==4)
                factor = abs(yawCmd);
            else
                factor=1;
            end
            
            if(k==1)
                status = rwaInfoArr(j-1+k);
                if(status == 0)
                    statusStr = 'Active';
                elseif(status == 1)
                    statusStr = 'Inactive';
                elseif(status == 2)
                    statusStr = 'Destroyed';
                else
                    statusStr = 'Unknown';
                end
                tableData{i,k} = statusStr;
            else
                tableData{i,k} = factor*rwaInfoArr(j-1+k);
            end
        end
    end
    
    setTableData(hRwaInfoUitable, tableData)
end

function attActuatorStatusStr = generateActStatPanel(attData)
    timeWarpRate = attData(20);
    isCntrlable = attData(21);
    rcsEnab = attData(22);
    asasEnab = attData(23);
    throtSet = 100*attData(24);
    preciseMode = attData(25);
    stagelock = attData(26);
    isneutral = attData(27);
    
    if(isneutral == 1)
        fltCtrlStatus = 'Neutral';
    else
        fltCtrlStatus = 'Cmding';
    end
    
    if(isCntrlable == 1)
        isCntrlableB = 'True';
    else
        isCntrlableB = 'False';
    end
    
    if(asasEnab == 1)
        asasStatus = 'Active';
    else
        asasStatus = 'Inactive';
    end
    
    if(rcsEnab == 0)
        rcsStatus = 'Active';
    else
        rcsStatus = 'Inactive';
    end
    
    if(preciseMode == 1)
        preciseModeB = 'Active';
    else
        preciseModeB = 'Inactive';
    end
    
    if(stagelock == 1)
        stagelockB = 'Active';
    else
        stagelockB = 'Inactive';
    end
    
    timeWarpRate = ['x',num2str(timeWarpRate)];
    
    rendDescArr = {};
    rendDescArr(end+1,:) = {'Flt Ctrl Status', fltCtrlStatus, ''};
    
    rendDescArr(end+1,:) = {'hrhrhr','hrhrhr','hrhrhr'};
    rendDescArr(end+1,:) = {'Controllable', isCntrlableB, ''};
    rendDescArr(end+1,:) = {'ASAS Status', asasStatus, ''};
    rendDescArr(end+1,:) = {'RCS Status', rcsStatus, ''};
    rendDescArr(end+1,:) = {'Throttle Set', throtSet, '%'};
    rendDescArr(end+1,:) = {'Precise Ctrl', preciseModeB, ''};
    rendDescArr(end+1,:) = {'Stage Lock', stagelockB, ''};
    rendDescArr(end+1,:) = {'Time Warp', timeWarpRate, ''};

    attActuatorStatusStr = formRendText(rendDescArr);
end

function attCmdDataStr = generateAttCmdPanel(attData)
    rollCmd = (attData(10));
    pitchCmd = (attData(11));
    yawCmd = (attData(12));
    
    rendDescArr = {};
    rendDescArr(end+1,:) = {'S/C Cmd. Roll', rollCmd, ''};
    rendDescArr(end+1,:) = {'S/C Cmd. Pitch', pitchCmd, ''};
    rendDescArr(end+1,:) = {'S/C Cmd. Yaw', yawCmd, ''};

    attCmdDataStr = formRendText(rendDescArr);
end

function attRatesDataStr = generateAttRatesPanel(attData)
    pitchD = rad2deg(attData(7));
    rollD = rad2deg(attData(8));
    yawD = rad2deg(attData(9));
    
    rendDescArr = {};
    rendDescArr(end+1,:) = {'S/C Roll Rate', rollD, 'deg/s'};
    rendDescArr(end+1,:) = {'S/C Pitch Rate', pitchD, 'deg/s'};
    rendDescArr(end+1,:) = {'S/C Yaw Rate', yawD, 'deg/s'};

    attRatesDataStr = formRendText(rendDescArr);
end

function attPointingDataStr = generateAttPointingPanel(attData)
    roll = attData(1);
    pitch = attData(2);
    yaw = attData(3);
    e1 = attData(16);
    e2 = attData(17);
    e3 = attData(18);
    e4 = attData(19);
    
    C(1,1)=1 - 2*e2^2 - 2*e3^2;
    C(1,2)=2*(e1*e2 - e3*e4);
    C(1,3)=2*(e3*e1 + e2*e4);
    C(2,1)=2*(e1*e2 + e3*e4);
    C(2,2)=1 - 2*e3^2 - 2*e1^2;
    C(2,3)=2*(e2*e3 - e1*e4);
    C(3,1)=2*(e3*e1 - e2*e4);
    C(3,2)=2*(e2*e3 + e1*e4);
    C(3,3)=1 - 2*e1^2 - 2*e2^2;

    zRot = C*[0, 0, 1]';
    zRot2 = zRot;
    zRot2Y = zRot2(2);
    zRot2Z = zRot2(3);
    zRot(2) = zRot2Z;    
    zRot(3) = zRot2Y;
    zRot = (zRot/norm(zRot));
       
    fwdvecx = zRot(1);
    fwdvecy = zRot(2);
    fwdvecz = zRot(3);
    
    [az,el] = cart2sph(fwdvecx,fwdvecy,fwdvecz);
    
    rendDescArr = {};
    rendDescArr(end+1,:) = {'S/C Roll', roll, 'deg'};
    rendDescArr(end+1,:) = {'S/C Pitch', pitch, 'deg'};
    rendDescArr(end+1,:) = {'S/C Heading', yaw, 'deg'};
    
    rendDescArr(end+1,:) = {'hrhrhr','hrhrhr','hrhrhr'};
    rendDescArr(end+1,:) = {'Fwd. Unit Vect. X', fwdvecx, ''};
    rendDescArr(end+1,:) = {'Fwd. Unit Vect. Y', fwdvecy, ''};
    rendDescArr(end+1,:) = {'Fwd. Unit Vect. Z', fwdvecz, ''};
    
    rendDescArr(end+1,:) = {'hrhrhr','hrhrhr','hrhrhr'};
    rendDescArr(end+1,:) = {'Fwd. Vect. Az.', rad2deg(az), 'deg'};
    rendDescArr(end+1,:) = {'Fwd. Vect. El.', rad2deg(el), 'deg'};

    attPointingDataStr = formRendText(rendDescArr);
end

function rendText = formRendText(rendDescArr) 
    padLengthQuant = 17;
    form = '%9.3f';
    formQuat = '%9.6f';
    rendText = {};
    
    for(i=1:size(rendDescArr,1))
        row = rendDescArr(i,:);
        if(strcmpi(row{1},'hrhrhr'))
            rendText{end+1} = '-------------------------------------';
            continue;
        elseif(strfind(row{1}, 'Quat'))
            formToUse = formQuat;
        else
            formToUse = form;
        end
        
        quant = paddStr(row{1}, padLengthQuant);
        rendText{i} = [quant, ' = ', num2str(row{2}, formToUse), ' ', row{3}];
    end
end