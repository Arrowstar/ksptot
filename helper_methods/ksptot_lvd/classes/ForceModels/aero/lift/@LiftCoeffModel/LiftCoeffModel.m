classdef LiftCoeffModel < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LiftCoeffModel Summary of this class goes here
    %   Detailed explanation goes here

    properties
        cylinderModel(1,:) CylindricalLiftModel 

        liftCoeffObj(1,:) AbstractLiftCoefficientModel = AbstractLiftCoefficientModel.empty(1,0);
    end

    methods
        function obj = LiftCoeffModel()
            obj.cylinderModel = CylindricalLiftModel(1, 1);

            obj.liftCoeffObj = obj.cylinderModel;
        end

        function [ClS, liftUnitVectInertial] = getLiftCoeffAndDir(obj, ut, rVect, vVect, bodyInfo, mass, altitude, pressure, density, vVectECEF, attState)
            arguments
                obj(1,1) LiftCoeffModel
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

            [ClS, liftUnitVectInertial] = obj.liftCoeffObj.getLiftCoeffAndDir(ut, rVect, vVect, bodyInfo, mass, altitude, pressure, density, vVectECEF, attState);
        end

        function useTf = openEditDialog(obj, lvdData)
            out = AppDesignerGUIOutput();
            lvd_EditLiftCoefficientModels_App(obj, lvdData, out);
            useTf = out.output{1};
        end
    end

    methods(Static)
        function obj = loadobj(obj)
            if(isempty(obj.cylinderModel))
                obj.cylinderModel = CylindricalLiftModel(1, 1);
            end

            if(isempty(obj.liftCoeffObj))
                obj.liftCoeffObj = obj.cylinderModel;
            end
        end
    end
end