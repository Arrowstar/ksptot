classdef SensorTargetResults < matlab.mixin.SetGet
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sensor AbstractSensor
        target AbstractSensorTarget
        
        time(1,1) double
        resultsBool(:,1) logical %corresponds to position vectors
        targetRVect(:,3) double %target position vector at time
        frame AbstractReferenceFrame %reference frame of target rVects
    end
    
    methods
        function obj = SensorTargetResults(sensor, target, time, resultsBool, targetRVect, frame)
            obj.sensor = sensor;
            obj.target = target;
            obj.time = time;
            obj.resultsBool = resultsBool;
            obj.targetRVect = targetRVect;
            obj.frame = frame;
        end
        
        function [bool, rVects] = getTargetResultsInFrame(obj, inFrame)
            bool = vertcat(obj.resultsBool);
            rVects = vertcat(obj.targetRVect);
            
            numPts = numel(bool);
            
            if(any(inFrame ~= [obj.frame]))
                times = obj.time*ones(1, numPts);
                vVects = zeros(3,numPts);
                cartElem = CartesianElementSet(times, rVects, vVects, obj.frame, true);
                
                cartElem = convertToFrame(cartElem, inFrame);
                rVects = cartElem.rVects;
            end
        end
    end
end