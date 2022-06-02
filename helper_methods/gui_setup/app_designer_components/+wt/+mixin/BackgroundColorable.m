classdef BackgroundColorable < handle
    % Mixin for component with colorable background
    %

    % Copyright 2020-2021 The MathWorks Inc.
    
    
    %% Properties
    properties (AbortSet, Abstract)
        
        % Background Color
        BackgroundColor (1,3) double {wt.validators.mustBeBetweenZeroAndOne}
        
    end %properties
    
    
    
    %% Internal properties
    properties (AbortSet, Transient, NonCopyable, ...
            Access = {?wt.abstract.BaseWidget, ?wt.test.BaseWidgetTest} )
        
        % List of graphics controls to apply to
        BackgroundColorableComponents (:,1) matlab.graphics.Graphics
        
    end %properties
    
    
    
    %% Accessors
    methods
        
%         function set.BackgroundColor(obj,value)
%             obj.BackgroundColor = value;
%             obj.updateBackgroundColorableComponents()
%         end
        
        function set.BackgroundColorableComponents(obj,value)
            obj.BackgroundColorableComponents = value;
            obj.updateBackgroundColorableComponents()
        end
        
    end %methods
    
    
    
    %% Methods
    methods (Access = protected)
        
        function updateBackgroundColorableComponents(obj)
            
            hasProp = isprop(obj.BackgroundColorableComponents,'BackgroundColor');
            wt.utility.fastSet(obj.BackgroundColorableComponents(hasProp),...
                "BackgroundColor",obj.BackgroundColor);
            
        end %function
        
    end %methods
    
end %classdef