classdef LaunchVehicleViewProfileOverlayData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileOverlayData Draws the view profile's data
    %overlay (LvdViewOverlaySettings) as one text block on the 3-D axes and
    %updates it on every rendered frame.
    %
    %   The Graphical Analysis quantities are evaluated over the whole state
    %   log once (the same GraphicalAnalysisTask.executeTask the plots use),
    %   grouped by event so a discontinuity at an event boundary is kept
    %   rather than smeared, and interpolated linearly in time inside each
    %   event.  The evaluation is lazy (first frame that needs it) and cached
    %   for the life of this object, which is rebuilt on every plot.

    properties
        settings LvdViewOverlaySettings
        lvdData LvdData

        hText = [];                 %matlab.graphics.primitive.Text or []
        computed(1,1) logical = false;
        itemSegments(1,:) cell = {};   %per item: struct array (times, interp)
        itemUnits(1,:) cell = {};
        itemErrors(1,:) cell = {};
        missionStartTime(1,1) double = NaN;
    end

    properties(Constant)
        TextTag = 'LvdViewOverlayText';
    end

    methods
        function obj = LaunchVehicleViewProfileOverlayData(settings, lvdData)
            obj.settings = settings;
            obj.lvdData = lvdData;
        end

        %% ------------------------------------------------- evaluation
        function precompute(obj)
            %precompute Evaluates every overlay quantity over the state log.
            obj.itemSegments = {};
            obj.itemUnits = {};
            obj.itemErrors = {};
            obj.computed = true;

            if(isempty(obj.lvdData) || isempty(obj.settings))
                return;
            end

            entries = obj.lvdData.stateLog.getAllEntries();
            if(isempty(entries))
                return;
            end
            entries = entries(:)';
            obj.missionStartTime = min([entries.time]);

            items = obj.settings.items;
            if(isempty(items))
                return;
            end

            celBodyData = obj.lvdData.celBodyData;
            try
                propNames = obj.lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
            catch
                propNames = {};
            end
            maTaskList = ma_getGraphAnalysisTaskList(getLvdGAExcludeList());

            values = NaN(numel(entries), numel(items));
            units = repmat({''}, 1, numel(items));
            errs = repmat({''}, 1, numel(items));
            for(j=1:numel(items)) %#ok<*NO4LP>
                task = items(j).task;
                if(isempty(task))
                    errs{j} = 'no quantity';
                    continue;
                end
                prevDistTraveled = 0;
                for(i=1:numel(entries))
                    try
                        [values(i,j), unit, prevDistTraveled] = task.executeTask(entries(i), maTaskList, prevDistTraveled, [], [], propNames, celBodyData);
                        if(ischar(unit) || isstring(unit))
                            units{j} = char(unit);
                        end
                    catch ME
                        values(i,j) = NaN;
                        errs{j} = ME.message;
                    end
                end
            end

            %group by event: the later event owns a shared boundary time
            evts = [entries.event];
            uniqueEvts = unique(evts, 'stable');
            for(j=1:numel(items))
                segs = struct('times', {}, 'interp', {});
                for(k=1:numel(uniqueEvts))
                    sel = evts == uniqueEvts(k);
                    t = [entries(sel).time];
                    v = values(sel, j)';
                    [t, ia] = unique(t, 'stable');
                    v = v(ia);
                    [t, order] = sort(t);
                    v = v(order);
                    good = isfinite(v);
                    if(nnz(good) == 0)
                        continue;
                    end
                    t = t(good); v = v(good);
                    if(numel(t) == 1)
                        t = [t, t + 10*eps(max(1, abs(t)))];
                        v = [v, v];
                    end
                    segs(end+1) = struct('times', t, 'interp', griddedInterpolant(t, v, 'linear', 'nearest')); %#ok<AGROW>
                end
                obj.itemSegments{j} = segs;
                obj.itemUnits{j} = units{j};
                obj.itemErrors{j} = errs{j};
            end
        end

        function value = getItemValueAtTime(obj, itemInd, time)
            %getItemValueAtTime Interpolated value of item itemInd at time,
            %NaN when no event segment covers the time.
            value = NaN;
            if(not(obj.computed))
                obj.precompute();
            end
            if(itemInd < 1 || itemInd > numel(obj.itemSegments))
                return;
            end
            segs = obj.itemSegments{itemInd};
            for(k=numel(segs):-1:1)   %later event owns a shared boundary
                t = segs(k).times;
                if(time >= t(1) - 1e-9 && time <= t(end) + 1e-9)
                    value = segs(k).interp(min(max(time, t(1)), t(end)));
                    return;
                end
            end
        end

        function lines = buildLines(obj, time)
            %buildLines The overlay text for `time`, one cell per line.
            s = obj.settings;
            lines = {};
            if(isempty(s))
                return;
            end
            if(not(isempty(strtrim(s.title))))
                lines{end+1} = strtrim(s.title);
            end
            if(s.showEpoch)
                try
                    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(time);
                    lines{end+1} = formDateStr(year, day, hour, minute, sec);
                catch
                end
            end
            if(s.showUT)
                lines{end+1} = sprintf('UT: %.3f s', time);
            end
            if(s.showMet)
                if(not(obj.computed))
                    obj.precompute();
                end
                t0 = obj.missionStartTime;
                if(isnan(t0))
                    try
                        [t0, ~] = obj.lvdData.stateLog.getStartAndEndTimes();
                    catch
                        t0 = NaN;
                    end
                end
                if(isfinite(t0))
                    lines{end+1} = sprintf('MET: %s', LaunchVehicleViewProfileOverlayData.formatDuration(time - t0));
                end
            end
            if(s.showEventName)
                evtStr = obj.eventNamesAtTime(time);
                if(not(isempty(evtStr)))
                    lines{end+1} = sprintf('Event: %s', evtStr);
                end
            end
            for(j=1:numel(s.items))
                item = s.items(j);
                value = obj.getItemValueAtTime(j, time);
                unit = '';
                if(j <= numel(obj.itemUnits))
                    unit = obj.itemUnits{j};
                end
                lines{end+1} = item.formatLine(value, unit); %#ok<AGROW>
            end
        end

        %% --------------------------------------------------- rendering
        function plotOverlayAtTime(obj, time, hAx)
            if(isempty(obj.settings) || not(obj.settings.enabled) || not(obj.settings.hasContent()))
                obj.hide();
                return;
            end

            lines = obj.buildLines(time);
            if(isempty(lines))
                obj.hide();
                return;
            end

            if(isempty(obj.hText) || not(isvalid(obj.hText)))
                obj.hText = text(hAx, 0, 0, 0, lines, ...
                                 'Units', 'normalized', ...
                                 'Interpreter', 'none', ...
                                 'HitTest', 'off', ...
                                 'PickableParts', 'none', ...
                                 'Clipping', 'off', ...
                                 'Margin', 6, ...
                                 'Tag', obj.TextTag);
            else
                obj.hText.String = lines;
            end
            obj.applyAppearance();
            obj.hText.Visible = 'on';
        end

        function applyAppearance(obj)
            %applyAppearance Placement, font and background from the settings.
            if(isempty(obj.hText) || not(isvalid(obj.hText)))
                return;
            end
            s = obj.settings;
            [x, y, hAlign, vAlign] = s.getAnchor();
            obj.hText.Units = 'normalized';
            obj.hText.Position = [x, y, 0];
            obj.hText.HorizontalAlignment = hAlign;
            obj.hText.VerticalAlignment = vAlign;
            obj.hText.FontName = s.fontName;
            obj.hText.FontSize = s.fontSize;
            obj.hText.FontWeight = char(s.fontWeight);
            obj.hText.Color = s.fontColor;
            obj.hText.BackgroundColor = s.getBackgroundColorSpec();
            obj.hText.EdgeColor = 'none';
        end

        function refreshAppearance(obj)
            obj.applyAppearance();
        end

        function invalidate(obj)
            %invalidate Forces re-evaluation of the quantities on the next frame
            %(after items were added or removed).
            obj.computed = false;
            obj.itemSegments = {};
            obj.itemUnits = {};
            obj.itemErrors = {};
        end

        function hide(obj)
            if(not(isempty(obj.hText)) && isvalid(obj.hText))
                obj.hText.Visible = 'off';
            end
        end

        function deleteGraphics(obj)
            if(not(isempty(obj.hText)) && isvalid(obj.hText))
                delete(obj.hText);
            end
            obj.hText = [];
        end

        function h = getTextHandle(obj)
            h = obj.hText;
        end
    end

    methods(Access = private)
        function str = eventNamesAtTime(obj, time)
            str = '';
            try
                [evts, ~] = obj.lvdData.script.getAllEvtsThatOccurAtTime(time);
                if(isempty(evts))
                    return;
                end
                names = cell(1, numel(evts));
                for(i=1:numel(evts))
                    num = obj.lvdData.script.getNumOfEvent(evts(i));
                    if(isempty(num))
                        names{i} = evts(i).name;
                    else
                        names{i} = sprintf('%u - %s', num, evts(i).name);
                    end
                end
                str = strjoin(names, ' | ');
            catch
                str = '';
            end
        end
    end

    methods(Static)
        function str = formatDuration(seconds)
            %formatDuration +D d HH:MM:SS.sss
            sgn = '+';
            if(seconds < 0)
                sgn = '-';
                seconds = -seconds;
            end
            days = floor(seconds / 86400);
            rem1 = seconds - days*86400;
            hours = floor(rem1 / 3600);
            rem2 = rem1 - hours*3600;
            minutes = floor(rem2 / 60);
            secs = rem2 - minutes*60;
            if(days > 0)
                str = sprintf('%s%ud %02u:%02u:%06.3f', sgn, days, hours, minutes, secs);
            else
                str = sprintf('%s%02u:%02u:%06.3f', sgn, hours, minutes, secs);
            end
        end
    end
end
