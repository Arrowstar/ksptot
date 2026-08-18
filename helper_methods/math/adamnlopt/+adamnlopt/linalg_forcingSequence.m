function eta = linalg_forcingSequence(normFnew, normFold, etaPrev, opts)
%LINALG_FORCINGSEQUENCE Eisenstat-Walker inexact-Newton forcing term.
%   eta = adamnlopt.linalg_forcingSequence(normFnew, normFold, etaPrev, opts)
%   returns the relative residual tolerance for the next Krylov solve, so the
%   linear system is solved only as accurately as the current nonlinear
%   progress warrants. Uses "choice 2":
%
%       eta = gamma * (normFnew / normFold)^alpha
%
%   with the safeguard that prevents the tolerance from loosening too fast
%   (eta = max(eta, gamma*etaPrev^alpha) when that guard exceeds 0.1) and a
%   clamp to [etaMin, etaMax]. On the first step (normFold empty/zero) it
%   returns etaMax so the initial solve is cheap.
%
%   Inputs:
%     normFnew - norm of the current (new) nonlinear residual.
%     normFold - norm of the previous nonlinear residual. Empty or <= 0 on the
%                first step, which forces eta = etaMax.
%     etaPrev  - previous forcing term, used by the over-decrease safeguard.
%                Pass empty to skip the safeguard.
%     opts     - options struct with fields .forcingGamma, .forcingAlpha,
%                .forcingEtaMax and .forcingEtaMin.
%
%   Outputs:
%     eta - relative residual tolerance for the next Krylov solve, clamped to
%           [forcingEtaMin, forcingEtaMax].
%
%   See also LINALG_SOLVEKKTKRYLOV, KKT_RESIDUAL.

g   = opts.forcingGamma;
a   = opts.forcingAlpha;
eMx = opts.forcingEtaMax;
eMn = opts.forcingEtaMin;

if isempty(normFold) || normFold <= 0
    eta = eMx;
    return;
end

eta = g * (normFnew / normFold)^a;

% Safeguard against an over-eager decrease (Eisenstat-Walker, eq. 3.2).
if ~isempty(etaPrev)
    guard = g * etaPrev^a;
    if guard > 0.1
        eta = max(eta, guard);
    end
end

eta = min(eMx, max(eMn, eta));
end
