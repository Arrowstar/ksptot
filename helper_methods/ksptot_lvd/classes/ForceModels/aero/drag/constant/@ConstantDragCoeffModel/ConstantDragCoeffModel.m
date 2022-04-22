classdef ConstantDragCoeffModel < AbstractDragCoefficientModel
    %ConstantDragCoeffModel Summary of this class goes here
    %   Detailed explanation goes here

    properties
        CdA(1,1) double
    end

    properties(Constant)
        enum = DragCoefficientModelEnum.Constant
    end

    methods
        function obj = ConstantDragCoeffModel(CdA)
            obj.CdA = CdA;
        end

        function CdA = getDragCoeff(obj, ut, rVect, vVect, bodyInfo, mass, altitude, vVectECEFMag, aoa)
            arguments
                obj(1,1) ConstantDragCoeffModel
                ut(1,1) double 
                rVect(3,1) double 
                vVect(3,1) double 
                bodyInfo(1,1) KSPTOT_BodyInfo
                mass(1,1) double
                altitude(1,1) double
                vVectECEFMag(1,1) double
                aoa(1,1) double = 0;  %this is not implemented yet
            end

            CdA = obj.CdA;
        end

        function tf = usesAoA(obj)
            tf = false;
        end

        function useTf = openEditDialog(obj, lvdData)
            out = AppDesignerGUIOutput({false});
            lvd_EditConstDragPropertiesGUI_App(obj, lvdData, out);
            useTf = out.output{1};
        end
    end
end