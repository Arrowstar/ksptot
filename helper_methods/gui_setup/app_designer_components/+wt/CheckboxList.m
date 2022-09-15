classdef CheckboxList < wt.abstract.BaseWidget &...
        wt.mixin.Enableable & wt.mixin.FontStyled & wt.mixin.Tooltipable
    % A checkbox list
    
    % Copyright 2020-2021 The MathWorks Inc.
    
    
    %% Public properties
    properties (AbortSet)
        
        % Name of each item
        Items (:,1) string = [
            "Item 1"
            "Item 2"
            "Item 3"
            "Item 4"
            "Item 5"
            "Item 6"
            ]
        
        % The current value shown
        Value (:,1) logical = true(6,1)
        
        % Indicates whether to show the Select All field
        ShowSelectAll  (1,1) matlab.lang.OnOffSwitchState = false
        
    end %properties
    
    
    
    %% Events
    events (HasCallbackProperty, NotifyAccess = protected)
        
        % Triggered on value changed, has companion callback
        ValueChanged
        
    end %events
    
    
    
    %% Internal Properties
    properties ( Transient, NonCopyable, ...
            Access = {?wt.abstract.BaseWidget, ?wt.test.BaseWidgetTest} )
        
        % Item checkboxes
        ItemCheck (1,:) matlab.ui.control.CheckBox
        
        % Select All checkbox
        AllCheck (1,1) matlab.ui.control.CheckBox
        
    end %properties
    
    
    
    %% Protected methods
    methods (Access = protected)
        
        function setup(obj)
            
            % Call superclass setup first to establish the grid
            obj.setup@wt.abstract.BaseWidget();
            
            % Set default size
            obj.Position(3:4) = [100 130];
            
            % Configure Grid
            obj.Grid.Padding = 10;
            obj.Grid.ColumnWidth = {'fit'};
            obj.Grid.RowHeight = {0,'fit'};
            obj.Grid.RowSpacing = 5;
            obj.Grid.Scrollable = true;
            
            % Default background to white
            obj.BackgroundColor = [1 1 1];
            
            % Create the Select All checkbox
            obj.AllCheck = matlab.ui.control.CheckBox(...
                "Parent",obj.Grid,...
                "Text","Select All",...
                "FontWeight","bold",...
                "Visible","off",...
                "ValueChangedFcn",@(h,e)obj.onSelectAllClicked(e));
            
            % Update the internal component lists
            obj.FontStyledComponents = [obj.AllCheck, obj.ItemCheck];
            obj.EnableableComponents = [obj.AllCheck, obj.ItemCheck];
            obj.TooltipableComponents = [obj.AllCheck, obj.ItemCheck];
            
        end %function
        
        
        function update(obj)
            
            % How many items?
            numOld = numel(obj.ItemCheck);
            numNew = numel(obj.Items);
            
            % Update number of rows
            if numNew > numOld
                
                % Add rows
                for idx = (numOld+1):numNew
                    obj.ItemCheck(idx) = uicheckbox(obj.Grid,...
                        "Text",obj.Items(idx),...
                        'ValueChangedFcn', @(h,e)obj.onCheckboxClicked(e));
                    obj.Grid.RowHeight{idx+1} = 'fit';
                end
                
                % Update the internal component lists
                obj.FontStyledComponents = [obj.AllCheck, obj.ItemCheck];
                obj.EnableableComponents = [obj.AllCheck, obj.ItemCheck];
                obj.TooltipableComponents = [obj.AllCheck, obj.ItemCheck];
                
            elseif numOld > numNew
                
                % Remove rows
                delete(obj.ItemCheck((numNew+1):end));
                obj.ItemCheck((numNew+1):end) = [];
                
            end %if numNew > numOld
            
            % Update each control
            for idx = 1:numNew
                wt.utility.fastSet(obj.ItemCheck(idx),...
                    'Text',obj.Items(idx),...
                    'Value',obj.Value(idx) );
            end
            
            % Update the Select All control
            if obj.ShowSelectAll
                wt.utility.fastSet( obj.AllCheck, 'Value', all(obj.Value) ); 
            end
            
            % Show/hide Select All
            if obj.ShowSelectAll && ~obj.AllCheck.Visible
                obj.AllCheck.Visible = "on";
                obj.Grid.RowHeight{1} = 30;
            elseif ~obj.ShowSelectAll && obj.AllCheck.Visible
                obj.AllCheck.Visible = "off";
                obj.Grid.RowHeight{1} = 0;
            end
            
        end %function
        
        
        function updateFontStyledComponents(obj,varargin)
            
            % Call superclass method first
            obj.updateFontStyledComponents@wt.mixin.FontStyled(varargin{:});
            
            % Always make AllCheck bold
            obj.AllCheck.FontWeight = "bold";
            
        end %function
        
        
        function onSelectAllClicked(obj,evt)
            % Triggered on select all
            
            % Calculate the new selection
            newValue = obj.Value;
            newValue(:) = evt.Value;
                
            % Prepare event data
            evtOut = wt.eventdata.PropertyChangedData('Value', newValue, obj.Value);
            
            % Store new result
            obj.Value = newValue;
            
            % Trigger event
            notify(obj,"ValueChanged",evtOut);
            
        end %function
        
        
        function onCheckboxClicked(obj,~)
            % Triggered on select all
                 
            % Calculate the new selection
            newValue = [obj.ItemCheck.Value];
            
            % Prepare event data
            evtOut = wt.eventdata.PropertyChangedData('Value', newValue, obj.Value);
            
            % Store new result
            obj.Value = newValue;
            
            % Trigger event
            notify(obj,"ValueChanged",evtOut);
            
        end %function
        
    end %methods
    
    
    
    %% Accessors
    methods
        
        function value = get.Value(obj)
            numItems = numel(obj.Items);
            value = obj.Value;
            value(end+1:numItems) = true;
            value(numItems+1:end) = [];
        end
        
    end % methods
    
    
end % classdef