classdef parallel_asyncEvaluator < handle
%PARALLEL_ASYNCEVALUATOR Asynchronous function evaluator via parfeval.
%   ev = adamnlopt.parallel_asyncEvaluator(fun, nout) creates an evaluator
%   for FUN that accepts a single vector argument and returns NOUT outputs.
%   When the Parallel Computing Toolbox is available, evaluations are
%   dispatched via parfeval and polled asynchronously; otherwise they fall
%   back to synchronous calls.
%
%   ev.submit(x)       — dispatch an evaluation at x, returns a job token.
%   result = ev.fetch(token) — block until the submitted job completes and
%                            return its output as a cell array {out1, out2, ...}.
%   ev.cancel()        — cancel all pending jobs and reset.
%
%   Properties:
%     fun_         - (private) evaluated function handle @(x).
%     nout_        - (private) number of outputs captured from fun_.
%     futures_     - (private) containers.Map from token char to a parfeval
%                    future (parallel path) or a completed-result struct
%                    (synchronous path).
%     useParallel_ - (private) logical; true when the Parallel Computing Toolbox
%                    is available and parfeval is used.
%     nextId_      - (private) uint64 counter used to mint unique job tokens.
%
%   Methods:
%     parallel_asyncEvaluator - construct an evaluator for FUN with NOUT outputs.
%     submit                  - dispatch an evaluation at x; returns a token.
%     fetch                   - block for a token's result and remove the job.
%     cancel                  - cancel all pending jobs and reset the map.
%
%   See also PARALLEL_BATCHEVALUATE, PARALLEL_PARALLELFINITEDIFF.

    properties (Access = private)
        fun_      % function handle
        nout_     % number of function outputs
        futures_  % containers.Map from token (char) to future/struct
        useParallel_  logical = false
        nextId_   = uint64(0)
    end

    methods
        function obj = parallel_asyncEvaluator(fun, nout)
        %PARALLEL_ASYNCEVALUATOR  Construct an asynchronous function evaluator.
        %   obj = parallel_asyncEvaluator(fun, nout) stores FUN and its output
        %   count, initializes the empty job map, and selects the parallel path
        %   when the Parallel Computing Toolbox is available.
        %
        %   Inputs:
        %     fun  - function handle @(x) -> [out1, ..., outNOUT].
        %     nout - number of outputs to capture from FUN.
        %
        %   Outputs:
        %     obj - the constructed parallel_asyncEvaluator handle object.
            obj.fun_  = fun;
            obj.nout_ = nout;
            obj.futures_ = containers.Map('KeyType','char','ValueType','any');
            obj.useParallel_ = ~isempty(ver('parallel'));
        end

        function token = submit(obj, x)
        %SUBMIT  Dispatch an evaluation at x and return its job token.
        %   token = submit(obj, x) mints a unique token and either dispatches
        %   FUN(x) via parfeval (parallel path) or evaluates it eagerly and
        %   stores the completed result (synchronous path). The token is later
        %   passed to fetch to retrieve the outputs.
        %
        %   Inputs:
        %     obj - the parallel_asyncEvaluator handle object.
        %     x   - argument vector passed to FUN.
        %
        %   Outputs:
        %     token - char job identifier of the form 'job_<n>'.
            obj.nextId_ = obj.nextId_ + 1;
            token = sprintf('job_%u', obj.nextId_);
            if obj.useParallel_
                f = parfeval(obj.fun_, obj.nout_, x);
                obj.futures_(token) = f;
            else
                % Eager synchronous evaluation stored as a completed result.
                c = cell(1, obj.nout_);
                [c{:}] = obj.fun_(x);
                obj.futures_(token) = struct('result', {c}, 'done', true);
            end
        end

        function result = fetch(obj, token)
        %FETCH  Block for a submitted job's result and remove it from the map.
        %   result = fetch(obj, token) returns the stored outputs for a
        %   synchronous job, or blocks on fetchOutputs for a parfeval future,
        %   then removes the job from the map. Errors if TOKEN is unknown.
        %
        %   Inputs:
        %     obj   - the parallel_asyncEvaluator handle object.
        %     token - char job identifier returned by submit.
        %
        %   Outputs:
        %     result - 1-by-nout cell array {out1, out2, ...} of FUN's outputs.
            if ~obj.futures_.isKey(token)
                error('adamnlopt:asyncEvaluator:unknownToken', ...
                      'No job with token ''%s''.', token);
            end
            entry = obj.futures_(token);
            if isstruct(entry)
                result = entry.result;
            else
                % parfeval future — block until done.
                result = cell(1, obj.nout_);
                [result{:}] = fetchOutputs(entry);
            end
            obj.futures_.remove(token);
        end

        function cancel(obj)
        %CANCEL  Cancel all pending jobs and reset the evaluator.
        %   cancel(obj) cancels every outstanding parfeval future (synchronous
        %   entries need no cancellation) and replaces the job map with a fresh
        %   empty one.
        %
        %   Inputs:
        %     obj - the parallel_asyncEvaluator handle object.
        %
        %   Outputs:
        %     (none) obj is modified in place.
            keys_ = obj.futures_.keys;
            for k = 1:numel(keys_)
                entry = obj.futures_(keys_{k});
                if ~isstruct(entry)
                    try, cancel(entry); catch, end
                end
            end
            obj.futures_ = containers.Map('KeyType','char','ValueType','any');
        end
    end
end
