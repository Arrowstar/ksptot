classdef EventColorLineSpec < matlab.mixin.SetGet
    %EventColorLineSpec Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        color(1,1) ColorSpecEnum = ColorSpecEnum.Red
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.SolidLine
    end
    
    methods
        function obj = EventColorLineSpec()

        end
    end
end

