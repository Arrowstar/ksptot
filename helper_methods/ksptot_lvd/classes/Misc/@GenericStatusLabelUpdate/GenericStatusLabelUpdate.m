classdef GenericStatusLabelUpdate < event.EventData
    properties
        labelText(1,:) char
    end
    
    methods
        function obj = GenericStatusLabelUpdate(labelText)
            obj.labelText = labelText;
        end
    end
end