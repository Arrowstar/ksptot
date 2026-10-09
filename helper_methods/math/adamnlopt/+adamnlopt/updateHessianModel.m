function hinfo = updateHessianModel(hmodel, gOld, JEold, JIold, gNew, JEnew, JInew, ...
                                    lamE, lamI, sVec, ev, xNew, forcedStep)
%UPDATEHESSIANMODEL  Feed a constrained secant pair to the Hessian model.
%   Forms y = gradL(x+, lam+) - gradL(x, lam+), evaluated with the *new*
%   multipliers at both points (Nocedal & Wright, 18.13), and updates the model
%   with the pair (sVec, y). No-op when hmodel is [].
%
%   HINFO reports what the update did. The ACCEPTED flag in particular was
%   computed by BFGSHessian.update and then dropped at this call site, so a
%   model that was silently rejecting most of its curvature pairs (Powell
%   damping failing, s'y at the noise floor) looked identical from outside to
%   one accumulating curvature normally. RESETFIRED is the same story for the
%   conditioning recovery, which flattens B to a scaled identity: nResets was
%   readable only at exit, as a total, with no way to tell which iterations it
%   happened on.
%
%   Inputs:
%     hmodel               - HessianModel handle, or [] (no-op).
%     gOld, JEold, JIold   - objective gradient and Jacobians at the old point.
%     gNew, JEnew, JInew   - objective gradient and Jacobians at the new point.
%     lamE, lamI           - equality and inequality multipliers (new values).
%     sVec                 - primal step x+ - x (i.e. alpha*dx).
%
%   Outputs:
%     hinfo - scalar struct of diagnostics: bfgsAccepted, bfgsResetFired,
%             bfgsNResets, bfgsNUpdates, bfgsGammaLast, bfgsGammaBase,
%             bfgsRebaseFired, condB, secantNormS, secantNormY, secantSY.
%             Fields the model does not expose (LBFGSHessian has no reset
%             counter) stay NaN rather than erroring, so both models share one
%             column set.
%   The model is otherwise updated in place.
%
%   The field names are the TRACE COLUMN names, not the model's property names,
%   because the caller folds this struct into the row wholesale -- a field that
%   does not match a column is silently dropped, which reads as "the model never
%   reported it" rather than as a wiring mistake.
hinfo = struct('bfgsAccepted', NaN, 'bfgsResetFired', NaN, ...
               'bfgsNResets', NaN, 'bfgsNUpdates', NaN, ...
               'bfgsGammaLast', NaN, 'bfgsGammaBase', NaN, ...
               'bfgsRebaseFired', NaN, 'condB', NaN, ...
               'secantNormS', NaN, 'secantNormY', NaN, 'secantSY', NaN, ...
               'bfgsSkippedShort', 0);
if isempty(hmodel), return; end
% D6: do not learn from a step that cannot carry curvature.
%  - FORCEDSTEP: the line search failed and the step is the 1e-10 creep it
%    returns, not a point accepted on merit.
%  - A step shorter than the derivatives' own resolution: with FD gradients both
%    gradients carry error ~fdStep, so over a distance below ~2*fdStep*|x| the
%    difference y is noise.  BFGS then injected yy'/s'y ~ 1e10*noise along a
%    random direction (n = 50: eig(B) went from [2.9, 3.1] to [0.018, 1.2e5])
%    without tripping the cosine floor, damping or the condition-number reset.
if nargin >= 13 && ~isempty(ev)
    if ~(ev.hasObjGrad && ev.hasConGrad)
        sMin = 2 * ev.fdStep * max(1, norm(xNew, inf));
    else
        sMin = sqrt(eps) * max(1, norm(xNew, inf));
    end
    if forcedStep || norm(sVec, inf) <= sMin
        hinfo.bfgsAccepted = 0;  hinfo.bfgsSkippedShort = 1;
        return;
    end
end
% Constrained secant update: y = gradL(x+, lam+) - gradL(x, lam+), evaluated
% with the *new* multipliers at both points (Nocedal & Wright, 18.13).
gLold = gOld;  gLnew = gNew;
if ~isempty(JEold)
    gLold = gLold + JEold.' * lamE;  gLnew = gLnew + JEnew.' * lamE;
end
if ~isempty(JIold)
    gLold = gLold + JIold.' * lamI;  gLnew = gLnew + JInew.' * lamI;
end
yVec = gLnew - gLold;
% Snapshot the reset counter before the update so resetFired reports THIS
% update's recovery rather than the cumulative total.
nResetsBefore  = readModelProp(hmodel, 'nResets');
nRebasesBefore = readModelProp(hmodel, 'nRebases');
accepted = hmodel.update(sVec, yVec);

hinfo.secantNormS = norm(sVec);
hinfo.secantNormY = norm(yVec);
hinfo.secantSY    = sVec.' * yVec;
if ~isempty(accepted) && isscalar(accepted)
    hinfo.bfgsAccepted = double(accepted);
end
hinfo.bfgsNResets   = readModelProp(hmodel, 'nResets');
hinfo.bfgsNUpdates  = readModelProp(hmodel, 'nUpdates');
hinfo.bfgsGammaLast = readModelProp(hmodel, 'gammaLast');
hinfo.bfgsGammaBase = readModelProp(hmodel, 'gammaBase');
hinfo.condB         = readModelProp(hmodel, 'condLast');
hinfo.bfgsNRejected = readModelProp(hmodel, 'nRejected');
% True when bfgsB0Refresh is on but its refractory and learned-fraction gates
% leave no admissible sinceRebase at this n, so the trigger is inert rather
% than merely declining to fire.  Without this the two are indistinguishable.
hinfo.bfgsB0RefreshUnreachable = readModelProp(hmodel, 'b0RefreshUnreachable');
if ~isnan(hinfo.bfgsNResets) && ~isnan(nResetsBefore)
    hinfo.bfgsResetFired = double(hinfo.bfgsNResets > nResetsBefore);
end
% Rebases are counted separately from resets: a reset is a conditioning fault,
% a rebase is a deliberate response to a curvature-regime shift, and a run that
% conflated them would read as unhealthy exactly when the trigger is working.
nRebasesNow = readModelProp(hmodel, 'nRebases');
if ~isnan(nRebasesNow) && ~isnan(nRebasesBefore)
    hinfo.bfgsRebaseFired = double(nRebasesNow > nRebasesBefore);
end
end

% ------------------------------------------------------------------------
function v = readModelProp(hmodel, name)
%READMODELPROP  Read a scalar diagnostic property, NaN when absent.
%   The two Hessian models expose different diagnostics -- LBFGSHessian has no
%   conditioning recovery and therefore no nResets -- so guard with isprop and
%   let the trace column stay NaN rather than making the caller branch on the
%   model class. Mirrors the guard in bfgsDescentProbe.
v = NaN;
if isprop(hmodel, name)
    p = hmodel.(name);
    if isscalar(p) && (isnumeric(p) || islogical(p))
        v = double(p);
    end
end
end
