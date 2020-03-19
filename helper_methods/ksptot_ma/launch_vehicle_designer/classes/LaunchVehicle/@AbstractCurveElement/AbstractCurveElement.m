classdef(Abstract) AbstractCurveElement < matlab.mixin.SetGet & matlab.mixin.Copyable & matlab.mixin.Heterogeneous
    %AbstractCurveElement Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        indepVar(1,1) double %independent variable, such as indepVar
        depVar(1,1) double   %dependendent variable, such as throttleModifier
    end
    
    properties(Abstract, Constant)
        minIndepValue
        maxIndepValue
        
        minDepValue
        maxDepValue
    end
    
    methods(Abstract)
        indepVarName = getIndepVarName(obj)
        indepVarUnit = getIndepVarUnit(obj)
        depVarName = getDepVarName(obj)
        depVarUnit = getDepVarUnit(obj)
    end
end