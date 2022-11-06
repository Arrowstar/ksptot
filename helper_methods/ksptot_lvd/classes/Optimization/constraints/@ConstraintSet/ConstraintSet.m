classdef ConstraintSet < matlab.mixin.SetGet
    %ConstraintSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        consts AbstractConstraint
        
        lvdOptim LvdOptimization
        lvdData LvdData
        
        lastRunValues ConstraintValues
    end
    
    methods
        function obj = ConstraintSet(lvdOptim, lvdData)
            obj.consts = AbstractConstraint.empty(1,0);
            obj.lastRunValues = ConstraintValues();
            
            if(nargin > 0)
                obj.lvdOptim = lvdOptim;
                obj.lvdData = lvdData;   
            end
        end
        
        function addConstraint(obj, newConst)
            obj.consts(end+1) = newConst;
        end
        
        function removeConstraint(obj, const)
            obj.consts(obj.consts == const) = [];
        end      
        
        function constraint = getConstraintForInd(obj, ind)
            constraint = AbstractConstraint.empty(1,0);
            
            if(ind >= 1 && ind <= length(obj.consts))
                constraint = obj.consts(ind);
            end
        end
        
        function [listBoxStr, consts] = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.consts))
                if(obj.consts(i).active)
                    prefStr = '';
                else
                    prefStr = '** ';
                end
                
                listBoxStr{end+1} = [prefStr,obj.consts(i).getName()]; %#ok<AGROW>
            end
            
            consts = obj.consts;
        end
        
        function tooltipStrs = getToolboxStrs(obj)
            tooltipStrs = {};
            
            for(i=1:length(obj.consts))
                if(ismember(i,obj.lastRunValues.cCeqInds))
                    bool = obj.lastRunValues.cCeqInds == i;
                    scaledValue = max(obj.lastRunValues.ceq(bool));
                elseif(ismember(i,obj.lastRunValues.cCInds))
                    bool = obj.lastRunValues.cCInds == i;
                    scaledValue = max(obj.lastRunValues.c(bool));
                else
                    scaledValue = 0;
                end
                
                tooltipStrs{end+1} = obj.consts(i).getListboxTooltipStr(scaledValue); %#ok<AGROW>
            end
        end
        
        function num = getNumConstraints(obj)
            num = length(obj.consts);
        end
        
        function tf = canUseSparseOutput(obj)
            tf = true;
            
            for(i=1:length(obj.consts))
                tf = tf && obj.consts(i).canUseSparseOutput();
            end
        end
        
        function [c, ceq, value, lb, ub, type, eventNum, cEventInds, ceqEventInds, typeNumConstrArr, constraints, cCInds, cCeqInds, valueStateComps] = evalConstraints(obj, x, tfRunScript, evtToStartScriptExecAt, allowInterrupt, stateLogToEval)
            c = [];
            ceq = [];
            value = [];
            lb = [];
            ub = [];
            type = {};
            eventNum = [];
            cEventInds = [];
            ceqEventInds = [];
            typeNumConstrArr = {};
            constraints = AbstractConstraint.empty(1,0);
            cCInds = [];
            cCeqInds = [];
            valueStateComps = [];
            
            celBodyData = obj.lvdData.celBodyData;
            
            if(~isempty(obj.consts))
                if(tfRunScript == true)                   
                    obj.lvdOptim.vars.updateObjsWithScaledVarValues(x);
                    useSparse = obj.canUseSparseOutput();
                    
                    try
                        stateLog = obj.lvdData.script.executeScript(useSparse, evtToStartScriptExecAt, false, allowInterrupt, false, false);
                    catch ME
                        c = NaN;
                        ceq = NaN;

                        return;
                    end

                elseif(not(isempty(stateLogToEval)) && isa(stateLogToEval, 'LaunchVehicleStateLog'))
                    stateLog = stateLogToEval;
                else
                    stateLog = obj.lvdData.stateLog;
                end

                constCnt = 1;
                for(i=1:length(obj.consts)) %#ok<*NO4LP>
                    constraint = obj.consts(i);
                    
                    if(obj.isEventOptimDisabled(constraint) || constraint.active == false)
                        continue;
                    end
                    
                    [c1, ceq1, value1, lb1, ub1, type1, eventNum1, valueStateComp1] = constraint.evalConstraint(stateLog, celBodyData);
                    c1 = c1(:)';
                    ceq1 = ceq1(:)';
                    value1 = value1(:)';
                    lb1 = lb1(:)';
                    ub1 = ub1(:)';
                    
                    for(j=1:length(c1))
                        cEventInds(end+1) = eventNum1; %#ok<AGROW>
                        cCInds(end+1) = constCnt; %#ok<AGROW>
                    end
                    
                    for(j=1:length(ceq1))
                        ceqEventInds(end+1) = eventNum1; %#ok<AGROW>
                        cCeqInds(end+1) = constCnt; %#ok<AGROW>
                    end
                    
                    c   = [c, c1]; %#ok<AGROW>
                    ceq = [ceq, ceq1]; %#ok<AGROW>
                    value = [value, value1]; %#ok<AGROW>
                    lb = [lb, lb1]; %#ok<AGROW>
                    ub = [ub, ub1]; %#ok<AGROW>
                    type = horzcat(type, type1); %#ok<AGROW>
                    typeNumConstrArr = horzcat(typeNumConstrArr, repmat({type1}, 1, numel(c1)+numel(ceq1))); %#ok<AGROW>
                    eventNum = [eventNum, eventNum1]; %#ok<AGROW>
                    constraints = [constraints, constraint]; %#ok<AGROW>
                    valueStateComps = [valueStateComps, valueStateComp1]; %#ok<AGROW>
                    
                    constCnt = constCnt+1;
                end
            end
        end

        function [cAtX0, cEqAtX0, DC, DCeq] = evalConstraintsWithGradients(obj, x, tfRunScript, evtToStartScriptExecAt, allowInterrupt, stateLogToEval)
            [cAtX0, cEqAtX0] = obj.evalConstraints(x, tfRunScript, evtToStartScriptExecAt, allowInterrupt, stateLogToEval);

            p = gcp('nocreate');
            if(not(isempty(p)))
                if(p.NumWorkers > 1)
                    useParallel = true;
                else
                    useParallel = false;
                end
            else
                useParallel = false;
            end

            fC = @(x) obj.evalConstraints(x, tfRunScript, evtToStartScriptExecAt, allowInterrupt, stateLogToEval);
            DC = computeGradAtPoint(fC, x, cAtX0, 1E-5, FiniteDiffTypeEnum.Forward, 2, [], useParallel);

            fCEq = @(x) out2(fC, x);
            DCeq = computeGradAtPoint(fCEq, x, cEqAtX0, 1E-5, FiniteDiffTypeEnum.Forward, 2, [], useParallel);
        end
        
        function tf = usesStage(obj, stage)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesStage(stage);
            end
        end
        
        function tf = usesEngine(obj, engine)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesEngine(engine);
            end
        end
        
        function tf = usesTank(obj, tank)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesTank(tank);
            end
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesEngineToTankConn(engineToTank);
            end
        end
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesStopwatch(stopwatch);
            end
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesExtremum(extremum);
            end
        end
        
        function tf = usesGroundObj(obj, grdObj)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesGroundObj(grdObj);
            end
        end
        
        function tf = usesCalculusCalc(obj, calculusCalc)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesCalculusCalc(calculusCalc);
            end
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesGeometricPoint(point);
            end
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesGeometricVector(vector);
            end
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesGeometricCoordSys(coordSys);
            end
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesGeometricRefFrame(refFrame);
            end
        end
        
        function tf = usesGeometricAngle(obj, angle)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesGeometricAngle(angle);
            end
        end
        
        function tf = usesGeometricPlane(obj, plane)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesGeometricPlane(plane);
            end
        end 
        
        function tf = usesPlugin(obj, plugin)
            tf = false;
            
            for(i=1:length(obj.consts))
                tf = tf || obj.consts(i).usesPlugin(plugin);
            end
        end 
        
        function removeConstraintsThatUseEvent(obj, event)
            indsToRemove = [];
            for(i=1:length(obj.consts))
                c = obj.consts(i);
                
                if(c.usesEvent(event))
                    indsToRemove(end+1) = i; %#ok<AGROW>
                end
            end
            
            for(i=length(indsToRemove):-1:1)
                indToRemove = indsToRemove(i);
                c = obj.consts(indToRemove);
                obj.removeConstraint(c);
            end
        end
        
        function evts = getConstrEvents(obj)
            evts = LaunchVehicleEvent.empty(1,0);
            
            for(i=1:length(obj.consts))
                evts(i) = obj.consts(i).getConstraintEvent();
            end
        end
    end
    
    methods(Access=private)
        function tf = isEventOptimDisabled(obj, constraint)
            tf = false;
            
            event = constraint.getConstraintEvent();
            if(not(isempty(event)))
                if(not(isempty(event)) && event.disableOptim == true)
                    tf = true;
                end
            end
        end
    end
end

function out = out2(fun, x)
    [~,out] = fun(x);
end