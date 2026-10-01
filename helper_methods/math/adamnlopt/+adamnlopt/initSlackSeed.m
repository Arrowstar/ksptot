function [s, sMin] = initSlackSeed(cI)
%INITSLACKSEED  Strictly positive slack seed for the inequality residuals.
%   [s, sMin] = adamnlopt.initSlackSeed(cI) returns the start-up slacks
%   s = max(-cI, sMin) for the inequality residuals cI (feasible where
%   cI <= 0), together with the strict-positivity floor sMin that was applied.
%
%   The floor is RELATIVE to the residual magnitude actually present.  An
%   absolute 1e-2 is an enormous perturbation on a problem whose inequality
%   residuals live at 1e-6 -- it discards the natural slack -cI entirely and
%   starts the barrier a long way off the central path -- and a negligible one
%   when they live at 1e6.  It falls back to the old absolute 1e-2 when cI is
%   empty or identically zero (there is no scale to read off those) and keeps an
%   absolute backstop so a vanishing cI cannot drive the floor, and with it
%   mu/s, to the edge of double precision.
%
%   This lives in one place because it has two callers -- the start-up seed in
%   initializeIterate and the post-restoration re-seed in solve, which promises
%   to re-seed "exactly as at start-up".  The two copies had already drifted:
%   the restoration one carried an absolute 1e-4 floor.
%
%   Inputs:
%     cI - mI-by-1 inequality residuals (may be empty).
%
%   Outputs:
%     s    - mI-by-1 strictly positive slacks, max(-cI, sMin).
%     sMin - the strict-positivity floor that was applied.
%
%   See also INITIALIZEITERATE, SOLVE.

cScale = 0;
if ~isempty(cI), cScale = norm(cI, inf); end
if ~(cScale > 0), cScale = 1; end
sMin = max(1e-2 * cScale, 1e-10);
s = max(-cI, sMin);
end
