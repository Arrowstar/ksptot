classdef CR3BPOrbitStateModel < AbstractOrbitStateModel
    %CR3BPOrbitStateModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        x(1,1) double
        y(1,1) double
        z(1,1) double
        
        vx(1,1) double
        vy(1,1) double
        vz(1,1) double
        
        celBodyData
        
        optVar CR3BPOrbitVariable
    end

    methods
        function obj = CR3BPOrbitStateModel(x, y, z, vx, vy, vz)
            obj.x = x;
            obj.y = y;
            obj.z = z;
            obj.vx = vx;
            obj.vy = vy;
            obj.vz = vz;
        end
        
        function [rVectECI, vVectECI] = getPositionAndVelocityVector(obj, ut, secBodyInfo)
            rVectCR3BP = [obj.x; obj.y; obj.z];
            vVectCR3BP = [obj.vx;obj.vy;obj.vz];
            
            [rVectECI, vVectECI] = getECIVectFromCR3BPVect(ut, rVectCR3BP, vVectCR3BP, secBodyInfo, obj.celBodyData);
        end
        
        function elemVect = getElementVector(obj)
            elemVect = [obj.x, obj.y, obj.z, obj.vx, obj.vy, obj.vz];
        end
    end
    
    methods(Static)
        function defaultOrbitState = getDefaultOrbitState()
            defaultOrbitState = CR3BPOrbitStateModel(0, 0, 0, 0, 0, 0);
        end
        
        function errMsg = validateInputOrbit(errMsg, hX, hY, hZ, hVx, hVy, hVz, secBodyInfo, bndStr, checkElement)
            if(isempty(bndStr))
                bndStr = '';
            else
                bndStr = sprintf(' (%s Bound)', bndStr);
            end
            
            if(checkElement(1))
                lat = str2double(get(hX,'String'));
                enteredStr = get(hX,'String');
                numberName = ['CR3BP Position (X)', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(lat, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(2))
                long = str2double(get(hY,'String'));
                enteredStr = get(hY,'String');
                numberName = ['CR3BP Position (Y)', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(long, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(3))
                alt = str2double(get(hZ,'String'));
                enteredStr = get(hZ,'String');
                numberName = ['CR3BP Position (Z)', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(alt, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(4))
                bfVx = str2double(get(hVx,'String'));
                enteredStr = get(hVx,'String');
                numberName = ['CR3BP Velocity (X)', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(bfVx, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(5))
                bfVy = str2double(get(hVy,'String'));
                enteredStr = get(hVy,'String');
                numberName = ['CR3BP Velocity (Y)', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(bfVy, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(6))
                bfVz = str2double(get(hVz,'String'));
                enteredStr = get(hVz,'String');
                numberName = ['CR3BP Velocity (Z)', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(bfVz, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
        end
    end
end