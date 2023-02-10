classdef SliderCheckboxGroup < wt.abstract.BaseWidget &...
        wt.mixin.Enableable & wt.mixin.FontStyled
    % A group of sliders with checkboxes, useful for visibility of various
    % layers of imagery
    
    % Copyright 2020-2021 The MathWorks Inc.
    
    
    %% Events
    events (HasCallbackProperty, NotifyAccess = protected)
        
        % Triggered when the value changes
        ValueChanged
        
    end %events
    
    
    %% Public properties
    properties (AbortSet, UsedInUpdate = true)
        
        % Name of each slider
        Name (1,:) string = ["Slider 1","Slider 2","Slider 3"];
        
        % State of each slider
        State (1,:) logical = true(1,3);
        
        % Value of each slider
        Value (1,:) double {mustBeNonnegative, ...
            mustBeLessThanOrEqual(Value,1)} = ones(1,3);
        
        % Height of each row
        RowHeight (1,1) double = 25
        
    end %properties
    
    
    % These properties do not trigger the update method
    properties (Dependent, AbortSet, UsedInUpdate = false)
        
        % Width of checkbox column
        CheckboxWidth
        
    end %properties
    
    
    
    %% Internal Properties
    properties ( Transient, NonCopyable, ...
            Access = {?wt.abstract.BaseWidget, ?wt.test.BaseWidgetTest} )
        
        % Checkboxes
        Checkbox (1,:) matlab.ui.control.CheckBox
        
        % Sliders
        Slider (1,:) matlab.ui.control.Slider

    end %properties
    
    
    
    %% Protected methods
    methods (Access = protected)
        
        function setup(obj)
            
            % Call superclass setup first to establish the grid
            obj.setup@wt.abstract.BaseWidget();
            
            % Set default size
            obj.Position(3:4) = [120 150];
            
            % Configure Main Grid
            obj.Grid.Padding = 2;
            obj.Grid.ColumnSpacing = 5;
            obj.Grid.RowSpacing = 5;
            obj.Grid.ColumnWidth = {'fit','1x'};
            
        end %function
        
        
        function update(obj)
            
            % How many rows?
            numOld = numel(obj.Slider);
            numNew = numel(obj.Name);
            
            % Remove extra rows if necessary
            if numOld > numNew
                
                delete(obj.Checkbox((numNew+1):end));
                obj.Checkbox((numNew+1):end) = [];
                
                delete(obj.Slider((numNew+1):end));
                obj.Slider((numNew+1):end) = [];
                
            end %if numNew > numOld
            
            % Update grid size
                obj.Grid.RowHeight = repmat({obj.RowHeight},1,numNew);
            
            % Add new rows if necessary
            if numNew > numOld
                
                % Add rows
                for idx = (numOld+1):numNew
                    obj.Checkbox(idx) = uicheckbox(obj.Grid);
                    obj.Slider(idx) = uislider(obj.Grid);
                end
                
                % Set properties
                set(obj.Checkbox,'ValueChangedFcn',@(h,e)obj.onCheckboxChanged(e));
                set(obj.Slider,'ValueChangedFcn',@(h,e)obj.onSliderChanged(e));
                set(obj.Slider,'ValueChangingFcn',@(h,e)obj.onSliderChanged(e));
                set(obj.Slider,'Limits',[0 1]);
                set(obj.Slider,'MajorTicks',[]);
                set(obj.Slider,'MinorTicks',[]);
                set(obj.Checkbox,'WordWrap','on');
                
                % Update the internal component lists
                obj.FontStyledComponents = [obj.Checkbox, obj.Slider];
                obj.EnableableComponents = [obj.Checkbox, obj.Slider];
                
                % Set scrollability
                obj.Grid.Scrollable = true;
                
            end
            
            % Update names and values
            for idx = 1:numNew
                obj.Checkbox(idx).Text = obj.Name(idx);
                obj.Checkbox(idx).Value = obj.State(idx);
                obj.Slider(idx).Value = obj.Value(idx);
                obj.Slider(idx).Enable = obj.Enable && obj.State(idx);
            end
            
        end %function
        
        
        function updateEnableableComponents(obj)
            
            % Call superclass method first
            obj.updateEnableableComponents@wt.mixin.Enableable();
            
            % Sliders might remain disabled
            if obj.Enable
                for idx = 1:numel(obj.Slider)
                    if numel(obj.State) >= idx && ~obj.State(idx)
                        obj.Slider(idx).Enable = false;
                    end
                end
            end
            
        end %function
        
        
        function onSliderChanged(obj,e)
            % Triggered on button pushed
            
            % What changed?
            newValue = e.Value;
            idx = find(e.Source == obj.Slider, 1);
            
            % Update the state
            obj.Value(idx) = newValue;
            
            % Create event data
            evt = wt.eventdata.SliderCheckboxChangedData(...
                obj.Name(idx), idx, "Value", obj.State(idx), obj.Value(idx) );
            
            % Trigger event
            notify(obj,"ValueChanged",evt);
            
        end %function
        
        
        function onCheckboxChanged(obj,e)
            % Triggered on button pushed
            
            % What changed?
            newValue = e.Value;
            idx = find(e.Source == obj.Checkbox, 1);
            
            % Update the state
            obj.State(idx) = newValue;
            
            % Create event data
            evt = wt.eventdata.SliderCheckboxChangedData(...
                obj.Name(idx), idx, "State", obj.State(idx), obj.Value(idx) );
            
            % Trigger event
            notify(obj,"ValueChanged",evt);
            
        end %function
        
    end %methods
    
    
    %% Accessors
    methods
        
        function value = get.Value(obj)
            value = obj.Value;
            value((end+1):numel(obj.Name)) = 1;
        end
        
        function value = get.State(obj)
            value = obj.State;
            value((end+1):numel(obj.Name)) = 1;
        end
        
        function value = get.CheckboxWidth(obj)
            value = obj.Grid.ColumnWidth{1};
        end
        
        function set.CheckboxWidth(obj,value)
            obj.Grid.ColumnWidth{1} = value;
        end
        
    end % methods
    
    
end % classdef