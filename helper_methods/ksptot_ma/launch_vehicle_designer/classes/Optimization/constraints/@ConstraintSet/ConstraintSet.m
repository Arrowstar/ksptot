classdef ConstraintSet < matlab.mixin.SetGet
    %ConstraintSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        consts(1,:) AbstractConstraint
    end
    
    methods
        function obj = ConstraintSet()
            
        end
        
        function addConstraint(obj, newConst)
            obj.consts(end+1) = newConst;
        end
        
        function removeConstraint(obj, const)
            obj.consts(obj.consts == const) = [];
        end        
        
        function [c, ceq, value, lb, ub, type, eventNum] = evalConstraints(x, optimVarSet,script,initStateLogEntry,simDriver,stateLog)
            optimVarSet.updateObjsWithVarValues(x);
            stateLog = script.executeScript(initStateLogEntry, simDriver, stateLog);
            
            c = [];
            ceq = [];
            value = [];
            lb = [];
            ub = [];
            type = {};
            eventNum = [];
            
            for(i=1:length(obj.consts)) %#ok<*NO4LP>
                [c1, ceq1, value1, lb1, ub1, type1, eventNum1] = obj.consts(i).evalConstraint(stateLog);
                
                c   = [c,c1]; %#ok<AGROW>
                ceq = [ceq, ceq1]; %#ok<AGROW>
                value = [value, value1]; %#ok<AGROW>
                lb = [lb, lb1]; %#ok<AGROW>
                ub = [ub, ub1]; %#ok<AGROW>
                type = horzcat(type, type1); %#ok<AGROW>
                eventNum = [eventNum, eventNum1]; %#ok<AGROW>
            end
        end
    end
end

