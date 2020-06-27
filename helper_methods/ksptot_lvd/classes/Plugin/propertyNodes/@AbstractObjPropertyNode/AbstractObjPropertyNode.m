classdef (Abstract) AbstractObjPropertyNode < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    %ObjPropertyNode Summary of this class goes here
    %   Detailed explanation goes here

    methods
        function createBreadcrumbs(obj, grid, jBreadCrumbBar)
            hBreadcrumbBar = handle(jBreadCrumbBar, 'CallbackProperties');
            
            [treeNodes, propNodeObjs] = obj.getAllTreeNodesHereUp();
            treeModel = jBreadCrumbBar.getModel();
            treeModel.setRoot(treeNodes(1))
            jBreadCrumbBar.setModel(treeModel);
      
            jTreePath = javax.swing.tree.TreePath(treeNodes);
            jBreadCrumbBar.setSelectedPath(jTreePath);
            jBreadCrumbBar.setDropDownAllowed(false)

            propChangeCallback = @(src,evt) AbstractObjPropertyNode.breadcrumbButtonPushCallback(src,evt,propNodeObjs,grid,jBreadCrumbBar);
            hBreadcrumbBar.PropertyChangeCallback = propChangeCallback;
        end
        
        function [treeNodes, propNodeObjs] = getAllTreeNodesHereUp(obj)          
            node = javax.swing.tree.DefaultMutableTreeNode(obj.nodeName);
            
            if(not(isempty(obj.nodeParent)))
                [parentNodes, parentPropNodeObjs] = obj.nodeParent.getAllTreeNodesHereUp();
                
                if(not(isempty(parentNodes)))
                    immediateParentNode = parentNodes(end);
                    immediateParentNode.add(node);
                end
                
                treeNodes = [parentNodes, node];
                propNodeObjs = [parentPropNodeObjs, obj];
            else
                treeNodes = node;
                propNodeObjs = obj;
            end
        end
    end
    
    methods(Static, Access=protected)
        function [type, value] = getTypeOfObject(item)
            type = 'string';
            value = item;
            
            if isa(item,'java.awt.Color')
                type = 'color';
            elseif isa(item,'java.awt.Font')
                type = 'font';
            elseif isnumeric(item)
                if(numel(item)==1)
                    if isa(item,'uint') || isa(item,'uint8') || isa(item,'uint16') || isa(item,'uint32') || isa(item,'uint64')
                        type = 'unsigned';
                    elseif isinteger(item)
                        type = 'signed';
                    else
                        type = 'float';
                    end
                else
                    value = regexprep(sprintf('%dx',size(value)),{'^(.)','x$'},{'<$1','> numeric array'});
                end
            elseif islogical(item)
                if numel(item)==1
                    % a single value
                    type = 'boolean';
                else % an array of boolean values
                    value = regexprep(sprintf('%dx',size(item)),{'^(.)','x$'},{'<$1','> logical array'});
                end
            elseif ischar(item)
                if exist(item,'dir')
                    type = 'folder';
                    value = java.io.File(value);
                elseif exist(item,'file')
                    type = 'file';
                    value = java.io.File(value);
                elseif length(item) >= 1 && item(1)=='*'
                    type = 'password';
                elseif sum(item=='.')==3
                    type = 'IPAddress';
                else
                    type = 'text';
                    if length(value) > 50
                        value(51:end) = '';
                        value = [value '...'];
                    end
                end
            elseif iscell(item)
                value = regexprep(sprintf('%dx',size(item)),{'^(.)','x$'},{'<$1','> cell array'});
            elseif isa(item,'java.util.Date')
                type = 'date';
            elseif isa(item,'java.io.File')
                if item.isFile
                    type = 'file';
                else
                    type = 'folder';
                end
            elseif isobject(item)
                if(numel(item)==1)
                    value = class(item);
                else
                    value = sprintf(regexprep(sprintf('%dx',size(item)),{'^(.)','x$'},{'<$1','> %s array'}), class(item));
                end
            elseif ~isstruct(item)
                value = strtrim(regexprep(evalc('disp(value)'),' +',' '));
            end
        end
        
        function prop = createNewPropertyNode(dataStruct, propName, label, dataType, description, propUpdatedCallback, category)
            % Auto-generate the label from the property name, if the label was not specified
            if isempty(label)
                label = getFieldLabel(propName);
            end
            % Create a new property with the chosen label
            prop = javaObjectEDT(com.jidesoft.grid.DefaultProperty);  % UNDOCUMENTED internal MATLAB component
            prop.setName(label);
            prop.setExpanded(true);
            prop.setCategory(category);
            % Set the property to the current patient's data value
            try
                thisProp = dataStruct.(propName);
            catch
                thisProp = dataStruct;
            end
            origProp = thisProp;
            prop.setValue(thisProp);
            
            % Set property editor, renderer and alignment
            if iscell(dataType)
                % treat this as drop-down values
                % Set the defaults
                firstIndex = 1;
                cbIsEditable = false;
                % Extract out the number of items in the user list
                nItems = length(dataType);
                % Check for any empty items
                emptyItem = find(cellfun('isempty', dataType) == 1);
                % If only 1 empty item found check editable rules
                if length(emptyItem) == 1
                    % If at the end - then remove it and set editable flag
                    if emptyItem == nItems
                        cbIsEditable = true;
                        dataType(end) = []; % remove from the drop-down list
                    elseif emptyItem == nItems - 1
                        cbIsEditable = true;
                        dataType(end-1) = []; % remove from the drop-down list
                    end
                end
                % Try to find the initial (default) drop-down index
                if ~isempty(dataType)
                    if iscell(dataType{end})
                        if isnumeric(dataType{end}{1})
                            firstIndex = dataType{end}{1};
                            dataType(end) = []; % remove the [] from drop-down list
                        end
                    else
                        try
                            if ismember(dataType{end}, dataType(1:end-1))
                                firstIndex = find(strcmp(dataType(1:end-1),dataType{end}));
                                dataType(end) = [];
                            end
                        catch
                            % ignore - possibly mixed data
                        end
                    end
                    % Build the editor
                    editor = com.jidesoft.grid.ListComboBoxCellEditor(dataType);
                    try editor.getComboBox.setEditable(cbIsEditable); catch, end % #ok<NOCOM>
                    %set(editor,'EditingStoppedCallback',{@propUpdatedCallback,tagName,propName});
                    alignProp(prop, editor);
                    try prop.setValue(origProp{firstIndex}); catch, end
                end
                
                isEditable = false;
            else
                switch lower(dataType)
                    case 'signed',    %alignProp(prop, com.jidesoft.grid.IntegerCellEditor,    'int32');
                        model = javax.swing.SpinnerNumberModel(prop.getValue, -intmax, intmax, 1);
                        editor = com.jidesoft.grid.SpinnerCellEditor(model);
                        alignProp(prop, editor, 'int32');
                        isEditable = true;
                    case 'unsigned',  %alignProp(prop, com.jidesoft.grid.IntegerCellEditor,    'uint32');
                        val = max(0, min(prop.getValue, intmax));
                        model = javax.swing.SpinnerNumberModel(val, 0, intmax, 1);
                        editor = com.jidesoft.grid.SpinnerCellEditor(model);
                        alignProp(prop, editor, 'uint32');
                        isEditable = true;
                    case 'float',     %alignProp(prop, com.jidesoft.grid.CalculatorCellEditor, 'double');  % DoubleCellEditor
                        alignProp(prop, com.jidesoft.grid.DoubleCellEditor, 'double');
                        isEditable = true;
                    case 'boolean',   alignProp(prop, com.jidesoft.grid.BooleanCheckBoxCellEditor, 'logical'); isEditable = true;
                    case 'folder',    alignProp(prop, com.jidesoft.grid.FolderCellEditor); isEditable = true;
                    case 'file',      alignProp(prop, com.jidesoft.grid.FileCellEditor); isEditable = true;
                    case 'ipaddress', alignProp(prop, com.jidesoft.grid.IPAddressCellEditor); isEditable = true;
                    case 'password',  alignProp(prop, com.jidesoft.grid.PasswordCellEditor); isEditable = true;
                    case 'color',     alignProp(prop, com.jidesoft.grid.ColorCellEditor); isEditable = true;
                    case 'font',      alignProp(prop, com.jidesoft.grid.FontCellEditor); isEditable = true;
                    case 'text',      alignProp(prop); isEditable = true;
                    case 'time',      alignProp(prop); isEditable = true; % maybe use com.jidesoft.grid.FormattedTextFieldCellEditor ?
                    case 'date',      dateModel = com.jidesoft.combobox.DefaultDateModel;
                        dateFormat = java.text.SimpleDateFormat('dd/MM/yyyy');
                        dateModel.setDateFormat(dateFormat);
                        editor = com.jidesoft.grid.DateCellEditor(dateModel, 1);
                        alignProp(prop, editor, 'java.util.Date');
                        try
                            prop.setValue(dateFormat.parse(prop.getValue));  % convert string => Date
                        catch
                            % ignore
                        end
                        
                        isEditable = true;
                    otherwise,       
                        alignProp(prop);  % treat as a simple text field
                        isEditable = false;
                end
            end  % for all possible data types
            
%             prop.setEditable(isEditable);
            prop.setEditable(false);
            
            prop.setDescription(description);
            if ~isempty(description)
                renderer = com.jidesoft.grid.CellRendererManager.getRenderer(prop.getType, prop.getEditorContext);
                renderer.setToolTipText(description);
            end
            % Set the property's editability state
            if prop.isEditable & not(isempty(propUpdatedCallback))
                % Set the property's label to be black
                prop.setDisplayName(['<html><font color="black">' label]);
                % Add callbacks for property-change events
                hprop = handle(prop, 'CallbackProperties');
                set(hprop,'PropertyChangeCallback',{propUpdatedCallback,propName});
            else
                % Set the property's label to be gray
                prop.setDisplayName(['<html><font color="gray">' label]);
            end
            setPropName(prop,propName);
        end  % newProperty
        
        function getGridMouseDoubleClickCallback(src, evt, nodeParent, grid, jBreadCrumbBar)
            if(evt.getButton() == 1 && evt.getClickCount() >= 2)
                selectedPropertyName = char(src.getSelectedProperty().getName());
                
                nodeParentObj = nodeParent.nodeObj;
                
                nodeObj = [];
                if(numel(nodeParentObj) == 1 && isprop(nodeParentObj,selectedPropertyName))
                    nodeObj = nodeParentObj.(selectedPropertyName);
                elseif(numel(nodeParentObj) > 1)
                    out = regexp(selectedPropertyName,'[\w+]\((\d+)\)','tokens');
                    if(numel(out) == 1 && numel(out{1}) == 1)
                        index = str2double(out{1}{1});
                        
                        nodeObj = nodeParentObj(index);
                    end
                end
                
                if(isobject(nodeObj))
                    if(numel(nodeObj) == 1)
                        newNode = ScalarObjPropertyNode(nodeObj, selectedPropertyName, nodeParent);
                        newNode.createPropertyTableModel(grid,jBreadCrumbBar);
                    elseif(numel(nodeObj) > 1)
                        newNode = ArrayObjPropertyNode(nodeObj, selectedPropertyName, nodeParent);
                        newNode.createPropertyTableModel(grid,jBreadCrumbBar);
                    end
                end
            end
        end
               
        function breadcrumbButtonPushCallback(src,evt,propNodeObjs,grid,jBreadCrumbBar)
            if(strcmpi(evt.getPropertyName(),'selectedPath'))
                if(evt.getNewValue().getPathCount() < evt.getOldValue().getPathCount())
                    newNode = propNodeObjs(evt.getNewValue().getPathCount());                    
                    newNode.createPropertyTableModel(grid,jBreadCrumbBar);
                end
            end
        end
    end
end

function alignProp(prop, editor, propTypeStr, direction)
    persistent propTypeCache
    if isempty(propTypeCache),  propTypeCache = java.util.Hashtable;  end
    if nargin < 2 || isempty(editor),      editor = com.jidesoft.grid.StringCellEditor;  end  %(javaclass('char',1));
    if nargin < 3 || isempty(propTypeStr), propTypeStr = 'cellstr';  end  % => javaclass('char',1)
    if nargin < 4 || isempty(direction),   direction = javax.swing.SwingConstants.RIGHT;  end
    % Set this property's data type
    propType = propTypeCache.get(propTypeStr);
    if isempty(propType)
        propType = javaclass(propTypeStr);
        propTypeCache.put(propTypeStr,propType);
    end
    prop.setType(propType);
    % Prepare a specific context object for this property
    if strcmpi(propTypeStr,'logical')
        %TODO - FIXME
        context = editor.CONTEXT;
        prop.setEditorContext(context);
        %renderer = CheckBoxRenderer;
        %renderer.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        %com.jidesoft.grid.CellRendererManager.registerRenderer(propType, renderer, context);
    else
        context = com.jidesoft.grid.EditorContext(prop.getName);
        prop.setEditorContext(context);
        % Register a unique cell renderer so that each property can be modified seperately
        %renderer = com.jidesoft.grid.CellRendererManager.getRenderer(propType, prop.getEditorContext);
        renderer = com.jidesoft.grid.ContextSensitiveCellRenderer;
        com.jidesoft.grid.CellRendererManager.registerRenderer(propType, renderer, context);
        renderer.setBackground(java.awt.Color.white);
        renderer.setHorizontalAlignment(direction);
        %renderer.setHorizontalTextPosition(direction);
    end
    % Update the property's cell editor
    try editor.setHorizontalAlignment(direction); catch, end
    try editor.getTextField.setHorizontalAlignment(direction); catch, end
    try editor.getComboBox.setHorizontalAlignment(direction); catch, end
    % Set limits on unsigned int values
    try
        if strcmpi(propTypeStr,'uint32')
            %pause(0.01);
            editor.setMinInclusive(java.lang.Integer(0));
            editor.setMinExclusive(java.lang.Integer(-1));
            editor.setMaxExclusive(java.lang.Integer(intmax));
            editor.setMaxInclusive(java.lang.Integer(intmax));
        end
    catch
        % ignore
    end
    com.jidesoft.grid.CellEditorManager.registerEditor(propType, editor, context);
end  % alignProp

function jclass = javaclass(mtype, ndims)
    % Input arguments:
    % mtype:
    %    the MatLab name of the type for which to return the java.lang.Class
    %    instance
    % ndims:
    %    the number of dimensions of the MatLab data type
    %
    % See also: class
    
    % Copyright 2009-2010 Levente Hunyadi
    % Downloaded from: http://www.UndocumentedMatlab.com/files/javaclass.m
    
    validateattributes(mtype, {'char'}, {'nonempty','row'});
    if nargin < 2
        ndims = 0;
    else
        validateattributes(ndims, {'numeric'}, {'nonnegative','integer','scalar'});
    end
    
    if ndims == 1 && strcmp(mtype, 'char');  % a character vector converts into a string
        jclassname = 'java.lang.String';
    elseif ndims > 0
        jclassname = javaarrayclass(mtype, ndims);
    else
        % The static property .class applied to a Java type returns a string in
        % MatLab rather than an instance of java.lang.Class. For this reason,
        % use a string and java.lang.Class.forName to instantiate a
        % java.lang.Class object; the syntax java.lang.Boolean.class will not do so
        switch mtype
            case 'logical'  % logical vaule (true or false)
                jclassname = 'java.lang.Boolean';
            case 'char'  % a singe character
                jclassname = 'java.lang.Character';
            case {'int8','uint8'}  % 8-bit signed and unsigned integer
                jclassname = 'java.lang.Byte';
            case {'int16','uint16'}  % 16-bit signed and unsigned integer
                jclassname = 'java.lang.Short';
            case {'int32','uint32'}  % 32-bit signed and unsigned integer
                jclassname = 'java.lang.Integer';
            case {'int64','uint64'}  % 64-bit signed and unsigned integer
                jclassname = 'java.lang.Long';
            case 'single'  % single-precision floating-point number
                jclassname = 'java.lang.Float';
            case 'double'  % double-precision floating-point number
                jclassname = 'java.lang.Double';
            case 'cellstr'  % a single cell or a character array
                jclassname = 'java.lang.String';
            otherwise
                jclassname = mtype;
                %error('java:javaclass:InvalidArgumentValue', ...
                %    'MatLab type "%s" is not recognized or supported in Java.', mtype);
        end
    end
    % Note: When querying a java.lang.Class object by name with the method
    % jclass = java.lang.Class.forName(jclassname);
    % MatLab generates an error. For the Class.forName method to work, MatLab
    % requires class loader to be specified explicitly.
    jclass = java.lang.Class.forName(jclassname, true, java.lang.Thread.currentThread().getContextClassLoader());
end  % javaclass
    
% Return the type qualifier for a multidimensional Java array
function jclassname = javaarrayclass(mtype, ndims)
    switch mtype
        case 'logical'  % logical array of true and false values
            jclassid = 'Z';
        case 'char'  % character array
            jclassid = 'C';
        case {'int8','uint8'}  % 8-bit signed and unsigned integer array
            jclassid = 'B';
        case {'int16','uint16'}  % 16-bit signed and unsigned integer array
            jclassid = 'S';
        case {'int32','uint32'}  % 32-bit signed and unsigned integer array
            jclassid = 'I';
        case {'int64','uint64'}  % 64-bit signed and unsigned integer array
            jclassid = 'J';
        case 'single'  % single-precision floating-point number array
            jclassid = 'F';
        case 'double'  % double-precision floating-point number array
            jclassid = 'D';
        case 'cellstr'  % cell array of strings
            jclassid = 'Ljava.lang.String;';
        otherwise
            jclassid = ['L' mtype ';'];
            %error('java:javaclass:InvalidArgumentValue', ...
            %    'MatLab type "%s" is not recognized or supported in Java.', mtype);
    end
    jclassname = [repmat('[',1,ndims), jclassid];
end  % javaarrayclass

function setPropName(hProp,propName)
    try
        set(hProp,'UserData',propName)
    catch
        %setappdata(hProp,'UserData',propName)
        hp = schema.prop(handle(hProp),'UserData','mxArray'); %#ok<NASGU>
        set(handle(hProp),'UserData',propName)
    end
end  % setPropName
% Get property name from the Java property reference
function propName = getPropName(hProp)
    try
        propName = get(hProp,'UserData');
    catch
        %propName = char(getappdata(hProp,'UserData'));
        propName = get(handle(hProp),'UserData');
    end
end  % getPropName
