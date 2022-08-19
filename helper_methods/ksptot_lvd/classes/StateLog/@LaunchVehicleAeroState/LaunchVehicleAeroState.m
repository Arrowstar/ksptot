classdef LaunchVehicleAeroState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleAeroState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties    
        %drag
        dragCoeffModel DragCoeffModel
        
        %lift
        liftCoeffModel LiftCoeffModel
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

        %lift
        useLift(1,1) logical = false;
        areaLift(1,1) double = 16.2; 
        Cl_0(1,1) double = 0.731;  
        bodyLiftVect(3,1) double = [0;0;-1];
    end
    
    methods
        function obj = LaunchVehicleAeroState()
            obj.dragCoeffModel = DragCoeffModel();
            obj.liftCoeffModel = LiftCoeffModel();
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
        end

        function [ClS, liftUnitVectInertial] = getLiftCoeffAndDir(obj, ut, rVect, vVect, bodyInfo, mass, altitude, pressure, density, vVectECEF, attState)
            arguments
                obj(1,1) LaunchVehicleAeroState
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

            [ClS, liftUnitVectInertial] = obj.liftCoeffModel.getLiftCoeffAndDir(ut, rVect, vVect, bodyInfo, mass, altitude, pressure, density, vVectECEF, attState);
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

            if(isempty(obj.liftCoeffModel))
                obj.liftCoeffModel = LiftCoeffModel();
            end
        end
    end
end