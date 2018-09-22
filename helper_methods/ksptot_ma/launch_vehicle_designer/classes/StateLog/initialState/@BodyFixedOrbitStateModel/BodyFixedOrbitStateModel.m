classdef BodyFixedOrbitStateModel < AbstractOrbitStateModel
    %BodyFixedOrbitStateModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lat(1,1) double
        long(1,1) double
        alt(1,1) double
        
        vVectECEF_x(1,1) double
        vVectECEF_y(1,1) double
        vVectECEF_z(1,1) double
    end
    
    methods
        function obj = BodyFixedOrbitStateModel(lat, long, alt, vVectECEF_x, vVectECEF_y, vVectECEF_z)
            obj.lat = lat;
            obj.long = long;
            obj.alt = alt;
            obj.vVectECEF_x = vVectECEF_x;
            obj.vVectECEF_y = vVectECEF_y;
            obj.vVectECEF_z = vVectECEF_z;
        end
        
        function [rVect, vVect] = getPositionAndVelocityVector(obj, ut, bodyInfo)
            vVectECEF = [obj.vVectECEF_x; obj.vVectECEF_y; obj.vVectECEF_z];
            
            [rVect,vVect] = getInertialVectFromLatLongAlt(ut, obj.lat, obj.long, obj.alt, bodyInfo, vVectECEF);
        end
    end
    
    methods(Static)
        function defaultOrbitState = getDefaultOrbitState()
            defaultOrbitState = BodyFixedOrbitStateModel(0, 0, 0, 0, 0, 0);
        end
    end
end