classdef CartesianElementSet < AbstractElementSet
    %CartesianElementSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rVect(3,1)% double %km
        vVect(3,1)% double %km/s
        
        optVar CartesianElementSetVariable
    end
    
    properties(Constant)
        typeEnum = ElementSetEnum.CartesianElements;
    end
    
    methods
        function obj = CartesianElementSet(time, rVect, vVect, frame)
            if(nargin > 0)
                obj.time = time;
                obj.rVect = rVect;
                obj.vVect = vVect;
                obj.frame = frame;
            end
        end
        
        function cartElemSet = convertToCartesianElementSet(obj)
            cartElemSet = obj;
        end
        
        function kepElemSet = convertToKeplerianElementSet(obj)
            gmu = obj.frame.getOriginBody().gm;
            [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(obj.rVect, obj.vVect, gmu);
            
            kepElemSet = KeplerianElementSet(obj.time, sma, ecc, inc, raan, arg, tru, obj.frame);
        end
        
        function geoElemSet = convertToGeographicElementSet(obj)
            rNorm = norm(obj.rVect);
            
            long = AngleZero2Pi(atan2(obj.rVect(2),obj.rVect(1)));
            lat = pi/2 - acos(obj.rVect(3)/rNorm);
            alt = rNorm - obj.frame.getOriginBody().radius;
            
            vectorSez = rotVectToSEZCoords(obj.rVect, obj.vVect);
            [velAz, velEl, velMag] = cart2sph(vectorSez(1), vectorSez(2), vectorSez(3));
            velAz = pi - velAz;
            
            geoElemSet = GeographicElementSet(obj.time, lat, long, alt, velAz, velEl, velMag, obj.frame);
        end
        
        function univElemSet = convertToUniversalElementSet(obj)
            univElemSet = obj.convertToKeplerianElementSet().convertToUniversalElementSet();
        end
        
        function elemVect = getElementVector(obj)
            elemVect = [obj.rVect(1),obj.rVect(2),obj.rVect(3),obj.vVect(1),obj.vVect(2),obj.vVect(3)];
        end
    end
    
    methods(Access=protected)
        function displayScalarObject(obj)
            fprintf('Cartesian State \n\tTime: %0.3f sec UT \n\tPosition: [%0.3f, %0.3f, %0.3f] km \n\tVelocity: [%0.3f, %0.3f, %0.3f] km/s \n\tFrame: %s\n', ...
                    obj.time, ...
                    obj.rVect(1), obj.rVect(2), obj.rVect(3), ...
                    obj.vVect(1), obj.vVect(2), obj.vVect(3), ...
                    obj.frame.getNameStr());
        end        
    end
    
    methods(Static)
        function elemSet = getDefaultElements()
            elemSet = CartesianElementSet();
        end
        
        function errMsg = validateInputOrbit(errMsg, hRx, hRy, hRz, hVx, hVy, hVz, bodyInfo, bndStr, checkElement)
            if(isempty(bndStr))
                bndStr = '';
            else
                bndStr = sprintf(' (%s Bound)', bndStr);
            end
            
            if(checkElement(1))
                rx = str2double(get(hRx,'String'));
                enteredStr = get(hRx,'String');
                numberName = ['Rx', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(rx, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(2))
                ry = str2double(get(hRy,'String'));
                enteredStr = get(hRy,'String');
                numberName = ['Ry', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(ry, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(3))
                rz = str2double(get(hRz,'String'));
                enteredStr = get(hRz,'String');
                numberName = ['Rz', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(rz, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(4))
                vx = str2double(get(hVx,'String'));
                enteredStr = get(hVx,'String');
                numberName = ['Vx', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(vx, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(5))
                vy = str2double(get(hVy,'String'));
                enteredStr = get(hVy,'String');
                numberName = ['Vy', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(vy, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(checkElement(6))
                vz = str2double(get(hVz,'String'));
                enteredStr = get(hVz,'String');
                numberName = ['Vz', bndStr];
                lb = -Inf;
                ub = Inf;
                isInt = false;
                errMsg = validateNumber(vz, numberName, lb, ub, isInt, errMsg, enteredStr);
            end
            
            if(all(checkElement(1:3)))
                if(norm([rx, ry, rz]) == 0)
                    errMsg{end+1} = 'Length of the position vector (Rx, Ry, Rz) must be greater than zero.';
                end
            end
            
            if(all(checkElement(4:6)))
                if(norm([vx, vy, vz]) == 0)
                    errMsg{end+1} = 'Length of the velocity vector (Vx, Vy, Vz) must be greater than zero.';
                end
            end
        end
    end
end