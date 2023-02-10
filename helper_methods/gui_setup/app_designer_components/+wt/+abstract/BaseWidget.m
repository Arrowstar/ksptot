classdef (Abstract) BaseWidget < matlab.ui.componentcontainer.ComponentContainer & ...
        wt.mixin.ErrorHandling
    % Base class for a graphical widget

    % Copyright 2020-2021 The MathWorks Inc.
    
    
    %% Internal properties
    properties (AbortSet, Transient, NonCopyable, ...
            Access = {?wt.abstract.BaseWidget, ?wt.test.BaseWidgetTest} )
        
        % List of graphics controls that BackgroundColor should apply to
        BackgroundColorableComponents (:,1) matlab.graphics.Graphics
        
    end %properties
    
    
    properties (Transient, NonCopyable, Access = {?wt.test.BaseWidgetTest})
        
        % Used internally to indicate when setup has finished
        SetupFinished_I (1,1) logical = false
        
    end %properties

    
    properties (Transient, NonCopyable, UsedInUpdate, Access = {?wt.test.BaseWidgetTest})
        
        % Used internally to request update call
        RequestUpdate_I (1,1) logical = false
        
    end %properties
    
    
    %% Debugging Methods
    methods
        
        function forceUpdate(obj)
           % Forces update to run (For debugging only!)
           
            obj.update();
            
        end %function
        
    end %methods
    
    
    
    %% Setup
    properties ( Transient, NonCopyable, ...
            Access = {?wt.abstract.BaseWidget, ?wt.test.BaseWidgetTest} )
        
        % The internal grid to manage contents
        Grid matlab.ui.container.GridLayout
        
    end %properties
    
    
    methods (Access = protected)
        
        function setup(obj)
            % Configure the widget
            
            % Use CreateFcn to tell when setup finishes
            obj.CreateFcn = @(src,evt)obj.toggleSetupFinished_I();
            
            % Grid Layout to manage building blocks
            obj.Grid = uigridlayout(obj);
            obj.Grid.ColumnWidth = {'1x'};
            obj.Grid.RowHeight = {'1x'};
            obj.Grid.RowSpacing = 2;
            obj.Grid.ColumnSpacing = 2;
            obj.Grid.Padding = [0 0 0 0];
            
            % Listen to BackgroundColor changes
            addlistener(obj,'BackgroundColor','PostSet',...
                @(h,e)obj.updateBackgroundColorableComponents());
            
        end %function
        
    end %methods
    
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function updateBackgroundColorableComponents(obj)
            % Update components that are affected by BackgroundColor
            
            obj.Grid.BackgroundColor = obj.BackgroundColor;
            hasProp = isprop(obj.BackgroundColorableComponents,'BackgroundColor');
            set(obj.BackgroundColorableComponents(hasProp),...
                "BackgroundColor",obj.BackgroundColor);
            
        end %function
        
        
        function requestUpdate(obj)
            % Request update method to run
            
            if ~obj.SetupFinished_I
                % Do nothing
            elseif verLessThan('matlab','9.10')
                % g228243 Force a call to update
                obj.update();
            else
                % Trigger set of a UsedInUpdate property to request update
                % during next drawnow. (for optimal efficiency)
                obj.RequestUpdate_I = true;
            end
            
        end %function
        
    end %methods
    
    
    
    %% Private Methods
    methods (Access = private)
            
        function toggleSetupFinished_I(obj)
            % Indicate setup is complete
            
            obj.SetupFinished_I = true;
            obj.CreateFcn = '';
            
        end %function
        
    end %methods
    
    
    
    %% Display customization
    methods (Hidden, Access = protected)
        
        function groups = getPropertyGroups(obj)
            % Customize how the properties are displayed
            
            % Ignore most superclass properties for default display
            persistent superProps
            if isempty(superProps)
                superProps = properties('matlab.ui.componentcontainer.ComponentContainer');
            end
            
            % Get the relevant properties
            allProps = properties(obj);
            propNames = setdiff(allProps, superProps, 'stable');
            
            % Remove props we don't need to see
            propNames( startsWith(propNames, "Font") ) = [];
            propNames( matches(propNames, "Enable") ) = [];
            
            % Split out the callbacks, fonts
            isCallback = endsWith(propNames, "Fcn");
            isColor = endsWith(propNames, "Color");
            normalProps = propNames(~isCallback & ~isColor);
            callbackProps = propNames(isCallback & ~isColor);
            
            % Define the groups
            groups = [
                matlab.mixin.util.PropertyGroup(callbackProps)
                matlab.mixin.util.PropertyGroup(normalProps)
                matlab.mixin.util.PropertyGroup(["Position", "Units"])
                ];
            
            % Ignore empty groups
            groups(~[groups.NumProperties]) = [];
            
        end %function
        
    end %methods
    
    
    
    %% Accessors
    methods
        
        function set.BackgroundColorableComponents(obj,value)
            obj.BackgroundColorableComponents = value;
            obj.updateBackgroundColorableComponents()
        end
        
    end %methods
    
    
end %classdef

