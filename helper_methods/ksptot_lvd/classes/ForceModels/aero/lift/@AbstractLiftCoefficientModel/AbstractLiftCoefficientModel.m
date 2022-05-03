classdef(Abstract) AbstractLiftCoefficientModel < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
    %AbstractDragCoefficientModel Summary of this class goes here
    %   Detailed explanation goes here

    properties(Abstract, Constant)
        enum LiftCoefficientModelEnum
    end

    methods
        [ClS, liftUnitVectInertial] = getLiftCoeffAndDir(obj, ut, rVect, vVect, bodyInfo, mass, altitude, pressure, density, vVectECEF, attState)

        useTf = openEditDialog(obj)
    end
end