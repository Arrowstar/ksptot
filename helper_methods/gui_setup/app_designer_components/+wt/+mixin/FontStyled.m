classdef FontStyled < handle
    % Mixin for component with Font properties

    % Copyright 2020-2021 The MathWorks Inc.
    
    
    %% Properties
    properties (AbortSet)
        
        % Font name
        FontName char {mustBeNonempty} = 'Helvetica'
        
        % Font size in points
        FontSize (1,1) double {mustBePositive,mustBeFinite} = 12
        
        % Font weight (normal/bold)
        FontWeight {mustBeMember(FontWeight,{'normal','bold'})} = 'normal'
        
        % Font angle (normal/italic)
        FontAngle {mustBeMember(FontAngle,{'normal','italic'})} = 'normal'
        
        % Font color
        FontColor (1,3) double {wt.validators.mustBeBetweenZeroAndOne} = [0 0 0]
        
    end %properties
    
    
    
    %% Internal properties
    properties (AbortSet, Transient, NonCopyable, ...
            Access = {?wt.abstract.BaseWidget, ?wt.test.BaseWidgetTest} )
        
        % List of graphics controls to apply to
        FontStyledComponents (:,1) matlab.graphics.Graphics
        
    end %properties
    
    
    
    %% Accessors
    methods
        
        function set.FontName(obj,value)
            obj.FontName = value;
            obj.updateFontStyledComponents("FontName",value)
        end
        
        function set.FontSize(obj,value)
            obj.FontSize = value;
            obj.updateFontStyledComponents("FontSize",value)
        end
        
        function set.FontWeight(obj,value)
            obj.FontWeight = value;
            obj.updateFontStyledComponents("FontWeight",value)
        end
        
        function set.FontAngle(obj,value)
            obj.FontAngle = value;
            obj.updateFontStyledComponents("FontAngle",value)
        end
        
        function set.FontColor(obj,value)
            obj.FontColor = value;
            obj.updateFontStyledComponents("FontColor",value)
        end
        
        function set.FontStyledComponents(obj,value)
            obj.FontStyledComponents = value;
            obj.updateFontStyledComponents();
        end
        
    end %methods
    
    
    
    %% Methods
    methods (Access = protected)
        
        function updateFontStyledComponents(obj,prop,value)
            
            if nargin > 1
                % Update specific property
                hasProp = isprop(obj.FontStyledComponents,prop);
                wt.utility.fastSet(obj.FontStyledComponents(hasProp),prop,value);
            else
                % Update all
                obj.updateFontStyledComponents("FontName",obj.FontName)
                obj.updateFontStyledComponents("FontSize",obj.FontSize)
                obj.updateFontStyledComponents("FontWeight",obj.FontWeight)
                obj.updateFontStyledComponents("FontAngle",obj.FontAngle)
                obj.updateFontStyledComponents("FontColor",obj.FontColor)
            end
            
        end %function
        
    end %methods
    
end %classdef