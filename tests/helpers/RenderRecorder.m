classdef RenderRecorder < handle
    %RenderRecorder Test double for a render callback: remembers every time
    %it was asked to render.

    properties
        times(1,:) double = zeros(1,0);
    end

    methods
        function record(obj, t)
            obj.times(end+1) = t;
        end

        function reset(obj)
            obj.times = zeros(1,0);
        end
    end
end
