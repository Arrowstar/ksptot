classdef LaunchVehicleViewProfileOverlayData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileOverlayData Draws the view profile's data
    %overlay (LvdViewOverlaySettings) as one text block on the 3-D axes and
    %updates it on every rendered frame.
    %
    %   The block lives in a transparent 2-D overlay axes in the 3-D axes'
    %   own grid cell: the overlay has its own fixed 2-D camera, so unlike
    %   a normalized 3-D position the block is never re-projected through
    %   the scene camera (no drift on dolly/orbit, no disappearing at
    %   range, no occlusion by the planet).  Same-cell stacking also keeps
    %   the overlay inside every getframe/export capture, and HitTest off
    %   keeps the mouse on the 3-D view.  A figure annotation would do the
    %   same job but cannot parent to a uifigure, which the LVD window is.
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
        hMainAx = [];               %the 3-D view axes (for data-box mapping)
        computed(1,1) logical = false;
        itemSegments(1,:) cell = {};   %per item: struct array (times, interp)
        itemUnits(1,:) cell = {};
        itemErrors(1,:) cell = {};
        missionStartTime(1,1) double = NaN;
    end

    properties(Constant)
        TextTag = 'LvdViewOverlayText';
        OverlayAxesTag = 'LvdViewOverlayAxes';
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
            %Lazy: nothing is created while the overlay is off, so a
            %disabled overlay leaves the figure layout pixel-identical.
            if(isempty(obj.settings) || not(obj.settings.enabled) || not(obj.settings.hasContent()))
                LaunchVehicleViewProfileOverlayData.hideExisting(hAx);
                obj.hide();
                return;
            end

            lines = obj.buildLines(time);
            if(isempty(lines))
                LaunchVehicleViewProfileOverlayData.hideExisting(hAx);
                obj.hide();
                return;
            end

            ovAx = LaunchVehicleViewProfileOverlayData.getOverlayAxes(hAx);
            if(isempty(ovAx))
                obj.hide();
                return;
            end

            %Migration: drop figure annotations left by an earlier revision
            %(a TextBox cannot parent to a uifigure).  The live block lives
            %in the overlay axes, so anything else with this tag goes.
            try
                hFigM = ancestor(hAx, 'figure');
                if(not(isempty(hFigM)) && all(isvalid(hFigM)))
                    tagged = findobj(hFigM(1), 'Tag', obj.TextTag);
                    for(k=1:numel(tagged))
                        try
                            if(isvalid(tagged(k)) && (isa(tagged(k), 'matlab.graphics.shape.TextBox') || ...
                               (isequal(tagged(k).Parent, hAx) && not(isequal(obj.hText, tagged(k))))))
                                delete(tagged(k));
                            end
                        catch
                        end
                    end
                end
            catch
            end

            %Adopt the live block (a previous data object rebuilt on replot
            %while its overlay graphics outlived it) instead of stacking.
            needsNew = isempty(obj.hText) || not(isvalid(obj.hText));
            if(not(needsNew))
                try
                    needsNew = not(isa(obj.hText, 'matlab.graphics.primitive.Text')) || not(isequal(obj.hText.Parent, ovAx));
                catch
                    needsNew = true;
                end
            end
            if(needsNew)
                try
                    if(not(isempty(obj.hText)) && all(isvalid(obj.hText)))
                        delete(obj.hText);
                    end
                catch
                end
                obj.hText = [];
                try
                    existing = findobj(ovAx, 'Tag', obj.TextTag);
                    for(k=1:numel(existing))
                        try
                            if(isvalid(existing(k)) && isa(existing(k), 'matlab.graphics.primitive.Text') && isempty(obj.hText))
                                obj.hText = existing(k);
                            else
                                delete(existing(k));
                            end
                        catch
                        end
                    end
                catch
                end
                if(isempty(obj.hText))
                    obj.hText = text(ovAx, 0, 0, 0, lines, ...
                                     'Units', 'normalized', ...
                                     'Interpreter', 'none', ...
                                     'HitTest', 'off', ...
                                     'PickableParts', 'none', ...
                                     'Clipping', 'off', ...
                                     'Margin', 6, ...
                                     'Tag', obj.TextTag);
                end
                %A newborn block dirties the overlay layout; flush once so
                %the InnerPosition reads below are settled on this very
                %frame (plain drawnow: limitrate may legitimately skip, and
                %stale insets misplace the block until the next frame).
                %Steady-state frames skip this entirely.
                try
                    drawnow;
                catch
                end
            else
                obj.hText.String = lines;
            end
            obj.applyAppearance(hAx);
            %Mirror the 3-D view visibility (e.g. the Ground Track tab hides
            %it).  An invisible figure is an offscreen/test render, where
            %the axes' own Visible flag is not meaningful (layout passes can
            %flip it transiently), so the block stays on there.
            try
                showIt = true;
                try
                    hFigV = ancestor(hAx, 'figure');
                    figVisOn = strcmp(hFigV(1).Visible, 'on');
                catch
                    figVisOn = true;
                end
                if(figVisOn)
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

        function applyAppearance(obj, hAx)
            %applyAppearance Placement, font and background from the settings.
            %   The anchor (fraction of the 3-D view's OUTER box, top corners
            %   at half margin for optical alignment) is mapped into the
            %   overlay axes' data box via the overlay InnerPosition, so the
            %   block lands on the same screen pixels however the two axes'
            %   insets differ.  Deliberately the OUTER box on the 3-D side:
            %   its InnerPosition breathes with the 3-D camera (insets are
            %   projection-derived), which would recouple the block to camera
            %   moves; the outer rect is layout-managed and never moves with
            %   the camera.  The mapping only runs on settled geometry —
            %   outer rects agreeing AND insets matching the previous frame
            %   (outer agreement alone still admits mid-reflow insets, which
            %   overshoot the block off the top when maximizing).  Raw
            %   fractions otherwise: always fully visible, slightly low at
            %   worst, and the next render re-decides.
            if(isempty(obj.hText) || not(isvalid(obj.hText)))
                return;
            end
            if(nargin < 2 || isempty(hAx) || not(all(isvalid(hAx))))
                hAx = obj.hMainAx;
            end
            if(not(isempty(hAx)) && all(isvalid(hAx)))
                obj.hMainAx = hAx;
            end
            s = obj.settings;
            [x, y, hAlign, vAlign] = s.getAnchor();
            if(strcmpi(vAlign, 'top'))
                y = 1 - s.marginFrac/2;
            end
            try
                hOv = obj.hText.Parent;
                axOut = hAx.Position;
                ovOut = hOv.Position;
                ovIn = hOv.InnerPosition;
                axUnits = hAx.Units;
                ovUnits = hOv.Units;
            catch
                axOut = [];
            end
            try
                okShapes = not(isempty(axOut)) && numel(axOut) >= 4 && all(isfinite(axOut)) && all(axOut(3:4) > 0) && ...
                           numel(ovIn) >= 4 && all(isfinite(ovIn)) && all(ovIn(3:4) > 0) && ...
                           ischar(axUnits) && ischar(ovUnits) && strcmpi(axUnits, ovUnits);
            catch
                okShapes = false;
            end
            %Use the mapped placement only on settled geometry.  Two gates,
            %both required: the outer rects must agree (mid-reflow the
            %layout engine hands the two same-cell axes different rects),
            %AND the full geometry must match the previous frame (outer
            %rects can agree while the insets are still converging — that
            %combination overshoots the block off the top, which is exactly
            %the resize cutoff this guards).  Raw fractions otherwise:
            %always fully visible, ~12 px low at worst.  The last-seen
            %geometry rides on the overlay axes so it outlives replots; the
            %next render always re-decides, so nothing can stick.
            try
                outerAgree = max(abs(axOut(1:4) - ovOut(1:4))) <= 1.5;
            catch
                outerAgree = false;
            end
            try
                lastGeom = getappdata(hOv, 'LvdOverlayLastGeom');
                geomNow = [axOut(:)', ovIn(:)'];
                converged = isequal(geomNow, lastGeom);
                if(okShapes)
                    setappdata(hOv, 'LvdOverlayLastGeom', geomNow);
                end
            catch
                converged = false;
            end
            try
                okMap = okShapes && outerAgree && converged;
            catch
                okMap = false;
            end
            if(okMap)
                xn = (axOut(1) + x*axOut(3) - ovIn(1))/ovIn(3);
                yn = (axOut(2) + y*axOut(4) - ovIn(2))/ovIn(4);
            else
                xn = x;
                yn = y;
            end
            obj.hText.Units = 'normalized';
            obj.hText.Position = [xn, yn, 0];
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
            %deleteGraphics Removes the block (replot rebuilds it on the
            %next rendered frame).
            try
                if(not(isempty(obj.hText)) && all(isvalid(obj.hText)))
                    delete(obj.hText);
                end
            catch
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
        function ovAx = getOverlayAxes(hAx)
            %getOverlayAxes Transparent 2-D axes in the 3-D axes' own grid
            %cell that owns the overlay text.  Shared singleton per grid
            %(adopted across replots); [] on any failure.  Never throws.
            %
            %   Two grid footguns are guarded: a fresh axes in a grid
            %   auto-expands it (halving the 3-D view), and GridLayoutOptions
            %   is a VALUE class, so the cell must be assigned DIRECTLY on
            %   the axes (`ovAx.Layout.Row = ...` — staging it in a temp is
            %   a silent no-op).  The grid geometry and the 3-D axes rect are
            %   verified afterwards; anything off and the overlay is dropped.
            ovAx = [];
            try
                if(isempty(hAx) || not(all(isvalid(hAx))))
                    return;
                end
                hParent = hAx.Parent;
                if(isempty(hParent) || not(all(isvalid(hParent))))
                    return;
                end
                try
                    hFig = ancestor(hAx, 'figure');
                catch
                    hFig = [];
                end
                if(not(isempty(hFig)))
                    hFig = hFig(1);
                end
                try
                    found = findobj(hParent, 'Tag', LaunchVehicleViewProfileOverlayData.OverlayAxesTag);
                catch
                    found = [];
                end
                for(k=1:numel(found))
                    try
                        if(isvalid(found(k)) && (isa(found(k), 'matlab.graphics.axis.Axes') || isa(found(k), 'matlab.ui.control.UIAxes')))
                            if(isempty(ovAx))
                                ovAx = found(k);
                            else
                                delete(found(k));   %never more than one
                            end
                        else
                            try
                                delete(found(k));
                            catch
                            end
                        end
                    catch
                    end
                end
                createdHere = false;
                if(isempty(ovAx))
                    createdHere = true;
                    %Creating an axes steals CurrentAxes; hand it back so
                    %the 3-D view keeps whatever it had.
                    try
                        prevCA = hFig.CurrentAxes;
                    catch
                        prevCA = [];
                    end
                    try
                        isUI = not(isempty(hFig)) && all(isvalid(hFig)) && isa(hFig, 'matlab.ui.Figure');
                    catch
                        isUI = false;
                    end
                    try
                        if(isUI)
                            ovAx = uiaxes(hParent, 'Tag', LaunchVehicleViewProfileOverlayData.OverlayAxesTag);
                        else
                            ovAx = axes(hParent, 'Tag', LaunchVehicleViewProfileOverlayData.OverlayAxesTag);
                        end
                    catch
                        ovAx = [];
                    end
                    try
                        if(not(isempty(prevCA)) && all(isvalid(prevCA)) && all(isvalid(hFig)))
                            hFig.CurrentAxes = prevCA;
                        end
                    catch
                    end
                    if(isempty(ovAx))
                        return;
                    end
                    try
                        view(ovAx, 2);
                    catch
                        try
                            ovAx.View = [0 90];
                        catch
                        end
                    end
                    %Flush once so the new axes' InnerPosition reads settled
                    %on the very first frame (plain drawnow: limitrate may
                    %legitimately skip.  Creation is rare — once per replot
                    %— so this costs nothing per frame).
                    try
                        drawnow;
                    catch
                    end
                end
                %Same cell as the 3-D view (direct assignment — see header).
                %Figure-parented axes have no Layout — those sync the rect
                %instead.
                try
                    tmpLay = hAx.Layout;
                    hasLayout = not(isempty(tmpLay));
                catch
                    hasLayout = false;
                end
                if(hasLayout)
                    try
                        ovAx.Layout.Row = hAx.Layout.Row;
                        ovAx.Layout.Column = hAx.Layout.Column;
                    catch
                    end
                else
                    try
                        ovAx.Units = hAx.Units;
                        ovAx.Position = hAx.Position;
                    catch
                    end
                end
                %Re-assert the invisibility contract every render (cheap;
                %also repairs any external theming that recoloured it).
                try
                    ovAx.Color = 'none';
                catch
                end
                try
                    ovAx.XColor = 'none'; ovAx.YColor = 'none'; ovAx.ZColor = 'none';
                catch
                end
                try
                    ovAx.XTick = []; ovAx.YTick = []; ovAx.ZTick = [];
                catch
                end
                try
                    ovAx.Box = 'off';
                catch
                end
                try
                    ovAx.Toolbar.Visible = 'off';
                catch
                end
                try
                    ovAx.Interactions = [];
                catch
                end
                try
                    disableDefaultInteractivity(ovAx);
                catch
                end
                try
                    ovAx.HitTest = 'off';
                catch
                end
                try
                    ovAx.PickableParts = 'none';
                catch
                end
                try
                    if(not(isequal(hParent.Children(end), ovAx)))
                        uistack(ovAx, 'top');
                    end
                catch
                end
                %Verify: same cell (or same rect without a grid).  Only a
                %freshly created overlay that refuses its cell is deleted
                %(it would corrupt the layout); an adopted one is left
                %alone, and the 3-D rect is never compared — layout passes
                %triggered by our own drawnow can shift it mid-call, and
                %deleting over that churns forever with no overlay and no
                %error.  (We never modify the 3-D axes, so there is nothing
                %to guard there.)
                try
                    if(hasLayout)
                        okCell = isequal(ovAx.Layout.Row, hAx.Layout.Row) && isequal(ovAx.Layout.Column, hAx.Layout.Column);
                    else
                        okCell = isequal(ovAx.Position, hAx.Position);
                    end
                catch
                    okCell = false;
                end
                if(not(okCell) && createdHere)
                    try
                        delete(ovAx);
                    catch
                    end
                    ovAx = [];
                    return;
                end
            catch
                ovAx = [];
            end
        end

        function hideExisting(hAx)
            %hideExisting Hides any live overlay block for hAx's figure
            %(covers a previous data object's block this object never
            %adopted).  Never throws, never creates graphics.
            try
                if(isempty(hAx) || not(all(isvalid(hAx))))
                    return;
                end
                try
                    hFig = ancestor(hAx, 'figure');
                catch
                    return;
                end
                if(isempty(hFig) || not(all(isvalid(hFig))))
                    return;
                end
                tx = findobj(hFig(1), 'Tag', LaunchVehicleViewProfileOverlayData.TextTag);
                for(k=1:numel(tx))
                    try
                        if(isvalid(tx(k)) && isa(tx(k), 'matlab.graphics.primitive.Text'))
                            tx(k).Visible = 'off';
                        end
                    catch
                    end
                end
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
