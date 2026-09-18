classdef LvdMouseCameraHandler < handle
    % LvdMouseCameraHandler - Handles 3D axes mouse interaction for LVD
    % Left: orbit, Middle: pan, Right: dolly (vertical only)
    % Designed to survive App Designer saves - store state in this object, not in app private props
    % Call LvdMouseCameraHandler.setup(app) from ma_LvdMainGUI_OpeningFcn
    
    properties (Access=public)
        % When false, mouse drags over the 3-D axes do not move the camera.
        % Nothing in LVD clears this any more: the chase and scripted
        % cameras cooperate with the mouse through cameraDragFcn instead.
        enabled(1,1) logical = true

        % Called after every camera change made by a mouse drag, as
        % cameraDragFcn(hAx, phase) with phase "motion" while the button is
        % held and "end" once when it is released.  The LVD scene camera
        % driver uses it to turn a drag into chase-camera offsets (Chase
        % mode) or to hand the camera back to the user (Scripted mode).
        cameraDragFcn = []

        % Drag sensitivities.  Dolly and pan are scaled by the camera's
        % distance to its target (not by the axes limits, which span the
        % whole scene), so the controls feel the same whether the camera is
        % thousands of km out or a few km from a chased vehicle.
        OrbitDegPerPixel(1,1) double = 0.5
        % Dolly multiplies the camera distance by exp(-pixels * rate): 100 px
        % toward the target brings the camera to ~37% of its distance and it
        % can never pass through the target.
        DollyRatePerPixel(1,1) double = 0.01
        % Pan moves the scene one-for-one with the pointer (fraction of the
        % visible height per pixel); 1 = exact, <1 slower.
        PanGain(1,1) double = 1
    end

    properties (Access=private)
        app ma_LvdMainGUI_App
        hFig matlab.ui.Figure
        hAx matlab.ui.control.UIAxes

        isDragging = false
        dragMode char = '' % 'orbit','dollyhv','dollyfb'
        startPt double = [0 0]
        startPos double = [NaN NaN NaN]
        startTgt double = [NaN NaN NaN]
        startUp double = [NaN NaN NaN]
        startVA double = NaN
        
        origWindowButtonDown
        origWindowButtonUp
        origWindowButtonMotion
        origDispAxesButtonDown
    end
    
    methods (Static)
        function handler = setup(app)
            % Call from ma_LvdMainGUI_OpeningFcn after app.dispAxes is created
            % Example: app.mouseCameraHandler = LvdMouseCameraHandler.setup(app);
            handler = LvdMouseCameraHandler(app);
            % Store on app for persistence (use dynamic property if needed)
            try
                app.mouseCameraHandler = handler;
            catch
                % If app doesn't have the property, store via setappdata
                setappdata(app.ma_LvdMainGUI, 'LvdMouseCameraHandler', handler);
            end
        end
    end
    
    methods
        function obj = LvdMouseCameraHandler(app)
            arguments
                app(1,1) ma_LvdMainGUI_App
            end
            obj.app = app;
            obj.hFig = app.ma_LvdMainGUI;
            obj.hAx = app.dispAxes;
            
            % Disable cameratoolbar context menu via Tag workaround
            try
                cm = uicontextmenu(obj.hFig, 'Tag', 'CameratoolbarContextMenu', 'Visible', 'off');
                obj.hAx.ContextMenu = cm;
            catch
            end
            try
                obj.hFig.CurrentObject; % ensure figure is ready
            catch
            end
            
            % Save original callbacks
            try obj.origWindowButtonDown = obj.hFig.WindowButtonDownFcn; catch, obj.origWindowButtonDown = []; end
            try obj.origWindowButtonUp = obj.hFig.WindowButtonUpFcn; catch, obj.origWindowButtonUp = []; end
            try obj.origWindowButtonMotion = obj.hFig.WindowButtonMotionFcn; catch, obj.origWindowButtonMotion = []; end
            try obj.origDispAxesButtonDown = obj.hAx.ButtonDownFcn; catch, obj.origDispAxesButtonDown = []; end
            
            % Install our handlers
            obj.hFig.WindowButtonDownFcn = @(src,evt) obj.onWindowButtonDown(src, evt);
            obj.hFig.WindowButtonUpFcn = @(src,evt) obj.onWindowButtonUp(src, evt);
            obj.hFig.WindowButtonMotionFcn = @(src,evt) obj.onWindowButtonMotion(src, evt);
            obj.hAx.ButtonDownFcn = @(src,evt) obj.onDispAxesButtonDown(src, evt);
            
            % Also ensure parent containers don't show menu
            try app.DisplayAxesGridLayout.ContextMenu = []; catch, end
            try app.Panel_3.ContextMenu = []; catch, end
        end
        
        function delete(obj)
            % Restore original callbacks on delete
            try
                if isvalid(obj.hFig)
                    obj.hFig.WindowButtonDownFcn = obj.origWindowButtonDown;
                    obj.hFig.WindowButtonUpFcn = obj.origWindowButtonUp;
                    obj.hFig.WindowButtonMotionFcn = obj.origWindowButtonMotion;
                end
                if isvalid(obj.hAx)
                    obj.hAx.ButtonDownFcn = obj.origDispAxesButtonDown;
                end
            catch
            end
        end
        
        function tf = isMouseOverDispAxes(obj)
            tf = false;
            try
                if obj.app.TabGroup.SelectedTab ~= obj.app.DTrajectoryTab
                    return;
                end
                curObj = obj.hFig.CurrentObject;
                if ~isempty(curObj) && isvalid(curObj)
                    o = curObj;
                    while ~isempty(o) && isvalid(o)
                        if o == obj.hAx
                            tf = true;
                            return;
                        end
                        try o = o.Parent; catch, break; end
                    end
                    if tf, return; end
                end
                % Fallback pixel check
                try
                    pos = getpixelposition(obj.hAx, true);
                    mousePt = obj.hFig.CurrentPoint;
                    if mousePt(1) >= pos(1) && mousePt(1) <= pos(1)+pos(3) && ...
                       mousePt(2) >= pos(2) && mousePt(2) <= pos(2)+pos(4)
                        tf = true;
                    elseif mousePt(1) >= pos(1) && mousePt(1) <= pos(1)+pos(3) && ...
                           mousePt(2) >= pos(2)+34 && mousePt(2) <= pos(2)+pos(4)+34
                        tf = true;
                    end
                catch
                end
            catch
            end
        end
        
        function mode = getModeForSelection(obj, selType, event)
            % Try event.Button first (1=left,2=middle,3=right) for reliability
            mode = '';
            try
                btn = [];
                if isprop(event,'Button') && ~isempty(event.Button)
                    btn = event.Button;
                elseif isfield(event,'Button') && ~isempty(event.Button)
                    btn = event.Button;
                end
                if ~isempty(btn)
                    if btn == 1, mode = 'orbit';
                    elseif btn == 2, mode = 'dollyhv';
                    elseif btn == 3, mode = 'dollyfb';
                    end
                end
            catch
            end
            if isempty(mode)
                % Fallback to SelectionType
                if strcmpi(selType,'normal'), mode='orbit';
                elseif strcmpi(selType,'extend'), mode='dollyhv';
                elseif strcmpi(selType,'alt'), mode='dollyfb';
                end
            end
        end
        
        function onWindowButtonDown(obj, ~, event)
            % Call original first if needed for resizers (only for left)
            selType = '';
            try selType = obj.hFig.SelectionType; catch, end
            
            % Check if over dispAxes and should handle as camera drag
            % (skipped entirely while a chase/scripted camera owns the axes)
            try
                if obj.enabled && obj.isMouseOverDispAxes()
                    mode = obj.getModeForSelection(selType, event);
                    % Ensure context menu stays disabled for right
                    if strcmpi(mode,'dollyfb')
                        try
                            cms = findall(obj.hFig,'Tag','CameratoolbarContextMenu');
                            if isempty(cms)
                                cm = uicontextmenu(obj.hFig,'Tag','CameratoolbarContextMenu','Visible','off');
                                obj.hAx.ContextMenu = cm;
                            else
                                obj.hAx.ContextMenu = cms(1);
                                try cms(1).Visible='off'; catch, end
                            end
                        catch
                        end
                    end
                    if ~isempty(mode)
                        obj.beginDrag(mode, obj.hFig.CurrentPoint);
                        % Turn off toolbar toggles visually
                        try
                            obj.app.panPushMenuToggle.State='off';
                            obj.app.orbitCameraPushMenuToggle.State='off';
                            obj.app.zoomOutPushMenuToggle.State='off';
                            obj.app.zoomInPushMenuToggle.State='off';
                            obj.app.rotateCameraPushMenuToggle.State='off';
                        catch
                        end
                        try cameratoolbar(obj.hFig,'SetMode','nomode'); catch, end
                        try cameratoolbar(obj.hFig,'SetCoordSys','none'); catch, end
                        if strcmpi(mode,'orbit')
                            try cameratoolbar(obj.hFig,'SetCoordSys','z'); catch, end
                        end
                        % Prevent resizers from handling this drag if over axes
                        return;
                    end
                end
            catch
            end
            
            % Fallback to original WindowButtonDown handling (resizers etc.)
            % Replicate original logic for left normal
            try
                if strcmpi(selType,'normal')
                    if ~isMATLABReleaseOlderThan("R2022b")
                        try cameratoolbar(obj.hFig,'SetMode','nomode'); catch, end
                        try obj.app.gridLayout7Resizer.windowButtonDownCallback(); catch, end
                        try obj.app.gridLayout4Resizer.windowButtonDownCallback(); catch, end
                        try obj.app.gridLayout3Resizer.windowButtonDownCallback(); catch, end
                        try obj.app.gridLayout23Resizer.windowButtonDownCallback(); catch, end
                    end
                end
            catch
            end
            % Call original if it was a function handle
            try
                if ~isempty(obj.origWindowButtonDown) && isa(obj.origWindowButtonDown,'function_handle')
                    obj.origWindowButtonDown(obj.hFig, event);
                end
            catch
            end
        end
        
        function onWindowButtonUp(obj, ~, event)
            if obj.isDragging
                obj.endDrag();
                try cameratoolbar(obj.hFig,'SetMode','nomode'); catch, end
                % Restore toolbar toggles will be handled by original logic if needed
            end
            % Always call resizer up and original
            try
                if ~isMATLABReleaseOlderThan("R2022b")
                    try obj.app.gridLayout7Resizer.windowButtonUpCallback(); catch, end
                    try obj.app.gridLayout4Resizer.windowButtonUpCallback(); catch, end
                    try obj.app.gridLayout3Resizer.windowButtonUpCallback(); catch, end
                    try obj.app.gridLayout23Resizer.windowButtonUpCallback(); catch, end
                end
            catch
            end
            try
                if ~isempty(obj.origWindowButtonUp) && isa(obj.origWindowButtonUp,'function_handle')
                    obj.origWindowButtonUp(obj.hFig, event);
                end
            catch
            end
        end
        
        function beginDrag(obj, mode, startPt)
            % beginDrag Starts a camera drag of the given mode ('orbit',
            % 'dollyhv' = pan, 'dollyfb' = dolly) from a figure point in
            % pixels, remembering the camera it started from.  Public so
            % tests can drive the same code path the mouse does.
            obj.isDragging = true;
            obj.dragMode = mode;
            obj.startPt = startPt;
            try
                % freeze the camera (as camdolly/camorbit do): in 'auto' mode
                % MATLAB re-fits the view angle after every move, which
                % partly cancels a dolly and changes the pan scale mid-drag
                obj.hAx.CameraPositionMode = 'manual';
                obj.hAx.CameraTargetMode = 'manual';
                obj.hAx.CameraUpVectorMode = 'manual';
                obj.hAx.CameraViewAngleMode = 'manual';
            catch
            end
            try
                obj.startPos = obj.hAx.CameraPosition;
                obj.startTgt = obj.hAx.CameraTarget;
                obj.startUp = obj.hAx.CameraUpVector;
                obj.startVA = obj.hAx.CameraViewAngle;
            catch
            end
        end

        function applyDrag(obj, curPt)
            % applyDrag Moves the camera for the pointer now being at curPt
            % (figure pixels) and reports the change through cameraDragFcn.
            if ~obj.isDragging
                return;
            end
            mode = obj.dragMode;
            try
                delta = curPt - obj.startPt;
                if strcmpi(mode,'orbit')
                    % Custom orbit - incremental
                    dAz = -delta(1)*obj.OrbitDegPerPixel;
                    dEl = -delta(2)*obj.OrbitDegPerPixel;
                    try camorbit(obj.hAx, dAz, dEl, 'data', [0 0 1]); catch, end
                    obj.startPt = curPt;
                elseif strcmpi(mode,'dollyhv')
                    % Pan - translate both pos and tgt so the scene follows the
                    % pointer one-for-one at the target's depth
                    pos = obj.startPos(:); tgt = obj.startTgt(:); up = obj.startUp(:);
                    if any(isnan(pos))||any(isnan(tgt))||any(isnan(up))
                        pos = obj.hAx.CameraPosition(:); tgt = obj.hAx.CameraTarget(:); up = obj.hAx.CameraUpVector(:);
                    end
                    x = (tgt-pos); dist = norm(x); x=x/dist; z=up/norm(up); y=cross(z,x); y=y/norm(y);
                    z = cross(x, y); z = z/norm(z);   % true screen-up, orthogonal to the sight line
                    scale = obj.PanGain * obj.worldUnitsPerPixel(dist);
                    offset = (delta(1)*scale)*y + (delta(2)*scale)*z;
                    newPos = pos+offset; newTgt = tgt+offset;
                    obj.hAx.CameraPosition = newPos'; obj.hAx.CameraTarget = newTgt';
                    if ~any(isnan(up)), obj.hAx.CameraUpVector=up'; end
                elseif strcmpi(mode,'dollyfb')
                    % Dolly - scale the camera distance to the target
                    % exponentially with the vertical drag, so the camera can
                    % never pass through the target and the feel is the same at
                    % every scale
                    deltaY = curPt(2)-obj.startPt(2);
                    pos = obj.startPos(:); tgt = obj.startTgt(:);
                    if any(isnan(pos))||any(isnan(tgt))
                        pos=obj.hAx.CameraPosition(:); tgt=obj.hAx.CameraTarget(:);
                    end
                    d0 = norm(tgt-pos);
                    if d0 > 0
                        x=(tgt-pos)/d0;
                        newDist = d0 * exp(-deltaY * obj.DollyRatePerPixel);
                        newPos = tgt - x*newDist;
                        obj.hAx.CameraPosition=newPos';
                    end
                    up=obj.startUp(:); if ~any(isnan(up)), obj.hAx.CameraUpVector=up'; end
                end
            catch
            end
            obj.notifyDrag("motion");
        end

        function w = worldUnitsPerPixel(obj, distToTarget)
            % worldUnitsPerPixel Scene length covered by one pixel at the
            % target's depth: visible height (2 d tan(va/2)) over the axes
            % height in pixels.  Falls back to 400 px when the size is unknown.
            va = 20;
            try
                va = obj.hAx.CameraViewAngle;
            catch
            end
            heightPx = 400;
            try
                pos = obj.hAx.InnerPosition;
                if numel(pos) >= 4 && isfinite(pos(4)) && pos(4) > 10
                    heightPx = pos(4);
                end
            catch
            end
            w = 2 * distToTarget * tan(deg2rad(va)/2) / heightPx;
        end

        function endDrag(obj)
            % endDrag Finishes the current drag and reports it as "end".
            if ~obj.isDragging
                return;
            end
            obj.isDragging = false;
            obj.dragMode = '';
            obj.notifyDrag("end");
        end

        function tf = isDragInProgress(obj)
            tf = obj.isDragging;
        end

        function onWindowButtonMotion(obj, ~, event)
            if obj.isDragging
                try
                    obj.applyDrag(obj.hFig.CurrentPoint);
                catch
                end
                return;
            end
            % Not dragging - handle resizer hover
            try
                if ~isMATLABReleaseOlderThan("R2022b")
                    try obj.app.gridLayout23Resizer.windowButtonMotionCallback(); catch, end
                    try obj.app.gridLayout3Resizer.windowButtonMotionCallback(); catch, end
                    try obj.app.gridLayout7Resizer.windowButtonMotionCallback(); catch, end
                    try obj.app.gridLayout4Resizer.windowButtonMotionCallback(); catch, end
                end
            catch
            end
            try
                if ~isempty(obj.origWindowButtonMotion) && isa(obj.origWindowButtonMotion,'function_handle')
                    obj.origWindowButtonMotion(obj.hFig, event);
                end
            catch
            end
        end
        
        function notifyDrag(obj, phase)
            fcn = obj.cameraDragFcn;
            if isempty(fcn) || ~isa(fcn, 'function_handle')
                return;
            end
            try
                fcn(obj.hAx, string(phase));
            catch ME
                warning('LvdMouseCameraHandler:dragCallback', 'Camera drag callback failed: %s', ME.message);
            end
        end

        function onDispAxesButtonDown(obj, ~, event)
            % Delegate to window down for unified handling (handles clicks directly on axes)
            try
                obj.onWindowButtonDown(obj.hFig, event);
            catch
            end
            % Also call original axes ButtonDown if any
            try
                if ~isempty(obj.origDispAxesButtonDown) && isa(obj.origDispAxesButtonDown,'function_handle')
                    obj.origDispAxesButtonDown(obj.hAx, event);
                end
            catch
            end
        end
    end
end
