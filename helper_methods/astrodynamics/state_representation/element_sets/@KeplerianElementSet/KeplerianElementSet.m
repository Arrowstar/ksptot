classdef KeplerianElementSet < AbstractElementSet
    %KeplerianElementSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sma(1,1) double = 1000; %km 
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
        
        function univElemSet = convertToUniversalElementSet(obj)
            gmu = obj.frame.getOriginBody().gm;
            
            c3 = -gmu./obj.sma;
            rP = (1-obj.ecc) .* obj.sma;
            
            n = computeMeanMotion(obj.sma, gmu);
            mean = computeMeanFromTrueAnom(obj.tru, obj.ecc);
            tau = mean ./ n;
            
            univElemSet = UniversalElementSet(obj.time, c3, rP, obj.inc, obj.raan, obj.arg, tau, obj.frame);
        end
        
        function elemVect = getElementVector(obj)
            elemVect = [obj.sma,obj.ecc,rad2deg(obj.inc),rad2deg(obj.raan),rad2deg(obj.arg),rad2deg(obj.tru)];
        end
        
        function mean = getMeanAnomaly(obj)
            [mean] = computeMeanFromTrueAnom(obj.tru, obj.ecc);
        end
        
        function meanMotion = getMeanMotion(obj)
            gmu = obj.frame.getOriginBody().gm;
            meanMotion = computeMeanMotion(obj.sma, gmu);
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
        
        function errMsg = validateInputOrbit(errMsg, hSMA, hEcc, hInc, hRaan, hArg, hTru, bodyInfo, bndStr, checkElement)
            if(isempty(bndStr))
                bndStr = '';
            else
                bndStr = sprintf(' (%s Bound)', bndStr);
            end
            
            if(checkElement(2) || checkElement(1))
                ecc = str2double(get(hEcc,'String'));
                enteredStr = get(hEcc,'String');
                numberName = ['Eccentricity', bndStr];
                lb = 0;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(ecc, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(1))
                sma = str2double(get(hSMA,'String'));
                enteredStr = get(hSMA,'String');
                numberName = ['Semi-major Axis', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(sma, numberName, lb, ub, isInt, errMsg, enteredStr);

                if(isempty(errMsg))
                    if(ecc < 1)
                        sma = str2double(get(hSMA,'String'));
                        enteredStr = get(hSMA,'String');
                        numberName = ['Semi-major Axis', bndStr];
                        lb = 1E-3;
                        ub = Inf;
                        isInt = false;
                        errMsg = validateNumber(sma, numberName, lb, ub, isInt, errMsg, enteredStr);
                    else
                        sma = str2double(get(hSMA,'String'));
                        enteredStr = get(hSMA,'String');
                        numberName = ['Semi-major Axis', bndStr];
                        lb = -Inf;
                        ub = -1E-3;
                        isInt = false;
                        errMsg = validateNumber(sma, numberName, lb, ub, isInt, errMsg, enteredStr);
                    end
                end
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
                tru = str2double(get(hTru,'String'));
                enteredStr = get(hTru,'String');
                numberName = ['True Anomaly', bndStr];
                lb = -360;
                ub = 360;
                isInt = false;
                errMsg = validateNumber(tru, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
        end
    end
end