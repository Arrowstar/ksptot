classdef KeplerianOrbitStateModel < AbstractOrbitStateModel
    %KeplerianOrbitStateModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sma(1,1) double
        ecc(1,1) double
        inc(1,1) double
        raan(1,1) double
        arg(1,1) double
        tru(1,1) double
    end
    
    methods
        function obj = KeplerianOrbitStateModel(sma, ecc, inc, raan, arg, tru)
            obj.sma = sma;
            obj.ecc = ecc;
            obj.inc = inc;
            obj.raan = raan;
            obj.arg = arg;
            obj.tru = tru;
        end
        
        function [rVect, vVect] = getPositionAndVelocityVector(obj, ~, bodyInfo)
            [rVect,vVect] = getStatefromKepler(obj.sma, obj.ecc, obj.inc, obj.raan, obj.arg, obj.tru, bodyInfo.gm);
        end
    end
end