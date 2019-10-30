classdef LvdOptimAlgorithmEnum < matlab.mixin.SetGet
    %LvdOptimAlgorithmEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        InteriorPoint('interior-point');
        SQP('sqp');
        ActiveSet('active-set');
    end
    
    properties
        algoName char
    end
    
    methods
        function obj = LvdOptimAlgorithmEnum(algoName)
            obj.algoName = algoName;
        end
    end
end