classdef(Abstract) AbstractAnglePolySteeringModel < AbstractSteeringModel
    %AbstractAnglePolySteeringModel Summary of this class goes here
    %   Detailed explanation goes here
        
    methods 
        [angle1Name, angle2Name, angle3Name] = getAngleNames(obj)
        
        angleModel = getAngleNModel(obj, n)
        
        [tf, lb, ub] = getAngleNModelOptVarParams(obj, n)
    end
end