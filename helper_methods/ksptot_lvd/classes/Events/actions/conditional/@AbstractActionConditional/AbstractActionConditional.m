classdef (Abstract) AbstractActionConditional < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractActionConditional Summary of this class goes here
    %   Detailed explanation goes here

    properties(Abstract)
        
    end

    methods
        tf = evaluateConditional(obj, stateLogEntry);

        listboxStr = getListboxStr(obj);

        condStr = getConditionalString(obj);

        nodes = getTreeNodes(obj, parent);
    end

    methods(Sealed)
        function tf = eq(a,b)
            tf = eq@handle(a,b);
        end
        
        function tf = ne(a,b)
            tf = ne@handle(a,b);
        end
    end
end