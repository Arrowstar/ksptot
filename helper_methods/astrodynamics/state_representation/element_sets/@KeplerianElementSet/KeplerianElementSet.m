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
        
        %vectorized
        function cartElemSet = convertToCartesianElementSet(obj)
            gmu = NaN(length(obj), 1);
            for(i=1:length(obj))
                gmu(i) = obj(i).frame.getOriginBody().gm;
            end

            [rVect, vVect] = vect_getStatefromKepler([obj.sma], [obj.ecc], [obj.inc], [obj.raan], [obj.arg], [obj.tru], gmu);

            obj = obj(:)';
            cartElemSet = CartesianElementSet([obj.time], rVect, vVect, [obj.frame]);
        end
        
        %vectorized
        function kepElemSet = convertToKeplerianElementSet(obj)
            kepElemSet = obj;
        end
        
        %vectorized
        function geoElemSet = convertToGeographicElementSet(obj)
            geoElemSet = convertToGeographicElementSet(convertToCartesianElementSet(obj));
        end
        
        %vectorized
        function univElemSet = convertToUniversalElementSet(obj)
            gmu = NaN(length(obj), 1);
            for(i=1:length(obj))
                gmu(i) = obj(i).frame.getOriginBody().gm;
            end
            
            c3 = -gmu./[obj.sma];
            rP = (1-[obj.ecc]) .* [obj.sma];
            
            n = computeMeanMotion([obj.sma], gmu);             
            mean = computeMeanFromTrueAnom([obj.tru], [obj.ecc]);
            tau = mean ./ n;
            
            univElemSet = repmat(UniversalElementSet.getDefaultElements(), size(obj));
            for(i=1:length(obj))
                univElemSet(i) = UniversalElementSet(obj(i).time, c3(i), rP(i), obj(i).inc, obj(i).raan, obj(i).arg, tau(i), obj(i).frame);
            end
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
        
        function period = getPeriod(obj)
            period = computePeriod(obj.sma, obj.getOriginBodyGM());
        end
        
        function rPe = getRadiusPeriapsis(obj)
            [~, rPe] = computeApogeePerigee(obj.sma, obj.ecc);
        end
        
        function rAp = getRadiusApoapsis(obj)
            [rAp, ~] = computeApogeePerigee(obj.sma, obj.ecc);
        end
        
        function altPe = getAltitudePeriapsis(obj)
            rPe = obj.getRadiusPeriapsis();
            altPe = rPe - obj.frame.getOriginBody().radius;
        end
        
        function altApo = getAltitudeApoapsis(obj)
            rAp = obj.getRadiusApoapsis();
            altApo = rAp - obj.frame.getOriginBody().radius;
        end
        
        function fpa = getFlightPathAngle(obj)
            [~, ~, fpa] = computeRVFpaFromSmaEccTru(obj.sma, obj.ecc, obj.tru, obj.getOriginBodyGM());            
        end
        
        function driftRate = getLongDriftRate(obj)
            driftRate = computeDriftRate(obj.sma, obj.frame.getOriginBody()); %rad/s
        end
        
        function [h1, k1, h2, k2] = getEquinoctialElements(obj)
            h1 = obj.ecc .* cos(obj.arg + obj.raan); %http://www.cdeagle.com/pdf/mee.pdf
            k1 = obj.ecc .* sin(obj.arg + obj.raan); %http://www.cdeagle.com/pdf/mee.pdf
            h2 = tan(obj.inc/2) .* cos(obj.raan);    %http://www.cdeagle.com/pdf/mee.pdf
            k2 = tan(obj.inc/2) .* sin(obj.raan);    %http://www.cdeagle.com/pdf/mee.pdf            
        end
        
        function [xUnitVectElem, yUnitVectElem, zUnitVectElem, vInfRA, vInfDec, hyperbolicVelMag] = getOutboundHyperbolicVelocityElements(obj)
            gmu = obj.getOriginBodyGM();
            
            [~, OUnitVector] = computeHyperSVectOVect(obj.sma, obj.ecc, obj.inc, obj.raan, obj.arg, obj.tru, gmu);
            [vInfRA,vInfDec,~] = cart2sph(OUnitVector(1),OUnitVector(2),OUnitVector(3));
            vInfRA = rad2deg(AngleZero2Pi(vInfRA));
            vInfDec = rad2deg(vInfDec);
            
            xUnitVectElem = OUnitVector(1);
            yUnitVectElem = OUnitVector(2);
            zUnitVectElem = OUnitVector(3);
            hyperbolicVelMag = sqrt(-gmu/obj.sma);
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
                lb = -360;
                ub = 360;
                isInt = false;
                errMsg = validateNumber(raan, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(5))
                arg = str2double(get(hArg,'String'));
                enteredStr = get(hArg,'String');
                numberName = ['Argument of Periapsis', bndStr];
                lb = -360;
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