classdef EventColorLineSpec < matlab.mixin.SetGet
    %EventColorLineSpec Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        color(1,1) ColorSpecEnum = ColorSpecEnum.Red
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.SolidLine
        lineWidth(1,1) double = 1.5;
    end
    
    methods
        function obj = EventColorLineSpec()

        end
    end
end

