classdef EventTermCondLogicEnum < matlab.mixin.SetGet
    %EventTermCondLogicEnum How an event combines multiple termination conditions.
    %
    %   Any - the event ends the first time any one of its termination
    %         conditions fires.  This is the behavior of an event with a
    %         single termination condition, so it is the default.
    %
    %   All - the event ends once every termination condition has fired at
    %         least once.  Conditions latch as they fire: a condition that
    %         has already fired is removed from the integrator's event list
    %         for the remainder of the event, so it cannot re-trigger and
    %         cannot block the remaining conditions.

    enumeration
        Any('Any (first condition to fire ends the event)')
        All('All (every condition must fire at least once)')
    end

    properties
        name char = '';
    end

    methods
        function obj = EventTermCondLogicEnum(name)
            obj.name = name;
        end
    end

    methods(Static)
        function listBoxStr = getListboxStr()
            m = enumeration('EventTermCondLogicEnum');
            listBoxStr = {m.name};
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('EventTermCondLogicEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
