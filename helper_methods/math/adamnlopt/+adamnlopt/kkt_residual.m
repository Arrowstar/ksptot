function res = kkt_residual(state)
%KKT_RESIDUAL  Primal-dual KKT residual for the current iterate.
%   res = adamnlopt.kkt_residual(state) evaluates the Karush-Kuhn-Tucker
%   optimality residual of the current primal-dual iterate and returns it as a
%   struct. The residual blocks are:
%       rStat   stationarity: g + JE'*lamE + JI'*lamI - zL + zU
%       rFeasE  equality feasibility: cE
%       rFeasI  inequality feasibility (with slacks): cI + s
%       rComp   complementarity residual (barrier-free): [s.*lamI; ...]
%       feas, opt, comp   scalar infinity norms
%   Empty blocks (no inequalities/bounds) drop out cleanly, so the same
%   routine serves the equality-only core and the full interior-point method.
%
%   Sign convention (documented once, see also kkt_assemble):
%       L = f + lamE'*cE + lamI'*(cI+s) - zL'*(x-l) - zU'*(u-x)
%   with lamI, zL, zU >= 0.
%
%   Inputs:
%     state - iterate struct. Required fields: g (n-by-1 objective gradient),
%             JE (mE-by-n equality Jacobian, empty if none), JI (mI-by-n
%             inequality Jacobian, empty if none), lamE (mE-by-1 equality
%             multipliers), lamI (mI-by-1 inequality multipliers >= 0),
%             cE (mE-by-1 equality residual), cI (mI-by-1 inequality residual),
%             s (mI-by-1 slacks, empty if no inequalities). Optional fields
%             zL, zU (bound multipliers >= 0 for lower/upper bounds).
%
%   Outputs:
%     res - struct with fields rStat (n-by-1 stationarity residual),
%           rFeasE (mE-by-1), rFeasI (mI-by-1, empty if no slacks),
%           rComp (complementarity residual, empty if no slacks), and the
%           scalar infinity norms opt (of rStat), feas (of rFeasE and rFeasI),
%           and comp (of rComp).
%
%   See also KKT_ASSEMBLE, STEP_MULTIPLIERUPDATE.

import adamnlopt.*

g  = state.g;
JE = state.JE;  JI = state.JI;

rStat = g;
if ~isempty(JE), rStat = rStat + JE.' * state.lamE; end
if ~isempty(JI), rStat = rStat + JI.' * state.lamI; end
if isfield(state, 'zL') && ~isempty(state.zL), rStat = rStat - state.zL; end
if isfield(state, 'zU') && ~isempty(state.zU), rStat = rStat + state.zU; end

rFeasE = state.cE;
if isempty(state.s)
    rFeasI = zeros(0,1);
else
    rFeasI = state.cI + state.s;
end

% Complementarity (barrier-free residual used for termination).
compParts = {};
if ~isempty(state.s),  compParts{end+1} = state.s  .* state.lamI; end
res.rStat  = rStat;
res.rFeasE = rFeasE;
res.rFeasI = rFeasI;
res.rComp  = vertcatParts(compParts);

res.opt  = util_norms(rStat);
res.feas = util_norms(rFeasE, rFeasI);
res.comp = util_norms(res.rComp);
end

function v = vertcatParts(parts)
%VERTCATPARTS  Vertically concatenate cell array parts into a column vector.
%   v = vertcatParts(parts) stacks the vectors in the cell array PARTS, or
%   returns a 0-by-1 empty vector when PARTS is empty. Used to assemble the
%   complementarity residual from its optionally-present blocks.
%
%   Inputs:
%     parts - cell array of column vectors (possibly empty).
%
%   Outputs:
%     v - the vertical concatenation of the parts, or a 0-by-1 empty vector.
if isempty(parts)
    v = zeros(0,1);
else
    v = vertcat(parts{:});
end
end
