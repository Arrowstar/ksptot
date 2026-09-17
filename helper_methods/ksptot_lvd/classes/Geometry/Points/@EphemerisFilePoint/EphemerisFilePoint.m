classdef EphemerisFilePoint < AbstractGeometricPoint
    %EphemerisFilePoint A point whose position and velocity are read from a
    %time-tagged CSV ephemeris file (UT sec, x, y, z, vx, vy, vz in km and
    %km/s) expressed in a user-selected reference frame.  Queries between
    %table rows are spline-interpolated; queries outside the table span are
    %clamped to the first/last row.

    properties
        filePath(1,:) char = '';
        frame AbstractReferenceFrame

        times(1,:) double = [];
        rvVects(6,:) double = zeros(6,0);

        name(1,:) char = 'New Point';

        lvdData LvdData

        %marker
        markerColor(1,1) ColorSpecEnum = ColorSpecEnum.Red;
        markerShape(1,1) MarkerStyleEnum = MarkerStyleEnum.RightTriangle;

        %track line
        plotTrkLine(1,1) logical = true;
        trkLineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        trkLineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
    end

    methods
        function obj = EphemerisFilePoint(filePath, frame, name, lvdData)
            arguments
                filePath(1,:) char
                frame(1,1) AbstractReferenceFrame
                name(1,:) char
                lvdData(1,1) LvdData
            end

            obj.frame = frame;
            obj.name = name;
            obj.lvdData = lvdData;

            if(not(isempty(filePath)))
                obj.loadFromFile(filePath);
            end
        end

        function loadFromFile(obj, filePath)
            [t, rv] = lvd_readEphemerisCsv(filePath);

            obj.filePath = filePath;
            obj.times = t;
            obj.rvVects = rv;
        end

        function setTable(obj, times, rvVects)
            %setTable Directly sets the ephemeris table (times 1xN sec,
            %rvVects 6xN km & km/s), bypassing the file reader.
            [times, I] = unique(times(:)', 'sorted');
            obj.times = times;
            obj.rvVects = rvVects(:,I);
            obj.filePath = '';
        end

        function tf = hasEphemeris(obj)
            tf = not(isempty(obj.times));
        end

        function [tMin, tMax] = getTimeSpan(obj)
            if(obj.hasEphemeris())
                tMin = obj.times(1);
                tMax = obj.times(end);
            else
                tMin = NaN;
                tMax = NaN;
            end
        end

        function newCartElem = getPositionAtTime(obj, time, ~, inFrame)
            time = time(:)';
            numTimes = numel(time);

            if(not(obj.hasEphemeris()))
                rv = NaN(6, numTimes);
            elseif(isscalar(obj.times))
                rv = repmat(obj.rvVects, 1, numTimes);
            else
                tq = min(max(time, obj.times(1)), obj.times(end));
                rv = interp1(obj.times', obj.rvVects', tq', 'spline')';
            end

            newCartElem = CartesianElementSet(time, rv(1:3,:), rv(4:6,:), obj.frame);
            newCartElem = convertToFrame(newCartElem, inFrame, true);
        end

        function name = getName(obj)
            name = obj.name;
        end

        function setName(obj, name)
            obj.name = name;
        end

        function listboxStr = getListboxStr(obj)
            [~, fName, fExt] = fileparts(obj.filePath);
            if(isempty(fName))
                srcStr = 'no file loaded';
            else
                srcStr = [fName, fExt];
            end

            listboxStr = sprintf('%s (Ephemeris File: %s)', obj.getName(), srcStr);
        end

        function useTf = openEditDialog(obj)
            output = AppDesignerGUIOutput({false});
            lvd_EditEphemerisFilePointGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end

        function tf = isVehDependent(~)
            tf = false;
        end

        function tf = canBePlotted(~)
            tf = true;
        end

        function bodyInfo = getOriginBody(obj)
            bodyInfo = obj.frame.getOriginBody();
        end

        function tf = usesGroundObj(~, ~)
            tf = false;
        end

        function tf = usesGeometricPoint(~, ~)
            tf = false;
        end

        function tf = usesGeometricVector(~, ~)
            tf = false;
        end

        function tf = usesGeometricCoordSys(~, ~)
            tf = false;
        end

        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = isa(obj.frame, 'UserDefinedGeometricFrame') && obj.frame.geometricFrame == refFrame;
        end

        function tf = usesGeometricAngle(~, ~)
            tf = false;
        end

        function tf = usesGeometricPlane(~, ~)
            tf = false;
        end

        function tf = isInUse(obj, lvdData)
            tf = lvdData.usesGeometricPoint(obj);
        end
    end
end
