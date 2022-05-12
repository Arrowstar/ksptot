classdef CylindricalLiftModel < AbstractLiftCoefficientModel
    %CylindricalLiftModel Summary of this class goes here
    %   Detailed explanation goes here

    properties
        cylinderLength(1,1) double = 1; %m
        cylinderRadius(1,1) double = 1; %m

        liftCurves(1,1) LiftCoefficientCurves = LiftCoefficientCurves();
    end

    properties(Constant)
        enum = LiftCoefficientModelEnum.KSPCylinder;
    end

    methods
        function obj = CylindricalLiftModel(cylinderLength, cylinderRadius)
            obj.cylinderLength = cylinderLength;
            obj.cylinderRadius = cylinderRadius;

            obj.liftCurves = LiftCoefficientCurves();
        end

        function [ClS, liftUnitVectInertial] = getLiftCoeffAndDir(obj, ut, rVect, vVect, bodyInfo, mass, altitude, pressure, density, vVectECEF, attState)
            arguments
                obj(1,1) CylindricalLiftModel
                ut(1,1) double 
                rVect(3,1) double 
                vVect(3,1) double 
                bodyInfo(1,1) KSPTOT_BodyInfo
                mass(1,1) double
                altitude(1,1) double
                pressure(1,1) double
                density(1,1) double
                vVectECEF(3,1) double
                attState(1,1) LaunchVehicleAttitudeState
            end    

            [~,aoa,sideslip,totalAoA] = attState.getAeroAngles(ut, rVect, vVect, bodyInfo);
            
            vVectECEFMag = norm(vVectECEF);
            pressurePa = pressure*1000;
            speedSound = sqrt(1.4 * pressurePa / density); %m/s
            speedMS = vVectECEFMag*1000;                   %m/s
            thisMachNum = speedMS / speedSound;

            area = obj.getIncidentArea(totalAoA);
            
            ClS = obj.liftCurves.bodyLiftGiLift(sin(totalAoA))*obj.liftCurves.bodyLiftMachCurve(thisMachNum)*area;
%             disp(ClS);

            bodyXInertial = attState.bodyX;
            bff = bodyInfo.getBodyFixedFrame();
%             [~, ~, ~, rotMatToInertial] = bff.getOffsetsWrtInertialOrigin(ut, []);
            rotMatToInertial = bff.getRotMatToInertialAtTime(ut, [], []);
            rotMatInertialToECEF = rotMatToInertial';
            bodyXECEF = rotMatInertialToECEF*bodyXInertial;

            v1 = crossARH(vVectECEF, bodyXECEF);
            liftUnitVectECEF = normVector(crossARH(v1, bodyXECEF));
            liftUnitVectInertial = rotMatToInertial * liftUnitVectECEF;

            if(abs(ut - 21673513) < 1)
                a = 1;
            end
        end

        function useTf = openEditDialog(obj, lvdData)
            out = AppDesignerGUIOutput({false});
            lvd_EditKSPCylinderLiftPropertiesGUI_App(obj, lvdData, out);
            useTf = out.output{1};
        end
    end

    methods(Access=private)
        function area = getIncidentArea(obj, totalAoA)
            flatPlateArea = obj.cylinderLength*(2*obj.cylinderRadius);
            circleArea = pi*obj.cylinderRadius^2;

            area = cos(totalAoA)*circleArea + sin(totalAoA)*flatPlateArea;
        end
    end
end