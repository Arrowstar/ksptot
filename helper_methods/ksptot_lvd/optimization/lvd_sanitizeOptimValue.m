function v = lvd_sanitizeOptimValue(v, penalty)
%lvd_sanitizeOptimValue Force optimizer-facing values real and finite.
%   Complex inputs are replaced by their real part (tiny imaginary parts
%   arise from acos/sqrt roundoff).  NaN and +/-Inf are replaced by a
%   large positive penalty so solvers treat the point as maximally bad
%   (infeasible for c <= 0 and ceq == 0 alike; +Inf for an objective
%   being minimized) instead of erroring on non-real or non-finite input.
%   Warns at most once per MATLAB session.  Works on scalars and arrays.

    if(nargin < 2)
        penalty = 1e10;
    end

    if(not(isreal(v)))
        lvd_sanitizeOptimValueWarn('complex value(s) replaced by their real part');
        v = real(v);
    end

    bad = not(isfinite(v));
    if(any(bad(:)))
        lvd_sanitizeOptimValueWarn('NaN/Inf value(s) replaced by the penalty +%g', penalty);
        v(bad) = penalty;
    end
end

function lvd_sanitizeOptimValueWarn(msg, varargin)
    persistent warned
    if(isempty(warned))
        warned = false;
    end
    if(not(warned))
        warned = true;
        warning('LVD:OptimizerValueSanitized', ...
                ['Optimizer-facing value sanitized: ', msg, '. (Further occurrences in this session will not warn.)'], varargin{:});
    end
end
