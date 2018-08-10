function maData = ma_updateMAData(maData, handles)
%ma_updateMAData Summary of this function goes here
%   Detailed explanation goes here
	if(not(isfield(maData,'settings') && isstruct(maData.settings) && isfield(maData.settings,'strictSoISearch')))
        maData.settings.strictSoISearch = true;
	end
    
	if(not(isfield(maData,'settings') && isstruct(maData.settings) && isfield(maData.settings,'useSelectiveSoISearch')))
        maData.settings.useSelectiveSoISearch = true;
	end
    
	if(not(isfield(maData,'settings') && isstruct(maData.settings) && isfield(maData.settings,'parallelScriptOptim')))
        maData.settings.parallelScriptOptim = false;
	end
    
	if(not(isfield(maData,'settings') && isstruct(maData.settings) && isfield(maData.settings,'optimAlg')))
        maData.settings.optimAlg = 'interior-point';
    end
    
	if(not(isfield(maData,'settings') && isstruct(maData.settings) && isfield(maData.settings,'soiSearchTol')))
        maData.settings.soiSearchTol = 1E-6;
	end
    
    thrusters = maData.spacecraft.thrusters;
    for(i=1:length(thrusters)) %#ok<*NO4LP>
        thruster = thrusters{i};
        if(~isfield(thruster,'thrust'))
            thruster.thrust = 100;
            thrusters{i} = thruster;
        end
        
        script = maData.script;
        for(j=1:length(script))
            event = script{j};
            if(isfield(event,'thruster'))
                if(isempty(event.thruster))
                    event.thruster = thrusters{1};
                end
                if(event.thruster.id == thruster.id)
                    event.thruster = thruster;
                end
            end
            if(strcmpi(event.type,'Coast'))
                if(~isfield(event,'soiSkipIds'))
                    event.soiSkipIds = [];
                end
                
                if(~isfield(event,'lineColor'))
                    event.lineColor = 'r';
                end
                
                if(~isfield(event,'lineStyle'))
                    event.lineStyle = '-';
                end
                
                if(~isfield(event,'massloss') || (~isfield(event.massloss,'use') || ~isfield(event.massloss,'lossConvert')))
                    event.massloss = struct();
                    event.massloss.use  = false;
                    event.massloss.lossConvert = getDefaultLossConvert(handles);
                end
                
                if(~isfield(event,'funcHandle'))
                    event.funcHandle = []; 
                end
                
                if(~isfield(event,'maxPropTime'))
                    event.maxPropTime = 0.0; 
                end
            elseif(strcmpi(event.type,'DV_Maneuver'))
                if(~isfield(event,'lineColor'))
                    event.lineColor = 'r';
                end
                
                if(~isfield(event,'lineStyle'))
                    event.lineStyle = '-';
                end
                
            elseif(strcmpi(event.type,'Set_State'))
                if(~isfield(event,'subType'))
                    event.subType = 'setState';
                end
                if(~isfield(event,'launch'))
                    event.launch = [];
                end
                if(~isfield(event,'vars'))
                    event.vars = zeros(3,0);
                end
                
                if(~isempty(event.launch))
                    event.launch.lineStyle = '-';
                end
            elseif(strcmpi(event.type,'Aerobrake'))
                if(~isfield(event,'lineColor'))
                    event.lineColor = 'r';
                end
                
                if(~isfield(event,'lineStyle'))
                    event.lineStyle = '-';
                end
                
            elseif(strcmpi(event.type,'Docking'))
                if(~isfield(event,'lineStyle'))
                    event.lineStyle = '-';
                end
                
            elseif(strcmpi(event.type,'Landing'))
                if(~isfield(event,'lineStyle'))
                    event.lineStyle = '-';
                end
                
            elseif(strcmpi(event.type,'NBodyCoast'))
                if(~isfield(event,'lineStyle'))
                    event.lineStyle = '-';
                end
            end
            script{j} = event;
        end
        maData.script = script;
    end
    maData.spacecraft.thrusters = thrusters;
    
    if(~isfield(maData.settings,'numStateLogPtsPerCoast'))
        maData.settings.numStateLogPtsPerCoast = 1000;
    end
    
    if(~isfield(maData.settings,'numSoISearchRevs'))
        maData.settings.numSoISearchRevs = 3;
    end
    
    if(~isfield(maData.settings,'gravParamType'))
        maData.settings.gravParamType = 'kspStockLike';
    end
    
    if(~isfield(maData.spacecraft,'comm'))
        maData.spacecraft.comm = struct();
    end
    
    if(~isfield(maData.spacecraft,'propellant'))
        maData.spacecraft.propellant = struct();
        maData.spacecraft.propellant.names = {'Fuel/Ox', 'Monoprop', 'Xenon'};
    end
    
    if(~isfield(maData.spacecraft.comm,'maxCommRange'))
        maData.spacecraft.comm.maxCommRange = Inf;
    end
    
    for(i=1:length(maData.spacecraft.otherSC))
        if(~isfield(maData.spacecraft.otherSC{i},'maxCommRange'))
            maData.spacecraft.otherSC{i}.maxCommRange = Inf;
        end
    end
    
    for(i=1:length(maData.spacecraft.stations))
        if(~isfield(maData.spacecraft.stations{i},'maxCommRange'))
            maData.spacecraft.stations{i}.maxCommRange = Inf;
        end
    end
    
    if(~isfield(maData,'launch'))
        maData.launch = getDefaultMaDataLaunchStruct(maData.spacecraft.stations{1});
    end
    
    if(~isfield(maData,'notes'))
        maData.notes = '';
    end
    
    if(isfield(maData,'optimizer'))
        if(isfield(maData.optimizer,'constraints') && iscell(maData.optimizer.constraints) && ~isempty(maData.optimizer.constraints))
            taskList = ma_getGraphAnalysisTaskList({});
            rowsToDelete = [];
            for(i=1:size(maData.optimizer.constraints{1,1},1))
                if(isempty(maData.optimizer.constraints{1,1}{i,3}) || ~any(ismember(taskList,maData.optimizer.constraints{1,1}{i,3})))
                    rowsToDelete(end+1) = i; %#ok<AGROW>
                end
            end
            
            maData.optimizer.constraints{1,1}(rowsToDelete,:) = [];
        end
    end
    
    if(isfield(maData,'celBodyData'))
        bodyNames = fieldnames(maData.celBodyData);
        for(i=1:length(bodyNames))
            if(isstruct(maData.celBodyData.(bodyNames{i})))
                maData.celBodyData.(bodyNames{i}) = KSPTOT_BodyInfo.getObjFromBodyInfoStruct(maData.celBodyData.(bodyNames{i}));
            end
        end
    end
end

