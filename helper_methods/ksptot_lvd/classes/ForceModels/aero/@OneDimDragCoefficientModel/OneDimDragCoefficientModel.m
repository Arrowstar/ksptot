classdef OneDimDragCoefficientModel < AbstractDragCoefficientModel
    %OneDimDragCoefficientModel Summary of this class goes here
    %   Detailed explanation goes here

    properties
        area(1,1) double = 1; %m^2
        CdInterp %should be (1,1) griddedInterpolant
        CdIndepVar (1,1) AeroIndepVar = AeroIndepVar.Altitude;
        CdInterpMethod (1,1) GriddedInterpolantMethodEnum = GriddedInterpolantMethodEnum.Linear;
        CdInterpPts(1,1) GriddedInterpolantPointSet
    end

    properties(Constant)
        enum = DragCoefficientModelEnum.OneDim
    end

    methods
        function obj = OneDimDragCoefficientModel()
            obj.CdInterpMethod = GriddedInterpolantMethodEnum.Linear;
            
            pointSet = GriddedInterpolantPointSet();
            obj.CdInterpPts = pointSet;
            
            pointSet.addPoint(GriddedInterpolantPoint(0,0.3));
            pointSet.addPoint(GriddedInterpolantPoint(1,0.3));
            obj.CdInterp = pointSet.getGriddedInterpFromPoints(obj.CdInterpMethod, GriddedInterpolantMethodEnum.Nearest);
        end

        function CdA = getDragCoeff(obj, ut, rVect, vVect, bodyInfo, mass, altitude, vVectECEFMag, aoa)
            arguments
                obj(1,1) OneDimDragCoefficientModel
                ut(1,1) double 
                rVect(3,1) double 
                vVect(3,1) double 
                bodyInfo(1,1) KSPTOT_BodyInfo
                mass(1,1) double
                altitude(1,1) double
                vVectECEFMag(1,1) double
                aoa(1,1) double = 0;  %this is not implemented yet
            end

            celBodyData = bodyInfo.celBodyData;
            stateLogEntry = [ut, rVect(:)', vVect(:)', bodyInfo.id, mass, 0, 0, 0, -1];

            switch obj.CdIndepVar
                case AeroIndepVar.Altitude
                    indVarValue = altitude;
                    
                case AeroIndepVar.MachNum
                    indVarValue = ma_GAAeroTasks(stateLogEntry, 'machNumber', celBodyData);
                    
                case AeroIndepVar.AtmoPressure
                    indVarValue = ma_GAAeroTasks(stateLogEntry, 'atmoPress', celBodyData);
                    
                case AeroIndepVar.AtmoDensity
                    indVarValue = ma_GAAeroTasks(stateLogEntry, 'atmoDensity', celBodyData);
                    
                case AeroIndepVar.DynPressure
                    indVarValue = ma_GAAeroTasks(stateLogEntry, 'dynPress', celBodyData);
                    
                case AeroIndepVar.BodyFixedVelocity
                    indVarValue = vVectECEFMag;
                    
                otherwise
                    error('Unknown aero independent variable: %s', obj.CdIndepVar);
            end
            
            CdA = obj.area * obj.CdInterp(indVarValue);
            CdA = max([CdA, 0]);
        end

        function useTf = openEditDialog(obj, lvdData)
            out = AppDesignerGUIOutput({false});
            lvd_Edit1DDragPropertiesGUI_App(obj, lvdData, out);
            useTf = out.output{1};
        end
    end
end