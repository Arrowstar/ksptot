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
        
        optVar KeplerianOrbitVariable
    end
    
    methods
        function obj = KeplerianOrbitStateModel(sma, ecc, inc, raan, arg, tru)
            obj.sma = sma;
            obj.ecc = ecc;
            obj.inc = deg2rad(inc);
            obj.raan = deg2rad(raan);
            obj.arg = deg2rad(arg);
            obj.tru = deg2rad(tru);
        end
        
        function [rVect, vVect] = getPositionAndVelocityVector(obj, ~, bodyInfo)
            [rVect,vVect] = getStatefromKepler(obj.sma, obj.ecc, obj.inc, obj.raan, obj.arg, obj.tru, bodyInfo.gm);
        end
        
        function elemVect = getElementVector(obj)
            elemVect = [obj.sma,obj.ecc,rad2deg(obj.inc),rad2deg(obj.raan),rad2deg(obj.arg),rad2deg(obj.tru)];
        end
    end
    
    methods(Static)
        function defaultOrbitState = getDefaultOrbitState()
            defaultOrbitState = KeplerianOrbitStateModel(700, 0, 0, 0, 0, 0);
        end
        
        function errMsg = validateInputOrbit(errMsg, hSMA, hEcc, hInc, hRaan, hArg, hTru, bodyInfo, bndStr)
            if(isempty(bndStr))
                bndStr = '';
            else
                bndStr = sprintf(' (%s Bound)', bndStr);
            end
            
            sma = str2double(get(hSMA,'String'));
            enteredStr = get(hSMA,'String');
            numberName = ['Semi-major Axis', bndStr];
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(sma, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            ecc = str2double(get(hEcc,'String'));
            enteredStr = get(hEcc,'String');
            numberName = ['Eccentricity', bndStr];
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(ecc, numberName, lb, ub, isInt, errMsg, enteredStr);
            
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
            
            inc = str2double(get(hInc,'String'));
            enteredStr = get(hInc,'String');
            numberName = ['Inclination', bndStr];
            lb = 0;
            ub = 180;
            isInt = false;
            errMsg = validateNumber(inc, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            raan = str2double(get(hRaan,'String'));
            enteredStr = get(hRaan,'String');
            numberName = ['Right Asc. of the Asc. Node', bndStr];
            lb = 0;
            ub = 360;
            isInt = false;
            errMsg = validateNumber(raan, numberName, lb, ub, isInt, errMsg, enteredStr);
            
            arg = str2double(get(hArg,'String'));
            enteredStr = get(hArg,'String');
            numberName = ['Argument of Periapsis', bndStr];
            lb = 0;
            ub = 360;
            isInt = false;
            errMsg = validateNumber(arg, numberName, lb, ub, isInt, errMsg, enteredStr);
            
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