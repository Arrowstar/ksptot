classdef Enableable < handle
    % Mixin for component with Enable property

    % Copyright 2020-2021 The MathWorks Inc.
    
    
    %% Properties
    properties (AbortSet)
        
        % Enable of the component
        Enable (1,1) matlab.lang.OnOffSwitchState = 'on'
        
    end %properties
    
    
    
    %% Internal properties
    properties (AbortSet, Transient, NonCopyable, ...
            Access = {?wt.abstract.BaseWidget, ?wt.test.BaseWidgetTest} )
        
        % List of graphics controls to apply to
        EnableableComponents (:,1) matlab.graphics.Graphics
        
    end %properties
    
    
    
    %% Accessors
    methods
        
        function set.Enable(obj,value)
            obj.Enable = value;
            obj.updateEnableableComponents()
        end
        
        function set.EnableableComponents(obj,value)
            obj.EnableableComponents = value;
            obj.updateEnableableComponents()
        end
        
    end %methods
    
    
    
    %% Methods
    methods (Access = protected)
        
        function updateEnableableComponents(obj)
            
            wt.utility.fastSet(obj.EnableableComponents,"Enable",obj.Enable);
            
        end %function
        
    end %methods
    
end %classdef