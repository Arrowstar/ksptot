classdef ThreePointCoordSystem < AbstractGeometricCoordSystem
    %ThreePointCoordSystem A coordinate system defined by three geometric points.
    %
    %   The "primary" axis points from the origin point toward the primary
    %   axis point.  The "normal" axis is perpendicular to the plane through
    %   all three points, on the side given by the right-hand rule going from
    %   the primary axis point to the plane point.  The third axis completes
    %   a right-handed set and lies in the plane of the three points, on the
    %   plane point's side.  Which coordinate axes the primary and normal
    %   directions map onto is selectable, exactly as it is for the
    %   Aligned/Constrained coordinate system.
    %
    %   To turn this into a full reference frame (origin plus orientation),
    %   pair it with the origin point in a "Coordinate System and Point"
    %   reference frame (CoordSysPointRefFrame).  Two vectors rather than
    %   three points?  That is the Aligned/Constrained coordinate system.

    properties
        originPoint(1,1) AbstractGeometricPoint
        primaryAxisPoint(1,1) AbstractGeometricPoint
        planePoint(1,1) AbstractGeometricPoint

        primaryAxis(1,1) AlignedConstrainedCoordSysAxesEnum = AlignedConstrainedCoordSysAxesEnum.PosX;
        normalAxis(1,1) AlignedConstrainedCoordSysAxesEnum = AlignedConstrainedCoordSysAxesEnum.PosZ;

        name(1,:) char
        lvdData LvdData
    end

    methods
        function obj = ThreePointCoordSystem(originPoint, primaryAxisPoint, planePoint, name, lvdData)
            obj.originPoint = originPoint;
            obj.primaryAxisPoint = primaryAxisPoint;
            obj.planePoint = planePoint;

            obj.name = name;
            obj.lvdData = lvdData;
        end

        function R_CoordSys_to_GlobalInertial = getCoordSysAtTime(obj, time, vehElemSet, inFrame)
            time = time(:)';
            numTimes = numel(time);

            originCartElem = obj.originPoint.getPositionAtTime(time, vehElemSet, inFrame);
            primaryCartElem = obj.primaryAxisPoint.getPositionAtTime(time, vehElemSet, inFrame);
            planeCartElem = obj.planePoint.getPositionAtTime(time, vehElemSet, inFrame);

            o = [originCartElem.rVect];
            p = [primaryCartElem.rVect];
            q = [planeCartElem.rVect];

            %Orthonormal pair in inFrame: u along the primary direction and w
            %normal to the plane of the points.  The in-plane axis w x u is
            %implied by right-handedness.
            u = p - o;
            w = cross(u, q - o, 1);

            [u, w] = ThreePointCoordSystem.orthonormalPair(u, w);

            %Map the triad onto the requested coordinate axes.  With a = the
            %primary axis unit vector and c = the normal axis unit vector in
            %coordinate-system components, R*a = u, R*c = w and therefore
            %R*(a x c) = u x w, so R = [u w u x w] * [a c a x c]^T.
            a = obj.primaryAxis.vect;
            c = obj.normalAxis.vect;
            axisBasis = [a, c, cross(a, c)];

            R_CoordSys_to_GlobalInertial = zeros(3, 3, numTimes);
            for(k=1:numTimes) %#ok<*NO4LP>
                R_CoordSys_to_InFrame = [u(:,k), w(:,k), cross(u(:,k), w(:,k))] * axisBasis';

                R_InFrame_to_GlobalInertial = inFrame.getRotMatToInertialAtTime(time(k));
                R_CoordSys_to_GlobalInertial(:,:,k) = R_InFrame_to_GlobalInertial * R_CoordSys_to_InFrame;
            end

            if(numTimes == 1)
                R_CoordSys_to_GlobalInertial = R_CoordSys_to_GlobalInertial(:,:,1);
            end
        end

        function name = getName(obj)
            name = obj.name;
        end

        function setName(obj, name)
            obj.name = name;
        end

        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Three Points "%s", "%s", "%s")', obj.getName(), obj.originPoint.getName(), obj.primaryAxisPoint.getName(), obj.planePoint.getName());
        end

        function useTf = openEditDialog(obj)
            output = AppDesignerGUIOutput({false});
            lvd_EditThreePointCoordSysGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end

        function tf = isVehDependent(obj)
            tf = obj.originPoint.isVehDependent() || ...
                 obj.primaryAxisPoint.isVehDependent() || ...
                 obj.planePoint.isVehDependent();
        end

        function tf = usesGroundObj(obj, groundObj)
            tf = obj.originPoint.usesGroundObj(groundObj) || ...
                 obj.primaryAxisPoint.usesGroundObj(groundObj) || ...
                 obj.planePoint.usesGroundObj(groundObj);
        end

        function tf = usesGeometricPoint(obj, point)
            tf = obj.originPoint == point || ...
                 obj.primaryAxisPoint == point || ...
                 obj.planePoint == point;
        end

        function tf = usesGeometricVector(~, ~)
            tf = false;
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
            tf = lvdData.usesGeometricCoordSys(obj);
        end
    end

    methods(Static, Access=private)
        function [u, w] = orthonormalPair(u, w)
            %orthonormalPair Normalizes u and w column by column, replacing
            %degenerate inputs (coincident points, collinear points) with an
            %arbitrary but valid perpendicular pair so the rotation matrix is
            %always proper.
            uMag = vecNormARH(u);
            bool = uMag == 0;
            if(any(bool))
                u(:,bool) = repmat([1;0;0], 1, sum(bool));
            end
            u = vect_normVector(u);

            wMag = vecNormARH(w);
            bool = wMag == 0;
            if(any(bool))
                %Any vector not parallel to u: pick the world axis u is
                %least aligned with and take the cross product.
                for(k = find(bool))
                    [~, minInd] = min(abs(u(:,k)));
                    e = zeros(3,1);
                    e(minInd) = 1;
                    w(:,k) = cross(u(:,k), e);
                end
            end

            %Remove any component of w along u (only nonzero for numerically
            %degenerate input) and normalize.
            w = w - bsxfun(@times, u, dot(u, w, 1));
            w = vect_normVector(w);
        end
    end
end
