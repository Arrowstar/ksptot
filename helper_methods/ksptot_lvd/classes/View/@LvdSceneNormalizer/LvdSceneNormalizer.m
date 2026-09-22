classdef LvdSceneNormalizer
    %LvdSceneNormalizer Unit-scale (~1) normalizer for the LVD 3-D view.
    %
    %   All mission geometry is kept in kilometres (physics units).  A single
    %   hgtransform with a uniform scale matrix nests every scene object so
    %   the longest axes span (max(diff(XLim), diff(YLim), diff(ZLim))) is
    %   ~1.  Profile/camera values stay in km and are converted at the axes
    %   boundary (multiply by getScale on write, divide on read).
    %
    %   Deliberately origin-anchored (pure scale, no translation): directions
    %   and the view-frame origin are preserved; only the span is normalized.
    %   Ground-track (2-D) axes are never touched.

    methods(Static)
        function tag = Tag()
            tag = 'LvdUnitScale';
        end

        function s = getScale(hAx)
            %getScale Current normalization scale for axes hAx (1 = none).
            s = 1;
            try
                if(isempty(hAx) || not(all(isvalid(hAx))))
                    return;
                end
                h = findobj(hAx, 'Tag', LvdSceneNormalizer.Tag());
                for(k=1:numel(h))
                    try
                        if(isvalid(h(k)) && isa(h(k), 'matlab.graphics.primitive.Transform'))
                            M = h(k).Matrix;
                            if(not(isempty(M)) && all(isfinite(M(:))) && M(1,1) ~= 0)
                                s = M(1,1);
                            end
                            return;
                        end
                    catch
                    end
                end
            catch
            end
            if(not(isfinite(s)) || s <= 0)
                s = 1;
            end
        end

        function hNorm = getOrCreate(hAx)
            %getOrCreate Finds or creates the normalization transform.
            hNorm = gobjects(1,0);
            try
                if(isempty(hAx) || not(all(isvalid(hAx))))
                    return;
                end
                h = findobj(hAx, 'Tag', LvdSceneNormalizer.Tag());
                for(k=1:numel(h))
                    try
                        if(isvalid(h(k)) && isa(h(k), 'matlab.graphics.primitive.Transform'))
                            hNorm = h(k);
                            break;
                        end
                    catch
                    end
                end
                if(isempty(hNorm) || not(all(isvalid(hNorm))))
                    hNorm = hgtransform('Parent', hAx, 'Tag', LvdSceneNormalizer.Tag());
                    try
                        hNorm.Annotation.LegendInformation.IconDisplayStyle = 'off';
                    catch
                    end
                end
                %the skybox must stay at the very bottom of the draw order
                try
                    sky = findall(hAx, 'Tag', 'KSPTOT_SkyboxTransform');
                    if(not(isempty(sky)) && all(isvalid(sky)))
                        uistack(sky(1), 'bottom');
                    end
                catch
                end
            catch
            end
        end

        function s = computeScaleFromAxes(hAx)
            %computeScaleFromAxes 1 / longest current axes span (km).
            s = 1;
            try
                xL = xlim(hAx);
                yL = ylim(hAx);
                zL = zlim(hAx);
                spans = [diff(xL), diff(yL), diff(zL)];
                if(all(isfinite(spans)) && all(spans > 0))
                    m = max(spans);
                    if(isfinite(m) && m > 0)
                        s = 1/m;
                    end
                end
            catch
            end
            if(not(isfinite(s)) || s <= 0)
                s = 1;
            end
        end

        function s = applyForAxes(hAx)
            %applyForAxes (Re)computes the scale from the plotted km data,
            %sets the transform matrix and reparents scene children so the
            %longest span is ~1.  Returns the scale.  MATLAB recomputes
            %auto limits from the transformed geometry on reparent; manual
            %limits are rescaled explicitly as a fallback.
            s = LvdSceneNormalizer.computeScaleFromAxes(hAx);
            try
                try
                    xL0 = xlim(hAx); yL0 = ylim(hAx); zL0 = zlim(hAx);
                catch
                    xL0 = []; yL0 = []; zL0 = [];
                end
                hNorm = LvdSceneNormalizer.getOrCreate(hAx);
                if(not(isempty(hNorm)) && all(isvalid(hNorm)))
                    hNorm.Matrix = makehgtform('scale', s);
                end
                LvdSceneNormalizer.reparentSceneChildren(hAx);
                try
                    spans = [diff(xlim(hAx)), diff(ylim(hAx)), diff(zlim(hAx))];
                    if(not(all(isfinite(spans))) || max(spans) > 1.5 || max(spans) < 0.5)
                        if(not(isempty(xL0)))
                            xlim(hAx, xL0*s);
                            ylim(hAx, yL0*s);
                            zlim(hAx, zL0*s);
                        end
                    end
                catch
                end
            catch
            end
        end

        function reparentSceneChildren(hAx)
            %reparentSceneChildren Moves any new direct scene children under
            %the normalization transform.  Skybox graphics and lights stay
            %parented to the axes.  Safe to call every frame.
            try
                if(isempty(hAx) || not(all(isvalid(hAx))))
                    return;
                end
                hNorm = LvdSceneNormalizer.getOrCreate(hAx);
                if(isempty(hNorm) || not(all(isvalid(hNorm))))
                    return;
                end
                kids = hAx.Children; %snapshot: Parent changes mutate Children
                for(k=1:numel(kids))
                    c = kids(k);
                    try
                        if(not(isvalid(c)))
                            continue;
                        end
                        if(isequal(c, hNorm))
                            continue;
                        end
                        try
                            tag = string(c.Tag);
                        catch
                            tag = "";
                        end
                        if(strlength(tag) > 0 && (tag == "KSPTOT_SkyboxTransform" || startsWith(tag, "KSPTOT_Skybox")))
                            continue;
                        end
                        if(isa(c, 'matlab.graphics.primitive.Light'))
                            continue; %infinite light: direction preserved at axes level
                        end
                        if(c.Parent == hAx)
                            c.Parent = hNorm;
                        end
                    catch
                    end
                end
            catch
            end
        end

        function pose = scalePoseToAxes(pose, s)
            %scalePoseToAxes Converts a km pose to scaled axes units.
            if(not(isempty(pose)) && isfinite(s) && s ~= 1)
                pose.position = pose.position*s;
                pose.target = pose.target*s;
            end
        end

        function pos = unscalePos(pos, hAx)
            %unscalePos Converts scaled axes coordinates back to km.
            try
                s = LvdSceneNormalizer.getScale(hAx);
            catch
                s = 1;
            end
            if(isfinite(s) && s ~= 0)
                pos = pos/s;
            end
        end
    end
end
