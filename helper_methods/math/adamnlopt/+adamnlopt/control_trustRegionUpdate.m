function [Delta, accept, ratio] = control_trustRegionUpdate(Delta, predRed, actRed, pNorm, opts)
%CONTROL_TRUSTREGIONUPDATE  Update the trust-region radius from step quality.
%   [Delta, accept, ratio] = adamnlopt.control_trustRegionUpdate(Delta,
%   predRed, actRed, pNorm, opts) applies the classic ratio test
%       ratio = actRed / predRed
%   (actual over predicted reduction) and:
%     * rejects and shrinks when ratio < opts.trEta1,
%     * accepts and expands (up to opts.deltaMax) when ratio > opts.trEta2 and
%       the step reached the boundary,
%     * otherwise accepts and leaves Delta unchanged.
%   PREDRED should be >= 0 (a valid model reduction). A nonpositive PREDRED is
%   treated as a failed step so the region shrinks rather than dividing by ~0.
%
%   Inputs:
%     Delta   - current trust-region radius (scalar > 0).
%     predRed - reduction predicted by the model (scalar); should be >= 0.
%     actRed  - actual reduction achieved by the trial step (scalar).
%     pNorm   - norm of the trial step, used to detect a boundary step.
%     opts    - options struct with fields trEta1, trEta2, trShrink, trExpand,
%               deltaMax.
%
%   Outputs:
%     Delta  - updated trust-region radius (shrunk, expanded, or unchanged).
%     accept - logical; true if the step is accepted (ratio >= trEta1).
%     ratio  - actRed/predRed step-quality ratio, or -inf when predRed <= 0.
%
%   See also STEP_TRUSTREGIONSUBPROBLEM, CONTROL_MODECONTROLLER.

if predRed <= 0
    ratio = -inf;
else
    ratio = actRed / predRed;
end

if ratio < opts.trEta1
    accept = false;
    Delta = opts.trShrink * Delta;
else
    accept = true;
    if ratio > opts.trEta2 && pNorm >= (1 - 1e-10) * Delta
        Delta = min(opts.trExpand * Delta, opts.deltaMax);
    end
end
end
