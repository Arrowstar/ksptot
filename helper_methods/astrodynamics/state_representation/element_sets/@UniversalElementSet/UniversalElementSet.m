classdef UniversalElementSet < AbstractElementSet
    %KeplerianElementSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        c3(1,1) double = 0; %km^2/s^2 
        rP(1,1) double = 1000 %km
        inc(1,1) double %rad
        raan(1,1) double %rad
        arg(1,1) double %rad
        tau(1,1) double %s
        
% %         optVar KeplerianElementSetVariable
    end
    
    properties(Constant)
        typeEnum = ElementSetEnum.UniversalElements
    end
    
    methods
        function obj = UniversalElementSet(time, c3, rP, inc, raan, arg, tau, frame)
            if(nargin > 0)
                obj.time = time;
                obj.c3 = c3;
                obj.rP = rP;
                obj.inc = inc;
                obj.raan = raan;
                obj.arg = arg;
                obj.tau = tau;
                obj.frame = frame;
            end
        end
        
        function cartElemSet = convertToCartesianElementSet(obj)           
            cartElemSet = obj.convertToKeplerianElementSet().convertToCartesianElementSet();
        end
        
        function kepElemSet = convertToKeplerianElementSet(obj)
            gmu = obj.frame.getOriginBody().gm;
            
            sma = -gmu./obj.c3;
            ecc = abs(1 - obj.rP./sma);
            
            n = computeMeanMotion(sma, gmu);
            mean = obj.tau .* n;
            tru = computeTrueAnomFromMean(mean, ecc);
            
            kepElemSet = KeplerianElementSet(obj.time, sma, ecc, obj.inc, obj.raan, obj.arg, tru, obj.frame);
        end
        
        function geoElemSet = convertToGeographicElementSet(obj)
            geoElemSet = obj.convertToCartesianElementSet().convertToGeographicElementSet();
        end
        
        function univElemSet = convertToUniversalElementSet(obj)
            univElemSet = obj;
        end
        
        function elemVect = getElementVector(obj)
            elemVect = [obj.c3,obj.Rp,rad2deg(obj.inc),rad2deg(obj.raan),rad2deg(obj.arg),obj.tau];
        end
    end
    
    methods(Access=protected)
        function displayScalarObject(obj)
            fprintf('Universal State \n\tTime: %0.3f sec UT \n\tC3 Energy: %0.3f km^2/s^2 \n\tRp: %0.9f km \n\tInc: %0.3f deg \n\tRAAN: %0.3f deg \n\tArg Peri: %0.3f deg \n\tTime Past Peri.: %0.3f s \n\tFrame: %s\n', ...
                    obj.time, ...
                    obj.c3, ...
                    obj.Rp, ...
                    rad2deg(obj.inc), ...
                    rad2deg(obj.raan), ...
                    rad2deg(obj.arg), ...
                    obj.tau, ...
                    obj.frame.getNameStr());
        end        
    end
    
    methods(Static)
        function elemSet = getDefaultElements()
            elemSet = UniversalElementSet();
        end
        
        function errMsg = validateInputOrbit(errMsg, hC3, hRp, hInc, hRaan, hArg, hTau, bodyInfo, bndStr, checkElement)
            if(isempty(bndStr))
                bndStr = '';
            else
                bndStr = sprintf(' (%s Bound)', bndStr);
            end
            
            if(checkElement(2))
                Rp = str2double(get(hRp,'String'));
                enteredStr = get(hRp,'String');
                numberName = ['Radius of Periapsis', bndStr];
                lb = 0;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(Rp, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(1))
                c3 = str2double(get(hC3,'String'));
                enteredStr = get(hC3,'String');
                numberName = ['C3 Energy', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(c3, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(3))
                inc = str2double(get(hInc,'String'));
                enteredStr = get(hInc,'String');
                numberName = ['Inclination', bndStr];
                lb = 0;
                ub = 180;
                isInt = false;
                errMsg = validateNumber(inc, numberName, lb, ub, isInt, errMsg, enteredStr);
            end

            if(checkElement(4))
                raan = str2double(get(hRaan,'String'));
                enteredStr = get(hRaan,'String');
                numberName = ['Right Asc. of the Asc. Node', bndStr];
                lb = 0;
                ub = 360;
                isInt = false;
                errMsg = validateNumber(raan, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(5))
                arg = str2double(get(hArg,'String'));
                enteredStr = get(hArg,'String');
                numberName = ['Argument of Periapsis', bndStr];
                lb = 0;
                ub = 360;
                isInt = false;
                errMsg = validateNumber(arg, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(6))
                tru = str2double(get(hTau,'String'));
                enteredStr = get(hTau,'String');
                numberName = ['Time Past Periapsis', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(tru, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
        end
    end
end