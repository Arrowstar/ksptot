classdef(Abstract) AbstractSensor < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractSensor Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant, Abstract)
        typeEnum(1,1) SensorEnum 
    end
    
    methods
        [V,F] = getSensorMesh(obj, scElem, dcm, inFrame)
        
        boreDir = getSensorBoresightDirection(obj, sensorState, scElem, dcm, inFrame)
        
        sensorDcm = getSensorDcmToInertial(obj, sensorState, scElem, dcm, inFrame)
        
        origin = getOriginInFrame(obj, time, scElem, inFrame)
        
        tf = isVehDependent(obj, sensorState)
        
        listboxStr = getListboxStr(obj)
        
        color = getMeshColor(obj)
        
        alpha = getMeshAlpha(obj)
        
        tf = getDisplayMeshEdges(obj)
        
        name = getName(obj)
        
        tf = isInUse(obj, lvdData)
        
        openEditDialog(obj)
        
        state = getInitialState(obj)
        
        function [VTotal,FTotal] = getObscuringMesh(obj, sensorState, scElem, dcm, bodyInfos, inFrame)
            arguments
                obj(1,1) AbstractSensor
                sensorState(1,1) AbstractSensorState
                scElem(1,1) CartesianElementSet
                dcm(3,3) double
                bodyInfos KSPTOT_BodyInfo
                inFrame(1,1) AbstractReferenceFrame
            end
            
            time = scElem.time;
            sensorRange = sensorState.getSensorMaxRange();
            rVectSensorOrigin = obj.getOriginInFrame(time, scElem, inFrame);
            boreDir = obj.getSensorBoresightDirection(sensorState, time, scElem, dcm, inFrame);
            maxAngle = sensorState.getMaxAngle();
            
            FTotal = [];
            VTotal = [];
            for(i=1:length(bodyInfos))
                bodyInfo = bodyInfos(i);
                
                bIFrame = bodyInfo.getBodyCenteredInertialFrame();
                cartElem = CartesianElementSet(time, [0;0;0],[0;0;0], bIFrame);
                cartElem = cartElem.convertToFrame(inFrame);
                rVectBody = cartElem.rVect;
                bRadius = bodyInfo.radius;
                
                sc2BodyVect = rVectBody - rVectSensorOrigin;
                body2BoreAngle = dang(boreDir, sc2BodyVect);
                bodyAngularSize = atan(bRadius/norm(sc2BodyVect));
                
                [p2,r2,theta] = AbstractSensor.getTangentCirclePointAndRadius(rVectSensorOrigin, rVectBody, bRadius);
                
                if(body2BoreAngle - theta < maxAngle && norm(sc2BodyVect) <= sensorRange && norm(sc2BodyVect) > bRadius)
                    S = [rVectBody(:)', bRadius];
                    [sV, ~] = sphereMesh(S, 'nTheta', 16, 'nPhi', 16);
                    
                    v = sc2BodyVect / norm(sc2BodyVect);
                    
                    if(~isnan(theta) && ~isnan(r2) && ~any(isnan(p2)))
                        coneBodyPts = ConicalSensor.getCircleInSpace(v, p2, r2);
                        angleToUse = theta;
                    else
                        coneBodyPts = ConicalSensor.getCircleInSpace(v, rVectBody, bRadius);
                        angleToUse = bodyAngularSize;
                    end
                    
                    circleCnterPt = rVectBody + vect_normVector(sc2BodyVect)*1.1*sensorRange;
                    circleRadius = tan(angleToUse) * norm(circleCnterPt - rVectSensorOrigin);
                    coneProjPts = ConicalSensor.getCircleInSpace(v, circleCnterPt, circleRadius);
                    
                    cV = [coneBodyPts';
                        coneProjPts'];
                    
                    V = [cV; sV];
                    F = convhull([cV; sV]);
                    
                    [V, F] = meshVertexClustering(V,F, 0.001);
                    
                    if(not(isempty(FTotal)))
                        [VTotal,FTotal] = concatenateMeshes(VTotal,FTotal, V,F);
                    else
                        FTotal = F;
                        VTotal = V;
                    end
                end
            end
            
            if(not(isempty(VTotal)) && not(isempty(FTotal)))
                [VTotal, FTotal] = meshVertexClustering(VTotal, FTotal, 0.001);
            end
        end
        
        function [V,F, Vobs,Fobs] = getObscuredSensorMesh(obj, sensorState, scElem, dcm, bodyInfos, inFrame)
            arguments
                obj(1,1) AbstractSensor
                sensorState(1,1) AbstractSensorState
                scElem(1,1) CartesianElementSet
                dcm(3,3) double
                bodyInfos KSPTOT_BodyInfo
                inFrame(1,1) AbstractReferenceFrame
            end
            
            activeTf = sensorState.getSensorActiveState();
            if(activeTf)
                [Vobs,Fobs] = obj.getObscuringMesh(sensorState, scElem, dcm, bodyInfos, inFrame);
                [Vsens,Fsens] = obj.getSensorMesh(sensorState, scElem, dcm, inFrame);
                
                rVectSensorOrigin = obj.getOriginInFrame(scElem.time, scElem, inFrame);
                
                if(not(isempty(Vobs)) && not(isempty(Fobs)))
                    [V3,F3] = AbstractSensor.mesh_boolean_fallback(Vsens,Fsens,Vobs,Fobs,'minus');
                else
                    V3 = Vsens;
                    F3 = Fsens;
                end
                
%                 SENS.VL = Vsens;
%                 SENS.FL = Fsens;
%                 OBS.VL = Vobs;
%                 OBS.FL = Fobs;
%                 out = SGbool5('-',SENS,OBS);
%                 V3 = out.VL;
%                 F3 = out.FL;
                
                MESHES = splitMesh(V3, F3);
                
                indDel = [];
                for(i=1:length(MESHES))
                    mesh = MESHES(i);
                    if(height(mesh.vertices) < 4 || height(mesh.faces) < 1)
                        indDel(end+1) = i; %#ok<AGROW>
                    end
                end
                MESHES(indDel) = [];
                
                if(length(MESHES) > 1)
                    for(i=1:length(MESHES))
                        centroid = mean(MESHES(i).vertices,1);
                        dist(i) = norm(centroid - rVectSensorOrigin); %#ok<AGROW>
                    end
                    
                    [~,meshInd] = min(dist);
                    coneMesh = MESHES(meshInd);
                else
                    coneMesh = MESHES;
                end
                
                [V,F] = meshVertexClustering(coneMesh,0.001); %needed for helping to determine if point is in mesh
            else
                V = [];
                F = [];
            end
        end
        
        function [results, V, F] = evaluateSensorTargets(obj, sensorState, targets, scElem, dcm, bodyInfos, inFrame)
            arguments
                obj(1,1) AbstractSensor
                sensorState(1,1) AbstractSensorState
                targets(1,:) AbstractSensorTarget
                scElem(1,1) CartesianElementSet
                dcm(3,3) double
                bodyInfos KSPTOT_BodyInfo
                inFrame(1,1) AbstractReferenceFrame
            end
            
            inertialFrame = inFrame.getOriginBody().getBodyCenteredInertialFrame();
            
            time = scElem.time;
            [V,F] = obj.getObscuredSensorMesh(sensorState, scElem, dcm, bodyInfos, inertialFrame);
            
            allRVects = [];
            targetColInds = [];
            for(i=1:length(targets))
                target = targets(i);
                rVects = target.getTargetPositions(time, scElem, inertialFrame);
                
                allRVects = vertcat(allRVects, rVects'); %#ok<AGROW>
                targetColInds = vertcat(targetColInds, i*ones(size(rVects,2), 1)); %#ok<AGROW>
            end
            
            if(isempty(allRVects))
                bool = false(0);
            else 
                if(isempty(V) || isempty(F))
                    bool = false(height(allRVects),1);
                else
                    bool = in_polyhedron(F,V,allRVects);
                end
            end
            
            rVectSensorOrigin = obj.getOriginInFrame(time, scElem, inertialFrame);
            
            results = SensorTargetResults.empty(1,0);
            for(i=1:length(targets))
                target = targets(i);
                
                inds = targetColInds == i;
                subBool = bool(inds);
                subRVects = allRVects(inds, :);
                
                results(i) = SensorTargetResults(obj, target, time, rVectSensorOrigin, subBool, subRVects, inertialFrame);
            end
            
            sensorMeshPts = V';
            sensorPtsCartElem = CartesianElementSet(repmat(time, 1, width(sensorMeshPts)), sensorMeshPts, zeros(size(sensorMeshPts)), inertialFrame, true);
            sensorPtsCartElem = sensorPtsCartElem.convertToFrame(inFrame);
            V = [sensorPtsCartElem.rVect]';
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
        end
        
        function tf = usesGeometricAngle(obj, angle)
            tf = false;
        end
        
        function tf = usesGeometricPlane(obj, plane)
            tf = false;
        end
    end
    
    methods(Sealed)
        function tf = eq(A,B)
            tf = eq@handle(A,B);
        end
    end
    
    methods(Static, Access=protected)
        function circlePts = getCircleInSpace(normDir, circleCnterPt, circleRadius)
            arguments
                normDir(3,1) double
                circleCnterPt(3,1) double
                circleRadius(1,1) double
            end
            
%             if(abs(dang(normDir,[0;0;1])) < deg2rad(10) || abs(dang(normDir,[0;0;1])) > deg2rad(170))
%                 borePlaneV0 = [0;1;0];
%             else
%                 borePlaneV0 = [0;0;1];
%             end
%             
%             borePlaneV1 = cross(normDir,borePlaneV0);
%             borePlaneV2 = cross(normDir,borePlaneV1);
%             
%             numAngles = 25;
%             theta = linspace(0,2*pi,numAngles);
%             
%             circlePts = circleCnterPt + circleRadius*borePlaneV1*cos(theta) + circleRadius*borePlaneV2*sin(theta);

            numAngles = 25;
            theta = linspace(0,2*pi,numAngles);

            circlePts = circleRadius*[1;0;0]*cos(theta) + circleRadius*[0;1;0]*sin(theta);
            r = vrrotvec([0;0;1], normDir);
            M = vrrotvec2mat(r);
            
            circlePts = M*circlePts + circleCnterPt;
        end
        
        function [W,H] = mesh_boolean_fallback(V,F,U,G,operation)
            try
                [W,H] = mesh_boolean(V,F, U,G, operation);
            catch  %if the mex file doesn't work
                [W,H] = mesh_boolean_winding_number(V,F, U,G, operation);
            end
            
            if(height(W)<4 && height(H)<4)
                [W,H] = mesh_boolean_winding_number(V,F, U,G, operation);
            end
        end
        
        function [p2,r2,theta] = getTangentCirclePointAndRadius(offPoint, sphereCenter, r)
            d0 = norm(sphereCenter - offPoint);
            point = [-d0;0;0];
            circleCenter = [0;0;0];
            
            p1 = (r^2/d0^2)*point(1:2) + (r/d0^2)*sqrt(d0^2 - r^2)*[-point(2);point(1)];
            p1 = [p1;0];
            
            v1 = vect_normVector(circleCenter - point);
            v2 = vect_normVector(p1 - point);
            theta = dang(v1,v2);
            
            d1 = norm(p1 - point);
            d2 = d1*cos(theta);
            r2 = d1 * sin(theta);
            
            v1 = vect_normVector(sphereCenter - offPoint);
            p2 = offPoint + v1*d2;
        end
    end
end