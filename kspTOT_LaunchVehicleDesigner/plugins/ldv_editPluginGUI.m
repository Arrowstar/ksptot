function varargout = ldv_editPluginGUI(varargin)
    % LDV_EDITPLUGINGUI MATLAB code for ldv_editPluginGUI.fig
    %      LDV_EDITPLUGINGUI, by itself, creates a new LDV_EDITPLUGINGUI or raises the existing
    %      singleton*.
    %
    %      H = LDV_EDITPLUGINGUI returns the handle to a new LDV_EDITPLUGINGUI or the handle to
    %      the existing singleton*.
    %
    %      LDV_EDITPLUGINGUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in LDV_EDITPLUGINGUI.M with the given input arguments.
    %
    %      LDV_EDITPLUGINGUI('Property','Value',...) creates a new LDV_EDITPLUGINGUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before ldv_editPluginGUI_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to ldv_editPluginGUI_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help ldv_editPluginGUI
    
    % Last Modified by GUIDE v2.5 29-Jun-2020 20:55:51
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @ldv_editPluginGUI_OpeningFcn, ...
        'gui_OutputFcn',  @ldv_editPluginGUI_OutputFcn, ...
        'gui_LayoutFcn',  [] , ...
        'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end
    
    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT
    
    
    % --- Executes just before ldv_editPluginGUI is made visible.
function ldv_editPluginGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to ldv_editPluginGUI (see VARARGIN)
    
    % Choose default command line output for ldv_editPluginGUI
    handles.output = hObject;
    
    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    handles = populateGUI(lvdData, handles);
    
    setappdata(hObject,'lvdCodeExplorerFig',[]);
    
    % Update handles structure
    guidata(hObject, handles);
    
    % UIWAIT makes ldv_editPluginGUI wait for user response (see UIRESUME)
    uiwait(handles.ldv_editPluginGUI);
    
function handles = populateGUI(lvdData, handles)
    handles = setupCodeEditor(handles);
    
    pluginListboxStr = lvdData.plugins.getListboxStr();
    handles.pluginsListbox.String = pluginListboxStr;
    if(length(pluginListboxStr) >= 1)
        ind = handles.pluginsListbox.Value;
        plugin = lvdData.plugins.plugins(ind);
        
        enableDisableIndividualPluginElements(true, handles);
        setupIndividualPluginUiElements(lvdData, plugin, handles);
    else
        enableDisableIndividualPluginElements(false, handles);
        handles.pluginNameText.String = 'No Plugin Selected';
        handles.pluginDescText.String = '';
    end
    
    syntaxLblPos = handles.functionInputSigLbl.Position;
    
    codeType = com.mathworks.widgets.SyntaxTextLabel.M_STYLE;
    jCodeLabel = com.mathworks.widgets.SyntaxTextLabel('',codeType);
    [jFuncInputSynLbl,~] = javacomponent(jCodeLabel,syntaxLblPos,handles.functionInputSigLbl.Parent);
    handles.jCodeLabel = jCodeLabel;
    handles.jFuncInputSynLbl = jFuncInputSynLbl;
    
    listBoxStr = PluginFunctionInputSignatureEnum.getListBoxStr();
    handles.functionInputSigCombo.String = listBoxStr;
    functionInputSigCombo_Callback(handles.functionInputSigCombo, [], handles);
    
    quotedwords = cellfun(@(c) sprintf('"%s"', c), LvdPlugin.getDisallowedStrings(), 'UniformOutput',false);
    wordList = grammaticalList(quotedwords);
    handles.codeBadWordsLabel.TooltipString = sprintf('%s', wordList);
    
    handles.enablePluginsCheckbox.Value = double(lvdData.plugins.enablePlugins);
    enablePluginsCheckbox_Callback(handles.enablePluginsCheckbox, [], handles);
    
function setupIndividualPluginUiElements(lvdData, plugin, handles)
    handles.jCodePane.setText(plugin.pluginCode);
    
    handles.pluginNameText.String = plugin.pluginName;
    handles.pluginDescText.String = plugin.pluginDesc;
    
    handles.execBeforePropCheckbox.Value = plugin.execBeforePropTF;
    handles.execBeforeEventsCheckbox.Value = plugin.execBeforeEventsTF;
    handles.execAfterEventsCheckbox.Value = plugin.execAfterEventsTF;
    handles.execAfterPropCheckbox.Value = plugin.execAfterPropTF;
    handles.execAfterTimeStepsCheckbox.Value = plugin.execAfterTimeStepsTF;
    
    
function handles = setupCodeEditor(handles)
    jCodePane = com.mathworks.widgets.SyntaxTextPane();
    codeType = jCodePane.M_MIME_TYPE;  % ='text/m-MATLAB'
    jCodePane.setContentType(codeType)
    
    str = '';
    str = sprintf(strrep(str,'%','%%'));
    jCodePane.setText(str);
    
    jbh = handle(jCodePane,'CallbackProperties');
    set(jbh, 'KeyTypedCallback',@(src, evt) jCodePaneCallback(src,evt,handles));
    
    hCodeTbrPanel = handles.codeTbrPanel;
    codePanelPos = hCodeTbrPanel.Position;
    
    jCodePaneWidth = codePanelPos(3);
    jCodePaneHgt = codePanelPos(4);
    jCodePane.setSize(java.awt.Dimension(jCodePaneWidth-20, jCodePaneHgt));
    
    glyph = org.netbeans.editor.GlyphGutter(jCodePane.getEditorUI);
    glyph.setPreferredSize(java.awt.Dimension(20, jCodePaneHgt));
    
    jPanelLineNum = javax.swing.JPanel;
    jPanelLineNum.getLayout.setHgap(0);
    jPanelLineNum.getLayout.setVgap(0);
    jPanelLineNum.setSize(java.awt.Dimension(20, jCodePaneHgt));
    jPanelLineNum.setPreferredSize(java.awt.Dimension(20, jCodePaneHgt))
    jPanelLineNum.add(glyph);
    
    jCodeParentPanel = javax.swing.JPanel();
    jCodeParentPanel.setLayout(javax.swing.BoxLayout(jCodeParentPanel, javax.swing.BoxLayout.X_AXIS));
    jCodeParentPanel.add(jPanelLineNum);
    jCodeParentPanel.add(jCodePane);
    
    jScrollPane = com.mathworks.mwswing.MJScrollPane(jCodeParentPanel);
    [jhPanel,hContainer] = javacomponent(jScrollPane,[0,0,jCodePaneWidth+2,jCodePaneHgt+2],hCodeTbrPanel);
    
    handles.jCodePane = jCodePane;
    handles.jPanelLineNum = jPanelLineNum;
    handles.jCodeParentPanel = jCodeParentPanel;
    handles.jScrollPane = jhPanel;
    handles.hScrollPane = hContainer;
    
function enableDisableIndividualPluginElements(tf, handles)
    if(tf)
        handles.pluginsListbox.Enable = 'on';
        
        handles.pluginNameText.Enable = 'on';
        handles.pluginDescText.Enable = 'on';
        
        handles.execBeforePropCheckbox.Enable = 'on';
        handles.execBeforeEventsCheckbox.Enable = 'on';
        handles.execAfterEventsCheckbox.Enable = 'on';
        handles.execAfterPropCheckbox.Enable = 'on';
        handles.execAfterTimeStepsCheckbox.Enable = 'on';
        
        handles.functionInputSigCombo.Enable = 'on';
    else
        handles.pluginsListbox.Enable = 'off';
        
        handles.pluginNameText.Enable = 'off';
        handles.pluginDescText.Enable = 'off';
        
        handles.execBeforePropCheckbox.Enable = 'off';
        handles.execBeforeEventsCheckbox.Enable = 'off';
        handles.execAfterEventsCheckbox.Enable = 'off';
        handles.execAfterPropCheckbox.Enable = 'off';
        handles.execAfterTimeStepsCheckbox.Enable = 'off';
        
        handles.functionInputSigCombo.Enable = 'off';
    end
    
    handles.jCodePane.setEditable(tf);
    handles.jCodePane.setEnabled(tf);
    
    
function setDeletePluginEnable(lvdData, handles)
    numPlugins = lvdData.plugins.getNumPlugins();
    
    if(numPlugins > 0)
        handles.deletePluginButton.Enable = 'on';
    else
        handles.deletePluginButton.Enable = 'off';
    end
    
function selPlugin = getSelectedPlugin(handles)
    lvdData = getappdata(handles.ldv_editPluginGUI,'lvdData');
    selInd = handles.pluginsListbox.Value;
    
    if(selInd >= 1)
        selPlugin = lvdData.plugins.plugins(selInd);
    else
        selPlugin = LvdPlugin.empty(1,0);
    end
    
function jCodePaneCallback(jObject, jEventData, handles)
    selPlugin = getSelectedPlugin(handles);
    selPlugin.pluginCode = jObject.getText();
    
    % --- Outputs from this function are returned to the command line.
function varargout = ldv_editPluginGUI_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        varargout{1} = true;
        close(handles.ldv_editPluginGUI);
    end
    
    
    % --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
    % hObject    handle to saveAndCloseButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    %     errMsg = validateInputs(handles);
    
    errMsg = {};
    if(isempty(errMsg))
        uiresume(handles.ldv_editPluginGUI);
    else
        msgbox(errMsg,'Errors were found while editing plugins.','error');
    end
    
    % --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
    % hObject    handle to cancelButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    close(handles.ldv_editPluginGUI);
    
    % --- Executes on button press in showLvdDataStructButton.
function showLvdDataStructButton_Callback(hObject, eventdata, handles)
    % hObject    handle to showLvdDataStructButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ldv_editPluginGUI,'lvdData');
    
    contents = cellstr(get(handles.functionInputSigCombo,'String'));
    nameStr = contents{get(handles.functionInputSigCombo,'Value')};
    sigEnum = PluginFunctionInputSignatureEnum.getEnumForListboxStr(nameStr);
    
    inputNames = {'lvdData', 'stateLog', 'event', 'execLoc', 't', 'y', 'flag'};
    switch sigEnum
        case PluginFunctionInputSignatureEnum.BeforeProp
            stateLog = lvdData.stateLog;
            inputData = {lvdData, stateLog, [], LvdPluginExecLocEnum.BeforeProp, [],[],[]};
            
        case PluginFunctionInputSignatureEnum.BeforeEvents
            stateLog = lvdData.stateLog;
            event = lvdData.script.evts(1);
            inputData = {lvdData, stateLog, event, LvdPluginExecLocEnum.BeforeEvent, [],[],[]};
            
        case PluginFunctionInputSignatureEnum.AfterTimeStep
            event = lvdData.script.evts(1);
            [t,y] = lvdData.initialState.getFirstOrderIntegratorStateRepresentation();
            flag = 'init';
            inputData = {lvdData, [], event, LvdPluginExecLocEnum.AfterTimestep, t,y,flag};
            
        case PluginFunctionInputSignatureEnum.AfterEvents
            stateLog = lvdData.stateLog;
            event = lvdData.script.evts(1);
            inputData = {lvdData, stateLog, event, LvdPluginExecLocEnum.AfterEvent, [],[],[]};
            
        case PluginFunctionInputSignatureEnum.AfterProp
            stateLog = lvdData.stateLog;
            inputData = {lvdData, stateLog, [], LvdPluginExecLocEnum.AfterProp, [],[],[]};
            
        otherwise
            error('Unknown plugin function input signature: %s', sigEnum);
    end
    
    hFig = lvd_dataExplorerGUI(inputData, inputNames);
    setappdata(handles.ldv_editPluginGUI,'lvdCodeExplorerFig',hFig);
    
    % --- Executes on button press in execBeforePropCheckbox.
function execBeforePropCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to execBeforePropCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of execBeforePropCheckbox
    selPlugin = getSelectedPlugin(handles);
    selPlugin.execBeforePropTF = logical(get(hObject,'Value'));
    
    % --- Executes on button press in execBeforeEventsCheckbox.
function execBeforeEventsCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to execBeforeEventsCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of execBeforeEventsCheckbox
    selPlugin = getSelectedPlugin(handles);
    selPlugin.execBeforeEventsTF = logical(get(hObject,'Value'));
    
    % --- Executes on button press in execAfterEventsCheckbox.
function execAfterEventsCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to execAfterEventsCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of execAfterEventsCheckbox
    selPlugin = getSelectedPlugin(handles);
    selPlugin.execAfterEventsTF = logical(get(hObject,'Value'));
    
    % --- Executes on button press in execAfterPropCheckbox.
function execAfterPropCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to execAfterPropCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of execAfterPropCheckbox
    selPlugin = getSelectedPlugin(handles);
    selPlugin.execAfterPropTF = logical(get(hObject,'Value'));
    
    % --- Executes on button press in execAfterTimeStepsCheckbox.
function execAfterTimeStepsCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to execAfterTimeStepsCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of execAfterTimeStepsCheckbox
    selPlugin = getSelectedPlugin(handles);
    selPlugin.execAfterTimeStepsTF = logical(get(hObject,'Value'));
    
    
function pluginNameText_Callback(hObject, eventdata, handles)
    % hObject    handle to pluginNameText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of pluginNameText as text
    %        str2double(get(hObject,'String')) returns contents of pluginNameText as a double
    selPlugin = getSelectedPlugin(handles);
    selPlugin.pluginName = get(hObject,'String');
    
    lvdData = getappdata(handles.ldv_editPluginGUI,'lvdData');
    pluginListboxStr = lvdData.plugins.getListboxStr();
    handles.pluginsListbox.String = pluginListboxStr;
    
    % --- Executes during object creation, after setting all properties.
function pluginNameText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to pluginNameText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function pluginDescText_Callback(hObject, eventdata, handles)
    % hObject    handle to pluginDescText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of pluginDescText as text
    %        str2double(get(hObject,'String')) returns contents of pluginDescText as a double
    selPlugin = getSelectedPlugin(handles);
    selPlugin.pluginDesc = get(hObject,'String');
    
    % --- Executes during object creation, after setting all properties.
function pluginDescText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to pluginDescText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on selection change in pluginsListbox.
function pluginsListbox_Callback(hObject, eventdata, handles)
    % hObject    handle to pluginsListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns pluginsListbox contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from pluginsListbox
    lvdData = getappdata(handles.ldv_editPluginGUI,'lvdData');
    selPlugin = getSelectedPlugin(handles);
    
    enableDisableIndividualPluginElements(true, handles);
    setupIndividualPluginUiElements(lvdData, selPlugin, handles);
    setDeletePluginEnable(lvdData, handles);
    
    % --- Executes during object creation, after setting all properties.
function pluginsListbox_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to pluginsListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in addPluginButton.
function addPluginButton_Callback(hObject, eventdata, handles)
    % hObject    handle to addPluginButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ldv_editPluginGUI,'lvdData');
    newPlugin = LvdPlugin();
    lvdData.plugins.addPlugin(newPlugin);
    
    pluginListboxStr = lvdData.plugins.getListboxStr();
    handles.pluginsListbox.String = pluginListboxStr;
    
    handles.pluginsListbox.Value = lvdData.plugins.getNumPlugins();
    enableDisableIndividualPluginElements(true, handles);
    setupIndividualPluginUiElements(lvdData, newPlugin, handles);
    setDeletePluginEnable(lvdData, handles);
    
    % --- Executes on button press in deletePluginButton.
function deletePluginButton_Callback(hObject, eventdata, handles)
    % hObject    handle to deletePluginButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ldv_editPluginGUI,'lvdData');
    
    selPlugin = getSelectedPlugin(handles);
    lvdData.plugins.removePlugin(selPlugin);
    numPlugins = lvdData.plugins.getNumPlugins();
    
    pluginListboxStr = lvdData.plugins.getListboxStr();
    handles.pluginsListbox.String = pluginListboxStr;
    
    if(numPlugins > 0)
        enableDisableIndividualPluginElements(true, handles);
        
        if(handles.pluginsListbox.Value > numPlugins)
            handles.pluginsListbox.Value = numPlugins;
        end
        
        selPlugin = getSelectedPlugin(handles);
        setupIndividualPluginUiElements(lvdData, selPlugin, handles);
    else
        enableDisableIndividualPluginElements(false, handles);
        handles.jCodePane.setText('');
        handles.pluginNameText.String = 'No Plugin Selected';
        handles.pluginDescText.String = '';
    end
    
    setDeletePluginEnable(lvdData, handles);
    
    
    % --- Executes during object creation, after setting all properties.
function saveAndCloseButton_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to saveAndCloseButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    
    % --- Executes when user attempts to close ldv_editPluginGUI.
function ldv_editPluginGUI_CloseRequestFcn(hObject, eventdata, handles)
    % hObject    handle to ldv_editPluginGUI (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: delete(hObject) closes the figure
    lvdCodeExplorerFig = getappdata(hObject,'lvdCodeExplorerFig');
    
    if(not(isempty(lvdCodeExplorerFig)) && isvalid(lvdCodeExplorerFig) && ishandle(lvdCodeExplorerFig))
        delete(lvdCodeExplorerFig);
    end
    
    delete(hObject);
    
    
    % --- Executes on selection change in functionInputSigCombo.
function functionInputSigCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to functionInputSigCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns functionInputSigCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from functionInputSigCombo
    contents = cellstr(get(hObject,'String'));
    nameStr = contents{get(hObject,'Value')};
    
    enum = PluginFunctionInputSignatureEnum.getEnumForListboxStr(nameStr);
    handles.jCodeLabel.setText(enum.functionSig);
    
    
    % --- Executes during object creation, after setting all properties.
function functionInputSigCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to functionInputSigCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in movePluginDownButton.
function movePluginDownButton_Callback(hObject, eventdata, handles)
    % hObject    handle to movePluginDownButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ldv_editPluginGUI,'lvdData');
    
    pluginNum = get(handles.pluginsListbox,'Value');
    lvdData.plugins.movePluginAtIndexDown(pluginNum);
    
    if(pluginNum < lvdData.plugins.getNumPlugins())
        set(handles.pluginsListbox,'Value',pluginNum+1);
    end
    
    pluginListboxStr = lvdData.plugins.getListboxStr();
    handles.pluginsListbox.String = pluginListboxStr;
    
    % --- Executes on button press in movePluginUpButton.
function movePluginUpButton_Callback(hObject, eventdata, handles)
    % hObject    handle to movePluginUpButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.ldv_editPluginGUI,'lvdData');
    
    pluginNum = get(handles.pluginsListbox,'Value');
    lvdData.plugins.movePluginAtIndexUp(pluginNum);
    
    if(pluginNum > 1)
        set(handles.pluginsListbox,'Value',pluginNum-1);
    end
    
    pluginListboxStr = lvdData.plugins.getListboxStr();
    handles.pluginsListbox.String = pluginListboxStr;
    
    
    % --- Executes on button press in enablePluginsCheckbox.
function enablePluginsCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to enablePluginsCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of enablePluginsCheckbox
    lvdData = getappdata(handles.ldv_editPluginGUI,'lvdData');
    
    value = logical(get(hObject,'Value'));
    lvdData.plugins.enablePlugins = value;
    
    if(value)
        hObject.BackgroundColor = [1 0 0];
        hObject.TooltipString = 'Plugins are enabled and will execute.  Caution: plugins are capable of corupting LVD data files.';
    else
        hObject.BackgroundColor = [240 240 240]/255;
        hObject.TooltipString = 'Plugins are disabled and will not execute.';
    end
