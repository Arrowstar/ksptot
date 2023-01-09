classdef CartesianElementSet < AbstractElementSet
    %CartesianElementSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rVect%(3,1)% double %km
        vVect%(3,1)% double %km/s
        
        optVar CartesianElementSetVariable
    end
    
    properties(Constant)
        typeEnum = ElementSetEnum.CartesianElements;
    end
    
    methods
        function obj = CartesianElementSet(time, rVect, vVect, frame, createObjOfArray)
            arguments
                time = 0
                rVect = [0;0;0]
                vVect = [0;0;0]
                frame = AbstractReferenceFrame.empty(1,0);
                createObjOfArray(1,1) logical = false;
            end
            
            if(nargin > 0)
                if(createObjOfArray == false)
                    num = length(time);
                    if(num > 1)
                        obj(num) = obj;
                    end

                    if(numel(time) > 1)
                        obj(1) = CartesianElementSet();
                    end

                    bool = numel(frame) > 1;
                    for(i=1:num) %#ok<*NO4LP> 
                        obj(i).time = time(i);
                        obj(i).rVect = rVect(:,i);
                        obj(i).vVect = vVect(:,i);
                        obj(i).createObjOfArray = createObjOfArray;

                        if(bool)
                            obj(i).frame = frame(i);
                        end
                    end

                    if(numel(frame) == 1)
                        if(num > 1)
                            [obj.frame] = deal(frame);
                        else
                            obj.frame = frame;
                        end
                    end
                else
                    obj.time = time;
                    obj.rVect = rVect;
                    obj.vVect = vVect;
                    obj.frame = frame;
                    obj.createObjOfArray = createObjOfArray;
                end
            end
        end
        
        %vectorized
        function cartElemSet = convertToCartesianElementSet(obj)
            cartElemSet = obj;
        end
        
        %vectorized
        function kepElemSet = convertToKeplerianElementSet(obj)
%             gmu = obj.frame.getOriginBody().gm;
            gmu = NaN(length(obj), 1);
            for(i=1:length(obj))
                gmu(i) = obj(i).frame.getOriginBody().gm;
            end
            [sma, ecc, inc, raan, arg, tru] = getKeplerFromState([obj.rVect], [obj.vVect], gmu);
%             [sma, ecc, inc, raan, arg, tru] = vect_getKeplerFromState([obj.rVect], [obj.vVect], gmu);
            
%             kepElemSet = repmat(KeplerianElementSet.getDefaultElements(), size(obj));
            for(i=1:length(obj))
                kepElemSet(i) = KeplerianElementSet(obj(i).time, sma(i), ecc(i), inc(i), raan(i), arg(i), tru(i), obj(i).frame); %#ok<AGROW> 
            end
        end
        
        %vectorized
        function geoElemSet = convertToGeographicElementSet(obj)
            rVects = [obj.rVect];
            vVects = [obj.vVect];
            bodyInfos = getOriginBody([obj.frame]);
            
            rNorm = vecNormARH(rVects);
            
            long = AngleZero2Pi(atan2(rVects(2,:),rVects(1,:)));
            lat = pi/2 - acos(rVects(3,:)./rNorm);
            alt = rNorm - [bodyInfos.radius];
            
            vectorSez = rotVectToSEZCoords_mex(rVects, vVects);
            [velAz, velEl, velMag] = cart2sph(vectorSez(1,:), vectorSez(2,:), vectorSez(3,:));
            velAz = pi - velAz;
            
            geoElemSet = repmat(GeographicElementSet.getDefaultElements(), size(obj));
            for(i=1:length(obj))
                geoElemSet(i) = GeographicElementSet(obj(i).time, lat(i), long(i), alt(i), velAz(i), velEl(i), velMag(i), obj(i).frame);
            end
        end
        
        %vectorized
        function univElemSet = convertToUniversalElementSet(obj)
            univElemSet = convertToUniversalElementSet(convertToKeplerianElementSet(obj));
        end
        
        function txt = getDisplayText(obj, num)
            txt = {};
            txt{end+1} = ['Rx               = ', num2str(obj.rVect(1),num),  ' km'];
            txt{end+1} = ['Ry               = ', num2str(obj.rVect(2),num),  ' km'];
            txt{end+1} = ['Rz               = ', num2str(obj.rVect(3),num)   ' km'];
            txt{end+1} = ['Vx               = ', num2str(obj.vVect(1),num),  ' km/s'];
            txt{end+1} = ['Vy               = ', num2str(obj.vVect(2),num),  ' km/s'];
            txt{end+1} = ['Vz               = ', num2str(obj.vVect(3),num),  ' km/s'];
        end

        function rMag = getRadiusMagnitude(obj)
            rMag = vecNormARH(obj.rVect);
        end
        
        function vMag = getVelocityMagnitude(obj)
            vMag = vecNormARH(obj.vVect);
        end
        
        function [horzVel, vertVel] = getHorzVertVelocities(obj)
            vVectSez = rotVectToSEZCoords_mex(obj.rVect, obj.vVect);
            
            horzVel = sqrt(vVectSez(1)^2 + vVectSez(2)^2);
            vertVel = vVectSez(3);
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
            
%             if(all(checkElement(1:3)))
%                 if(norm([rx, ry, rz]) == 0)
%                     errMsg{end+1} = 'Length of the position vector (Rx, Ry, Rz) must be greater than zero.';
%                 end
%             end
%             
%             if(all(checkElement(4:6)))
%                 if(norm([vx, vy, vz]) == 0)
%                     errMsg{end+1} = 'Length of the velocity vector (Vx, Vy, Vz) must be greater than zero.';
%                 end
%             end
        end
    end
end