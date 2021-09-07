classdef FixedInCoordSysSensorSteeringModel < AbstractSensorSteeringModel
    %FixedInCoordSysSensorSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rhtAsc(1,1) double
        dec(1,1) double
        roll(1,1) double
        coordSys AbstractGeometricCoordSystem
    end
    
    methods
        function obj = FixedInCoordSysSensorSteeringModel(rhtAsc, dec, roll, coordSys)
            obj.rhtAsc = rhtAsc;
            obj.dec = dec;
            obj.roll = roll;
            obj.coordSys = coordSys;
        end
        
        function [boreDir] = getBoresightVector(obj, time, vehElemSet, ~, inFrame)
            rotMat = obj.coordSys.getCoordSysAtTime(time, vehElemSet, inFrame);
            
            [x,y,z] = sph2cart(obj.rhtAsc, obj.dec, 1);
            v = [x;y;z];
            
            boreDir = rotMat * v;
        end
        
        function rollAngle = getBoresightRollAngle(obj)
            rollAngle = obj.roll;
        end
    end
end