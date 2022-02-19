classdef SensorTargetResults < matlab.mixin.SetGet
    %SensorTargetResults Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sensor AbstractSensor
        target AbstractSensorTarget
        
        time(1,1) double
        sensorRVect(3,1) double %sensor position at time
        resultsBool(:,1) logical %corresponds to position vectors
        targetRVect(:,3) double %target position vector at time
        frame BodyCenteredInertialFrame %reference frame of target rVects
    end
    
    methods
        function obj = SensorTargetResults(sensor, target, time, sensorRVect, resultsBool, targetRVect, frame)
            obj.sensor = sensor;
            obj.target = target;
            obj.sensorRVect = sensorRVect;
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
                cartElem = CartesianElementSet(times, rVects', vVects, obj.frame, true);
                
                cartElem = convertToFrame(cartElem, inFrame);
                rVects = [cartElem.rVect]';
            end
        end
        
        function covFrac = getCoverageFraction(obj)
            for(i=1:length(obj))
                covFrac(i) = sum(obj(i).resultsBool) / numel(obj(i).resultsBool); %#ok<AGROW>
            end
        end
        
        function [az, el, range, angleFromBoresight] = getBoresightRelativeAngles(obj, sensorState, scElem, dcm)
            targetRVects = obj.targetRVect';
            
            scElem = scElem.convertToCartesianElementSet().convertToFrame(obj.frame);
            sensorDcm = obj.sensor.getSensorDcmToInertial(sensorState, scElem, dcm, obj.frame); %returns the body to inertial rotation
            
            sensorToTargetRVectInertial = targetRVects - obj.sensorRVect;
            sensorToTargetRVectInSensorFrame = sensorDcm' * sensorToTargetRVectInertial;
             
            [az, el, range] = cart2sph(sensorToTargetRVectInSensorFrame(1,:), sensorToTargetRVectInSensorFrame(2,:),sensorToTargetRVectInSensorFrame(3,:));
            
            boreDir = obj.sensor.getSensorBoresightDirection(sensorState, scElem.time, scElem, dcm, obj.frame); %in inertial frame
            boreDir = repmat(boreDir, 1, width(sensorToTargetRVectInertial));
            
            angleFromBoresight = dang(boreDir, sensorToTargetRVectInertial);
        end
    end
    
    methods(Static)
        function mergedResults = mergeResults(results)
            targets = unique([results.target]);
            for(i=1:length(targets))
                target = targets(i);
                
                subResults = results([results.target] == target);
                sensor = [subResults.sensor];
                time = subResults(1).time;
                sensorRVect = subResults(1).sensorRVect;
                targetRVect = subResults(1).targetRVect;
                frame = subResults(1).frame;
                
                allBools = any([subResults.resultsBool],2);
                
                mergedResults(i) = SensorTargetResults(sensor, target, time, sensorRVect, allBools, targetRVect, frame); %#ok<AGROW>
            end
        end
    end
end