function results = parallel_batchEvaluate(fun, points, nout)
%PARALLEL_BATCHEVALUATE Evaluate a function at multiple points in parallel.
%   results = adamnlopt.parallel_batchEvaluate(fun, points, nout) evaluates
%   FUN at each column of the matrix POINTS (n x k), where k is the number
%   of evaluation points and NOUT is the number of function outputs. Returns
%   a k-by-nout cell array where results{i,j} is the j-th output of FUN at
%   the i-th point.
%
%   Uses parfor when the Parallel Computing Toolbox is available; falls back
%   to a sequential loop otherwise. FUN is called once per column with that
%   column as its single argument, and its NOUT outputs are captured.
%
%   Inputs:
%     fun    - function handle @(x) -> [out1, ..., outNOUT] taking one column.
%     points - n-by-k matrix; each column is one evaluation point.
%     nout   - (optional) number of outputs to capture from FUN; defaults to 1.
%
%   Outputs:
%     results - k-by-nout cell array; results{i,j} is the j-th output of FUN at
%               the i-th point (column i of POINTS).
%
%   See also PARALLEL_PARALLELFINITEDIFF, PARALLEL_ASYNCEVALUATOR.

if nargin < 3 || isempty(nout), nout = 1; end

k = size(points, 2);
results = cell(k, nout);

useParfor = ~isempty(ver('parallel'));

if useParfor
    parfor i = 1:k
        c = cell(1, nout);
        [c{:}] = fun(points(:, i));
        results(i, :) = c;
    end
else
    for i = 1:k
        c = cell(1, nout);
        [c{:}] = fun(points(:, i));
        results(i, :) = c;
    end
end
end
