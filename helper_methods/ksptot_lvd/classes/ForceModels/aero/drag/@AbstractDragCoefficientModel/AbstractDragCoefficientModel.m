classdef(Abstract) AbstractDragCoefficientModel < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
    %AbstractDragCoefficientModel Summary of this class goes here
    %   Detailed explanation goes here

    properties(Abstract, Constant)
        enum DragCoefficientModelEnum
    end

    methods
        CdA = getDragCoeff(obj, ut, rVect, vVect, bodyInfo, mass, altitude, pressure, density, vVectECEFMag, totalAoA, aoa, sideslip);

        tf = usesTotalAoA(obj)

        tf = usesAoaAndSideslip(obj)

        useTf = openEditDialog(obj)
    end
end