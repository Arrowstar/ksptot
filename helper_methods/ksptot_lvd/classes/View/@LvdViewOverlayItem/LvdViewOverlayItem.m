classdef LvdViewOverlayItem < matlab.mixin.SetGet
    %LvdViewOverlayItem One Graphical Analysis quantity shown on the 3-D view
    %data overlay: the task (quantity + reference frame), how it is
    %labelled and how its number is formatted.

    properties
        task GraphicalAnalysisTask                    %quantity and frame
        label(1,:) char = '';                         %'' = the task's own name
        decimals(1,1) double {mustBeInteger, mustBeNonnegative} = 3;
        format(1,1) string {mustBeMember(format, ["Fixed", "Scientific", "Auto"])} = "Fixed";
        showUnits(1,1) logical = true;
        showFrame(1,1) logical = false;               %append the frame name to the label
    end

    methods
        function obj = LvdViewOverlayItem(task)
            arguments
                task = GraphicalAnalysisTask.empty(1,0)
            end
            if(not(isempty(task)))
                obj.task = task;
            end
        end

        function str = getDisplayLabel(obj)
            if(not(isempty(strtrim(obj.label))))
                str = strtrim(obj.label);
                return;
            end
            if(isempty(obj.task))
                str = '<no quantity>';
                return;
            end
            if(obj.showFrame)
                str = obj.task.getListBoxStr();
            else
                str = obj.task.taskStr;
            end
        end

        function str = getQuantityStr(obj)
            if(isempty(obj.task))
                str = '';
            else
                str = obj.task.taskStr;
            end
        end

        function str = getFrameStr(obj)
            str = '';
            if(not(isempty(obj.task)) && not(isempty(obj.task.frame)))
                try
                    str = obj.task.frame.getNameStr();
                catch
                    str = '';
                end
            end
        end

        function txt = formatValue(obj, value, unit)
            %formatValue The number as shown on the overlay ('--' when NaN),
            %with its unit when requested.
            arguments
                obj(1,1) LvdViewOverlayItem
                value(1,1) double
                unit = ''
            end
            if(not(isfinite(value)))
                txt = '--';
                return;
            else
                switch(obj.format)
                    case "Fixed"
                        txt = sprintf('%.*f', obj.decimals, value);
                    case "Scientific"
                        txt = sprintf('%.*e', obj.decimals, value);
                    otherwise %Auto
                        txt = sprintf('%.*g', max(1, obj.decimals + 1), value);
                end
            end

            if(obj.showUnits)
                u = LvdViewOverlayItem.prettyUnit(unit);
                if(not(isempty(u)))
                    txt = sprintf('%s %s', txt, u);
                end
            end
        end

        function line = formatLine(obj, value, unit)
            line = sprintf('%s: %s', obj.getDisplayLabel(), obj.formatValue(value, unit));
        end

        function tf = usesGeometricRefFrame(obj, refFrame)
            %usesGeometricRefFrame True when the quantity is expressed in
            %refFrame itself or in a frame built on it.
            tf = false;
            if(isempty(obj.task) || isempty(obj.task.frame))
                return;
            end
            try
                frame = obj.task.frame;
                if(frame.typeEnum == ReferenceFrameEnum.UserDefined && not(isempty(frame.geometricFrame)))
                    tf = (frame.geometricFrame == refFrame) || frame.geometricFrame.usesGeometricRefFrame(refFrame);
                end
            catch
                tf = false;
            end
        end

        function newObj = copy(obj)
            newObj = LvdViewOverlayItem();
            if(not(isempty(obj.task)))
                newObj.task = GraphicalAnalysisTask(obj.task.taskStr, obj.task.frame);
            end
            newObj.label = obj.label;
            newObj.decimals = obj.decimals;
            newObj.format = obj.format;
            newObj.showUnits = obj.showUnits;
            newObj.showFrame = obj.showFrame;
        end
    end

    methods(Static)
        function u = prettyUnit(unit)
            if(isempty(unit))
                u = '';
                return;
            end
            u = strtrim(char(string(unit)));
            if(any(isnan(double(u))))
                u = '';
                return;
            end
            switch(lower(u))
                case 'percent'
                    u = '%';
                case {'', 'nan'}
                    u = '';
            end
        end

        function obj = loadobj(obj)
            if(isstruct(obj))
                s = obj;
                obj = LvdViewOverlayItem();
                props = properties(obj);
                for(i=1:numel(props)) %#ok<*NO4LP>
                    if(isfield(s, props{i}))
                        try
                            obj.(props{i}) = s.(props{i});
                        catch
                        end
                    end
                end
            end
        end
    end
end
