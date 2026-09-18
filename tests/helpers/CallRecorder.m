classdef CallRecorder < handle
    %CallRecorder Test double that remembers every argument list it was
    %called with (for callbacks and listeners in unit tests).

    properties
        calls(1,:) cell = {};
    end

    methods
        function record(obj, varargin)
            obj.calls{end+1} = varargin;
        end

        function n = count(obj)
            n = numel(obj.calls);
        end

        function args = nth(obj, i)
            args = obj.calls{i};
        end

        function firsts = firstArgs(obj)
            %firstArgs Cell array of the first argument of every call.
            firsts = cellfun(@(c) c{1}, obj.calls, 'UniformOutput', false);
        end
    end
end
