classdef ColorSelector < wt.abstract.BaseWidget &...
        wt.mixin.Enableable & wt.mixin.FontStyled & wt.mixin.Tooltipable & ...
        wt.mixin.FieldColorable
    % A color selection control with browse button
    
    % Copyright 2020-2021 The MathWorks Inc.
    
    
    %% Public properties
    properties (AbortSet)
        
        % The current value shown
        Value (1,3) double {wt.validators.mustBeBetweenZeroAndOne} = [0 1 0]
        
    end %properties
    
    
    % These properties do not trigger the update method
    properties (AbortSet, UsedInUpdate = false)
        
        % Indicates whether to show the edit field
        ShowEditField (1,1) matlab.lang.OnOffSwitchState = true
        
    end %properties
    
    
    %% Events
    events (HasCallbackProperty, NotifyAccess = protected)
        
        % Triggered on value changed, has companion callback
        ValueChanged
        
    end %events
    
    
    
    %% Internal Properties
    properties ( Transient, NonCopyable, ...
            Access = {?wt.abstract.BaseWidget, ?wt.test.BaseWidgetTest} )
        
        % Button
        ButtonControl (1,1) matlab.ui.control.Button
        
        % Edit control
        EditControl (1,1) matlab.ui.control.EditField
        
    end %properties
    
    
    
    %% Protected methods
    methods (Access = protected)
        
        function setup(obj)
            
            % Call superclass setup first to establish the grid
            obj.setup@wt.abstract.BaseWidget();
            
            % Set default size
            obj.Position(3:4) = [100 25];
            
            % Configure Grid
            obj.Grid.ColumnWidth = {'1x',25};
            obj.Grid.RowHeight = {'1x'};
            
            % Create the standard edit control
            obj.EditControl = matlab.ui.control.EditField(...
                "Parent",obj.Grid,...
                "ValueChangedFcn",@(h,e)obj.onTextChanged(e));
            
            % Create Button
            obj.ButtonControl = matlab.ui.control.Button(...
                "Parent",obj.Grid,...
                "Text","",...
                "ButtonPushedFcn",@(h,e)obj.onButtonPushed(e));
            
            % Update the internal component lists
            obj.FontStyledComponents = [obj.EditControl];
            obj.FieldColorableComponents = [obj.EditControl];
            obj.EnableableComponents = [obj.EditControl, obj.ButtonControl];
            obj.TooltipableComponents = [obj.EditControl, obj.ButtonControl];
            
        end %function
        
        
        function update(obj)
            
            % Update the edit control text
            obj.EditControl.Value = mat2str(obj.Value,2);
            
            % Update the button color
            obj.ButtonControl.BackgroundColor = obj.Value;
            
        end %function
        
        
        function updateFieldVisibility(obj)
            
            % Is history being shown? If so, update history and items
            if obj.ShowEditField
                % Showing edit field
                
                if isempty(obj.EditControl.Parent)
                    obj.ButtonControl.Layout.Column = 2;
                    obj.EditControl.Parent = obj.Grid;
                    obj.EditControl.Layout.Column = 1;
                    obj.EditControl.Layout.Row = 1;
                end
                
            else
                % Hiding edit field
                
                if ~isempty(obj.EditControl.Parent)
                    obj.EditControl.Parent = [];
                    obj.ButtonControl.Layout.Column = [1 2];
                end
                
            end %if
            
        end %function
        
        
        function onButtonPushed(obj,~)
            % Triggered on button pushed
            
            % Get prior value
            oldValue = obj.Value;
            
            % Prompt for a new color
            newColor = uisetcolor(oldValue);
            
            % Did user make a choice or cancel?
            if ~isequal(newColor,0)
                % Update the color
                obj.Value = newColor;
            end
            
            % Trigger event
            evtOut = wt.eventdata.ValueChangedData(obj.Value, oldValue);
            notify(obj,"ValueChanged",evtOut);
            
        end %function
        
        
        function onTextChanged(obj,evt)
            % Triggered on text interaction - subclass may override
            
            % Get prior value
            oldValue = obj.Value;
            
            % Trap errors
            try
                
                % Store new result
                obj.Value = str2num(evt.Value); %#ok<ST2NM>
                
                % Trigger event
                evtOut = wt.eventdata.ValueChangedData(obj.Value, oldValue);
                notify(obj,"ValueChanged",evtOut);
                
            catch
                
                % Restore original value
                obj.update();
                
            end %try
            
        end %function
        
    end %methods
    
    
    %% Accessors
    methods
        
        function set.ShowEditField(obj,value)
            obj.ShowEditField = value;
            obj.updateFieldVisibility()
        end
        
    end % methods
    
    
end % classdef