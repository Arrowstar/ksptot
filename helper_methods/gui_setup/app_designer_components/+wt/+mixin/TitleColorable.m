classdef TitleColorable < handle
    % Mixin for component with Title font color

    % Copyright 2020-2021 The MathWorks Inc.
    
    
    %% Properties
    properties (AbortSet)
        
        % Title color
        TitleColor (1,3) double {wt.validators.mustBeBetweenZeroAndOne} = [0 0 0]
        
    end %properties
    
    
    
    %% Internal properties
    properties (AbortSet, Transient, NonCopyable, ...
            Access = {?wt.abstract.BaseWidget, ?wt.test.BaseWidgetTest} )
        
        % List of graphics controls to apply to
        TitleColorableComponents (:,1) matlab.graphics.Graphics
        
    end %properties
    
    
    
    %% Accessors
    methods
        
        function set.TitleColor(obj,value)
            obj.TitleColor = value;
            obj.updateTitleColorableComponents()
        end
        
        function set.TitleColorableComponents(obj,value)
            obj.TitleColorableComponents = value;
            obj.updateTitleColorableComponents()
        end
        
    end %methods
    
    
    
    %% Methods
    methods (Access = protected)
        
        function updateTitleColorableComponents(obj)
            
            wt.utility.fastSet(obj.TitleColorableComponents,"FontColor",obj.TitleColor)
            
        end %function
        
    end %methods
    
end %classdef