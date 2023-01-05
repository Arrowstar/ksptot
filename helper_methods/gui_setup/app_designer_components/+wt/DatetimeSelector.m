classdef DatetimeSelector < wt.abstract.BaseWidget &...
        wt.mixin.Enableable & wt.mixin.FontStyled & wt.mixin.FieldColorable
    % A date and time selection control
    
    % Copyright 2021 The MathWorks Inc.
    
    
    %% Events
    events (HasCallbackProperty, NotifyAccess = protected)
        
        % Triggered on value changed, has companion callback
        ValueChanged
        
    end %events
    
    
    %% Public properties
    properties (AbortSet)
        
        % The current value shown
        Value (1,1) datetime
        
        % The time format
        ShowAMPM (1,1) matlab.lang.OnOffSwitchState = 'on'
        
        % Show seconds or not
        ShowSeconds (1,1) matlab.lang.OnOffSwitchState = 'off'
        
    end %properties
    
    
    properties (AbortSet, Dependent, UsedInUpdate = false)
        
        % Format for display
        DateFormat
        
        % Disabled days of week
        DisabledDaysOfWeek
        
        % DisabledDates
        DisabledDates
        
        % Limits on the date
        Limits
        
    end %properties
    
    
    
    %% Internal Properties
    properties ( Transient, NonCopyable, ...
            Access = {?wt.abstract.BaseWidget, ?wt.test.BaseWidgetTest} )
        
        % Button
        DateControl (1,1) matlab.ui.control.DatePicker
        
        % Hour control
        HourControl (1,1) matlab.ui.control.Spinner
        
        % Minute control
        MinuteControl (1,1) matlab.ui.control.Spinner
        
        % Second control
        SecondControl (1,1) matlab.ui.control.Spinner
        
        % AmPm control
        AmPmControl (1,1) matlab.ui.control.DropDown
        
    end %properties
    
    
    
    %% Protected methods
    methods (Access = protected)
        
        function setup(obj)
            
            % Adjust default size
            obj.Position(3:4) = [270 25];
            
            % Set default date to today
            obj.Value = datetime("today",...
                "TimeZone","local",...
                "Format","dd-MMM-uuuu hh:mm aa");
            
            % Call superclass setup first to establish the grid
            obj.setup@wt.abstract.BaseWidget();
            
            % Configure Grid
            obj.Grid.ColumnWidth = {'9x',5,'4x','4x',0,0};
            obj.Grid.RowHeight = {'1x'};
            obj.Grid.ColumnSpacing = 0;
            
            % Create the date control
            obj.DateControl = matlab.ui.control.DatePicker(...
                "Parent",obj.Grid,...
                "ValueChangedFcn",@(h,e)obj.onDateEdited(e));
            
            % Spacer
            uicontainer(obj.Grid,'Visible','off'); 

            % Create the time controls       
            % obj.HourControl = matlab.ui.control.NumericEditField(...   
            obj.HourControl = uispinner(...
                "Parent",obj.Grid,...
                "Limits",[-1 24],...
                "HorizontalAlignment","center",...
                "ValueChangedFcn",@(h,e)obj.onTimeEdited(e));
            
            %obj.MinuteControl = matlab.ui.control.NumericEditField(...
            obj.MinuteControl = uispinner(...
                "Parent",obj.Grid,...
                "Limits",[-1 60],...
                "ValueDisplayFormat","%02.0f",...
                "HorizontalAlignment","center",...
                "ValueChangedFcn",@(h,e)obj.onTimeEdited(e));
            
            %obj.SecondControl = matlab.ui.control.NumericEditField(...
            obj.SecondControl = uispinner(...
                "Parent",obj.Grid,...
                "Limits",[-1 60],...
                "ValueDisplayFormat","%02.f",...
                "HorizontalAlignment","center",...
                "ValueChangedFcn",@(h,e)obj.onTimeEdited(e));
            
            obj.AmPmControl = matlab.ui.control.DropDown(...
                "Parent",obj.Grid,...
                "Items",["AM","PM"],...
                "ValueChangedFcn",@(h,e)obj.onTimeEdited(e));
            
            % Update the internal component lists
            allFields = [
                obj.DateControl
                obj.HourControl
                obj.MinuteControl
                obj.SecondControl
                obj.AmPmControl
                ];
            obj.FontStyledComponents = allFields;
            obj.FieldColorableComponents = allFields;
            obj.EnableableComponents = allFields;
            
        end %function
        
        
        function update(obj)
            
            % Get the value
            v = obj.Value;
            
            %RAJ - handle NaT
            
            % Toggle visibilities
            obj.SecondControl.Visible = obj.ShowSeconds;
            obj.AmPmControl.Visible = obj.ShowAMPM;
            if obj.ShowSeconds
                obj.Grid.ColumnWidth{5} = '4x';
            else
                obj.Grid.ColumnWidth{5} = 0;
            end
            if obj.ShowAMPM
                obj.Grid.ColumnWidth{6} = '5x';
            else
                obj.Grid.ColumnWidth{6} = 0;
            end

            % Update the date control
            valFormat = strtok(v.Format,' ');
            obj.DateControl.Value = v;
            obj.DateControl.DisplayFormat = valFormat;
            
            % Which hour format?
            if obj.ShowAMPM
                
                % Update the AM/PM
                if v.Hour < 12
                    obj.AmPmControl.Value = "AM";
                else
                    obj.AmPmControl.Value = "PM";
                end
                
                % Update the hour control
                if v.Hour > 12
                    obj.HourControl.Value = v.Hour - 12;
                elseif v.Hour == 0
                    obj.HourControl.Value = 12;
                else
                    obj.HourControl.Value = v.Hour;
                end
                %obj.HourControl.Limits = [1 12];
                obj.HourControl.ValueDisplayFormat = "%2.0f";
                
            else
                
                % Update the hour control
                %obj.HourControl.Limits = [0 23];
                obj.HourControl.ValueDisplayFormat = "%02.0f";
                obj.HourControl.Value = v.Hour;
                
            end %if obj.ShowAMPM
            
            % Update the minutes and seconds
            obj.MinuteControl.Value = v.Minute;
            obj.SecondControl.Value = v.Second;
            
        end %function
        
        
        function onDateEdited(obj,evt)
            % Triggered on edits
            
            % Get the new date
            newValue = evt.Source.Value;
            
            % Update the value
            value = obj.Value;
            value.Year = newValue.Year;
            value.Month = newValue.Month;
            value.Day = newValue.Day;
            obj.Value = value;
            
            % Trigger event
            evtOut = wt.eventdata.ValueChangedData(obj.Value);
            notify(obj,"ValueChanged",evtOut);
            
        end %function
        
        
        function onTimeEdited(obj,evt)
            % Triggered on edits
            
            % Get the new value
            newValue = evt.Source.Value;
            dt = obj.Value;
            
            % What was changed?
            switch evt.Source
                
                case obj.HourControl
                    if obj.ShowAMPM && dt.Hour == 0
                        dt.Hour = newValue - 12;
                    elseif obj.ShowAMPM && dt.Hour > 12
                        dt.Hour = newValue + 12;
                    else
                        dt.Hour = newValue;
                    end
                    
                case obj.MinuteControl
                    dt.Minute = newValue;
                    
                case obj.SecondControl
                    dt.Second = newValue;
                    
                case obj.AmPmControl
                    
                    if newValue == "AM" && dt.Hour > 11
                        dt.Hour = dt.Hour - 12;
                    elseif newValue == "PM" && dt.Hour < 12
                        dt.Hour = dt.Hour + 12;
                    end
                    
            end %switch
            
            % Update value
            obj.Value = dt;
            
            % Trigger event
            evtOut = wt.eventdata.ValueChangedData(obj.Value);
            notify(obj,"ValueChanged",evtOut);
            
        end %function
        
    end % methods
    
    
    
    %% Accessors
    methods
        
        function value = get.DateFormat(obj)
            value = obj.DateControl.DisplayFormat;
        end
        function set.DateFormat(obj,value)
            obj.DateControl.DisplayFormat = value;
        end
        
        function value = get.Limits(obj)
            value = obj.DateControl.Limits;
        end
        function set.Limits(obj,value)
            obj.DateControl.Limits = value;
        end
        
        function value = get.DisabledDaysOfWeek(obj)
            value = obj.DateControl.DisabledDaysOfWeek;
        end
        function set.DisabledDaysOfWeek(obj,value)
            obj.DateControl.DisabledDaysOfWeek = value;
        end
        
        function value = get.DisabledDates(obj)
            value = obj.DateControl.DisabledDates;
        end
        function set.DisabledDates(obj,value)
            obj.DateControl.DisabledDates = value;
        end
        
    end %methods
    
end % classdef