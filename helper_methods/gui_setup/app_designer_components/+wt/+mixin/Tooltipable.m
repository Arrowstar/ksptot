classdef Tooltipable < handle
    % Mixin for component with Tooltip property

    % Copyright 2020-2021 The MathWorks Inc.
    
    
    %% Properties
    properties (AbortSet)
        
        % Tooltip of the component
        Tooltip (1,1) string
        
    end %properties
    
    
    
    %% Internal properties
    properties (AbortSet, Transient, NonCopyable, ...
            Access = {?wt.abstract.BaseWidget, ?wt.test.BaseWidgetTest} )
        
        % List of graphics controls to apply to
        TooltipableComponents (:,1) matlab.graphics.Graphics
        
    end %properties
    
    
    
    %% Accessors
    methods
        
        function set.Tooltip(obj,value)
            obj.Tooltip = value;
            obj.updateTooltipableComponents()
        end
        
        function set.TooltipableComponents(obj,value)
            obj.TooltipableComponents = value;
            obj.updateTooltipableComponents()
        end
        
    end %methods
    
    
    
    %% Methods
    methods (Access = protected)
        
        function updateTooltipableComponents(obj)
            
            wt.utility.fastSet(obj.TooltipableComponents,"Tooltip",obj.Tooltip);
            
        end %function
        
    end %methods
    
end %classdef