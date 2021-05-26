function [celBodyData] = processINIBodyInfo(celBodyDataFromINI, varargin)
%processINIBodyInfo Summary of this function goes here
%   Detailed explanation goes here
    clear findRow

    if(length(varargin)>=1)
        showWaitbar = varargin{1};
        
        if(length(varargin)>=2)
            dataType = varargin{2};
        else
            dataType = 'bodyInfo';
        end
    else
        showWaitbar = true;
        dataType = 'bodyInfo';
    end

    if(showWaitbar)
        hWaitbar = waitbar(0,'Loading bodies file, please wait...');
    end

    celBodyData = struct();
    for(i=1:size(celBodyDataFromINI,1)) %#ok<*NO4LP>
        row = celBodyDataFromINI(i,:);
        row{1} = lower(matlab.lang.makeValidName(row{1}));
        row{3} = lower(matlab.lang.makeValidName(row{3}));
        
        if(~isfield(celBodyData,row{1}))
%             celBodyData.(row{1}) = struct();
            celBodyData.(row{1}) = getNewObjForDataType(dataType);
        end
        
        if(strcmpi(row{3}, 'atmoPressAlts'))
            celBodyData = createCurveFitFromRows(celBodyDataFromINI, row{1}, 'atmoPressAlts', 'atmoPressPresses', 'atmoPressCurve', celBodyData);
            
        elseif(strcmpi(row{3}, 'atmoTempAlts'))
            celBodyData = createCurveFitFromRows(celBodyDataFromINI, row{1}, 'atmoTempAlts', 'atmoTempTemps', 'atmoTempCurve', celBodyData);
            
        elseif(strcmpi(row{3}, 'atmoTempSunMultAlts'))
            celBodyData = createCurveFitFromRows(celBodyDataFromINI, row{1}, 'atmoTempSunMultAlts', 'atmoTempSunMults', 'atmoTempSunMultCurve', celBodyData);
            
        elseif(strcmpi(row{3}, 'latTempBiasLats'))
            celBodyData = createCurveFitFromRows(celBodyDataFromINI, row{1}, 'latTempBiasLats', 'latTempBiases', 'latTempBiasCurve', celBodyData);
            
        elseif(strcmpi(row{3}, 'latTempSunMultLats'))
            celBodyData = createCurveFitFromRows(celBodyDataFromINI, row{1}, 'latTempSunMultLats', 'latTempSunMults', 'latTempSunMultCurve', celBodyData);
            
        elseif(strcmpi(row{3}, 'axialtemperaturesunbiasdeg'))
           celBodyData = createCurveFitFromRows(celBodyDataFromINI, row{1}, 'axialtemperaturesunbiasdeg', 'axialtemperaturesunbiases', 'axialTempSunBiasCurve', celBodyData);
           
        elseif(strcmpi(row{3}, 'axialtemperaturesunmultlats'))
            celBodyData = createCurveFitFromRows(celBodyDataFromINI, row{1}, 'axialtemperaturesunmultlats', 'axialtemperaturesunmults', 'axialTempSunMultCurve', celBodyData);
            
        elseif(strcmpi(row{3}, 'eccentricitytemperaturebiaspts'))
            celBodyData = createCurveFitFromRows(celBodyDataFromINI, row{1}, 'eccentricitytemperaturebiaspts', 'eccentricitytemperaturebiases', 'eccTempBiasCurve', celBodyData);
            
        elseif(any(strcmpi(row{3}, {'atmoPressPresses', 'atmoTempTemps', 'atmoTempSunMults', 'latTempBiases', 'latTempSunMults', 'axialtemperaturesunbiases', 'axialtemperaturesunmults', 'eccentricitytemperaturebiases'})))
            continue;
        else
            if(~checkStrIsNumeric(row{4})) 
                entry = row{4};
            else
                entry = str2double(row{4});
            end
            
            if((strcmpi(row{3},'name') || strcmpi(row{3},'parent')) && ischar(entry))
                entry = matlab.lang.makeValidName(entry);
            end

            if(isfield(celBodyData,row{1}))
                celBodyData.(row{1}).(row{3}) = entry;
            else 
                celBodyData.(row{1}) = struct();
                celBodyData.(row{1}) = getNewObjForDataType(dataType);
                celBodyData.(row{1}).(row{3}) = entry;
            end
        end
        
        if(showWaitbar)
            waitbar(i/size(celBodyDataFromINI,1), hWaitbar, sprintf('Loading bodies file, please wait... [%u/%u]', i, size(celBodyDataFromINI,1)));
        end
    end
    
    if(strcmpi(dataType,'bodyInfo'))
        names = fieldnames(celBodyData);
        for(i=1:length(names))
            name = names{i};
            celBodyData.(name).celBodyData = celBodyData;
            [~] = celBodyData.(name).getParBodyInfo(celBodyData); %set that parent info now so that we don't have to handle it later
            [~] = celBodyData.(name).getChildrenBodyInfo(celBodyData); 
            
            celBodyData.(name).setPropTypeEnum();
            celBodyData.(name).setBaseBodySurfaceTexture();
        end
    end
    
    if(showWaitbar)
        close(hWaitbar);
    end
    
    return;
end

function celBodyData = createCurveFitFromRows(celBodyDataFromINI, bodyName, indVarRow, depVarRow, celBodyFieldName, celBodyData)
    indRow = findRow(celBodyDataFromINI, bodyName, indVarRow);
    depRow = findRow(celBodyDataFromINI, bodyName, depVarRow);

    indVar = str2double(strsplit(indRow{4},','));
    indVar = reshape(indVar, length(indVar), 1);
    
    depVar = str2double(strsplit(depRow{4},','));
    depVar = reshape(depVar, length(depVar), 1);

    if(length(indVar) > 1 && length(depVar) > 1)
        fitobject = griddedInterpolant(indVar,depVar,'linear', 'nearest');
%         fitobject = fit(indVar,depVar,'smoothingspline');
%         fitobject = @(xi) interp1qr(indVar,depVar,xi);
    elseif(length(indVar) == 1 && length(depVar) == 1)
        fitobject = griddedInterpolant([indVar(1) indVar(1)+1]',[depVar(1) depVar(1)]','linear', 'nearest');
%         fitobject = fit([indVar(1) indVar(1)+1]',[depVar(1) depVar(1)]','smoothingspline');
%         fitobject = @(xi) interp1qr([indVar(1) indVar(1)+1]',[depVar(1) depVar(1)]',xi);
    else
        fitobject = griddedInterpolant([0 1]',[0 0]','linear', 'nearest');
%         fitobject = fit([0 1]',[0 0]','smoothingspline');
%         fitobject = @(xi) interp1qr([0 1]',[0 0]',xi);
    end
    
    celBodyData.(bodyName).(lower(celBodyFieldName)) = fitobject;
end

function row = findRow(celBodyDataFromINI, col1, col3)
    persistent celBodyDataFromINICol1
    if(isempty(celBodyDataFromINICol1) || size(celBodyDataFromINI,1) ~= length(celBodyDataFromINICol1))
        celBodyDataFromINICol1 = matlab.lang.makeValidName(celBodyDataFromINI(:,1));
    end    

    row = celBodyDataFromINI(strcmpi(col1,celBodyDataFromINICol1) & strcmpi(col3,celBodyDataFromINI(:,3)), :);
end

function obj = getNewObjForDataType(dataType)
    switch dataType
        case 'bodyInfo'
            obj = KSPTOT_BodyInfo();
        case 'appOptions'
            obj = KSPTOT_AppOptions();
        otherwise
            error('Unknown data type %s in processINIBodyInfo().', dataType);
    end
end
