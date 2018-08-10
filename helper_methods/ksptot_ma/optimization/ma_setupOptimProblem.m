function [maData, problem] = ma_setupOptimProblem(maData, celBodyData, hWaitbar, selectedObjFunc, bodyID, selectedCelBodyValue, objEventNum, objEventID, optVarData, actConsts)
    problem = [];
    
    otherSCs = maData.spacecraft.otherSC;
    
    %%%%%%%
    % Prep objective function
    %%%%%%%
    switch selectedObjFunc
        case 'Minimize Distance to Body'
            objFunc = @(stateLog) ma_distFromBodyConstraint(stateLog, objEventID, 0.1, 0, bodyID, celBodyData, maData);
        case 'Maximize Spacecraft Mass'
            objFunc = @(stateLog) ma_maxTotalPropMassObjFunc(stateLog, objEventID, celBodyData, maData);
        case 'Minimize Inclination'
            objFunc = @(stateLog) ma_inclinationConstraint(stateLog, objEventID, 0.1, 0, -1, celBodyData, maData);
        case 'Minimize Eccentricity'
            objFunc = @(stateLog) ma_eccentricityConstraint(stateLog, objEventID, 0.1, 0, -1, celBodyData, maData);
        case 'Maximize Inclination'
            objFunc = @(stateLog) -ma_inclinationConstraint(stateLog, objEventID, 0.1, 0, -1, celBodyData, maData);
        case 'Maximize Eccentricity'
            objFunc = @(stateLog) -ma_eccentricityConstraint(stateLog, objEventID, 0.1, 0, -1, celBodyData, maData);
        case 'Minimize Mission Duration'
            objFunc = @(stateLog) ma_MinimizeMissionDuration(stateLog, objEventID, celBodyData, maData);
        case 'No Optimization (Satisfy Constraints Only)'
            objFunc = @(stateLog) ma_NoOptimSatConstraintsOnly(stateLog, objEventID, celBodyData, maData);
        otherwise
            close(hWaitbar);
            errordlg(['Unknown objection function selected: ', selectedObjFunc],'Unknown Objective','modal');
            return;
    end
    
    %%%%%%%
    % Prep variables
    %%%%%%%
    vars = {};
    for(i=1:length(maData.script))
        event = maData.script{i};
        
        if(~isfield(event,'vars') || all(event.vars(1,:)==0))
            continue;
        else
            activeVars = event.vars(1,:) == 1;
            numVar = length(find(activeVars));
        end
        
        eventNum = i;
        x0 = ma_getX0ForEvent(event);
        lb = event.vars(2,activeVars);
        ub = event.vars(3,activeVars);
        
        if(size(x0,1) > 1)
            x0 = x0';
        end
               
        vars{end+1} = ma_createOptimizationVariable(eventNum, numVar, x0, lb, ub); %#ok<AGROW>
    end
    
    if(isempty(vars))
        close(hWaitbar);
        errordlg('Error: No variables selected for optimization.','No Variables Selected','modal');
        return;
    end
    
    partialExecStartEvent = 1;
    varScript = maData.script;
    for(i=1:length(varScript))
        vEvent = varScript{i};
        if(isfield(vEvent,'vars'))
            pEVars = vEvent.vars;
            if(any(pEVars(1,:)==1))
                break;
            else
                partialExecStartEvent = partialExecStartEvent + 1;
                continue;
            end
        else
            partialExecStartEvent = partialExecStartEvent + 1;
            continue;
        end
    end
    
    if(partialExecStartEvent == 1)
        partialExecStateLog = [];
    else
        pEStateLog = maData.stateLog;
        pEStateLog = pEStateLog(pEStateLog(:,13)<=partialExecStartEvent-1,:);
        partialExecStateLog = pEStateLog;
    end
    partialExec = {partialExecStateLog,partialExecStartEvent};
    
    objFuncWrapper = @(x) ma_optimObjWrapper(x, maData.script,vars,objFunc,maData,celBodyData, partialExec);
    [x0All, lbAll, ubAll] = ma_formOptim_X0_LB_UB(vars);
    
    %%%%%%%
    % Prep constraints
    %%%%%%%
    constFuncts = {};
    for(i=1:size(actConsts,1)) %#ok<*NO4LP>
        if(all(cellfun(@isempty,actConsts(i,:))))
            continue;
        end
        
        constData = actConsts{i,5};
        if(constData(5)>=0)
            bodyInfo = getBodyInfoByNumber(constData(5), celBodyData);
            bodyName = bodyInfo.name;
        else
            bodyName = '';
        end
        otherSC.id = constData(8);
        if(length(constData) == 8)
            lbActive = true;
            ubActive = true;
        else
            lbActive = constData(9);
            ubActive = constData(10);
        end
        
        if(lbActive == false && ubActive == false)
            continue;
        end
        
        constFuncts{end+1} = buildConstraints(maData, celBodyData, constData(3), constData(4), constData(7), bodyName, otherSC, actConsts{i,3}, lbActive, ubActive); %#ok<AGROW>   
    end
    
    if(isempty(constFuncts))
        nonlcon = [];
    else
        nonlcon = @(x) ma_optimConstrWrapper(x, maData.script,vars,constFuncts,maData,celBodyData, partialExec);
    end
    
    %%%%%%%
    % Use Parallel?
    %%%%%%%
    try
        if(maData.settings.parallelScriptOptim)
            usePara = 'always';
        else
            usePara = 'never';
        end
    catch
        usePara = 'never';
    end
    
    %%%%%%%
    % Pack up optimization options   
    %%%%%%%
    x0AllTypical = x0All;
	x0AllTypical(abs(x0AllTypical)<1E-8) = 1;
    
    optimAlg = maData.settings.optimAlg;
    options = optimoptions('fmincon','Algorithm',optimAlg, 'Diagnostics','on', 'Display','iter-detailed','TolFun',1E-10,'TolX',1E-10,'TolCon',1E-10,'ScaleProblem','none','MaxIter',500,'UseParallel',usePara,'OutputFcn',[],'InitBarrierParam',1.0,'InitTrustRegionRadius',0.1,'HonorBounds',true,'MaxFunctionEvaluations',3000,'TypicalX',x0AllTypical);
    problem = createOptimProblem('fmincon', 'objective',objFuncWrapper, 'x0', x0All, 'lb', lbAll, 'ub', ubAll, 'nonlcon', nonlcon, 'options', options);
       
    maData.optimizer.variables = {optVarData, vars};
    maData.optimizer.objective = {selectedObjFunc, objEventNum, bodyID, selectedCelBodyValue, objEventID};

    maData.optimizer.constraints = {actConsts};
    maData.optimizer.bndsX0 = [x0All, lbAll, ubAll];

%     maData.optimizer.problem = problem;
    maData.optimizer.problem = [];
end