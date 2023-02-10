classdef LaunchVehicleSolarRadPressState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleSolarRadPressState Summary of this class goes here
    %   Detailed explanation goes here

    properties
        srpSphericalModel(1,1) SphericalSolarRadiationPressureModel = SphericalSolarRadiationPressureModel();
        srpSolarSailModel(1,1) SolarSailSolarRadiationPressureModel = SolarSailSolarRadiationPressureModel();

        srpModelObj(1,1) AbstractSolarRadiationPressureModel = SphericalSolarRadiationPressureModel();
    end

    methods
        function obj = LaunchVehicleSolarRadPressState()
            obj.srpSphericalModel = SphericalSolarRadiationPressureModel();
            obj.srpSolarSailModel = SolarSailSolarRadiationPressureModel();

            obj.srpModelObj = obj.srpSphericalModel;
        end

        function fSR = getSolarRadiationForce(obj, ut, rVect, vVect, bodyInfo, steeringModel)
            arguments
                obj(1,1) LaunchVehicleSolarRadPressState
                ut(1,1) double
                rVect(3,1) double
                vVect(3,1) double
                bodyInfo(1,1) KSPTOT_BodyInfo
                steeringModel(1,1) AbstractSteeringModel
            end

            elemSet = CartesianElementSet(ut, rVect, vVect, bodyInfo.getBodyCenteredInertialFrame(), false);
            fSR = obj.srpModelObj.getSolarRadiationForce(elemSet, steeringModel);
        end

        function newSrpState = deepCopy(obj)
            newSrpState = obj.copy();
        end

        function tf = openEditDialog(obj, lvdData)
            arguments   
                obj(1,1) LaunchVehicleSolarRadPressState
                lvdData(1,1) LvdData
            end
            
            out = AppDesignerGUIOutput({false});
            lvd_EditSrpModels_App(obj, lvdData, out);
            tf = out.output{1};
        end
    end
end