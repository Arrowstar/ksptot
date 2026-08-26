classdef OptimizationVariableSet < matlab.mixin.SetGet
    %OptimizationVariableSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
        vars AbstractOptimizationVariable
    end
    
    properties(Transient)
        cachedVars AbstractOptimizationVariable
        cachedVarEventDis logical

        %Incremental re-propagation support: records the scaled x vector
        %most recently pushed onto the variable objects (pending) and the
        %one for which propagation results were last produced (committed).
        pendingX double
        committedX double
    end
    
   events
        VarsListUpdatedAddedVar
        VarsListUpdatedRemovedVar
   end
    
    methods
        function obj = OptimizationVariableSet(lvdData)
            obj.lvdData = lvdData;
        end
        
        function addVariable(obj, newVar)
            obj.vars(end+1) = newVar;
            obj.sortVarsByEvtNum();
            
            obj.clearCachedVarEvtDisabledStatus();
            notify(obj,'VarsListUpdatedAddedVar');
        end
        
        function removeVariable(obj, var)
            if(not(isempty(var)))
                obj.vars([obj.vars] == var) = [];
                obj.sortVarsByEvtNum();

                obj.clearCachedVarEvtDisabledStatus();
                notify(obj,'VarsListUpdatedRemovedVar');
            end
        end
        
        function [x, vars, varNameStrs, xUnscaled] = getTotalScaledXVector(obj)
            x = [];
            xUnscaled = [];
            vars = AbstractOptimizationVariable.empty(0,1);
            
            varNameStrs = {};
            for(i=1:length(obj.vars)) %#ok<*NO4LP>
                var = obj.vars(i);
                
                if(obj.isVarEventOptimDisabled(var))
                    continue;
                end
                
                vX = var.getScaledXsForVariable();
                x = horzcat(x, vX); %#ok<AGROW>
                
                vXUnscaled = var.getXsForVariable();
                xUnscaled = horzcat(xUnscaled, vXUnscaled); %#ok<AGROW>
                
                for(j=1:length(vX))
                    vars(end+1) = obj.vars(i); %#ok<AGROW>
                end
                
                if(not(isempty(vX)))
                    [evtNum, varLocType] = getEventNumberForVar(var, obj.lvdData);
                    
                    if(isempty(evtNum))
                        evtNum = 0;
                    end
                    
                    varNameStrs = horzcat(varNameStrs,var.getStrNamesOfVars(evtNum, varLocType)); %#ok<AGROW>
                end
            end
        end
               
        function [LwrBnds, UprBnds, LwrBndsUnscaled, UprBndsUnscaled] = getTotalScaledBndsVector(obj)
            LwrBnds = [];
            UprBnds = [];
            LwrBndsUnscaled = [];
            UprBndsUnscaled = [];
            
            for(i=1:length(obj.vars)) %#ok<*NO4LP>
                var = obj.vars(i);
                
                if(obj.isVarEventOptimDisabled(var))
                    continue;
                end
                
                [~, lb, ub]= var.getScaledXsForVariable();
                LwrBnds = horzcat(LwrBnds, lb); %#ok<AGROW>
                UprBnds = horzcat(UprBnds, ub); %#ok<AGROW>
                
                [lb, ub] = var.getBndsForVariable();
                LwrBndsUnscaled = horzcat(LwrBndsUnscaled, lb); %#ok<AGROW>
                UprBndsUnscaled = horzcat(UprBndsUnscaled, ub); %#ok<AGROW>
            end
        end
        
        function typicalX = getTypicalScaledXVector(obj)
            [LwrBnds, UprBnds] = obj.getTotalScaledBndsVector();
            
            typicalX = zeros(size(LwrBnds));
            for(i=1:length(LwrBnds))
                lbO = floor(log10(LwrBnds(i)));
                ubO = floor(log10(UprBnds(i)));
                
                if(lbO > ubO)
                    typicalX(i) = LwrBnds(i);
                else
                    typicalX(i) = UprBnds(i);
                end
            end
            
            typicalX(typicalX<eps) = 1;
        end
        
        function updateObjsWithScaledVarValues(obj, x)
            initInd = 1;
            
            for(i=1:length(obj.vars))
                var = obj.vars(i);
                
                if(obj.isVarEventOptimDisabled(var))
                    continue;
                end
                
                numVars = var.getNumOfVars();
                
                inds = initInd:initInd+numVars-1;
                subX = x(inds);
                
                if(not(isempty(subX)))
                    var.updateObjWithScaledVarValue(subX);
                    initInd = inds(end) + 1;
                end
            end  
            
            %Always record as a row vector: callers may pass x as a row or
            %a column (e.g. finite-difference machinery slicing columns out
            %of a perturbation matrix), and change detection compares this
            %against previously recorded vectors element-wise.
            obj.pendingX = reshape(x, 1, []);
        end
        
        function commitPendingX(obj)
            %COMMITPENDINGX Promotes the pending x vector to committed.
            %
            %   Called by the script runner after propagation results have
            %   been produced for the pending x vector, marking it as the
            %   baseline against which the next evaluation's changes are
            %   measured.
            
            if(isempty(obj.pendingX))
                return;
            end
            
            obj.committedX = obj.pendingX;
        end
        
        function x = getPendingX(obj)
            x = obj.pendingX;
        end
        
        function x = getCommittedX(obj)
            x = obj.committedX;
        end
        
        function evtNums = getXElementEvtNums(obj)
            %GETXELEMENTEVTNUMS Event number owning each element of the x vector.
            %
            %   Returns an array aligned element-for-element with the scaled
            %   x vector (same filtering and ordering as
            %   updateObjsWithScaledVarValues).  Each entry is the number of
            %   the event whose objects consume that variable value, or 0
            %   when the variable is not event-owned (launch vehicle,
            %   initial state, plugins, non-sequential events), meaning it
            %   may affect any event.
            
            evtNums = [];
            
            for(i=1:length(obj.vars)) %#ok<*NO4LP>
                var = obj.vars(i);
                
                if(obj.isVarEventOptimDisabled(var))
                    continue;
                end
                
                numVars = var.getNumOfVars();
                
                if(numVars <= 0)
                    continue;
                end
                
                evtNum = getEventNumberForVar(var, obj.lvdData);
                
                if(isempty(evtNum))
                    evtNum = 0;
                end
                
                evtNums = horzcat(evtNums, repmat(evtNum, 1, numVars)); %#ok<AGROW>
            end
        end
        
        function perturbVarsAndUpdate(obj, pPct)
            for(i=1:length(obj.vars))
                var = obj.vars(i);
                
                if(obj.isVarEventOptimDisabled(var))
                    continue;
                end
                
                var.perturbVar(pPct);
            end
        end
        
        function removeVariablesThatUseEvent(obj, evt, lvdData)
            indsToDelete = [];
            for(i=1:length(obj.vars))
                var = obj.vars(i);
                
                evtNum = getEventNumberForVar(var, lvdData);
                
                if(not(isempty(evtNum)))
                    inputEvtNum = evt.getEventNum();
                    
                    if(evtNum == inputEvtNum)
                        indsToDelete(end+1) = i; %#ok<AGROW>
                    end
                end
            end
            
            for(i=length(indsToDelete):-1:1)
                indToDel = indsToDelete(i);
                obj.removeVariable(obj.vars(indToDel));  
            end
            
            obj.clearCachedVarEvtDisabledStatus();
        end
        
        function clearCachedVarEvtDisabledStatus(obj)
            obj.cachedVars = AbstractOptimizationVariable.empty(1,0);
            obj.cachedVarEventDis = logical([]);
            
            %Var set membership/order changed: x bookkeeping is no longer
            %aligned, so force a full re-baseline on the next evaluation.
            obj.pendingX = [];
            obj.committedX = [];
        end
        
        function sortVarsByEvtNum(obj)
            evtNums = [];
            for(i=1:length(obj.vars)) %#ok<*NO4LP>
                var = obj.vars(i);
                evtNum = getEventNumberForVar(var, obj.lvdData);
                if(isempty(evtNum))
                    evtNum = 0;
                end
                
                evtNums(i) = evtNum; %#ok<AGROW>
            end
            
            [~,I] = sort(evtNums);
            obj.vars = obj.vars(I);
            
            obj.clearCachedVarEvtDisabledStatus();
        end

        function varsStoredInRad = getVarsStoredInRad(obj)
            varsStoredInRad = [];
            
            for(i=1:length(obj.vars)) %#ok<*NO4LP>
                var = obj.vars(i);
                
                if(obj.isVarEventOptimDisabled(var))
                    continue;
                end
                
                useTf = var.getUseTfForVariable();
                varStoredInRad = var.getVarsStoredInRad();
                varsStoredInRad = horzcat(varsStoredInRad, varStoredInRad(useTf)); %#ok<AGROW>
            end
        end

        function varsDisplayedAsPercent = getVarsDisplayedAsPercents(obj)
            varsDisplayedAsPercent = [];
            
            for(i=1:length(obj.vars)) %#ok<*NO4LP>
                var = obj.vars(i);
                
                if(obj.isVarEventOptimDisabled(var))
                    continue;
                end
                
                useTf = var.getUseTfForVariable();
                varDisplayedAsPercent = var.getVarsDisplayedAsPercents();
                varsDisplayedAsPercent = horzcat(varsDisplayedAsPercent, varDisplayedAsPercent(useTf)); %#ok<AGROW>
            end
        end

        function varsDisplayedAsMeters = getVarsDisplayedAsMeters(obj)
            varsDisplayedAsMeters = [];
            
            for(i=1:length(obj.vars)) %#ok<*NO4LP>
                var = obj.vars(i);
                
                if(obj.isVarEventOptimDisabled(var))
                    continue;
                end
                
                useTf = var.getUseTfForVariable();
                varDisplayedAsMeters = var.getVarsDisplayedAsMeters();
                varsDisplayedAsMeters = horzcat(varsDisplayedAsMeters, varDisplayedAsMeters(useTf)); %#ok<AGROW>
            end
        end

        function removeUselessVars(obj)
            indsToRemove = [];
            for(i=1:length(obj.vars))
                var = obj.vars(i);
                [~, varLocType] = getEventNumberForVar(var, obj.lvdData);
                
                if(isempty(varLocType))
                    indsToRemove(end+1) = i; %#ok<AGROW>
                end
            end
            
            obj.vars(indsToRemove) = [];
        end
    end
    
    methods(Access=private)
        function tf = isVarEventOptimDisabled(obj, var)
            bool = obj.cachedVars == var;
            if(any(bool))
                tf = obj.cachedVarEventDis(bool);
            else
                tf = false;

                evtNum = getEventNumberForVar(var, obj.lvdData);
                if(not(isempty(evtNum)))
                    evt = obj.lvdData.script.getEventForInd(evtNum);

                    if(not(isempty(evt)) && evt.disableOptim == true)
                        tf = true;
                    end
                end
                
                obj.cachedVars(end+1) = var;
                obj.cachedVarEventDis(end+1) = tf;
            end
        end
    end
    
    methods(Static, Access=private)
        function obj = loadobj(obj)
            obj.removeUselessVars();
        end
    end
end