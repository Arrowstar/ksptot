classdef SliderSpinner < wt.abstract.BaseWidget &...
        wt.mixin.Enableable & wt.mixin.FontStyled &...
        wt.mixin.FieldColorable
    % A slider and spinner combination
    
    % Copyright 2020-2021 The MathWorks Inc.
    
    
    %% Public properties
    properties (Dependent, AbortSet, UsedInUpdate = false)
        % These properties do not trigger the update method
        
        % Value of the slider and spinner
        Value (1,1) double
        
        % Limits of the slider and spinner
        Limits
        
        % Passes through to the uislider
        Step
        
        % Passes through to the uislider
        RoundFractionalValues
        
        % Passes through to the uislider
        ValueDisplayFormat
        
        % Orientation of the spinner and slider
        Orientation (1,1) wt.enum.HorizontalVerticalState = wt.enum.HorizontalVerticalState.horizontal
        
        % Size of spinner (width for horizontal, height for vertical
        SpinnerSize
        
        % Passes through to the uispinner
        MajorTickLabels
        
        % Passes through to the uispinner
        MajorTickLabelsMode
        
        % Passes through to the uispinner
        MajorTicks
        
        % Passes through to the uispinner
        MajorTicksMode
        
        % Passes through to the uispinner
        MinorTickLabels
        
        % Passes through to the uispinner
        MinorTicks
        
        % Passes through to the uispinner
        MinorTicksMode
        
    end %properties
    
    
    %% Events
    events (HasCallbackProperty, NotifyAccess = protected)
        
        % Triggered on value changed, has companion callback
        ValueChanged
        
        % Triggered on value changing during slider motion, has companion callback
        ValueChanging
        
    end %events
    
    
    
    %% Internal Properties
    properties ( Transient, NonCopyable, ...
            Access = {?wt.abstract.BaseWidget, ?wt.test.BaseWidgetTest} )
        
        % Slider
        Slider (1,1) matlab.ui.control.Slider
        
        % Spinner
        Spinner (1,1) matlab.ui.control.Spinner
        
    end %properties
    
    
    
    %% Protected methods
    methods (Access = protected)
        
        function setup(obj)
            
            % Call superclass setup first to establish the grid
            obj.setup@wt.abstract.BaseWidget();
            
            % Set default size
            obj.Position(3:4) = [200 40];
            
            % Configure Main Grid
            obj.Grid.Padding = 2;
            obj.Grid.ColumnSpacing = 5;
            obj.Grid.ColumnWidth = {'1x',75};
            
            % Slider
            obj.Slider = uislider(obj.Grid);
            obj.Slider.ValueChangedFcn = @(h,e)obj.onSliderChanged(e);
            obj.Slider.ValueChangingFcn = @(h,e)obj.onSliderChanging(e);
            obj.Slider.Limits = [0 100];
            
            % Spinner
            obj.Spinner = uispinner(obj.Grid);
            obj.Spinner.ValueChangedFcn = @(h,e)obj.onSpinnerChanged(e);
            obj.Spinner.RoundFractionalValues = 'on';
            obj.Spinner.Limits = [0 100];
            
            % Update the internal component lists
            obj.FontStyledComponents = [obj.Spinner, obj.Slider];
            obj.EnableableComponents = [obj.Spinner, obj.Slider];
            obj.FieldColorableComponents = [obj.Spinner];
            
        end %function
        
        
        function update(obj)
            
            wt.utility.fastSet([obj.Slider obj.Spinner],'Value',obj.Value);
            
        end %function
        
        
        function updateLayout(obj)
            
            if obj.Orientation == "vertical"
                obj.Grid.ColumnWidth = {'1x'};
                obj.Grid.RowHeight = {'1x',25};
                obj.Spinner.Layout.Row = 2;
                obj.Spinner.Layout.Column = 1;
            else
                obj.Grid.ColumnWidth = {'1x',75};
                obj.Grid.RowHeight = {'1x'};
                obj.Spinner.Layout.Row = 1;
                obj.Spinner.Layout.Column = 2;
            end
            
        end %function
        
        
        function onSliderChanged(obj,e)
            % Triggered on button pushed
            
            % What changed?
            newValue = e.Value;
            oldValue = obj.Spinner.Value;
            
            % Round?
            if obj.RoundFractionalValues
                newValue = round(newValue);
                newValue = min(max(newValue,obj.Limits(1)),obj.Limits(2));
            end
            
            % Prepare event data
            evtOut = wt.eventdata.PropertyChangedData('Value', newValue, oldValue);
            
            % Update the state
            obj.Spinner.Value = newValue;
            if obj.RoundFractionalValues && newValue ~= obj.Slider.Value
                obj.Slider.Value = newValue;
            end
            
            % Trigger event ("ValueChanged" or "ValueChanging")
            notify(obj, e.EventName, evtOut);
            
        end %function
        
        
        function onSliderChanging(obj,e)
            % Triggered on button pushed
            
            % What changed?
            newValue = e.Value;
            oldValue = obj.Spinner.Value;
            
            % Round?
            if obj.RoundFractionalValues
                newValue = round(newValue);
                newValue = min(max(newValue,obj.Limits(1)),obj.Limits(2));
            end
            
            % Prepare event data
            evtOut = wt.eventdata.PropertyChangedData('Value', newValue, oldValue);
            
            % Update the state
            obj.Spinner.Value = newValue;
            
            % Trigger event ("ValueChanging")
            notify(obj, e.EventName, evtOut);
            
        end %function
        
        
        function onSpinnerChanged(obj,e)
            % Triggered on button pushed
            
            % What changed?
            newValue = e.Value;
            
            % Prepare event data
            evtOut = wt.eventdata.PropertyChangedData('Value', newValue, e.PreviousValue);
            
            % Update the state
            obj.Slider.Value = newValue;
            
            % Trigger event
            notify(obj, "ValueChanged", evtOut);
            
        end %function
        
    end %methods
    
    
    %% Accessors
    methods
        
        function value = get.SpinnerSize(obj)
            if obj.Orientation == "vertical"
                value = obj.Grid.RowHeight{end};
            else
                value = obj.Grid.ColumnWidth{end};
            end
        end
        
        function set.SpinnerSize(obj,value)
            if obj.Orientation == "vertical"
                obj.Grid.RowHeight{end} = value;
            else
                obj.Grid.ColumnWidth{end} = value;
            end
        end
        
        
        function value = get.Limits(obj)
            value = obj.Slider.Limits;
        end
        
        function set.Limits(obj,value)
            obj.Slider.Limits = value;
            obj.Spinner.Limits = value;
        end
        
        
        function value = get.Value(obj)
            value = obj.Spinner.Value;
        end
        
        function set.Value(obj,value)
            obj.Spinner.Value = value;
            obj.Slider.Value = obj.Spinner.Value;
        end
        
        
        function value = get.ValueDisplayFormat(obj)
            value = obj.Spinner.ValueDisplayFormat;
        end
        
        function set.ValueDisplayFormat(obj,value)
            obj.Spinner.ValueDisplayFormat = value;
        end
        
        
        function value = get.RoundFractionalValues(obj)
            value = obj.Spinner.RoundFractionalValues;
        end
        
        function set.RoundFractionalValues(obj,value)
            obj.Spinner.RoundFractionalValues = value;
        end
        
        
        function value = get.Step(obj)
            value = obj.Spinner.Step;
        end
        
        function set.Step(obj,value)
            obj.Spinner.Step = value;
        end
        
        
        function value = get.Orientation(obj)
            value = wt.enum.HorizontalVerticalState(obj.Slider.Orientation);
        end
        
        function set.Orientation(obj,value)
            obj.Slider.Orientation = char(value);
            obj.updateLayout();
        end

        
        function value = get.MajorTicks(obj)
            value = obj.Slider.MajorTicks;
        end
        
        function set.MajorTicks(obj,value)
            obj.Slider.MajorTicks = value;
        end
        
        
        function value = get.MajorTickLabels(obj)
            value = obj.Slider.MajorTicks;
        end
        
        function set.MajorTickLabels(obj,value)
            obj.Slider.MajorTicks = value;
        end
        
        
        function value = get.MajorTicksMode(obj)
            value = obj.Slider.MajorTicksMode;
        end
        
        function set.MajorTicksMode(obj,value)
            obj.Slider.MajorTicksMode = value;
        end
        
        
        function value = get.MajorTickLabelsMode(obj)
            value = obj.Slider.MajorTickLabelsMode;
        end
        
        function set.MajorTickLabelsMode(obj,value)
            obj.Slider.MajorTickLabelsMode = value;
        end
        
        
        function value = get.MinorTicks(obj)
            value = obj.Slider.MinorTicks;
        end
        
        function set.MinorTicks(obj,value)
            obj.Slider.MinorTicks = value;
        end
        
        
        function value = get.MinorTickLabels(obj)
            value = obj.Slider.MinorTicks;
        end
        
        function set.MinorTickLabels(obj,value)
            obj.Slider.MinorTicks = value;
        end
        
        
        function value = get.MinorTicksMode(obj)
            value = obj.Slider.MinorTicksMode;
        end
        
        function set.MinorTicksMode(obj,value)
            obj.Slider.MinorTicksMode = value;
        end
        
    end % methods
    
    
end % classdef