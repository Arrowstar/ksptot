classdef VectorPlaneIntersectionPoint < AbstractGeometricPoint
    %VectorPlaneIntersectionPoint The point where the line through an origin
    %point along a direction vector pierces a plane.  When the line is
    %parallel to the plane the position is NaN.

    properties
        originPoint(1,1) AbstractGeometricPoint
        vector(1,1) AbstractGeometricVector
        plane(1,1) AbstractGeometricPlane

        name(1,:) char

        lvdData LvdData

        %marker
        markerColor(1,1) ColorSpecEnum = ColorSpecEnum.Red;
        markerShape(1,1) MarkerStyleEnum = MarkerStyleEnum.RightTriangle;

        %track line
        plotTrkLine(1,1) logical = true;
        trkLineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        trkLineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
    end

    properties(Constant)
        %Finite difference half-step (sec) used to derive the point velocity
        %from its position history when no vehicle state is involved.
        velFdHalfStep = 0.01;
    end

    methods
        function obj = VectorPlaneIntersectionPoint(originPoint, vector, plane, name, lvdData)
            obj.originPoint = originPoint;
            obj.vector = vector;
            obj.plane = plane;

            obj.name = name;
            obj.lvdData = lvdData;
        end

        function newCartElem = getPositionAtTime(obj, time, vehElemSet, inFrame)
            time = time(:)';

            rVects = obj.computeIntersection(time, vehElemSet, inFrame);

            if(obj.isVehDependent())
                %A vehicle-dependent input is only meaningful at the time of
                %the supplied vehicle state, so no finite-difference velocity.
                vVects = zeros(size(rVects));
            else
                h = obj.velFdHalfStep;
                rPlus = obj.computeIntersection(time + h, vehElemSet, inFrame);
                rMinus = obj.computeIntersection(time - h, vehElemSet, inFrame);
                vVects = (rPlus - rMinus) / (2*h);
            end

            newCartElem = CartesianElementSet(time, rVects, vVects, inFrame);
        end

        function name = getName(obj)
            name = obj.name;
        end

        function setName(obj, name)
            obj.name = name;
        end

        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Line "%s" from "%s" onto plane "%s")', obj.getName(), obj.vector.getName(), obj.originPoint.getName(), obj.plane.getName());
        end

        function useTf = openEditDialog(obj)
            output = AppDesignerGUIOutput({false});
            lvd_EditVectorPlaneIntersectionPointGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end

        function tf = isVehDependent(obj)
            tf = obj.originPoint.isVehDependent() || ...
                 obj.vector.isVehDependent() || ...
                 obj.plane.isVehDependent();
        end

        function tf = canBePlotted(~)
            tf = true;
        end

        function bodyInfo = getOriginBody(obj)
            bodyInfo = obj.originPoint.getOriginBody();
        end

        function tf = usesGroundObj(obj, groundObj)
            tf = obj.originPoint.usesGroundObj(groundObj) || ...
                 obj.vector.usesGroundObj(groundObj) || ...
                 obj.plane.usesGroundObj(groundObj);
        end

        function tf = usesGeometricPoint(obj, point)
            tf = obj.originPoint == point;
        end

        function tf = usesGeometricVector(obj, vector)
            tf = obj.vector == vector;
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

        function tf = usesGeometricPlane(obj, plane)
            tf = obj.plane == plane;
        end

        function tf = isInUse(obj, lvdData)
            tf = lvdData.usesGeometricPoint(obj);
        end
    end

    methods(Access=private)
        function rVects = computeIntersection(obj, time, vehElemSet, inFrame)
            originCartElem = obj.originPoint.getPositionAtTime(time, vehElemSet, inFrame);
            o = [originCartElem.rVect];
            d = obj.vector.getVectorAtTime(time, vehElemSet, inFrame);

            N = vect_normVector(obj.plane.getPlaneNormVectAtTime(time, vehElemSet, inFrame));
            planeCartElem = obj.plane.getPlaneOriginPtAtTime(time, vehElemSet, inFrame);
            a = [planeCartElem.rVect];

            tNum = dot(N, a - o);
            tDen = dot(N, d);

            t = tNum ./ tDen;
            t(abs(tDen) <= eps(max(1, vecNormARH(d)))) = NaN;

            rVects = o + bsxfun(@times, d, t);
        end
    end
end
