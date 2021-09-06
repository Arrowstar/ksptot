classdef ConicalSensor < matlab.mixin.SetGet
    %ConicalSensor Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        angle(1,1) double = deg2rad(10) %rad
        range(1,1) double = 1000;       %km
    end
    
    methods
        function obj = ConicalSensor(angle, range)
            obj.angle = angle;
            obj.range = range;
        end
        
        function [VTotal,FTotal] = getObscuringMesh(obj, scElem, bodyInfos, inFrame)
            time = scElem.time;
            rVectSc = scElem.rVect;
            boreDir = obj.getSensorBoresightDirection();
              
            FTotal = [];
            VTotal = [];
            for(i=1:length(bodyInfos))
                bodyInfo = bodyInfos(i);
                
                bIFrame = bodyInfo.getBodyCenteredInertialFrame();
                cartElem = CartesianElementSet(time, [0;0;0],[0;0;0], bIFrame);
                cartElem = cartElem.convertToFrame(inFrame);
                rVectBody = cartElem.rVect;
                bRadius = bodyInfo.radius;
                
                sc2BodyVect = rVectBody - rVectSc;
                body2BoreAngle = dang(boreDir, sc2BodyVect);
                bodyAngularSize = atan(bRadius/norm(sc2BodyVect));

                if(body2BoreAngle - bodyAngularSize < obj.angle && norm(sc2BodyVect) < obj.range)
                    S = [rVectBody(:)', bRadius];                
                    [sV, sF] = sphereMesh(S, 'nTheta', 32, 'nPhi', 32);
%                     sF = convhull(sV);
                    sF = triangulateFaces(sF);

                    v = sc2BodyVect / norm(sc2BodyVect);
                    coneBodyPts = ConicalSensor.getCircleInSpace(v, rVectBody, bRadius);
                    
                    circleCnterPt = rVectBody + vect_normVector(sc2BodyVect)*1.1*obj.range;
                    circleRadius = tan(bodyAngularSize) * norm(circleCnterPt - rVectSc);
                    coneProjPts = ConicalSensor.getCircleInSpace(v, circleCnterPt, circleRadius);
                    
                    cV = [coneBodyPts';
                          coneProjPts'];
                    cF = convhull(cV);

                    [V,~] = concatenateMeshes(sV,sF,cV,cF);
                    F = convhull(V);

                    if(not(isempty(FTotal)))
                        [VTotal,FTotal] = concatenateMeshes(VTotal,FTotal, V,F);
                    else
                        FTotal = F;
                        VTotal = V;
                    end
                end
            end
        end
        
        function [V,F] = getSensorMesh(obj, scElem)
            sensorRange = obj.range;
            
            rVectSc = scElem.rVect;
            boreDir = obj.getSensorBoresightDirection(); 

            sensorOutlineCenter = rVectSc + sensorRange*boreDir;
            sensorRadius = obj.range*(sin(obj.angle) / sin(pi/2 - obj.angle));
            sensorOutlinePtsRaw = ConicalSensor.getCircleInSpace(boreDir, sensorOutlineCenter, sensorRadius);
            
            V = vertcat(rVectSc(:)', sensorOutlinePtsRaw');
            F = convhull(V);
        end
        
        function boreDir = getSensorBoresightDirection(obj)
%             dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect, bodyInfo) %AbstractSteeringModel
%             [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsWrtInertialOrigin(obj, time, vehElemSet) %AbstractReferenceFrame
            
            boreDir = vect_normVector([7.65;1;0]);
        end
        
        function [V,F, Vobs,Fobs] = getObscuredSensorMesh(obj, scElem, bodyInfos, inFrame)
            [Vobs,Fobs] = obj.getObscuringMesh(scElem, bodyInfos, inFrame);
            [Vsens,Fsens] = obj.getSensorMesh(scElem);
            
            rVectSc = scElem.rVect;
            
            [V3,F3] = mesh_boolean(Vsens,Fsens,Vobs,Fobs,'minus');
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
    end
    
    methods(Static)
        function circlePts = getCircleInSpace(normDir, circleCnterPt, circleRadius)
            if(abs(dang(normDir,[0;0;1])) < deg2rad(1))
                borePlaneV0 = [0;1;0];
            else
                borePlaneV0 = [0;0;1];
            end
            
            borePlaneV1 = cross(normDir,borePlaneV0);
            borePlaneV2 = cross(normDir,borePlaneV1);
            
            numAngles = 50;
            theta = linspace(0,2*pi,numAngles);
            
            circlePts = circleCnterPt + circleRadius*borePlaneV1*cos(theta) + circleRadius*borePlaneV2*sin(theta);
        end
    end
end