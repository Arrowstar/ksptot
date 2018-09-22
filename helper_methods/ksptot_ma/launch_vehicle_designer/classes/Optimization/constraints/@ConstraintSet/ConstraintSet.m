classdef ConstraintSet < matlab.mixin.SetGet
    %ConstraintSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        consts(1,:) AbstractConstraint
        
        lvdOptim LvdOptimization
        lvdData LvdData
    end
    
    methods
        function obj = ConstraintSet(lvdOptim, lvdData)
            obj.consts = AbstractConstraint.empty(1,0);
            
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
        
        function [c, ceq, value, lb, ub, type, eventNum] = evalConstraints(obj, x, maData) %optimVarSet,script,initStateLogEntry,stateLog,maData,celBodyData)
            c = [];
            ceq = [];
            value = [];
            lb = [];
            ub = [];
            type = {};
            eventNum = [];
            
            if(~isempty(obj.consts))
                obj.lvdOptim.vars.updateObjsWithVarValues(x);
                stateLog = obj.lvdData.script.executeScript();

                for(i=1:length(obj.consts)) %#ok<*NO4LP>
                    [c1, ceq1, value1, lb1, ub1, type1, eventNum1] = obj.consts(i).evalConstraint(stateLog, maData);

                    c   = [c,c1]; %#ok<AGROW>
                    ceq = [ceq, ceq1]; %#ok<AGROW>
                    value = [value, value1]; %#ok<AGROW>
                    lb = [lb, lb1]; %#ok<AGROW>
                    ub = [ub, ub1]; %#ok<AGROW>
                    type = horzcat(type, type1); %#ok<AGROW>
                    eventNum = [eventNum, eventNum1]; %#ok<AGROW>
                end
                
%                 disp(max([max(c), max(ceq)]));

                if(any(isnan(c)) || any(isnan(ceq)))
                    a = 1;
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
    end
end

