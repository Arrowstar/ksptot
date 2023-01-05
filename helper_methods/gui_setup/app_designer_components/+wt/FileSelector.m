classdef FileSelector < wt.abstract.BaseWidget &...
        wt.mixin.Enableable & wt.mixin.FontStyled & wt.mixin.Tooltipable &...
        wt.mixin.FieldColorable & wt.mixin.ButtonColorable
    % A file/folder selection control with browse button
    
    % Copyright 2020-2021 The MathWorks Inc.
    
    
    %% Public properties
    properties (AbortSet)
        
        % The current value shown. If a RootDirectory is used, this will be
        % a relative path to the root.
        Value (1,1) string
        
    end %properties
    
    
    properties (Dependent, SetAccess = protected)
        
        % Absolute path to the file. If RootDirectory is used, this will
        % show the full path combining the root and the Value property.
        FullPath (1,1) string
        
        % Indicates the current value is a valid file path
        ValueIsValidPath (1,1) logical
        
    end %properties
    
    
    properties (AbortSet)
        
        % Selection type: file or folder
        SelectionType (1,1) wt.enum.FileFolderState = wt.enum.FileFolderState.file
        
        % Optional root directory. If unspecified, Value uses an absolute
        % path (default). If specified, Value will show a relative path to
        % the root directory and Value must be beneath RootDirectory.
        RootDirectory (1,1) string
        
        % Indicates whether to show a dropdown of recent folders
        ShowHistory (1,1) matlab.lang.OnOffSwitchState = false
        
        % List of recently selected folders to display in dropdown
        History (:,1) string
        
    end %properties
    
    
    % These properties do not trigger the update method
    properties (AbortSet, UsedInUpdate = false)
        
        % Optional default directory to start in when Value does not exist
        % and user clicks the browse button.
        DefaultDirectory (1,1) string
        
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
        
        % Edit control or dropdown
        EditControl (1,1) matlab.ui.control.EditField
        DropdownControl (1,1) matlab.ui.control.DropDown
        
    end %properties
    
    
    
    %% Protected methods
    methods (Access = protected)
        
        function setup(obj)
            
            % Adjust default size
            obj.Position(3:4) = [200 25];
            
            % Call superclass setup first to establish the grid
            obj.setup@wt.abstract.BaseWidget();
            
            % Configure Grid
            obj.Grid.ColumnWidth = {'1x',25};
            obj.Grid.RowHeight = {'1x'};
            
            % Create the standard edit control
            obj.EditControl = matlab.ui.control.EditField(...
                "Parent",obj.Grid,...
                "ValueChangedFcn",@(h,e)obj.onTextChanged(e));
            
            % Create the optional dropdown control
            obj.DropdownControl = matlab.ui.control.DropDown(...
                "Parent",[],...
                "Editable",true,...
                "Value","",...
                "ValueChangedFcn",@(h,e)obj.onTextChanged(e));
            %"Visible",false,...
            %obj.DropdownControl.Layout.Column = 1;
            
            % Create Button
            obj.ButtonControl = matlab.ui.control.Button(...
                "Parent",obj.Grid,...
                "Text","",...
                "ButtonPushedFcn",@(h,e)obj.onButtonPushed(e));
            obj.updateButtonIcon();
            
            % Update the internal component lists
            obj.FontStyledComponents = [obj.EditControl, obj.DropdownControl];
            obj.FieldColorableComponents = [obj.EditControl, obj.DropdownControl];
            obj.EnableableComponents = [obj.EditControl, obj.DropdownControl, obj.ButtonControl];
            obj.ButtonColorableComponents = obj.ButtonControl;
            obj.TooltipableComponents = [obj.EditControl, obj.DropdownControl, obj.ButtonControl];
            
        end %function
        
        
        function update(obj)
            
            % Is history being shown?
            if obj.ShowHistory
                % YES - Using dropdown control
                
                % Get the dropdown (history) items
                histItems = obj.History;
                
                % Current value must be in the list
                if ~isempty(obj.Value) && ~any(histItems == obj.Value)
                    histItems = vertcat(obj.Value,histItems);
                end
                
                % Update the items and value
                obj.DropdownControl.Items = histItems;
                obj.DropdownControl.Value = obj.Value;
                
            else
                % NO - Using edit control
                
                % Update the edit control text
                obj.EditControl.Value = obj.Value;
                
            end %if obj.ShowHistory
            
        end %function
        
        
        function updateButtonIcon(obj)
            
            % Update the button icon
            if obj.SelectionType == "file"
                obj.ButtonControl.Icon = "folder_file_24.png";
            else
                obj.ButtonControl.Icon = "folder_24.png";
            end
            
        end %function
        
        
        function updateControlType(obj)
            
            % Is history being shown? If so, update history and items
            if obj.ShowHistory
                % Using dropdown control
                
                if isempty(obj.DropdownControl.Parent)
                    obj.EditControl.Parent = [];
                    obj.DropdownControl.Parent = obj.Grid;
                    obj.DropdownControl.Layout.Column = 1;
                    obj.DropdownControl.Layout.Row = 1;
                end
            else
                % Using edit control
                
                if isempty(obj.EditControl.Parent)
                    obj.DropdownControl.Parent = [];
                    obj.EditControl.Parent = obj.Grid;
                    obj.EditControl.Layout.Column = 1;
                    obj.EditControl.Layout.Row = 1;
                end
            end %if obj.ShowHistory
            
        end %function
        
        
        function onButtonPushed(obj,~)
            % Triggered on button pushed
            
            % What folder should the prompt start at?
            if obj.ValueIsValidPath
                initialPath = obj.FullPath;
            elseif exist(obj.DefaultDirectory,"dir")
                initialPath = obj.DefaultDirectory;
            else
                initialPath = pwd;
            end
            
            % Prompt user for the path
            if obj.SelectionType == "file"
                [fileName,pathName] = uigetfile(initialPath,"Select a file");
            else
                pathName = uigetdir(initialPath,"Select a folder");
                fileName = "";
            end
            
            % Proceed if user didn't cancel
            if ~isequal(pathName,0)
                obj.setValueFromFullPath( fullfile(pathName,fileName) );
            end %if ~isequal(pathName,0)
            
        end %function
        
        
        function onTextChanged(obj,evt)
            % Triggered on text interaction
            
            % Prepare event data
            evtOut = wt.eventdata.PropertyChangedData('Value', evt.Value, obj.Value);
            
            % Store new result
            obj.Value = evt.Value;
            
            % Trigger event
            notify(obj,"ValueChanged",evtOut);
            
        end %function
        
        
        function addToHistory(obj,value)
            % Add new item to history and clean up
            
            % Add this to the top of the history
            histFiles = obj.History;
            histFiles = vertcat(value,histFiles);
            
            % Clean up the history
            histFiles = wt.utility.cleanPath(histFiles);
            histFiles = unique(histFiles,"stable");
            
            % Filter to valid paths
            if obj.SelectionType == "file"
                fcn = @(x)gt(exist(fullfile(obj.RootDirectory, x),"file"), 0);
            else
                fcn = @(x)eq(exist(fullfile(obj.RootDirectory, x),"dir"), 7);
            end
            isValidPath = arrayfun(fcn,histFiles);
            histFiles(~isValidPath) = [];
            
            % Limit history length
            histFiles(11:end) = [];
            
            % Store the result
            obj.History = histFiles;
            
        end %function
        
        
        function setValueFromFullPath(obj,fullPath)
            
            arguments
                obj (1,1)
                fullPath (1,1) string
            end %arguments
            
            fullPath = wt.utility.cleanPath(fullPath);
            
            if strlength(obj.RootDirectory) && strlength(fullPath)
                % Calculate the relative path for the value
                
                % Split the paths apart
                rootParts = strsplit(obj.RootDirectory,filesep);
                fullParts = strsplit(fullPath,filesep);
                
                % Find where the paths diverge
                idx = 1;
                smallestPath = min(numel(rootParts), numel(fullParts));
                while idx<=smallestPath && strcmpi(rootParts(idx),fullParts(idx))
                    idx = idx+1;
                end
                
                % Is the specified path outside of the root directory?
                numAbove = max(numel(rootParts) - idx + 1, 0);
                if numAbove>0
                    
                    obj.throwError("Path '%s' is not within the root directory '%s'.",...
                        fullPath, obj.RootDirectory);
                    
                else
                    
                    % In case full path is above the RootPath, add ".." paths
                    parentPaths = string(repmat(['..' filesep],1,numAbove));
                    
                    % Form the relative path
                    relPath = filesep + fullfile(parentPaths, fullParts{idx:end});
                    
                    % What if paths are still the same?
                    if isempty(relPath)
                        relPath = "." + filesep;
                    end
                    
                    % Prepare event data
                    evtOut = wt.eventdata.PropertyChangedData('Value',relPath, obj.Value);
                    
                    % Store new result
                    obj.Value = relPath;
                    
                    % Trigger event
                    notify(obj,"ValueChanged",evtOut);
                    
                end
                
            else
                    
                    % Prepare event data
                    evtOut = wt.eventdata.PropertyChangedData('Value',fullPath, obj.Value);
                    
                    % Store new result
                    obj.Value = fullPath;
                    
                    % Trigger event
                    notify(obj,"ValueChanged",evtOut);
                
            end %if
            
        end %function
        
    end % methods
    
    
    %% Accessors
    methods
        
        function set.Value(obj,value)
            value = wt.utility.cleanPath(value);
            obj.Value = value;
            obj.addToHistory(value)
        end
        
        function set.RootDirectory(obj,value)
            value = wt.utility.cleanPath(value);
            obj.RootDirectory = value;
            obj.addToHistory(value)
        end
        
        function set.SelectionType(obj,value)
            obj.SelectionType = value;
            obj.updateButtonIcon()
        end
        
        function set.ShowHistory(obj,value)
            obj.ShowHistory = value;
            obj.updateControlType()
        end
        
        function value = get.FullPath(obj)
            value = fullfile(obj.RootDirectory, obj.Value);
        end
        
        function value = get.ValueIsValidPath(obj)
            filePath = fullfile(obj.RootDirectory, obj.Value);
            value = ( obj.SelectionType == "file" && exist(filePath,"file") ) || ...
                ( obj.SelectionType == "folder" && exist(filePath,"dir") );
        end
        
    end % methods
    
    
end % classdef