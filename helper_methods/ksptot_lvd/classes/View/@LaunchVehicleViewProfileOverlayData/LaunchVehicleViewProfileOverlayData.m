classdef LaunchVehicleViewProfileOverlayData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileOverlayData Draws the view profile's data
    %overlay (LvdViewOverlaySettings) as one figure-level annotation textbox
    %over the 3-D axes and updates it on every rendered frame.
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
                        [values(i,j), unit, prevDistTraveled] = task.executeTask(entries(i), maTaskList, prevDistTraveled, [], [], propNames, celBodyData, entries, i);
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
            %plotOverlayAtTime Draws the overlay for `time` as a figure-level
            %annotation textbox floating over hAx.
            %
            %   A figure annotation is used deliberately: anything parented to
            %   the 3-D view axes couples its screen position to the camera /
            %   projection (tracing showed the block drifting on dolly with no
            %   code path involved), while a figure annotation is outside the
            %   axes, scene graph, normalizer and skybox systems entirely.
            %   Export captures the figure cropped to the axes (see
            %   LvdViewExporter.cropFigureToAxes) so videos and images keep
            %   showing the block.
            hFig = [];
            try
                hFig = ancestor(hAx, 'figure');
            catch
            end
            try
                figOk = not(isempty(hFig)) && all(isvalid(hFig));
            catch
                figOk = false;
            end
            if(not(figOk))
                obj.hide();
                return;
            end
            hFig = hFig(1);

            if(isempty(obj.settings) || not(obj.settings.enabled) || not(obj.settings.hasContent()))
                obj.hide();
                LaunchVehicleViewProfileOverlayData.hideAll(hFig, obj.hText);
                return;
            end

            lines = obj.buildLines(time);
            if(isempty(lines))
                obj.hide();
                LaunchVehicleViewProfileOverlayData.hideAll(hFig, obj.hText);
                return;
            end

            if(isempty(obj.hText) || not(isvalid(obj.hText)))
                %Adopt a surviving annotation (previous data object rebuilt
                %on replot while its figure graphics outlived it) instead of
                %stacking a second one.  Anything that is not an annotation
                %textbox (e.g. a legacy axes text with the same tag) is
                %dropped so only one block ever exists.
                adopted = false;
                try
                    existing = findobj(hFig, 'Tag', obj.TextTag);
                    for(k=1:numel(existing))
                        try
                            if(isvalid(existing(k)))
                                if(not(adopted) && isa(existing(k), 'matlab.graphics.shape.TextBox'))
                                    obj.hText = existing(k);
                                    adopted = true;
                                else
                                    delete(existing(k));
                                end
                            end
                        catch
                        end
                    end
                catch
                end
                if(not(adopted))
                    try
                        obj.hText = annotation('textbox', [0.02 0.7 0.3 0.25], 'String', lines, 'Tag', obj.TextTag);
                    catch
                        obj.hide();
                        return;
                    end
                    try
                        obj.hText.Parent = hFig;
                    catch
                    end
                    try
                        obj.hText.HitTest = 'off';
                    catch
                    end
                    try
                        obj.hText.PickableParts = 'none';
                    catch
                    end
                    try
                        obj.hText.HandleVisibility = 'on';
                    catch
                    end
                end
            else
                try
                    if(not(isequal(obj.hText.Parent, hFig)))
                        obj.hText.Parent = hFig;
                    end
                catch
                end
            end
            obj.hText.String = lines;
            obj.applyAppearance(hAx, hFig);
            %Mirror the 3-D view visibility (e.g. the Ground Track tab hides it).
            try
                showIt = true;
                try
                    showIt = isvisible(hAx);
                catch
                    try
                        showIt = strcmp(hAx.Visible, 'on');
                    catch
                    end
                end
                if(showIt)
                    obj.hText.Visible = 'on';
                else
                    obj.hText.Visible = 'off';
                end
            catch
                obj.hText.Visible = 'on';
            end
        end

        function applyAppearance(obj, hAx, hFig)
            %applyAppearance Style from the settings, plus corner placement.
            %   Placement needs the 3-D axes and its figure; without them
            %   (plain refreshAppearance) only the style is pushed — the
            %   playback window always re-renders right after, which places.
            arguments
                obj(1,1) LaunchVehicleViewProfileOverlayData
                hAx = []
                hFig = []
            end
            if(isempty(obj.hText) || not(isvalid(obj.hText)))
                return;
            end
            if(not(isa(obj.hText, 'matlab.graphics.shape.TextBox')))
                return;
            end
            if(isempty(hFig))
                try
                    p = obj.hText.Parent;
                    if(not(isempty(p)) && all(isvalid(p)))
                        hFig = p;
                    end
                catch
                end
            end
            s = obj.settings;
            [xN, yN, hAlign, vAlign] = s.getAnchor();
            try
                obj.hText.Units = 'normalized';
            catch
            end
            try
                obj.hText.Interpreter = 'none';
            catch
            end
            try
                obj.hText.HorizontalAlignment = hAlign;
            catch
            end
            try
                obj.hText.VerticalAlignment = vAlign;
            catch
            end
            try
                obj.hText.FontName = s.fontName;
            catch
            end
            try
                obj.hText.FontSize = s.fontSize;
            catch
            end
            try
                obj.hText.FontWeight = char(s.fontWeight);
            catch
            end
            try
                obj.hText.Color = s.fontColor;
            catch
            end
            try
                obj.hText.BackgroundColor = s.getBackgroundColorSpec();
            catch
            end
            try
                obj.hText.EdgeColor = 'none';
            catch
            end
            try
                obj.hText.Margin = 6;
            catch
            end
            try
                obj.hText.FitBoxToText = 'off';
            catch
            end
            try
                pos = LaunchVehicleViewProfileOverlayData.cornerBox(hAx, hFig, xN, yN, hAlign, vAlign, obj.hText);
                if(not(isempty(pos)))
                    obj.hText.Position = pos;
                end
            catch
            end
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
        function hideAll(hFig, exceptHandle)
            %hideAll Hides overlay annotations in hFig left by another
            %profile's data object, except exceptHandle.  Never throws.
            try
                if(isempty(hFig))
                    return;
                end
                others = findobj(hFig, 'Tag', 'LvdViewOverlayText');
                for(k=1:numel(others))
                    try
                        if(isvalid(others(k)))
                            keep = false;
                            try
                                keep = not(isempty(exceptHandle)) && all(isvalid(exceptHandle)) && isequal(others(k), exceptHandle);
                            catch
                            end
                            if(not(keep))
                                others(k).Visible = 'off';
                            end
                        end
                    catch
                    end
                end
            catch
            end
        end

        function pos = cornerBox(hAx, hFig, xN, yN, hAlign, vAlign, hText)
            %cornerBox Figure-normalized annotation box hugging the content at
            %the axes corner (xN, yN are axes fractions).  [] when the sizes
            %cannot be determined (callers keep the previous box).
            pos = [];
            try
                try
                    fpx = getpixelposition(hFig);
                catch
                    fpx = [];
                end
                if(isempty(fpx) || numel(fpx) < 4)
                    try
                        fpx = hFig.Position;
                    catch
                        return;
                    end
                end
                figW = fpx(3); figH = fpx(4);
                if(not(all(isfinite([figW figH]))) || figW <= 0 || figH <= 0)
                    return;
                end
                try
                    apx = getpixelposition(hAx);
                catch
                    apx = [];
                end
                if(isempty(apx) || numel(apx) < 4 || any(not(isfinite(apx))))
                    return;
                end
                [tw, th] = LaunchVehicleViewProfileOverlayData.measureTight(hText);
                if(not(all(isfinite([tw th]))) || tw <= 0 || th <= 0)
                    return;
                end
                try
                    mgn = hText.Margin;
                catch
                    mgn = 0;
                end
                if(isempty(mgn) || not(isfinite(mgn)) || mgn < 0)
                    mgn = 0;
                end
                bw = (tw + 2*mgn) / figW;
                bh = (th + 2*mgn) / figH;
                cx = (apx(1) + xN*apx(3)) / figW;
                cy = (apx(2) + yN*apx(4)) / figH;
                if(strcmpi(hAlign, 'left'))
                    bx = cx;
                else
                    bx = cx - bw;
                end
                if(strcmpi(vAlign, 'top'))
                    by = cy - bh;
                else
                    by = cy;
                end
                bx = min(max(bx, 0), max(0, 1 - bw));
                by = min(max(by, 0), max(0, 1 - bh));
                pos = [bx by bw bh];
            catch
                pos = [];
            end
        end

        function [tw, th] = measureTight(hText)
            %measureTight Tight content size in pixels via a reused hidden
            %probe (text Extent is font-metric based and synchronous).
            %[NaN NaN] on failure (callers keep the previous box).
            tw = NaN; th = NaN;
            persistent probeFig probeTx;
            try
                if(isempty(probeFig) || not(all(isvalid(probeFig))))
                    probeFig = figure('Visible', 'off', 'HandleVisibility', 'off', ...
                                      'Tag', 'LvdOverlayProbe', 'MenuBar', 'none', ...
                                      'ToolBar', 'none', 'NumberTitle', 'off', ...
                                      'Name', 'KSPTOT overlay measure probe');
                    probeAx = axes('Parent', probeFig, 'Visible', 'off', 'Tag', 'LvdOverlayProbeAxes');
                    probeTx = text(probeAx, 0, 0, '', 'Units', 'pixels', 'Visible', 'off', ...
                                   'Tag', 'LvdOverlayProbeText', 'Interpreter', 'none');
                end
                if(isempty(probeTx) || not(all(isvalid(probeTx))))
                    try
                        probeTx = findobj(probeFig, 'Tag', 'LvdOverlayProbeText');
                    catch
                    end
                    if(isempty(probeTx) || not(all(isvalid(probeTx))))
                        return;
                    end
                    probeTx = probeTx(1);
                end
                probeTx.String = hText.String;
                try
                    probeTx.FontName = hText.FontName;
                catch
                end
                try
                    probeTx.FontSize = hText.FontSize;
                catch
                end
                try
                    probeTx.FontWeight = hText.FontWeight;
                catch
                end
                e = probeTx.Extent;
                tw = e(3); th = e(4);
            catch
            end
        end

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
