classdef FieldColorable < handle
    % Mixin for component with colorable text field

    % Copyright 2020-2021 The MathWorks Inc.
    
    %% Properties
    properties (AbortSet)
        
        % Field Color
        FieldColor (1,3) double {wt.validators.mustBeBetweenZeroAndOne} = [1 1 1]
        
    end %properties
    
    
    
    %% Internal properties
    properties (AbortSet, Transient, NonCopyable, ...
            Access = {?wt.abstract.BaseWidget, ?wt.test.BaseWidgetTest} )
        
        % List of graphics controls to apply to
        FieldColorableComponents (:,1) matlab.graphics.Graphics
        
    end %properties
    
    
    
    %% Accessors
    methods
        
        function set.FieldColor(obj,value)
            obj.FieldColor = value;
            obj.updateFieldColorableComponents()
        end
        
        function set.FieldColorableComponents(obj,value)
            obj.FieldColorableComponents = value;
            obj.updateFieldColorableComponents()
        end
        
    end %methods
    
    
    
    %% Methods
    methods (Access = protected)
        
        function updateFieldColorableComponents(obj)
            
            wt.utility.fastSet(obj.FieldColorableComponents,"BackgroundColor",obj.FieldColor);
            
        end %function
        
    end %methods
    
end %classdef