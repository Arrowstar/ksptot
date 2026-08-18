function util_echoProblem(problem, fx, sc, ev, opts, core)
%UTIL_ECHOPROBLEM  Print a summary of the problem being solved.
%   adamnlopt.util_echoProblem(problem, fx, sc, ev, opts, core) writes a
%   compact problem summary to the command window: variable count, linear and
%   nonlinear equality/inequality constraint counts, bounds, how derivatives
%   are supplied, and the transformations (fixed-variable elimination,
%   auto-scaling) the solve applies before iterating.  SOLVE calls it
%   immediately before UTIL_ECHOOPTIONS whenever Display is not 'off', so the
%   console opens with the problem followed by the non-default options in
%   effect.
%
%   Inputs:
%     problem - validated problem struct (see VALIDATEPROBLEM).
%     fx      - fixed-variable reduction map (see REDUCEPROBLEM).
%     sc      - scaling struct (see COMPUTESCALING).
%     ev      - Evaluator used for the solve (see EVALUATOR); supplies the
%               finite-difference step/type actually in effect.
%     opts    - resolved options struct (see MAPOPTIONS).
%     core    - 'ip' (interior-point) or 'eq' (equality-only core) selection.
%
%   Outputs:
%     (none) text is written to the command window and, when opts.LogFile is
%     set, appended to that file.
%
%   See also SOLVE, VALIDATEPROBLEM, REDUCEPROBLEM, COMPUTESCALING, EVALUATOR,
%            UTIL_ECHOOPTIONS.

import adamnlopt.*

n      = problem.n;
mElin  = size(problem.Aeqlin, 1);
mIlin  = size(problem.Aineq, 1);
mEnl   = problem.mEnl;
mInl   = problem.mInl;
nFinLb = nnz(isfinite(problem.lb));
nFinUb = nnz(isfinite(problem.ub));

txt = sprintf('Problem:\n');
if fx.applied
    txt = [txt sprintf('  %-18s%d (%d fixed, eliminated)\n', ...
                       'variables:', n, fx.nFixed)];
else
    txt = [txt sprintf('  %-18s%d\n', 'variables:', n)];
end
txt = [txt sprintf('  %-18s%s\n', 'constraints:', ...
                   sprintf('equality %d (%d linear + %d nonlinear)', ...
                           mElin + mEnl, mElin, mEnl))];
txt = [txt sprintf('                    %s\n', ...
                   sprintf('inequality %d (%d linear + %d nonlinear)', ...
                           mIlin + mInl, mIlin, mInl))];
if fx.applied && (fx.nDropEqLin > 0 || fx.nDropIneqLin > 0)
    txt = [txt sprintf('                    %s\n', ...
                       sprintf('(%d equality, %d inequality vacuous linear rows dropped)', ...
                               fx.nDropEqLin, fx.nDropIneqLin))];
end
txt = [txt sprintf('  %-18sfinite lower %d, finite upper %d\n', ...
                   'bounds:', nFinLb, nFinUb)];
if problem.hasObjGrad
    objDeriv = 'analytic';
else
    objDeriv = sprintf('finite-difference (step %.3g, %s)', ev.fdStep, ev.fdType);
end
if mEnl + mInl == 0
    conDeriv = 'n/a';
elseif problem.hasConGrad
    conDeriv = 'analytic';
else
    conDeriv = sprintf('finite-difference (step %.3g, %s)', ev.fdStep, ev.fdType);
end
txt = [txt sprintf('  %-18sobjective %s; constraints %s\n', ...
                   'derivatives:', objDeriv, conDeriv)];
if sc.applied
    wfTxt = '';
    if sc.wf < 1
        wfTxt = sprintf(', wf %.3g', sc.wf);
    end
    txt = [txt sprintf('  %-18son (Dx spread %.3g%s)\n', ...
                       'auto-scaling:', max(sc.Dx) / min(sc.Dx), wfTxt)];
else
    txt = [txt sprintf('  %-18soff\n', 'auto-scaling:')];
end
txt = [txt sprintf('  %-18s%s\n', 'hessian model:', opts.hessianApprox)];
txt = [txt sprintf('  %-18s%s\n', 'solver core:', core)];
if ~strcmpi(opts.parallel, 'off')
    txt = [txt sprintf('  %-18s%s\n', 'parallel:', opts.parallel)];
end
txt = [txt newline];

fprintf('%s', txt);
if isfield(opts, 'LogFile')
    util_logAppend(opts.LogFile, txt);
end
end
