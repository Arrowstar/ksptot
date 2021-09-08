classdef(Abstract) AbstractSensor < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %AbstractSensor Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        [V,F] = getSensorMesh(obj, scElem, dcm, inFrame)
        
        boreDir = getSensorBoresightDirection(obj, scElem, dcm, inFrame)
        
        maxRange = getMaximumRange(obj)
        
        origin = getOriginInFrame(obj, time, scElem, inFrame)
        
        listboxStr = getListboxStr(obj)
        
        color = getMeshColor(obj)
        
        alpha = getMeshAlpha(obj)
        
        name = getName(obj)
        
        tf = isInUse(obj, lvdData)
        
        openEditDialog(obj)
        
        function [VTotal,FTotal] = getObscuringMesh(obj, scElem, dcm, bodyInfos, inFrame)
            arguments
                obj(1,1) AbstractSensor
                scElem(1,1) CartesianElementSet 
                dcm
                bodyInfos KSPTOT_BodyInfo
                inFrame(1,1) AbstractReferenceFrame
            end
            
            time = scElem.time;
            rVectSensorOrigin = obj.getOriginInFrame(time, scElem, inFrame);
            boreDir = obj.getSensorBoresightDirection(time, scElem, dcm, inFrame);
              
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

                if(body2BoreAngle - bodyAngularSize < obj.angle && norm(sc2BodyVect) < obj.getMaximumRange())
                    S = [rVectBody(:)', bRadius];                
                    [sV, sF] = sphereMesh(S, 'nTheta', 16, 'nPhi', 16);
%                     sF = triangulateFaces(sF);

                    v = sc2BodyVect / norm(sc2BodyVect);
                    coneBodyPts = ConicalSensor.getCircleInSpace(v, rVectBody, bRadius);
                    
                    circleCnterPt = rVectBody + vect_normVector(sc2BodyVect)*1.1*obj.getMaximumRange();
                    circleRadius = tan(bodyAngularSize) * norm(circleCnterPt - rVectSensorOrigin);
                    coneProjPts = ConicalSensor.getCircleInSpace(v, circleCnterPt, circleRadius);
                    
                    cV = [coneBodyPts';
                          coneProjPts'];
%                     cF = convhull(cV);

%                     [V,~] = concatenateMeshes(sV,sF,cV,cF);
                    V = [cV; sV];
                    F = convhull([cV; sV]);

                    if(not(isempty(FTotal)))
                        [VTotal,FTotal] = concatenateMeshes(VTotal,FTotal, V,F);
                    else
                        FTotal = F;
                        VTotal = V;
                    end
                end
            end
        end

        function [V,F, Vobs,Fobs] = getObscuredSensorMesh(obj, scElem, dcm, bodyInfos, inFrame)
            arguments
                obj(1,1) AbstractSensor
                scElem(1,1) CartesianElementSet
                dcm
                bodyInfos KSPTOT_BodyInfo
                inFrame(1,1) AbstractReferenceFrame
            end
            
            [Vobs,Fobs] = obj.getObscuringMesh(scElem, dcm, bodyInfos, inFrame);
            [Vsens,Fsens] = obj.getSensorMesh(scElem, dcm, inFrame);
            
            rVectSc = scElem.rVect;
            
            [V3,F3] = AbstractSensor.mesh_boolean_fallback(Vsens,Fsens,Vobs,Fobs,'minus');
            
%             SENS.VL = Vsens;
%             SENS.FL = Fsens;
%             OBS.VL = Vobs;
%             OBS.FL = Fobs;
%             out = SGbool5('-',SENS,OBS);
%             V3 = out.VL;
%             F3 = out.FL;
            
            MESHES = splitMesh(V3, F3);

            if(length(MESHES) > 1)
                for(i=1:length(MESHES))
                    centroid = mean(MESHES(i).vertices,1);
                    dist(i) = norm(centroid - rVectSc); %#ok<AGROW>
                end

                [~,meshInd] = min(dist);
                coneMesh = MESHES(meshInd);
            else
                coneMesh = MESHES;
            end
            
            [V,F] = meshVertexClustering(coneMesh,0.1);
        end
        
        function [results, V, F] = evaluateSensorTargets(obj, targets, scElem, dcm, bodyInfos, inFrame)
            arguments
                obj(1,1) AbstractSensor
                targets(1,:) AbstractSensorTarget
                scElem(1,1) CartesianElementSet
                dcm
                bodyInfos KSPTOT_BodyInfo
                inFrame(1,1) AbstractReferenceFrame
            end
            
            time = scElem.time;
            [V,F] = obj.getObscuredSensorMesh(scElem, dcm, bodyInfos, inFrame);
            
            allRVects = [];
            targetColInds = [];
            for(i=1:length(targets))
                target = targets(i);
                rVects = target.getTargetPositions(time, scElem, inFrame);
                
                allRVects = vertcat(allRVects, rVects'); %#ok<AGROW>
                targetColInds = vertcat(targetColInds, i*ones(size(rVects,2), 1)); %#ok<AGROW>
            end
            
            if(isempty(allRVects))
                bool = false(0);
            else
                bool = vect_isPointInMesh(allRVects, V, F);
            end
            
            results = SensorTargetResults.empty(1,0);
            for(i=1:length(targets))
                target = targets(i);
                
                inds = targetColInds == i;
                subBool = bool(inds);
                subRVects = allRVects(inds, :);
                
                results(i) = SensorTargetResults(obj, target, time, subBool, subRVects, inFrame);
            end
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
    
    methods(Static, Access=protected)
        function circlePts = getCircleInSpace(normDir, circleCnterPt, circleRadius)
            arguments
                normDir(3,1) double
                circleCnterPt(3,1) double
                circleRadius(1,1) double
            end
            
            if(abs(dang(normDir,[0;0;1])) < deg2rad(1))
                borePlaneV0 = [0;1;0];
            else
                borePlaneV0 = [0;0;1];
            end
            
            borePlaneV1 = cross(normDir,borePlaneV0);
            borePlaneV2 = cross(normDir,borePlaneV1);
            
            numAngles = 25;
            theta = linspace(0,2*pi,numAngles);
            
            circlePts = circleCnterPt + circleRadius*borePlaneV1*cos(theta) + circleRadius*borePlaneV2*sin(theta);
        end
        
        function [W,H] = mesh_boolean_fallback(V,F,U,G,operation)
            try
                [W,H] = mesh_boolean(V,F, U,G, operation);
            catch %if the mex file doesn't work
                [W,H] = mesh_boolean_winding_number(V,F, U,G, operation);    
            end
        end
    end
end