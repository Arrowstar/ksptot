classdef DragCoeffModel < matlab.mixin.SetGet & matlab.mixin.Copyable
    %DragCoeffModel Summary of this class goes here
    %   Detailed explanation goes here

    properties
        constDragModel(1,:) ConstantDragCoeffModel
        oneDDragModel(1,:) OneDimDragCoefficientModel
        twoDimWindTunnelDragModel(1,:) TwoDimKspWindTunnelDragCoeffModel
        threeDimWindTunnelDragModel(1,:) ThreeDimKspWindTunnelDragCoeffModel

        dragCoeffObj(1,:) AbstractDragCoefficientModel = AbstractDragCoefficientModel.empty(1,0);
    end

    methods
        function obj = DragCoeffModel()
            obj.constDragModel = ConstantDragCoeffModel(1);
            obj.oneDDragModel = OneDimDragCoefficientModel();
            obj.twoDimWindTunnelDragModel = TwoDimKspWindTunnelDragCoeffModel('');
            obj.threeDimWindTunnelDragModel = ThreeDimKspWindTunnelDragCoeffModel.createDefault();

            obj.dragCoeffObj = obj.oneDDragModel;
        end

        function CdA = getDragCoeff(obj, ut, rVect, vVect, bodyInfo, mass, altitude, vVectECEFMag, aoa)
            arguments
                obj(1,1) DragCoeffModel
                ut(1,1) double 
                rVect(3,1) double 
                vVect(3,1) double 
                bodyInfo(1,1) KSPTOT_BodyInfo
                mass(1,1) double
                altitude(1,1) double
                vVectECEFMag(1,1) double
                aoa(1,1) double = 0;  %this is not implemented yet
            end

            CdA = obj.dragCoeffObj.getDragCoeff(ut, rVect, vVect, bodyInfo, mass, altitude, vVectECEFMag, aoa);
        end

        function tf = usesAoA(obj)
            tf = obj.dragCoeffObj.usesAoA();
        end

        function useTf = openEditDialog(obj, lvdData)
            out = AppDesignerGUIOutput();
            lvd_EditDragCoefficientModels_App(obj, lvdData, out);
            useTf = out.output{1};
        end
    end

    methods(Static)
        function obj = loadobj(obj)
            if(isempty(obj.constDragModel))
                obj.constDragModel = ConstantDragCoeffModel(1);
            end

            if(isempty(obj.oneDDragModel))
                obj.oneDDragModel = OneDimDragCoefficientModel();
            end

            if(isempty(obj.twoDimWindTunnelDragModel))
                obj.twoDimWindTunnelDragModel = TwoDimKspWindTunnelDragCoeffModel('');
            end

            if(isempty(obj.threeDimWindTunnelDragModel))
                obj.threeDimWindTunnelDragModel = ThreeDimKspWindTunnelDragCoeffModel.createDefault();
            end

            if(isempty(obj.dragCoeffObj))
                obj.dragCoeffObj = obj.oneDDragModel;
            end
        end

        function dragCoeffModel = createFromOldDragInputs(area, CdInterp, CdIndepVar, CdInterpMethod, CdInterpPts)
            dragCoeffModel = DragCoeffModel();
            dragCoeffModel.oneDDragModel.area = area;
            dragCoeffModel.oneDDragModel.CdInterp = CdInterp;
            dragCoeffModel.oneDDragModel.CdIndepVar = CdIndepVar;
            dragCoeffModel.oneDDragModel.CdInterpMethod = CdInterpMethod;
            dragCoeffModel.oneDDragModel.CdInterpPts = CdInterpPts;
        end
    end
end