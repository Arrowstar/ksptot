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
                
                listBoxStr{end+1} = [prefStr,obj.consts(i).getName(),obj.consts(i).getTagsDisplayStr()]; %#ok<AGROW>
            end
            
            consts = obj.consts;
        end

        function [listBoxStr, consts, tooltipStrs] = getFilteredListboxStr(obj, query)
            if(nargin < 2)
                query = '';
            end

            [listBoxStr, consts] = obj.getListboxStr();
            tooltipStrs = obj.getToolboxStrs();
            corpus = arrayfun(@(c) c.getSearchText(), consts, 'UniformOutput', false);
            keep = lvd_filterListboxItems(query, corpus);
            listBoxStr = listBoxStr(keep);
            consts = consts(keep);
            tooltipStrs = tooltipStrs(keep);
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
                    if(isempty(obj.lvdOptim))
                        obj.lvdOptim = obj.lvdData.optimizer;
                    end

                    useSparse = obj.canUseSparseOutput();
                    
                    try
                        stateLog = obj.lvdOptim.propagateForX(x, useSparse, evtToStartScriptExecAt, allowInterrupt);
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

                entries = stateLog.entries;
                eventsWithStates = unique([entries.event]);

                constCnt = 1;
                for(i=1:length(obj.consts)) %#ok<*NO4LP>
                    constraint = obj.consts(i);
                    
                    if(obj.isEventOptimDisabled(constraint) || constraint.active == false)
                        continue;
                    end

                    event = constraint.getConstraintEvent();
                    if(ismember(event, eventsWithStates))   
                        [c1, ceq1, value1, lb1, ub1, type1, eventNum1, valueStateComp1] = constraint.evalConstraint(stateLog, celBodyData);
                    else
                        %The constraint's event produced no state (the script
                        %stopped before it): carry the shape of the previous
                        %evaluation forward as NaNs.
                        bool = obj.lastRunValues.consts == constraint;
                        constInd = find(bool, 1, 'first');

                        if(not(isempty(constInd)) && constInd <= numel(obj.lastRunValues.value))
                            cBool = obj.lastRunValues.cCInds == constInd;
                            cEqBool = obj.lastRunValues.cCeqInds == constInd;

                            c1 = NaN(size(obj.lastRunValues.c(cBool)));
                            ceq1 = NaN(size(obj.lastRunValues.ceq(cEqBool)));
                            value1 = obj.lastRunValues.value(constInd);
                            lb1 = obj.lastRunValues.lb(constInd);
                            ub1 = obj.lastRunValues.ub(constInd);
                            type1 = obj.lastRunValues.type{constInd};
                            eventNum1 = obj.lastRunValues.eventNum(constInd);
                            valueStateComp1 = obj.lastRunValues.valueStateComps(constInd);
                        else
                            %Never evaluated before either: one NaN row so the
                            %per-constraint arrays stay aligned with "constraints"
                            %(the status table and validator index them by
                            %constraint).
                            c1 = [];
                            ceq1 = [];
                            value1 = NaN;
                            [lb1, ub1] = constraint.getBounds();
                            type1 = constraint.getConstraintType();
                            eventNum1 = event.getEventNum();
                            valueStateComp1 = NaN;
                        end
                    end

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

            obj.lastRunValues.updateValues(c, ceq, value, lb, ub, type, eventNum, cEventInds, ceqEventInds, constraints, cCInds, cCeqInds, valueStateComps);
        end

        function [cAtX0, cEqAtX0, DC, DCeq] = evalConstraintsWithGradients(obj, x, tfRunScript, evtToStartScriptExecAt, allowInterrupt, stateLogToEval)
            %evalConstraintsWithGradients Constraints and their Jacobians at x.
            %
            %   DC is [numel(x) x numel(c)] and DCeq is [numel(x) x numel(ceq)],
            %   the orientation fmincon expects from a nonlcon with
            %   SpecifyConstraintGradient.  Both come from ONE finite-difference
            %   pass over the stacked vector [c; ceq], using the step size,
            %   difference type and stencil configured on the mission's
            %   CustomFiniteDiffsCalculationMethod, and the structural sparsity
            %   from getConstraintJacobianSparsity so variables that cannot
            %   influence any constraint are never perturbed.
            [cAtX0, cEqAtX0] = obj.evalConstraints(x, tfRunScript, evtToStartScriptExecAt, allowInterrupt, stateLogToEval);
            cAtX0 = cAtX0(:)';
            cEqAtX0 = cEqAtX0(:)';

            numC = numel(cAtX0);
            numCeq = numel(cEqAtX0);

            if(isempty(obj.lvdOptim))
                obj.lvdOptim = obj.lvdData.optimizer;
            end

            useParallel = obj.getGradientUseParallelFlag();
            fdMethod = obj.lvdOptim.customFiniteDiffsCalcMethod;

            fStacked = @(xIn) ConstraintSet.stackedConstraintFcn(obj, xIn, tfRunScript, evtToStartScriptExecAt, allowInterrupt, stateLogToEval);
            stackedAtX0 = [cAtX0, cEqAtX0];

            sparsity = obj.getConstraintJacobianSparsity(); %[numC+numCeq x numX]
            if(not(isequal(size(sparsity), [numC + numCeq, numel(x)])))
                sparsity = [];
            end

            J = fdMethod.computeJacobian(fStacked, x, stackedAtX0, useParallel, sparsity); %[numC+numCeq x numX]

            DC = J(1:numC, :)';
            DCeq = J(numC+1:numC+numCeq, :)';
        end

        function useParallel = getGradientUseParallelFlag(obj)
            %getGradientUseParallelFlag The selected optimizer's parallel flag,
            %falling back to "a pool with more than one worker exists" when the
            %optimizer does not expose one.
            useParallel = [];

            if(not(isempty(obj.lvdOptim)))
                try
                    optimizer = obj.lvdOptim.getSelectedOptimizer();
                    if(ismethod(optimizer, 'usesParallel'))
                        useParallel = logical(optimizer.usesParallel());
                    end
                catch
                    useParallel = [];
                end
            end

            if(isempty(useParallel))
                p = gcp('nocreate');
                useParallel = not(isempty(p)) && p.NumWorkers > 1;
            end

            %A request for parallel evaluation without a pool would make
            %computeGradAtPoint error; treat it as serial instead.
            if(useParallel && isempty(gcp('nocreate')))
                useParallel = false;
            end
        end

        function sparsity = getConstraintJacobianSparsity(obj)
            %getConstraintJacobianSparsity Structural constraint Jacobian pattern.
            %
            %   Returns a logical matrix [numConstraintRows x numX] aligned with
            %   the most recent evalConstraints result (rows: c then ceq) and the
            %   scaled x vector.  Entry (j,i) is false when x element i is owned
            %   by an event that runs strictly after every event constraint row
            %   j reads, because a later event's variables cannot change an
            %   earlier state.  Non-event variables (vehicle, initial state,
            %   plugins, non-sequential events; event number 0) are dense.
            %
            %   The pattern is all-true whenever event order is not static:
            %   any SetNextEventAction (including inside ConditionalAction
            %   branches), any plugin, or any non-sequential event.
            if(isempty(obj.lvdOptim))
                obj.lvdOptim = obj.lvdData.optimizer;
            end

            xEvtNums = obj.lvdOptim.vars.getXElementEvtNums();
            numX = numel(xEvtNums);

            lrv = obj.lastRunValues;
            if(isempty(lrv))
                sparsity = true(0, numX);
                return;
            end

            rowEvtNums = [lrv.cEventInds(:)', lrv.ceqEventInds(:)'];
            rowConstInds = [lrv.cCInds(:)', lrv.cCeqInds(:)'];
            numRows = numel(rowEvtNums);

            sparsity = true(numRows, numX);

            if(numRows == 0 || numX == 0)
                return;
            end

            if(obj.eventOrderIsDynamic())
                return;
            end

            %StateComparison constraints read a second event; the row depends
            %on whichever of the two runs later.
            for(j = 1:numRows)
                constInd = rowConstInds(j);
                if(constInd >= 1 && constInd <= numel(lrv.consts))
                    const = lrv.consts(constInd);
                    if(isprop(const, 'evalType') && isprop(const, 'stateCompEvent') && ...
                       const.evalType == ConstraintEvalTypeEnum.StateComparison && not(isempty(const.stateCompEvent)))
                        compEvtNum = const.stateCompEvent.getEventNum();
                        if(not(isempty(compEvtNum)) && not(isnan(compEvtNum)))
                            rowEvtNums(j) = max(rowEvtNums(j), compEvtNum);
                        end
                    end
                end
            end

            for(i = 1:numX)
                if(xEvtNums(i) > 0)
                    sparsity(rowEvtNums < xEvtNums(i), i) = false;
                end
            end
        end

        function tf = eventOrderIsDynamic(obj)
            %eventOrderIsDynamic True when event execution order or per-event
            %inputs cannot be determined statically from the event list.
            lvdData = obj.lvdData;
            tf = false;

            if(isempty(lvdData))
                return;
            end

            if(not(isempty(lvdData.plugins)) && lvdData.plugins.getNumPlugins() > 0)
                tf = true;
                return;
            end

            script = lvdData.script;
            if(not(isempty(script.nonSeqEvts)) && script.nonSeqEvts.getTotalNumOfEvents() > 0)
                tf = true;
                return;
            end

            for(i = 1:length(script.evts))
                if(ConstraintSet.actionsContainSetNextEvent(script.evts(i).actions))
                    tf = true;
                    return;
                end
            end
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

    methods(Static)
        function stacked = stackedConstraintFcn(constraintSet, x, tfRunScript, evtToStartScriptExecAt, allowInterrupt, stateLogToEval)
            %stackedConstraintFcn [c(:); ceq(:)] as one column, for Jacobians.
            [c, ceq] = constraintSet.evalConstraints(x, tfRunScript, evtToStartScriptExecAt, allowInterrupt, stateLogToEval);
            stacked = [c(:); ceq(:)];
        end

        function tf = actionsContainSetNextEvent(actions)
            %actionsContainSetNextEvent Recursive SetNextEventAction search that
            %also looks inside ConditionalAction branches.
            tf = false;

            for(i = 1:length(actions)) %#ok<*NO4LP>
                action = actions(i);

                if(isa(action, 'SetNextEventAction'))
                    tf = true;
                    return;
                end

                if(isa(action, 'ConditionalAction') && ismethod(action, 'getAllBranchActions'))
                    if(ConstraintSet.actionsContainSetNextEvent(action.getAllBranchActions()))
                        tf = true;
                        return;
                    end
                end
            end
        end
    end
end