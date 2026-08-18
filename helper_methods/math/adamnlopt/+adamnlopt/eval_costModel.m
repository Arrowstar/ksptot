classdef eval_costModel < handle
%EVAL_COSTMODEL  Tracks objective/constraint evaluation cost over the iteration.
%   model = adamnlopt.eval_costModel() creates a cost tracker. Call
%   model.tick(t) after each evaluation where t is the elapsed wall time in
%   seconds. Call model.tooExpensive(threshold) to test whether the running
%   average exceeds THRESHOLD (default 0.1 s), which is the signal to switch
%   from full finite-difference Jacobians to a Broyden rank-1 update.
%
%   model.reset() clears the history (e.g. after the start point where
%   timings are inflated by cold JIT). The average is taken over a rolling
%   window of the most recent evaluations.
%
%   Properties:
%     times     - (private) column of the recent per-evaluation wall times (s).
%     window    - (private) rolling-window size used for the average.
%     nEvals    - (read-only) total number of recorded evaluations.
%     totalTime - (read-only) cumulative wall time across all evaluations (s).
%
%   Methods:
%     eval_costModel - construct a cost tracker with an optional window size.
%     tick           - record one evaluation's elapsed time.
%     avgTime        - mean elapsed time over the current window.
%     tooExpensive   - test whether the average time exceeds a threshold.
%     reset          - clear all recorded history.
%
%   See also EVALUATOR, EVAL_BROYDENJACOBIAN.

    properties (Access = private)
        times  = zeros(0,1)   % per-evaluation wall-clock times (seconds)
        window = 20           % rolling-window size for average
    end

    properties (SetAccess = private)
        nEvals    = 0
        totalTime = 0
    end

    methods
        function obj = eval_costModel(window)
        %EVAL_COSTMODEL  Construct an evaluation-cost tracker.
        %   obj = eval_costModel() uses the default rolling window.
        %   obj = eval_costModel(window) sets the number of recent evaluations
        %   averaged over.
        %
        %   Inputs:
        %     window - (optional) positive integer rolling-window size; the
        %              default (20) is kept when omitted or empty.
        %
        %   Outputs:
        %     obj - the constructed eval_costModel handle object.
            if nargin >= 1 && ~isempty(window)
                obj.window = window;
            end
        end

        function tick(obj, t)
        %TICK  Record one evaluation's elapsed wall time.
        %   tick(obj, t) appends t to the history, updates the running totals,
        %   and trims the history to the rolling window.
        %
        %   Inputs:
        %     obj - the eval_costModel handle object.
        %     t   - elapsed wall-clock time of one evaluation, in seconds.
        %
        %   Outputs:
        %     (none) obj is modified in place.
            obj.times     = [obj.times; t];
            obj.nEvals    = obj.nEvals + 1;
            obj.totalTime = obj.totalTime + t;
            if numel(obj.times) > obj.window
                obj.times = obj.times(end - obj.window + 1 : end);
            end
        end

        function v = avgTime(obj)
        %AVGTIME  Mean evaluation time over the current window.
        %   v = avgTime(obj) returns the mean of the retained per-evaluation
        %   times, or 0 when no evaluations have been recorded.
        %
        %   Inputs:
        %     obj - the eval_costModel handle object.
        %
        %   Outputs:
        %     v - mean elapsed time over the window, in seconds (0 if empty).
            if isempty(obj.times)
                v = 0;
            else
                v = mean(obj.times);
            end
        end

        function v = tooExpensive(obj, threshold)
        %TOOEXPENSIVE  Test whether the average evaluation time exceeds a threshold.
        %   v = tooExpensive(obj, threshold) returns true when the windowed
        %   average time is greater than THRESHOLD, the signal to switch from
        %   full finite-difference Jacobians to Broyden rank-1 updates.
        %
        %   Inputs:
        %     obj       - the eval_costModel handle object.
        %     threshold - (optional) time threshold in seconds; defaults to 0.1.
        %
        %   Outputs:
        %     v - logical; true if avgTime(obj) > threshold.
            if nargin < 2 || isempty(threshold), threshold = 0.1; end
            v = obj.avgTime() > threshold;
        end

        function reset(obj)
        %RESET  Clear all recorded evaluation history.
        %   reset(obj) empties the time history and zeros the running totals,
        %   e.g. after the start point where timings are inflated by cold JIT.
        %
        %   Inputs:
        %     obj - the eval_costModel handle object.
        %
        %   Outputs:
        %     (none) obj is modified in place.
            obj.times     = zeros(0,1);
            obj.nEvals    = 0;
            obj.totalTime = 0;
        end
    end
end
