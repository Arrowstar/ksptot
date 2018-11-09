classdef ConstraintValues < matlab.mixin.SetGet
    %ConstraintValues Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        c = [];
        ceq = [];
        value = [];
        lb = [];
        ub = [];
        type = {};
        eventNum = [];
        cEventInds = [];
        ceqEventInds = [];
    end
    
    methods
        function obj = ConstraintValues()

        end
        
        function updateValues(obj, c, ceq, value, lb, ub, type, eventNum, cEventInds, ceqEventInds)
            obj.c = c;
            obj.ceq = ceq;
            obj.value = value;
            obj.lb = lb;
            obj.ub = ub;
            obj.type = type;
            obj.eventNum = eventNum;
            obj.cEventInds = cEventInds;
            obj.ceqEventInds = ceqEventInds;
        end
        
        function [c, ceq, value, lb, ub, type, eventNum, cEventInds, ceqEventInds] = getValues(obj)
            c = obj.c;
            ceq = obj.ceq;
            value = obj.value;
            lb = obj.lb;
            ub = obj.ub;
            type = obj.type;
            eventNum = obj.eventNum;
            cEventInds = obj.cEventInds;
            ceqEventInds = obj.ceqEventInds;
        end
    end
end

