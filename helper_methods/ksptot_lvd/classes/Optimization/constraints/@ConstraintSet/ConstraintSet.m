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
            persistent stateLogCache;
            if(isempty(stateLogCache))
                stateLogCache.x = [];
                stateLogCache.stateLog = [];
            end
            
            c = []; ceq = []; value = []; lb = []; ub = []; type = {};
            eventNum = []; cEventInds = []; ceqEventInds = [];
            typeNumConstrArr = {}; constraints = AbstractConstraint.empty(1,0);
            cCInds = []; cCeqInds = []; valueStateComps = [];
            
            celBodyData = obj.lvdData.celBodyData;
            
            if(isempty(obj.consts))
                return;
            end

            if(tfRunScript)
                if(~isempty(stateLogCache.x) && all(x == stateLogCache.x))
                    stateLog = stateLogCache.stateLog;
                else
                    obj.lvdOptim.vars.updateObjsWithScaledVarValues(x);
                    useSparse = obj.canUseSparseOutput();
                    try
                        stateLog = obj.lvdData.script.executeScript(useSparse, evtToStartScriptExecAt, false, allowInterrupt, false, false);
                        stateLogCache.x = x;
                        stateLogCache.stateLog = stateLog;
                    catch ME
                        c = NaN; ceq = NaN; return;
                    end
                end
            elseif(~isempty(stateLogToEval) && isa(stateLogToEval, 'LaunchVehicleStateLog'))
                stateLog = stateLogToEval;
            else
                stateLog = obj.lvdData.stateLog;
            end

            entries = stateLog.entries;
            if(isempty(entries))
                c = NaN(1, length(obj.lastRunValues.c));
                ceq = NaN(1, length(obj.lastRunValues.ceq));
                return;
            end
            eventsWithStates = unique([entries.event]);

            constCnt = 1;
            for i = 1:length(obj.consts)
                constraint = obj.consts(i);
                
                if(~constraint.active || obj.isEventOptimDisabled(constraint))
                    continue;
                end

                event = constraint.getConstraintEvent();
                if(ismember(event, eventsWithStates))
                    [c1, ceq1, value1, lb1, ub1, type1, eventNum1, valueStateComp1] = constraint.evalConstraint(stateLog, celBodyData);
                else
                    % If the event did not run, use NaN values to indicate this
                    c1 = NaN; ceq1 = NaN; value1 = NaN; lb1 = constraint.lb; ub1 = constraint.ub;
                    type1 = constraint.getConstraintType(); eventNum1 = event.getEventNum(); valueStateComp1 = NaN;
                end

                c1 = c1(:)'; ceq1 = ceq1(:)'; value1 = value1(:)'; lb1 = lb1(:)'; ub1 = ub1(:)';
                
                cEventInds = [cEventInds, repmat(eventNum1, 1, length(c1))];
                cCInds = [cCInds, repmat(constCnt, 1, length(c1))];
                ceqEventInds = [ceqEventInds, repmat(eventNum1, 1, length(ceq1))];
                cCeqInds = [cCeqInds, repmat(constCnt, 1, length(ceq1))];
                
                c = [c, c1]; ceq = [ceq, ceq1]; value = [value, value1]; lb = [lb, lb1]; ub = [ub, ub1];
                type = [type, type1];
                typeNumConstrArr = [typeNumConstrArr, repmat({type1}, 1, numel(c1)+numel(ceq1))];
                eventNum = [eventNum, eventNum1];
                constraints = [constraints, constraint];
                valueStateComps = [valueStateComps, valueStateComp1];
                
                constCnt = constCnt + 1;
            end
            
            obj.lastRunValues.updateValues(c, ceq, value, lb, ub, type, eventNum, cEventInds, ceqEventInds, constraints, cCInds, cCeqInds, valueStateComps);
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
%             DC = jacobianest(fC,x,useParallel);

            fCEq = @(x) out2(fC, x);
            DCeq = computeGradAtPoint(fCEq, x, cEqAtX0, 1E-5, FiniteDiffTypeEnum.Forward, 2, [], useParallel);
%             DCeq = jacobianest(fCEq,x,useParallel)';
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