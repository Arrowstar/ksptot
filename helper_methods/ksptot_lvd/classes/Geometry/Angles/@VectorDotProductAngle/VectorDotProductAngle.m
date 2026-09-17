classdef VectorDotProductAngle < AbstractGeometricAngle
    %VectorDotProductAngle Output is the dot product of two geometric vectors.
    %
    %   This is a dimensionless scalar (km^2 for two position vectors, or
    %   plain cos(angle) when both inputs are unit vectors), not an angle.  It
    %   lives in the angle family because that is LVD's only scalar geometry
    %   type: it becomes a Graphical Analysis quantity, a constraint and an
    %   objective through exactly the same plumbing as the real angles.
    %   isDimensionless() tells those consumers not to convert the value to
    %   degrees and tells the 3D view not to draw an arc for it.
    %
    %   The angle between the vectors is available separately as
    %   TwoVectorAngle; wrap the inputs in UnitVector objects first to get the
    %   cosine of that angle from this class.

    properties
        vector1(1,1) AbstractGeometricVector
        vector2(1,1) AbstractGeometricVector

        name(1,:) char
        lvdData LvdData

        %Kept for interface parity with the other angles; nothing is drawn.
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Red;
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.SolidLine;
    end

    methods
        function obj = VectorDotProductAngle(vector1, vector2, name, lvdData)
            obj.vector1 = vector1;
            obj.vector2 = vector2;

            obj.name = name;
            obj.lvdData = lvdData;
        end

        function value = getAngleAtTime(obj, time, vehElemSet, inFrame)
            %getAngleAtTime The dot product (not an angle) at each time.
            vect1 = obj.vector1.getVectorAtTime(time, vehElemSet, inFrame);
            vect2 = obj.vector2.getVectorAtTime(time, vehElemSet, inFrame);

            value = dot(vect1, vect2, 1);
        end

        function tf = isDimensionless(~)
            tf = true;
        end

        function startPt = getAngleStartPointAtTime(obj, time, vehElemSet, inFrame)
            %Nothing is drawn for a dot product; provided so generic callers
            %that walk every angle keep working.
            startPt = obj.vector1.getVectorAtTime(time, vehElemSet, inFrame);
        end

        function anglePlaneNorm = getAnglePlaneNormalAtTime(obj, time, vehElemSet, inFrame)
            vect1 = obj.vector1.getVectorAtTime(time, vehElemSet, inFrame);
            vect2 = obj.vector2.getVectorAtTime(time, vehElemSet, inFrame);

            anglePlaneNorm = cross(vect1, vect2);

            bool = vecNormARH(anglePlaneNorm) == 0;
            if(any(bool))
                anglePlaneNorm(:,bool) = repmat([0;0;1], 1, sum(bool));
            end
        end

        function name = getName(obj)
            name = obj.name;
        end

        function setName(obj, name)
            obj.name = name;
        end

        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Dot Product of "%s" and "%s")', obj.getName(), obj.vector1.getName(), obj.vector2.getName());
        end

        function useTf = openEditDialog(obj)
            output = AppDesignerGUIOutput({false});
            lvd_EditVectorDotProductAngleGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end

        function tf = isVehDependent(obj)
            tf = obj.vector1.isVehDependent() || ...
                 obj.vector2.isVehDependent();
        end

        function tf = usesGroundObj(obj, groundObj)
            tf = obj.vector1.usesGroundObj(groundObj) || ...
                 obj.vector2.usesGroundObj(groundObj);
        end

        function tf = usesGeometricPoint(~, ~)
            tf = false;
        end

        function tf = usesGeometricVector(obj, vector)
            tf = obj.vector1 == vector || ...
                 obj.vector2 == vector;
        end

        function tf = usesGeometricCoordSys(~, ~)
            tf = false;
        end

        function tf = usesGeometricRefFrame(~, ~)
            tf = false;
        end

        function tf = usesGeometricAngle(~, ~)
            tf = false;
        end

        function tf = usesGeometricPlane(~, ~)
            tf = false;
        end

        function tf = isInUse(obj, lvdData)
            tf = lvdData.usesGeometricAngle(obj);
        end
    end
end
