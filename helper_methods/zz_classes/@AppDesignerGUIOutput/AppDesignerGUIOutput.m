classdef AppDesignerGUIOutput < matlab.mixin.SetGet
    %AppDesignerGUIOutput Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        output cell = {};
    end
    
    methods
        function obj = AppDesignerGUIOutput(defaultOut)
            arguments
                defaultOut cell = {};
            end
            
            if(not(isempty(defaultOut)))
                if(not(iscell(defaultOut)))
                    defaultOut = {defaultOut};
                end
                
                obj.output = defaultOut;
            end
        end
    end
end