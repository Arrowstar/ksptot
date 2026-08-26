classdef SkyboxManager < handle
    %SkyboxManager  Per-profile skybox lifecycle for LVD 3D axes.
    %
    %   Owns hgtransform+surf, cached sphere, cached image, listeners and
    %   a coalescing timer.  One instance per LaunchVehicleViewProfile
    %   (per-profile requirement), attached to a single axes at a time.
    %
    %   Usage: profile.getSkyboxManager().attach(ax, lvdData)

    properties(Access=private)
        viewProfile   % LaunchVehicleViewProfile (weak)
        hAx           % matlab.graphics.axis.Axes
        hTransform    % hgtransform
        hSurf         % matlab.graphics.primitive.Surface
        skyImage      % cached uint8 image
        skyImagePath  % string of loaded image path
        origin(1,3) double = [NaN NaN NaN]
        radius(1,1) double = NaN
        isUpdating(1,1) logical = false
        isAttached(1,1) logical = false
        savedAxesState struct = struct.empty(1,0)
    end

    properties(Access=private, Transient)
        listeners = event.listener.empty(1,0)
        axesDestroyedListener = event.listener.empty(1,0)
        debounceTimer = []
        lvdDataRef    % LvdData handle for callbacks
    end

    properties(Constant, Access=private)
        Tessellation = 96
        DebounceDelay = 0.05 % seconds
        MinRadius = 1e3
        MaxRadius = 1e9
        FallbackRadius = 1e5
        RecenterFraction = 0.5
    end

    methods
        function obj = SkyboxManager(viewProfile)
            if nargin > 0 && ~isempty(viewProfile)
                obj.viewProfile = viewProfile;
            end
        end

        function delete(obj)
            % Ensure timer and graphics are cleaned up
            try
                obj.detach();
            catch
            end
            try
                if ~isempty(obj.debounceTimer) && isvalid(obj.debounceTimer)
                    stop(obj.debounceTimer);
                    delete(obj.debounceTimer);
                end
            catch
            end
        end

        function tf = getIsAttached(obj)
            arguments
                obj(1,1) SkyboxManager
            end
            tf = obj.isAttached && ~isempty(obj.hAx) && isvalid(obj.hAx) && isgraphics(obj.hAx);
        end

        function ax = getAttachedAxes(obj)
            arguments
                obj(1,1) SkyboxManager
            end
            ax = obj.hAx;
        end

        function tf = getIsUpdating(obj)
            tf = obj.isUpdating;
        end

        function reapplyAxesSettings(obj)
            arguments
                obj(1,1) SkyboxManager
            end
            if obj.isAttached && ~isempty(obj.hAx) && isvalid(obj.hAx)
                obj.applySkyboxAxesSettings(obj.hAx);
            end
        end

        function attach(obj, hAx, lvdData)
            arguments
                obj(1,1) SkyboxManager
                hAx(1,1) matlab.graphics.axis.Axes
                lvdData
            end

            if ~isgraphics(hAx) || ~isvalid(hAx)
                return;
            end

            % If already attached to same axes, just ensure enabled state
            if obj.isAttached && isvalid(obj.hAx) && obj.hAx == hAx
                obj.lvdDataRef = lvdData;
                obj.updateVisibilityFromProfile();
                obj.scheduleUpdate(true);
                return;
            end

            % Detach from previous axes if needed
            if obj.isAttached
                obj.detach();
            end

            obj.hAx = hAx;
            obj.lvdDataRef = lvdData;
            obj.isAttached = true;

            % Save axes state before we mutate it (for restore on detach)
            obj.saveAxesState(hAx);

            % Apply skybox-required axes settings if enabled
            obj.applySkyboxAxesSettings(hAx);

            % Create hgtransform + surf if needed (lazy)
            obj.ensureGraphics(hAx);

            % Install listeners for camera and limits
            obj.installListeners(hAx);

            % Visibility according to profile
            obj.updateVisibilityFromProfile();

            % Initial update (force)
            obj.updateIfNeeded(true);
        end

        function detach(obj)
            % Remove listeners, timer, and optionally hide graphics.
            % Detach does NOT delete the surf - just hides and disconnects
            % so that re-attach can reuse it.  Full delete happens on manager delete.

            obj.cancelDebounce();

            % Delete listeners
            try
                if ~isempty(obj.listeners)
                    for k=1:numel(obj.listeners)
                        if isvalid(obj.listeners(k))
                            delete(obj.listeners(k));
                        end
                    end
                end
            catch
            end
            obj.listeners = event.listener.empty(1,0);

            try
                if ~isempty(obj.axesDestroyedListener) && isvalid(obj.axesDestroyedListener)
                    delete(obj.axesDestroyedListener);
                end
            catch
            end
            obj.axesDestroyedListener = event.listener.empty(1,0);

            % Hide surf but keep object for reuse; also restore axes state
            if ~isempty(obj.hSurf) && isvalid(obj.hSurf)
                try
                    obj.hSurf.Visible = 'off';
                catch
                end
            end
            if ~isempty(obj.hTransform) && isvalid(obj.hTransform)
                try
                    obj.hTransform.Visible = 'off';
                catch
                end
            end

            if obj.isAttached && ~isempty(obj.hAx) && isgraphics(obj.hAx) && isvalid(obj.hAx)
                obj.restoreAxesState(obj.hAx);
            end

            % Clear deprecated handles sync?
            obj.trySyncDeprecatedHandles();

            obj.isAttached = false;
            obj.hAx = matlab.graphics.axis.Axes.empty(1,0);
            obj.lvdDataRef = [];
        end

        function setVisible(obj, tf)
            arguments
                obj(1,1) SkyboxManager
                tf(1,1) logical
            end
            if ~isempty(obj.hSurf) && isvalid(obj.hSurf)
                if tf
                    obj.hSurf.Visible = 'on';
                    if ~isempty(obj.hTransform) && isvalid(obj.hTransform)
                        obj.hTransform.Visible = 'on';
                    end
                    if obj.isAttached && isvalid(obj.hAx)
                        obj.applySkyboxAxesSettings(obj.hAx);
                    end
                else
                    obj.hSurf.Visible = 'off';
                    if ~isempty(obj.hTransform) && isvalid(obj.hTransform)
                        obj.hTransform.Visible = 'off';
                    end
                    if obj.isAttached && isvalid(obj.hAx)
                        obj.restoreAxesState(obj.hAx);
                    end
                end
            end
            % Also ensure hgtransform visibility
            if ~isempty(obj.hTransform) && isvalid(obj.hTransform)
                obj.hTransform.Visible = tf2onoff(tf);
            end
        end

        function updateIfNeeded(obj, force)
            arguments
                obj(1,1) SkyboxManager
                force(1,1) logical = false
            end

            if obj.isUpdating
                return;
            end
            if ~obj.isAttached
                return;
            end
            if isempty(obj.hAx) || ~isvalid(obj.hAx) || ~isgraphics(obj.hAx)
                obj.detach();
                return;
            end
            if isempty(obj.viewProfile) || ~isvalid(obj.viewProfile)
                return;
            end
            if ~obj.viewProfile.useSkybox
                obj.setVisible(false);
                return;
            end

            % Guard against re-entrancy (setting transform triggers listeners?)
            obj.isUpdating = true;
            cleanup = onCleanup(@() setIsUpdatingFalse(obj));
            try
                hAx = obj.hAx;
                % Snapshot camera (use getters that don't trigger listeners)
                try
                    camPos = hAx.CameraPosition;
                    camTgt = hAx.CameraTarget;
                    camVA  = hAx.CameraViewAngle;
                catch
                    return;
                end

                if any(~isfinite(camPos)) || any(~isfinite(camTgt)) || ~isfinite(camVA)
                    return;
                end

                % Compute new size early so radius-change can trigger needUpdate
                multiplier = 1.5;
                try
                    if ~isempty(obj.viewProfile) && isprop(obj.viewProfile,'skyboxRadiusMultiplier')
                        multiplier = obj.viewProfile.skyboxRadiusMultiplier;
                    end
                catch
                end
                % Precompute newRadius for needUpdate check (use try to avoid errors during early init)
                try
                    newRadiusEarly = obj.computeSkyboxSize(hAx, camPos, camTgt, camVA, multiplier);
                catch
                    newRadiusEarly = NaN;
                end

                % Check if we need to recenter/resize
                needUpdate = force;
                if ~needUpdate
                    if any(isnan(obj.origin)) || isnan(obj.radius) || isempty(obj.hSurf) || ~isvalid(obj.hSurf)
                        needUpdate = true;
                    else
                        distFromOrigin = norm(camPos - obj.origin);
                        if distFromOrigin > obj.RecenterFraction * obj.radius
                            needUpdate = true;
                        end
                        % Also trigger if required radius has grown/shrunk significantly
                        % (e.g., zooming far out via dolly, or xlim change) even if dist small
                        if ~needUpdate && isfinite(obj.radius) && isfinite(newRadiusEarly)
                            if abs(newRadiusEarly - obj.radius)/obj.radius >= 0.05
                                needUpdate = true;
                            end
                        end
                    end
                end
                % Also check if surf is invalid or transform invalid -> force
                if isempty(obj.hTransform) || ~isvalid(obj.hTransform) || isempty(obj.hSurf) || ~isvalid(obj.hSurf)
                    needUpdate = true;
                    obj.ensureGraphics(hAx);
                end

                if ~needUpdate
                    % No resize needed, just ensure visual follow (translateOnly already did, but ensure)
                    % Use setTransformTranslation to also update origin for next check
                    obj.setTransformTranslation(camPos);
                    obj.setVisible(true);
                    return;
                end

                % Use precomputed newRadius if valid, otherwise recompute
                newRadius = newRadiusEarly;
                if ~isfinite(newRadius)
                    newRadius = obj.computeSkyboxSize(hAx, camPos, camTgt, camVA, multiplier);
                end

                % If size is similar to previous, just translate
                if ~force && isfinite(obj.radius) && isfinite(newRadius) && abs(newRadius - obj.radius)/obj.radius < 0.05
                    % Keep same radius, just translate
                    obj.origin = camPos;
                    obj.setTransformTranslation(camPos);
                    obj.setVisible(true);
                    obj.syncDeprecatedState();
                    return;
                end

                obj.origin = camPos;
                obj.radius = newRadius;

                % Ensure image is loaded
                img = obj.getOrLoadImage();
                if isempty(img)
                    % No image -> cannot show skybox
                    obj.setVisible(false);
                    return;
                end

                % Ensure graphics exists and update transform
                obj.ensureGraphics(hAx);
                % Update transform to new scale+translation
                obj.updateTransform(hAx, camPos, newRadius, img);

                obj.setVisible(true);

                % Sync deprecated props for backward compat (1 release)
                obj.syncDeprecatedState();

                % Keep skybox at bottom of render order
                try
                    % Use findall to locate even if HandleVisibility off
                    allKids = findall(hAx,'Type','surface','Tag','KSPTOT_Skybox');
                    if ~isempty(allKids)
                        % hgtransform child order matters? Ensure our transform is at bottom
                        % uistack works on axes children (hgtransform is a child)
                        try
                            uistack(obj.hTransform,'bottom');
                        catch
                        end
                    end
                catch
                end

                % Capture restored camera? The original code restored campos after Visible off trick.
                % With hgtransform we don't need that, but keep for safety if we ever trigger autoscale.
            catch ME
                % Don't let skybox errors break main plotting - warn once
                try
                    warning('SkyboxManager:updateFailed', 'Skybox update failed: %s', ME.message);
                catch
                end
            end
        end

        function scheduleUpdate(obj, force)
            arguments
                obj(1,1) SkyboxManager
                force(1,1) logical = false
            end
            if ~obj.isAttached || obj.isUpdating
                if force
                    obj.updateIfNeeded(true);
                end
                return;
            end
            if force
                obj.cancelDebounce();
                obj.updateIfNeeded(true);
                return;
            end
            % Debounce via timer: restart timer
            try
                if isempty(obj.debounceTimer) || ~isvalid(obj.debounceTimer)
                    obj.debounceTimer = timer( ...
                        'ExecutionMode','singleShot', ...
                        'StartDelay', obj.DebounceDelay, ...
                        'TimerFcn', @(~,~) obj.onDebounceTimer(), ...
                        'ErrorFcn', @(~,~) obj.cancelDebounce(), ...
                        'BusyMode','drop');
                end
                % Restart
                if strcmp(obj.debounceTimer.Running,'on')
                    stop(obj.debounceTimer);
                end
                start(obj.debounceTimer);
            catch
                % Fallback: immediate update
                obj.updateIfNeeded(false);
            end
        end
    end

    methods(Access=private)
        function setIsUpdatingFalse(obj)
            obj.isUpdating = false;
        end

        function onCameraChanged(obj, ~, ~)
            % Listener callback for any camera/limit change
            % Immediate translation: keep skybox visually centered without debounce
            % Use translate-only (does not update obj.origin) so that debounced
            % updateIfNeeded can still detect large moves via dist>0.5*radius
            try
                if obj.isAttached && ~isempty(obj.hAx) && isvalid(obj.hAx) && isfinite(obj.radius) && ~any(isnan(obj.origin))
                    try
                        camPos = obj.hAx.CameraPosition;
                        if all(isfinite(camPos))
                            if norm(camPos - obj.origin) > 1e-9
                                obj.translateTransformOnly(camPos);
                            end
                        end
                    catch
                    end
                    % Enforce critical axes settings that view/orbit may have clobbered
                    try
                        if ~strcmp(obj.hAx.Clipping,'off')
                            obj.hAx.Clipping = 'off';
                        end
                    catch
                    end
                    try
                        if ~strcmp(obj.hAx.SortMethod,'childorder')
                            obj.hAx.SortMethod = 'childorder';
                        end
                    catch
                    end
                    try
                        if ~strcmp(obj.hAx.ClippingStyle,'3dbox')
                            obj.hAx.ClippingStyle = '3dbox';
                        end
                    catch
                    end
                    try
                        if ~strcmp(obj.hAx.Projection,'perspective')
                            obj.hAx.Projection = 'perspective';
                        end
                    catch
                    end
                end
            catch
            end
            if obj.isUpdating
                return;
            end
            % Debounced resize/recenter if needed (handles growth)
            obj.scheduleUpdate(false);
        end

        function onDebounceTimer(obj)
            try
                obj.updateIfNeeded(false);
            catch
            end
        end

        function cancelDebounce(obj)
            try
                if ~isempty(obj.debounceTimer) && isvalid(obj.debounceTimer) && strcmp(obj.debounceTimer.Running,'on')
                    stop(obj.debounceTimer);
                end
            catch
            end
        end

        function onAxesDestroyed(obj, ~, ~)
            try
                obj.detach();
            catch
            end
        end

        function saveAxesState(obj, hAx)
            try
                obj.savedAxesState = struct( ...
                    'XTick', hAx.XTick, ...
                    'YTick', hAx.YTick, ...
                    'ZTick', hAx.ZTick, ...
                    'XTickMode', hAx.XTickMode, ...
                    'YTickMode', hAx.YTickMode, ...
                    'ZTickMode', hAx.ZTickMode, ...
                    'Box', hAx.Box, ...
                    'XColor', hAx.XColor, ...
                    'YColor', hAx.YColor, ...
                    'ZColor', hAx.ZColor, ...
                    'Projection', hAx.Projection, ...
                    'Clipping', hAx.Clipping, ...
                    'ClippingStyle', hAx.ClippingStyle, ...
                    'DataAspectRatio', hAx.DataAspectRatio, ...
                    'DataAspectRatioMode', hAx.DataAspectRatioMode, ...
                    'PlotBoxAspectRatio', hAx.PlotBoxAspectRatio, ...
                    'PlotBoxAspectRatioMode', hAx.PlotBoxAspectRatioMode, ...
                    'SortMethod', hAx.SortMethod);
            catch
                obj.savedAxesState = struct.empty(1,0);
            end
        end

        function restoreAxesState(obj, hAx)
            if isempty(obj.savedAxesState) || ~isstruct(obj.savedAxesState)
                % Fallback minimal restore
                try
                    hAx.XTickMode = 'auto';
                    hAx.YTickMode = 'auto';
                    hAx.ZTickMode = 'auto';
                    hAx.Box = 'on';
                catch
                end
                return;
            end
            try
                s = obj.savedAxesState;
                if isfield(s,'XTickMode'), hAx.XTickMode = s.XTickMode; end
                if isfield(s,'YTickMode'), hAx.YTickMode = s.YTickMode; end
                if isfield(s,'ZTickMode'), hAx.ZTickMode = s.ZTickMode; end
                if isfield(s,'Box'), hAx.Box = s.Box; end
                if isfield(s,'XColor'), hAx.XColor = s.XColor; end
                if isfield(s,'YColor'), hAx.YColor = s.YColor; end
                if isfield(s,'ZColor'), hAx.ZColor = s.ZColor; end
                if isfield(s,'Projection')
                    try
                        hAx.Projection = s.Projection;
                    catch
                    end
                end
                if isfield(s,'Clipping'), hAx.Clipping = s.Clipping; end
                if isfield(s,'ClippingStyle'), hAx.ClippingStyle = s.ClippingStyle; end
                if isfield(s,'SortMethod')
                    try
                        hAx.SortMethod = s.SortMethod;
                    catch
                    end
                end
                if isfield(s,'DataAspectRatio') && isfield(s,'DataAspectRatioMode')
                    try
                        hAx.DataAspectRatioMode = s.DataAspectRatioMode;
                        if strcmp(s.DataAspectRatioMode,'manual')
                            hAx.DataAspectRatio = s.DataAspectRatio;
                        end
                    catch
                    end
                end
                if isfield(s,'PlotBoxAspectRatio') && isfield(s,'PlotBoxAspectRatioMode')
                    try
                        hAx.PlotBoxAspectRatioMode = s.PlotBoxAspectRatioMode;
                        if strcmp(s.PlotBoxAspectRatioMode,'manual')
                            hAx.PlotBoxAspectRatio = s.PlotBoxAspectRatio;
                        end
                    catch
                    end
                end
            catch
            end
        end

        function applySkyboxAxesSettings(~, hAx)
            % Enforce settings required for skybox to work
            try
                hAx.Clipping = 'off';
                % ClippingStyle only meaningful when Clipping on, but keep 3dbox
                try
                    hAx.ClippingStyle = '3dbox';
                catch
                end
                hAx.Projection = 'perspective';
                % Use childorder so skybox (bottom) is drawn first and never depth-sorted in front of trajectory
                try
                    hAx.SortMethod = 'childorder';
                catch
                end
                % Hide ticks/grid/box for skybox aesthetic; these are intentional per original design
                % We keep user's gridType etc for other elements? Original code forced grid off + equal + no ticks when skybox on.
                try
                    grid(hAx,'off');
                catch
                end
                try
                    axis(hAx,'equal');
                catch
                end
                hAx.XTick = [];
                hAx.YTick = [];
                hAx.ZTick = [];
                hAx.Box = 'off';
                hAx.XColor = 'none';
                hAx.YColor = 'none';
                hAx.ZColor = 'none';
            catch
            end
        end

        function updateVisibilityFromProfile(obj)
            if isempty(obj.viewProfile) || ~isvalid(obj.viewProfile)
                obj.setVisible(false);
                return;
            end
            try
                tf = logical(obj.viewProfile.useSkybox);
            catch
                tf = false;
            end
            obj.setVisible(tf);
        end

        function ensureGraphics(obj, hAx)
            if ~isempty(obj.hTransform) && isvalid(obj.hTransform) && ~isempty(obj.hSurf) && isvalid(obj.hSurf)
                return;
            end
            % Create hgtransform
            try
                if isempty(obj.hTransform) || ~isvalid(obj.hTransform)
                    obj.hTransform = hgtransform('Parent', hAx, 'Tag','KSPTOT_SkyboxTransform', 'HandleVisibility','on');
                    % Keep handle visible for SortMethod childorder to work, but hide from legend via Annotation
                    try
                        obj.hTransform.Annotation.LegendInformation.IconDisplayStyle = 'off';
                    catch
                    end
                    % Exclude transform from axes limit calculations (defensive)
                    try
                        obj.hTransform.XLimInclude = 'off'; %#ok<*NASGU>
                        obj.hTransform.YLimInclude = 'off';
                        obj.hTransform.ZLimInclude = 'off';
                        obj.hTransform.CLimInclude = 'off';
                        obj.hTransform.ALimInclude = 'off';
                    catch
                    end
                    % Ensure transform is at bottom for childorder
                    try
                        uistack(obj.hTransform,'bottom');
                    catch
                    end
                end
            catch
                obj.hTransform = [];
            end

            if isempty(obj.hSurf) || ~isvalid(obj.hSurf)
                % Get unit sphere cached
                [X0,Y0,Z0] = obj.getUnitSphere();
                % Get image (may be empty initially)
                img = obj.getOrLoadImage();
                if isempty(img)
                    % Create placeholder gray image to avoid error
                    img = uint8(128*ones(10,20,3));
                end
                try
                    hold(hAx,'on');
                    obj.hSurf = surf(hAx, X0, Y0, Z0, ...
                        'Parent', obj.hTransform, ...
                        'EdgeColor','none', ...
                        'FaceColor','texturemap', ...
                        'CData', img, ...
                        'FaceLighting','none', ...
                        'BackFaceLighting','unlit', ...
                        'HandleVisibility','on', ...
                        'HitTest','off', ...
                        'PickableParts','none', ...
                        'Tag','KSPTOT_Skybox', ...
                        'Clipping','off', ...
                        'XLimInclude','off', ...
                        'YLimInclude','off', ...
                        'ZLimInclude','off', ...
                        'CLimInclude','off', ...
                        'ALimInclude','off');
                    % Ensure it doesn't interfere with picking/data tips
                    try
                        obj.hSurf.Annotation.LegendInformation.IconDisplayStyle = 'off';
                    catch
                    end
                    % Ensure interior of sphere is visible from inside (camera at center)
                    try
                        obj.hSurf.BackFaceLighting = 'unlit';
                    catch
                    end
                    % Double-check include properties (some MATLAB versions need explicit)
                    try
                        obj.hSurf.XLimInclude = 'off';
                        obj.hSurf.YLimInclude = 'off';
                        obj.hSurf.ZLimInclude = 'off';
                        obj.hSurf.CLimInclude = 'off';
                        obj.hSurf.ALimInclude = 'off';
                    catch
                    end
                catch ME
                    warning('SkyboxManager:createSurfFailed','Failed to create skybox surface: %s', ME.message);
                    obj.hSurf = [];
                end
            end
            % Try to keep at bottom
            try
                if ~isempty(obj.hTransform) && isvalid(obj.hTransform)
                    uistack(obj.hTransform,'bottom');
                end
            catch
            end
        end

        function updateTransform(obj, ~, camPos, radius, img)
            % Update hgtransform matrix and ensure surf CData is current
            try
                % Update CData if image changed
                if ~isempty(obj.hSurf) && isvalid(obj.hSurf)
                    try
                        if ~isequal(obj.hSurf.CData, img) && ~isempty(img)
                            obj.hSurf.CData = img;
                        end
                    catch
                    end
                end
            catch
            end
            try
                if ~isempty(obj.hTransform) && isvalid(obj.hTransform)
                    % Scale unit sphere (radius 1) to desired radius and translate to camPos
                    % Use makehgtform for correctness
                    M = makehgtform('translate', camPos) * makehgtform('scale', radius);
                    % Alternative manual: but makehgtform handles homogeneous correctly
                    obj.hTransform.Matrix = M;
                end
            catch
                % Fallback: directly set XData/YData/ZData (legacy path)
                try
                    [X0,Y0,Z0] = obj.getUnitSphere();
                    obj.hSurf.XData = radius*X0 + camPos(1);
                    obj.hSurf.YData = radius*Y0 + camPos(2);
                    obj.hSurf.ZData = radius*Z0 + camPos(3);
                catch
                end
            end
        end

        function setTransformTranslation(obj, camPos)
            % Lightweight: only translate, keep current radius scale
            % Avoid redundant Matrix set which would trigger MarkedClean loop
            try
                if ~isempty(obj.origin) && all(isfinite(obj.origin)) && norm(camPos - obj.origin) < 1e-9
                    return;
                end
            catch
            end
            try
                if ~isempty(obj.hTransform) && isvalid(obj.hTransform) && isfinite(obj.radius)
                    M = makehgtform('translate', camPos) * makehgtform('scale', obj.radius);
                    % Avoid setting identical matrix (causes MarkedClean)
                    try
                        if isequal(obj.hTransform.Matrix, M)
                            obj.origin = camPos;
                            return;
                        end
                    catch
                    end
                    obj.hTransform.Matrix = M;
                    obj.origin = camPos;
                    obj.syncDeprecatedState();
                else
                    % Fallback
                    if ~isempty(obj.hSurf) && isvalid(obj.hSurf) && isfinite(obj.radius)
                        [X0,Y0,Z0] = obj.getUnitSphere();
                        obj.hSurf.XData = obj.radius*X0 + camPos(1);
                        obj.hSurf.YData = obj.radius*Y0 + camPos(2);
                        obj.hSurf.ZData = obj.radius*Z0 + camPos(3);
                        obj.origin = camPos;
                    end
                end
            catch
            end
        end

        function translateTransformOnly(obj, camPos)
            % Like setTransformTranslation but does NOT update obj.origin
            % Used for immediate visual follow without affecting resize logic
            % that relies on distFromOrigin. Prevents lag-induced outside-sphere.
            try
                if ~isempty(obj.hTransform) && isvalid(obj.hTransform) && isfinite(obj.radius)
                    curM = obj.hTransform.Matrix;
                    % Extract translation from current matrix
                    curPos = curM(1:3,4)';
                    if norm(camPos - curPos) < 1e-9
                        return;
                    end
                end
            catch
            end
            try
                if ~isempty(obj.hTransform) && isvalid(obj.hTransform) && isfinite(obj.radius)
                    M = makehgtform('translate', camPos) * makehgtform('scale', obj.radius);
                    try
                        if isequal(obj.hTransform.Matrix, M)
                            return;
                        end
                    catch
                    end
                    obj.hTransform.Matrix = M;
                    % Do NOT update obj.origin here; keep old origin for resize detection
                    % But still sync deprecated surf handle visibility? No.
                else
                    if ~isempty(obj.hSurf) && isvalid(obj.hSurf) && isfinite(obj.radius)
                        [X0,Y0,Z0] = obj.getUnitSphere();
                        % Check if already at position
                        try
                            curX = obj.hSurf.XData(1,1) - obj.radius*X0(1,1);
                            if abs(curX - camPos(1)) < 1e-9
                                return;
                            end
                        catch
                        end
                        obj.hSurf.XData = obj.radius*X0 + camPos(1);
                        obj.hSurf.YData = obj.radius*Y0 + camPos(2);
                        obj.hSurf.ZData = obj.radius*Z0 + camPos(3);
                    end
                end
            catch
            end
        end

        function [X0,Y0,Z0] = getUnitSphere(obj)
            persistent cachedX cachedY cachedZ cachedN
            n = obj.Tessellation;
            if isempty(cachedX) || isempty(cachedY) || isempty(cachedZ) || cachedN ~= n
                [cachedX, cachedY, cachedZ] = sphere(n);
                cachedN = n;
            end
            X0 = cachedX;
            Y0 = cachedY;
            Z0 = cachedZ;
        end

        function img = getOrLoadImage(obj)
            % Return cached image or load from profile's texture enum/path
            if ~isempty(obj.skyImage) && ~isempty(obj.skyImagePath)
                % Check if profile's requested path changed
                try
                    desiredPath = obj.resolveDesiredImagePath();
                    if desiredPath == obj.skyImagePath
                        img = obj.skyImage;
                        return;
                    end
                catch
                end
            end
            % Need to (re)load
            try
                desiredPath = obj.resolveDesiredImagePath();
            catch ME
                warning('SkyboxManager:resolvePathFailed','Skybox path resolve failed: %s', ME.message);
                img = obj.skyImage;
                if isempty(img)
                    img = [];
                end
                return;
            end
            if strlength(desiredPath)==0 || ~isfile(desiredPath)
                % Try fallback to default enum?
                try
                    fallback = SkyboxTextureEnum.DarkStars.getFullPath();
                    if isfile(fallback)
                        desiredPath = fallback;
                    else
                        warning('SkyboxManager:imageNotFound','Skybox image not found: %s', desiredPath);
                        img = obj.skyImage;
                        if isempty(img)
                            img = [];
                        else
                            img = obj.skyImage;
                        end
                        return;
                    end
                catch
                    warning('SkyboxManager:imageNotFound','Skybox image not found: %s', desiredPath);
                    img = obj.skyImage;
                    if isempty(img)
                        img = [];
                    end
                    return;
                end
            end
            try
                I = imread(desiredPath);
                if isempty(I)
                    error('Empty image');
                end
                % Validate dims
                if ndims(I) == 2
                    I = repmat(I,1,1,3);
                elseif size(I,3) == 4
                    I = I(:,:,1:3);
                elseif size(I,3) ~= 3
                    % Convert grayscale to RGB or handle
                    if size(I,3) ~= 3
                        I = repmat(I(:,:,1),1,1,3);
                    end
                end
                % Flip vertical to correct texture orientation (original did flipud)
                I = flipud(I);
                obj.skyImage = I;
                obj.skyImagePath = desiredPath;
                img = I;
                % Sync deprecated cache if profile still exposes skyBoxImageI
                try
                    if ~isempty(obj.viewProfile) && isprop(obj.viewProfile,'skyBoxImageI')
                        obj.viewProfile.skyBoxImageI = I;
                    end
                catch
                end
                return;
            catch ME
                warning('SkyboxManager:imreadFailed','Failed to load skybox image %s: %s', desiredPath, ME.message);
                img = obj.skyImage;
                if isempty(img)
                    img = [];
                end
                return;
            end
        end

        function path = resolveDesiredImagePath(obj)
            % Map viewProfile's skyboxTexture + custom path + deprecated string to a file path
            if isempty(obj.viewProfile) || ~isvalid(obj.viewProfile)
                path = SkyboxTextureEnum.DarkStars.getFullPath();
                return;
            end
            % Prefer new enum if exists
            if isprop(obj.viewProfile,'skyboxTexture')
                try
                    tex = obj.viewProfile.skyboxTexture;
                    if ~isempty(tex) && isvalid(tex) %#ok<ISVLD> enum isvalid?
                        if tex.isCustom()
                            % Check custom path prop
                            if isprop(obj.viewProfile,'skyboxCustomTexturePath')
                                p = string(obj.viewProfile.skyboxCustomTexturePath);
                                if strlength(p) > 0
                                    path = p;
                                    % If relative, try to resolve
                                    if ~isfile(path)
                                        % Try relative to skyboxes folder?
                                        try
                                            candidate = string(fullfile(fileparts(which('SkyboxManager.m')),"..","..","..","..","..","images","skyboxes", char(p)));
                                            candidate = string(GetFullPath(candidate));
                                            if isfile(candidate)
                                                path = candidate;
                                            end
                                        catch
                                        end
                                    end
                                    return;
                                end
                            end
                            % Fallback to deprecated string if custom path empty
                            if isprop(obj.viewProfile,'skyBoxImgFileName')
                                try
                                    dep = string(obj.viewProfile.skyBoxImgFileName);
                                    if strlength(dep)>0 && isfile(dep)
                                        path = dep;
                                        return;
                                    elseif strlength(dep)>0
                                        % Try to resolve bare filename via enum folder
                                        try
                                            classFolder = fileparts(mfilename('fullpath'));
                                            candidate = fullfile(classFolder, '..', '..', '..', '..', '..', 'images', 'skyboxes', char(dep));
                                            candidate = string(GetFullPath(candidate));
                                            if isfile(candidate)
                                                path = candidate;
                                                return;
                                            end
                                        catch
                                        end
                                        path = dep;
                                        return;
                                    end
                                catch
                                end
                            end
                            path = SkyboxTextureEnum.DarkStars.getFullPath();
                            return;
                        else
                            % Non-custom enum -> ask enum for full path
                            path = tex.getFullPath();
                            if strlength(path)>0
                                return;
                            end
                        end
                    end
                catch
                end
            end
            % Fallback: deprecated string prop
            if isprop(obj.viewProfile,'skyBoxImgFileName')
                try
                    dep = string(obj.viewProfile.skyBoxImgFileName);
                    if strlength(dep)>0
                        % If absolute and exists, use it
                        if isfile(dep)
                            path = dep;
                            return;
                        end
                        % Try enum mapping
                        try
                            [enumVal, ~] = SkyboxTextureEnum.getEnumForFileName(dep);
                            if enumVal ~= SkyboxTextureEnum.Custom
                                path = enumVal.getFullPath();
                                if isfile(path)
                                    return;
                                end
                            end
                        catch
                        end
                        % Try bare file in images/skyboxes
                        try
                            classFolder = fileparts(mfilename('fullpath'));
                            candidate = fullfile(classFolder, '..', '..', '..', '..', '..', 'images', 'skyboxes', char(dep));
                            candidate = string(GetFullPath(candidate));
                            if isfile(candidate)
                                path = candidate;
                                return;
                            end
                        catch
                        end
                        path = dep;
                        return;
                    end
                catch
                end
            end
            path = SkyboxTextureEnum.DarkStars.getFullPath();
        end

        function r = computeSkyboxSize(obj, hAx, camPos, camTgt, camVA, multiplier)
            try
                xL = xlim(hAx);
                yL = ylim(hAx);
                zL = zlim(hAx);
                if all(isfinite(xL)) && all(isfinite(yL)) && all(isfinite(zL)) && ~any(isnan([xL yL zL])) && all(xL(2)>xL(1)) && all(yL(2)>yL(1)) && all(zL(2)>zL(1))
                    xD = max(abs(camPos(1) - xL));
                    yD = max(abs(camPos(2) - yL));
                    zD = max(abs(camPos(3) - zL));
                    % Use Euclidean distance to farthest box corner for guaranteed enclosure
                    % (max per-axis underestimates corner distance, causing clipping when camera close)
                    maxDistCorner = sqrt(xD^2 + yD^2 + zD^2);
                    maxDistAxis = max([xD,yD,zD]);
                    maxDist = max(maxDistCorner, maxDistAxis);
                else
                    maxDist = NaN;
                end
            catch
                maxDist = NaN;
            end
            if ~isfinite(maxDist) || maxDist <= 0
                try
                    distToTarget = norm(camPos - camTgt);
                    if ~isfinite(distToTarget) || distToTarget==0
                        distToTarget = obj.FallbackRadius;
                    end
                    % Frustum half-height from view angle
                    frustumHalfHeight = distToTarget * tan(deg2rad(camVA)/2);
                    % Aspect from axes position
                    try
                        pos = hAx.Position;
                        if numel(pos)>=4 && pos(4)>0
                            aspect = pos(3)/pos(4);
                        else
                            aspect = 1.5;
                        end
                    catch
                        aspect = 1.5;
                    end
                    frustumHalfWidth = frustumHalfHeight * aspect;
                    maxDist = max([frustumHalfHeight, frustumHalfWidth]) * 2.5;
                    if ~isfinite(maxDist) || maxDist<=0
                        maxDist = obj.FallbackRadius;
                    end
                    % Also ensure at least fallback to avoid tiny boxes
                    maxDist = max(maxDist, obj.FallbackRadius*0.1);
                catch
                    maxDist = obj.FallbackRadius;
                end
                % If we have central body info via lvdData/profile, use that as floor
                try
                    if ~isempty(obj.viewProfile) && isprop(obj.viewProfile,'frame') && ~isempty(obj.viewProfile.frame)
                        try
                            cBody = obj.viewProfile.frame.getOriginBody();
                            if ~isempty(cBody) && isprop(cBody,'radius')
                                maxDist = max(maxDist, 5*cBody.radius);
                            end
                        catch
                        end
                    end
                catch
                end
            end
            r = multiplier * maxDist;
            r = min(max(r, obj.MinRadius), obj.MaxRadius);
            if ~isfinite(r) || r<=0
                r = obj.FallbackRadius;
            end
        end

        function installListeners(obj, hAx)
            % Clean old
            if ~isempty(obj.listeners)
                for k=1:numel(obj.listeners)
                    try
                        if isvalid(obj.listeners(k))
                            delete(obj.listeners(k));
                        end
                    catch
                    end
                end
            end
            obj.listeners = event.listener.empty(1,0);
            % PostSet listeners for camera and limits.  Use handle's PostSet.
            try
                % CameraPosition is most important, but also listen to Target/ViewAngle for zoom/rotate
                obj.listeners(end+1) = addlistener(hAx, 'CameraPosition', 'PostSet', @(~,~) obj.onCameraChanged());
                obj.listeners(end+1) = addlistener(hAx, 'CameraTarget', 'PostSet', @(~,~) obj.onCameraChanged());
                obj.listeners(end+1) = addlistener(hAx, 'CameraViewAngle', 'PostSet', @(~,~) obj.onCameraChanged());
                obj.listeners(end+1) = addlistener(hAx, 'XLim', 'PostSet', @(~,~) obj.onCameraChanged());
                obj.listeners(end+1) = addlistener(hAx, 'YLim', 'PostSet', @(~,~) obj.onCameraChanged());
                obj.listeners(end+1) = addlistener(hAx, 'ZLim', 'PostSet', @(~,~) obj.onCameraChanged());
                % view() and cameratoolbar ResetCamera do NOT fire CameraPosition PostSet reliably
                % Listen to View and MarkedClean as catch-all for those and for campan/camorbit
                try
                    obj.listeners(end+1) = addlistener(hAx, 'View', 'PostSet', @(~,~) obj.onCameraChanged());
                catch
                end
                try
                    obj.listeners(end+1) = addlistener(hAx, 'MarkedClean', @(~,~) obj.onCameraChanged());
                catch
                end
            catch
                % Fallback: if PostSet not available for some props, use property events?
                try
                    obj.listeners(end+1) = addlistener(hAx, 'CameraPosition', 'PostSet', @(~,~) obj.onCameraChanged());
                catch
                end
                try
                    obj.listeners(end+1) = addlistener(hAx, 'MarkedClean', @(~,~) obj.onCameraChanged());
                catch
                end
            end
            % Axes destroyed listener
            try
                obj.axesDestroyedListener = addlistener(hAx, 'ObjectBeingDestroyed', @(~,~) obj.onAxesDestroyed());
            catch
                obj.axesDestroyedListener = event.listener.empty(1,0);
            end
        end

        function syncDeprecatedState(obj)
            % Keep deprecated LaunchVehicleViewProfile props in sync for 1-release compat
            if isempty(obj.viewProfile) || ~isvalid(obj.viewProfile)
                return;
            end
            try
                if isprop(obj.viewProfile,'skyboxOrigin')
                    obj.viewProfile.skyboxOrigin = obj.origin;
                end
            catch
            end
            try
                if isprop(obj.viewProfile,'skyboxRadius')
                    obj.viewProfile.skyboxRadius = obj.radius;
                end
            catch
            end
            try
                if isprop(obj.viewProfile,'skyBoxSurfHandle')
                    obj.viewProfile.skyBoxSurfHandle = obj.hSurf;
                end
            catch
            end
            try
                if isprop(obj.viewProfile,'skyBoxImageI')
                    if ~isempty(obj.skyImage)
                        obj.viewProfile.skyBoxImageI = obj.skyImage;
                    end
                end
            catch
            end
        end

        function trySyncDeprecatedHandles(obj)
            try
                obj.syncDeprecatedState();
            catch
            end
        end
    end
end

function p = GetFullPath(p)
    try
        p = char(java.io.File(p).getCanonicalPath());
    catch
    end
end

function s = tf2onoff(tf)
    if tf
        s = 'on';
    else
        s = 'off';
    end
end
