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
            obj.vars([obj.vars] == var) = [];
            obj.sortVarsByEvtNum();
            
            obj.clearCachedVarEvtDisabledStatus();
            notify(obj,'VarsListUpdatedRemovedVar');
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
            indsToRemove = [];
            for(i=1:length(obj.vars))
                var = obj.vars(i);
                lvdData = obj.lvdData;
                [~, varLocType] = getEventNumberForVar(var, lvdData);
                
                if(isempty(varLocType))
                    indsToRemove(end+1) = i; %#ok<AGROW>
                end
            end
            
            obj.vars(indsToRemove) = [];
        end
    end
end