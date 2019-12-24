classdef KeplerianElementSet < AbstractElementSet
    %KeplerianElementSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sma(1,1) double %km
        ecc(1,1) double %ND
        inc(1,1) double %rad
        raan(1,1) double %rad
        arg(1,1) double %rad
        tru(1,1) double %rad
        
        optVar KeplerianElementSetVariable
    end
    
    properties(Constant)
        typeEnum = ElementSetEnum.KeplerianElements;
    end
    
    methods
        function obj = KeplerianElementSet(time, sma, ecc, inc, raan, arg, tru, frame)
            if(nargin > 0)
                obj.time = time;
                obj.sma = sma;
                obj.ecc = ecc;
                obj.inc = inc;
                obj.raan = raan;
                obj.arg = arg;
                obj.tru = tru;
                obj.frame = frame;
            end
        end
        
        function cartElemSet = convertToCartesianElementSet(obj)
            gmu = obj.frame.getOriginBody().gm;
            [rVect, vVect] = getStatefromKepler(obj.sma, obj.ecc, obj.inc, obj.raan, obj.arg, obj.tru, gmu);
            
            cartElemSet = CartesianElementSet(obj.time, rVect, vVect, obj.frame);
        end
        
        function kepElemSet = convertToKeplerianElementSet(obj)
            kepElemSet = obj;
        end
        
        function geoElemSet = convertToGeographicElementSet(obj)
            geoElemSet = obj.convertToCartesianElementSet().convertToGeographicElementSet();
        end
        
        function elemVect = getElementVector(obj)
            elemVect = [obj.sma,obj.ecc,rad2deg(obj.inc),rad2deg(obj.raan),rad2deg(obj.arg),rad2deg(obj.tru)];
        end
    end
    
    methods(Access=protected)
        function displayScalarObject(obj)
            fprintf('Keplerian State \n\tTime: %0.3f sec UT \n\tSMA: %0.3f km \n\tEcc: %0.9f \n\tInc: %0.3f deg \n\tRAAN: %0.3f deg \n\tArg Peri: %0.3f deg \n\tTrue Anom: %0.3f deg \n\tFrame: %s\n', ...
                    obj.time, ...
                    obj.sma, ...
                    obj.ecc, ...
                    rad2deg(obj.inc), ...
                    rad2deg(obj.raan), ...
                    rad2deg(obj.arg), ...
                    rad2deg(obj.tru), ...
                    obj.frame.getNameStr());
        end        
    end
    
    methods(Static)
        function elemSet = getDefaultElements()
            elemSet = KeplerianElementSet();
        end
    end
end