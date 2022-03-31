classdef LvdCaseMatrixTaskRunStatusEnum < matlab.mixin.SetGet
    %LvdCaseMatrixTaskRunStatusEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        RunSuceeded('Run Succeeded');
        RunFailedPreReqNotSatisfied('Prerequisites Not Satisfied')
        RunFailedOptimizerNotConverged('Optimizer Not Converged');
        RunFailedDueToError('Run Failed Due to Script Execution Error');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = LvdCaseMatrixTaskRunStatusEnum(name)
            obj.name = name;
        end
    end
end