classdef CustomFiniteDiffsCalculationMethod < AbstractGradientCalculationMethod
    %CustomFiniteDiffsCalculationMethod 
    %   Detailed explanation goes here
    
    properties
        h(1,1) double = 1E-8;
        diffType(1,1) FiniteDiffTypeEnum = FiniteDiffTypeEnum.Forward;
        numPts(1,1) uint64 = 2;
    end
    
    methods
        function obj = CustomFiniteDiffsCalculationMethod()

        end
        
        function tf = useBuiltInMethod(obj)
            tf = false;
        end
        
        function g = computeGrad(obj, fun, x0, fAtX0, useParallel)
            g = computeGradAtPoint(fun, x0, fAtX0, obj.h, obj.diffType, double(obj.numPts), useParallel);
        end
    end
end