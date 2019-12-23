classdef LvdOptimSubroutineEnum < matlab.mixin.SetGet
    %LvdOptimSubroutineEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        fmincon('fmincon');
        patternseach('patternsearch');
    end
    
    properties
        name char
    end
    
    methods
        function obj = LvdOptimSubroutineEnum(name)
            obj.name = name;
        end
    end
end