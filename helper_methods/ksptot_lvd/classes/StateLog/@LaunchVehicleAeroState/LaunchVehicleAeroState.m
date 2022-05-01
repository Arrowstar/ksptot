classdef LaunchVehicleAeroState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleAeroState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties    
        %drag
        dragCoeffModel DragCoeffModel
        
        %lift
        useLift(1,1) logical = false;
        areaLift(1,1) double = 16.2; 
        Cl_0(1,1) double = 0.731;  
        bodyLiftVect(3,1) double = [0;0;-1];
    end
    
    %old properties
    properties(Access=private)
        %drag
        Cd(1,1) double = 0.3;

        %drag
        area(1,1) double = 1; %m^2
        CdInterp %should be (1,1) griddedInterpolant
        CdIndepVar (1,1) AeroIndepVar = AeroIndepVar.Altitude;
        CdInterpMethod (1,1) GriddedInterpolantMethodEnum = GriddedInterpolantMethodEnum.Linear;
        CdInterpPts(1,1) GriddedInterpolantPointSet
    end
    
    methods
        function obj = LaunchVehicleAeroState()
            obj.dragCoeffModel = DragCoeffModel();

%             obj.CdInterpMethod = GriddedInterpolantMethodEnum.Linear;
%             
%             pointSet = GriddedInterpolantPointSet();
%             obj.CdInterpPts = pointSet;
%             
%             pointSet.addPoint(GriddedInterpolantPoint(0,0.3));
%             pointSet.addPoint(GriddedInterpolantPoint(1,0.3));
%             obj.CdInterp = pointSet.getGriddedInterpFromPoints(obj.CdInterpMethod, GriddedInterpolantMethodEnum.Nearest);
        end
        
        function CdA = getDragCoeff(obj, ut, rVect, vVect, bodyInfo, mass, altitude, pressure, density, vVectECEFMag, totalAoA, aoa, sideslip)
            arguments
                obj(1,1) LaunchVehicleAeroState
                ut(1,1) double 
                rVect(3,1) double 
                vVect(3,1) double 
                bodyInfo(1,1) KSPTOT_BodyInfo
                mass(1,1) double
                altitude(1,1) double
                pressure(1,1) double %kPa
                density(1,1) double
                vVectECEFMag(1,1) double
                totalAoA(1,1) double = 0;
                aoa(1,1) double = 0;
                sideslip(1,1) double = 0;
            end

            CdA = obj.dragCoeffModel.getDragCoeff(ut, rVect, vVect, bodyInfo, mass, altitude, pressure, density, vVectECEFMag, totalAoA, aoa, sideslip);
%             stateLogEntry = [ut, rVect(:)', vVect(:)', bodyInfo.id, mass, 0, 0, 0, -1];
% 
%             switch obj.CdIndepVar
%                 case AeroIndepVar.Altitude
%                     indVarValue = ma_GALongLatAltTasks(stateLogEntry, 'alt', celBodyData);
%                     
%                 case AeroIndepVar.MachNum
%                     indVarValue = ma_GAAeroTasks(stateLogEntry, 'machNumber', celBodyData);
%                     
%                 case AeroIndepVar.AtmoPressure
%                     indVarValue = ma_GAAeroTasks(stateLogEntry, 'atmoPress', celBodyData);
%                     
%                 case AeroIndepVar.AtmoDensity
%                     indVarValue = ma_GAAeroTasks(stateLogEntry, 'atmoDensity', celBodyData);
%                     
%                 case AeroIndepVar.DynPressure
%                     indVarValue = ma_GAAeroTasks(stateLogEntry, 'dynPress', celBodyData);
%                     
%                 case AeroIndepVar.BodyFixedVelocity
%                     indVarValue = ma_GALongLatAltTasks(stateLogEntry, 'bodyFixedVNorm', celBodyData);
%                     
%                 otherwise
%                     error('Unknown aero independent variable: %s', obj.CdIndepVar);
%             end
%             
%             Cd = obj.CdInterp(indVarValue);
%             Cd = max([Cd, 0]);
        end
        
        function newAeroState = deepCopy(obj)
            newAeroState = obj.copy();
        end
    end
    
    methods(Static)
        function obj = loadobj(obj)
            arguments
                obj(1,1) LaunchVehicleAeroState
            end

            if(isempty(obj.CdInterp))
                pointSet = GriddedInterpolantPointSet();
                obj.CdInterpMethod = GriddedInterpolantMethodEnum.Linear;
                
                pointSet.addPoint(GriddedInterpolantPoint(0,obj.Cd));
                pointSet.addPoint(GriddedInterpolantPoint(1,obj.Cd));
                obj.CdInterp = pointSet.getGriddedInterpFromPoints(obj.CdInterpMethod, GriddedInterpolantMethodEnum.Nearest);
                obj.CdInterpPts = pointSet;
            end

            if(isempty(obj.dragCoeffModel))
                obj.dragCoeffModel = DragCoeffModel.createFromOldDragInputs(obj.area, obj.CdInterp, obj.CdIndepVar, obj.CdInterpMethod, obj.CdInterpPts);
            end
        end
    end
end