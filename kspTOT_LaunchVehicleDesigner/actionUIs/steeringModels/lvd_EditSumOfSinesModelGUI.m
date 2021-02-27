function varargout = lvd_EditSumOfSinesModelGUI(varargin)
    % LVD_EDITSUMOFSINESMODELGUI MATLAB code for lvd_EditSumOfSinesModelGUI.fig
    %      LVD_EDITSUMOFSINESMODELGUI, by itself, creates a new LVD_EDITSUMOFSINESMODELGUI or raises the existing
    %      singleton*.
    %
    %      H = LVD_EDITSUMOFSINESMODELGUI returns the handle to a new LVD_EDITSUMOFSINESMODELGUI or the handle to
    %      the existing singleton*.
    %
    %      LVD_EDITSUMOFSINESMODELGUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in LVD_EDITSUMOFSINESMODELGUI.M with the given input arguments.
    %
    %      LVD_EDITSUMOFSINESMODELGUI('Property','Value',...) creates a new LVD_EDITSUMOFSINESMODELGUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before lvd_EditSumOfSinesModelGUI_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to lvd_EditSumOfSinesModelGUI_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help lvd_EditSumOfSinesModelGUI
    
    % Last Modified by GUIDE v2.5 22-Feb-2021 08:38:23
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @lvd_EditSumOfSinesModelGUI_OpeningFcn, ...
        'gui_OutputFcn',  @lvd_EditSumOfSinesModelGUI_OutputFcn, ...
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
    
    
    % --- Executes just before lvd_EditSumOfSinesModelGUI is made visible.
function lvd_EditSumOfSinesModelGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditSumOfSinesModelGUI (see VARARGIN)
    
    % Choose default command line output for lvd_EditSumOfSinesModelGUI
    handles.output = hObject;
    
    sumOfSines = varargin{1};
    setappdata(hObject,'sumOfSines',sumOfSines);
    
    populateGUI(handles, sumOfSines);
    
    % Update handles structure
    guidata(hObject, handles);
    
    % UIWAIT makes lvd_EditSumOfSinesModelGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditSumOfSinesModelGUI);
    
function populateGUI(handles, sumOfSines)
    handles.constText.String = fullAccNum2Str(rad2deg(sumOfSines.const));
    handles.constOptCheckbox.Value = double(sumOfSines.varConst);
    handles.constLbText.String = fullAccNum2Str(rad2deg(sumOfSines.constLb));
    handles.constUbText.String = fullAccNum2Str(rad2deg(sumOfSines.constUb));
    
    constOptCheckbox_Callback(handles.constOptCheckbox, [], handles);
    
    sineListboxStr = sumOfSines.getListboxStr();
    handles.sineListbox.String = sineListboxStr;
    if(~isempty(sineListboxStr))
        handles.sineListbox.Value = 1;
    end
    
    populateSineDefinition(handles, sumOfSines);
    
function populateSineDefinition(handles, sumOfSines)
    sineModel = getSelectedSineModel(handles, sumOfSines);
    
    if(not(isempty(sineModel)))
        setSineModelWidgetsEnable(handles, 'on');
        
        handles.ampText.String = fullAccNum2Str(rad2deg(sineModel.amp));
        handles.ampOptCheckbox.Value = double(sineModel.varAmp);
        handles.ampLbText.String = fullAccNum2Str(rad2deg(sineModel.ampLb));
        handles.ampUbText.String = fullAccNum2Str(rad2deg(sineModel.ampUb));
        ampOptCheckbox_Callback(handles.ampOptCheckbox, [], handles);
        
        handles.periodText.String = fullAccNum2Str(sineModel.period);
        handles.periodOptCheckbox.Value = double(sineModel.varPeriod);
        handles.periodLbText.String = fullAccNum2Str(sineModel.periodLb);
        handles.periodUbText.String = fullAccNum2Str(sineModel.periodUb);
        periodOptCheckbox_Callback(handles.periodOptCheckbox, [], handles);
        
        handles.phaseText.String = fullAccNum2Str(sineModel.phase);
        handles.phaseOptCheckbox.Value = double(sineModel.varPhase);
        handles.phaseLbText.String = fullAccNum2Str(sineModel.phaseLb);
        handles.phaseUbText.String = fullAccNum2Str(sineModel.phaseUb);
        phaseOptCheckbox_Callback(handles.phaseOptCheckbox, [], handles);
        
    else
        setSineModelWidgetsEnable(handles, 'off');
    end
    
function setSineModelWidgetsEnable(handles, enableStr)
    handles.ampText.Enable = enableStr;
    handles.ampOptCheckbox.Enable = enableStr;
    handles.ampLbText.Enable = enableStr;
    handles.ampUbText.Enable = enableStr;
    
    handles.periodText.Enable = enableStr;
    handles.periodOptCheckbox.Enable = enableStr;
    handles.periodLbText.Enable = enableStr;
    handles.periodUbText.Enable = enableStr;
    
    handles.phaseText.Enable = enableStr;
    handles.phaseOptCheckbox.Enable = enableStr;
    handles.phaseLbText.Enable = enableStr;
    handles.phaseUbText.Enable = enableStr;
    
    
function sineModel = getSelectedSineModel(handles, sumOfSines)
    numSines = sumOfSines.getNumSines();
    
    if(numSines > 0)
        selSineInd = handles.sineListbox.Value;
        sineModel = sumOfSines.getSineAtInd(selSineInd);
    else
        sineModel = SineModel.empty(1,0);
    end
    
    
    % --- Outputs from this function are returned to the command line.
function varargout = lvd_EditSumOfSinesModelGUI_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        varargout{1} = true;
        close(handles.lvd_EditSumOfSinesModelGUI);
    end
    
    
    % --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
    % hObject    handle to saveAndCloseButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    errMsg = {};
    if(isempty(errMsg))
        uiresume(handles.lvd_EditSumOfSinesModelGUI);
    else
        msgbox(errMsg,'Errors were found while editing plugins.','error');
    end
    
    % --- Executes on selection change in sineListbox.
function sineListbox_Callback(hObject, eventdata, handles)
    % hObject    handle to sineListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns sineListbox contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from sineListbox
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    populateSineDefinition(handles, sumOfSines);
    
    
    % --- Executes during object creation, after setting all properties.
function sineListbox_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to sineListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function constText_Callback(hObject, eventdata, handles)
    % hObject    handle to constText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of constText as text
    %        str2double(get(hObject,'String')) returns contents of constText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Constant Offset';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sumOfSines.const = deg2rad(value);
    else
        hObject.String = fullAccNum2Str(sumOfSines.const);
        
        msgbox(errMsg,'Invalid Sine Constant Offset','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function constText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to constText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in constOptCheckbox.
function constOptCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to constOptCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of constOptCheckbox
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sumOfSines.varConst = logical(hObject.Value);
    
    if(hObject.Value)
        handles.constLbText.Enable = 'on';
        handles.constUbText.Enable = 'on';
    else
        handles.constLbText.Enable = 'off';
        handles.constUbText.Enable = 'off';
    end
    
    
function constLbText_Callback(hObject, eventdata, handles)
    % hObject    handle to constLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of constLbText as text
    %        str2double(get(hObject,'String')) returns contents of constLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Constant Offset Lower Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sumOfSines.constLb = deg2rad(value);
    else
        hObject.String = fullAccNum2Str(sumOfSines.constLb);
        
        msgbox(errMsg,'Invalid Sine Constant Offset Lower Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function constLbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to constLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function constUbText_Callback(hObject, eventdata, handles)
    % hObject    handle to constUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of constUbText as text
    %        str2double(get(hObject,'String')) returns contents of constUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Constant Offset Upper Bound';
    lb = sumOfSines.constLb;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sumOfSines.constUb = deg2rad(value);
    else
        hObject.String = fullAccNum2Str(sumOfSines.constUb);
        
        msgbox(errMsg,'Invalid Sine Constant Offset Upper Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function constUbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to constUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function ampText_Callback(hObject, eventdata, handles)
    % hObject    handle to ampText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of ampText as text
    %        str2double(get(hObject,'String')) returns contents of ampText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sineModel = getSelectedSineModel(handles, sumOfSines);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Amplitude';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sineModel.amp = deg2rad(value);
        
        handles.sineListbox.String = sumOfSines.getListboxStr();
    else
        hObject.String = fullAccNum2Str(sineModel.amp);
        
        msgbox(errMsg,'Invalid Sine Amplitude','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function ampText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to ampText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in ampOptCheckbox.
function ampOptCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to ampOptCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of ampOptCheckbox
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sineModel = getSelectedSineModel(handles, sumOfSines);
    sineModel.varAmp = logical(hObject.Value);
    
    if(hObject.Value)
        handles.ampLbText.Enable = 'on';
        handles.ampUbText.Enable = 'on';
    else
        handles.ampLbText.Enable = 'off';
        handles.ampUbText.Enable = 'off';
    end
    
    
function ampLbText_Callback(hObject, eventdata, handles)
    % hObject    handle to ampLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of ampLbText as text
    %        str2double(get(hObject,'String')) returns contents of ampLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sineModel = getSelectedSineModel(handles, sumOfSines);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Amplitude Lower Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sineModel.ampLb = deg2rad(value);
    else
        hObject.String = fullAccNum2Str(sineModel.ampLb);
        
        msgbox(errMsg,'Invalid Sine Amplitude Lower Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function ampLbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to ampLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function ampUbText_Callback(hObject, eventdata, handles)
    % hObject    handle to ampUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of ampUbText as text
    %        str2double(get(hObject,'String')) returns contents of ampUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sineModel = getSelectedSineModel(handles, sumOfSines);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Amplitude Upper Bound';
    lb = sineModel.ampLb;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sineModel.ampUb = deg2rad(value);
    else
        hObject.String = fullAccNum2Str(sineModel.ampUb);
        
        msgbox(errMsg,'Invalid Sine Amplitude Upper Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function ampUbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to ampUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function periodText_Callback(hObject, eventdata, handles)
    % hObject    handle to periodText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of periodText as text
    %        str2double(get(hObject,'String')) returns contents of periodText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sineModel = getSelectedSineModel(handles, sumOfSines);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Period';
    lb = 1E-10;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sineModel.period = value;
        
        handles.sineListbox.String = sumOfSines.getListboxStr();
    else
        hObject.String = fullAccNum2Str(sineModel.period);
        
        msgbox(errMsg,'Invalid Sine Period','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function periodText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to periodText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in periodOptCheckbox.
function periodOptCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to periodOptCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of periodOptCheckbox
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sineModel = getSelectedSineModel(handles, sumOfSines);
    sineModel.varPeriod = logical(hObject.Value);
    
    if(hObject.Value)
        handles.periodLbText.Enable = 'on';
        handles.periodUbText.Enable = 'on';
    else
        handles.periodLbText.Enable = 'off';
        handles.periodUbText.Enable = 'off';
    end
    
    
function periodLbText_Callback(hObject, eventdata, handles)
    % hObject    handle to periodLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of periodLbText as text
    %        str2double(get(hObject,'String')) returns contents of periodLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sineModel = getSelectedSineModel(handles, sumOfSines);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Period Lower Bound';
    lb = 1E-10;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sineModel.periodLb = value;
    else
        hObject.String = fullAccNum2Str(sineModel.periodLb);
        
        msgbox(errMsg,'Invalid Sine Period Lower Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function periodLbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to periodLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function periodUbText_Callback(hObject, eventdata, handles)
    % hObject    handle to periodUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of periodUbText as text
    %        str2double(get(hObject,'String')) returns contents of periodUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sineModel = getSelectedSineModel(handles, sumOfSines);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Period Upper Bound';
    lb = sineModel.periodLb;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sineModel.periodUb = value;
    else
        hObject.String = fullAccNum2Str(sineModel.periodUb);
        
        msgbox(errMsg,'Invalid Sine Period Upper Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function periodUbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to periodUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function phaseText_Callback(hObject, eventdata, handles)
    % hObject    handle to phaseText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of phaseText as text
    %        str2double(get(hObject,'String')) returns contents of phaseText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sineModel = getSelectedSineModel(handles, sumOfSines);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Phase Shift';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sineModel.phase = value;
        
        handles.sineListbox.String = sumOfSines.getListboxStr();
    else
        hObject.String = fullAccNum2Str(sineModel.phase);
        
        msgbox(errMsg,'Invalid Sine Phase Shift','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function phaseText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to phaseText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in phaseOptCheckbox.
function phaseOptCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to phaseOptCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of phaseOptCheckbox
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sineModel = getSelectedSineModel(handles, sumOfSines);
    sineModel.varPhase = logical(hObject.Value);
    
    if(hObject.Value)
        handles.phaseLbText.Enable = 'on';
        handles.phaseUbText.Enable = 'on';
    else
        handles.phaseLbText.Enable = 'off';
        handles.phaseUbText.Enable = 'off';
    end
    
    
function phaseLbText_Callback(hObject, eventdata, handles)
    % hObject    handle to phaseLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of phaseLbText as text
    %        str2double(get(hObject,'String')) returns contents of phaseLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sineModel = getSelectedSineModel(handles, sumOfSines);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Phase Shift Lower Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sineModel.phaseLb = value;
    else
        hObject.String = fullAccNum2Str(sineModel.phaseLb);
        
        msgbox(errMsg,'Invalid Sine Phase Shift Lower Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function phaseLbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to phaseLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function phaseUbText_Callback(hObject, eventdata, handles)
    % hObject    handle to phaseUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of phaseUbText as text
    %        str2double(get(hObject,'String')) returns contents of phaseUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sineModel = getSelectedSineModel(handles, sumOfSines);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Phase Shift Upper Bound';
    lb = sineModel.phaseLb;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sineModel.phaseUb = value;
    else
        hObject.String = fullAccNum2Str(sineModel.phaseUb);
        
        msgbox(errMsg,'Invalid Sine Phase Shift Upper Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function phaseUbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to phaseUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in addSineButton.
function addSineButton_Callback(hObject, eventdata, handles)
    % hObject    handle to addSineButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    
    sineModel = SineModel(0, 1, 2*pi, 0);
    sumOfSines.addSine(sineModel);
    
    handles.sineListbox.String = sumOfSines.getListboxStr();
    handles.sineListbox.Value = sumOfSines.getNumSines();
    
    populateSineDefinition(handles, sumOfSines);
    
    
    % --- Executes on button press in removeSineButton.
function removeSineButton_Callback(hObject, eventdata, handles)
    % hObject    handle to removeSineButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sineModel = getSelectedSineModel(handles, sumOfSines);
    
    if(not(isempty(sineModel)))
        sumOfSines.removeSine(sineModel);
    end
    
    listBoxStr = sumOfSines.getListboxStr();
    handles.sineListbox.String = listBoxStr;
    
    if(handles.sineListbox.Value > length(listBoxStr))
        handles.sineListbox.Value = length(listBoxStr);
    end
    
    populateSineDefinition(handles, sumOfSines);
    


% --- Executes on button press in plotOnePeriodButton.
function plotOnePeriodButton_Callback(hObject, eventdata, handles)
% hObject    handle to plotOnePeriodButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    period = sumOfSines.getLongestPeriod();
    
    if(period == 0)
        period = 1;
    end
    
    t = linspace(0,period,500);
    y = NaN(1,length(t));
    
    for(i=1:length(t))
        y(i) = rad2deg(sumOfSines.getValueAtTime(t(i)));
    end

    hAx = axes(figure());
    plot(hAx, t, y);
    grid(hAx,'minor');
    xlabel('DT [sec]');
    ylabel('Sum of Sines Value [deg]');
    


% --------------------------------------------------------------------
function copySineWaveMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copySineWaveMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    sumOfSines = getappdata(handles.lvd_EditSumOfSinesModelGUI,'sumOfSines');
    sineModel = getSelectedSineModel(handles, sumOfSines);
    
    newSineModel = sineModel.deepCopy();
    sumOfSines.addSine(newSineModel);
    
    listBoxStr = sumOfSines.getListboxStr();
    handles.sineListbox.String = listBoxStr;
    handles.sineListbox.Value = length(listBoxStr);
    
    populateSineDefinition(handles, sumOfSines);
    
% --------------------------------------------------------------------
function sineListboxMenu_Callback(hObject, eventdata, handles)
% hObject    handle to sineListboxMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
