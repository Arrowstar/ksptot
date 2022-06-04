classdef TimeUnitEnum < matlab.mixin.SetGet
    %TimeUnitEnum Summary of this class goes here
    %   Detailed explanation goes here

    enumeration
        Seconds('Seconds')
        Minutes('Minutes')
        Hours('Hours')
        Days('Days')
        Years('Years')
    end

    properties
        name(1,:) char
    end

    methods
        function obj = TimeUnitEnum(name)
            obj.name = name;
        end
    end

    methods(Static)
        function [listBoxStr, m] = getListboxStr()
            m = enumeration('TimeUnitEnum');
            listBoxStr = {m.name};
        end
    end
end