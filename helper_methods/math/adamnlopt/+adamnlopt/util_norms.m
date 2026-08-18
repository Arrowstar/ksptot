function nrm = util_norms(varargin)
%UTIL_NORMS Consistent scaled residual norm across the solver.
%   nrm = adamnlopt.util_norms(v1, v2, ...) returns the max over all supplied
%   vectors of their infinity norm, treating empty vectors as 0. Using a single
%   helper keeps termination tests and diagnostics consistent.
%
%   Inputs:
%     varargin - one or more vectors (any length; empties are ignored/treated
%                as 0). Each is reshaped to a column and reduced by max(abs(.)).
%
%   Outputs:
%     nrm - scalar; the maximum infinity norm across all supplied vectors, or 0
%           when no non-empty vectors are given.
%
%   See also TERMINATIONCHECK, KKT_RESIDUAL.

nrm = 0;
for k = 1:numel(varargin)
    v = varargin{k};
    if ~isempty(v)
        nrm = max(nrm, max(abs(v(:))));
    end
end
end
