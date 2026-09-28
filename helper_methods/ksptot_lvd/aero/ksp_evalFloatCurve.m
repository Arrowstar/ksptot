function y = ksp_evalFloatCurve(keys, x)
%ksp_evalFloatCurve Evaluate a KSP FloatCurve with Hermite semantics.
%
%   y = ksp_evalFloatCurve(keys, x)
%
%   KEYS is Nx3 or Nx4 [x y [m0 m1]] (m0/m1 default to 0, i.e. linear).
%   X is any size numeric array of query points. Y matches size(X).
%
%   Between keys, KSP/Unity uses cubic Hermite interpolation:
%       H(t) = (2t^3-3t^2+1)*y0 + (t^3-2t^2+t)*m0*dx
%            + (-2t^3+3t^2)*y1 + (t^3-t^2)*m1*dx,
%   with t = (x-x0)/dx. Outside the key range the edge value is held
%   (clamped), matching FloatCurve.Evaluate. NaN queries give NaN.
%
%   This matches Ren0k's kOS hermiteInterpolator in
%   Project-Atmospheric-Drag (CCAT/DragProfile/LIB/Profile.ks) and the
%   Physics.cfg key tangents. It deliberately does NOT match MATLAB
%   griddedInterpolant 'linear' for these curves: KSP tangents are nonzero
%   (e.g. DRAG_CD around Mach 0.75-0.9), so linear lookup would misstate
%   transonic drag by tens of percent.
%
%   See also: kwt_physicsGlobals, ksp_setDrag.

    if(isempty(keys))
        y = zeros(size(x));
        return;
    end

    keys = double(keys);
    if(size(keys, 2) == 2)
        keys(:, 3:4) = 0;
    elseif(size(keys, 2) == 3)
        % 3-col input is [x y m] with a single shared tangent.
        keys(:, 4) = keys(:, 3);
    end
    % At this point keys are Nx4 [x y m0 m1].

    % Sort by x (stable) and drop non-finite rows.
    [~, order] = sort(keys(:, 1));
    keys = keys(order, :);
    finite = all(isfinite(keys), 2);
    keys = keys(finite, :);
    if(isempty(keys))
        y = zeros(size(x));
        return;
    end
    % Merge duplicate x values (keep the last occurrence, KSP-like).
    [~, keepIdx] = unique(keys(:, 1), 'last');
    keys = keys(sort(keepIdx), :);

    sz = size(x);
    xv = double(x(:));
    yv = zeros(size(xv));

    x0 = keys(1, 1); yEdge0 = keys(1, 2);
    x1 = keys(end, 1); yEdge1 = keys(end, 2);

    lo = xv <= x0;
    hi = xv >= x1;
    yv(lo) = yEdge0;
    yv(hi) = yEdge1;

    mid = ~(lo | hi) & isfinite(xv);
    if(any(mid))
        xm = xv(mid);
        % Bin each query: largest key index with keys(k,1) <= xm.
        idx = arrayfun(@(v) find(keys(:, 1) <= v, 1, 'last'), xm);
        idx = min(max(idx, 1), size(keys, 1) - 1);

        xa = keys(idx, 1); ya = keys(idx, 2); ma = keys(idx, 4);
        xb = keys(idx + 1, 1); yb = keys(idx + 1, 2); mb = keys(idx + 1, 3);

        dx = xb - xa;
        degenerate = dx <= 0;
        t = (xm - xa) ./ dx;
        t(degenerate) = 0;

        t2 = t .* t;
        t3 = t2 .* t;
        h00 = 2 * t3 - 3 * t2 + 1;
        h10 = t3 - 2 * t2 + t;
        h01 = -2 * t3 + 3 * t2;
        h11 = t3 - t2;

        ym = h00 .* ya + h10 .* dx .* ma + h01 .* yb + h11 .* dx .* mb;
        ym(degenerate) = ya(degenerate);
        yv(mid) = ym;
    end

    nanMask = isnan(xv);
    yv(nanMask) = NaN;

    y = reshape(yv, sz);
end
