classdef FixedInVehicleFrameSensorSteeringModel < AbstractSensorSteeringModel
    %FixedInVehicleFrameSensorSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rhtAsc(1,1) double
        dec(1,1) double
        roll(1,1) double
    end
    
    methods
        function obj = FixedInVehicleFrameSensorSteeringModel(rhtAsc, dec, roll)
            obj.rhtAsc = rhtAsc;
            obj.dec = dec;
            obj.roll = roll;
        end
        
        function [boreDir] = getBoresightVector(obj, time, vehElemSet, scSteeringModel, inFrame)
            vehElemSet = convertToCartesianElementSet(vehElemSet);
            rVect = vehElemSet.rVect;
            vVect = vehElemSet.vVect;
            bodyInfo = vehElemSet.frame.getOriginBody();
            
            rotMat = scSteeringModel.getBody2InertialDcmAtTime(time, rVect, vVect, bodyInfo);
            
            [x,y,z] = sph2cart(obj.rhtAsc, obj.dec, 1);
            v = [x;y;z];
            
            boreDir = rotMat * v;
        end
        
        function rollAngle = getBoresightRollAngle(obj)
            rollAngle = obj.roll;
        end
    end
end