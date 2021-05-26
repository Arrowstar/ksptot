function varargout = lvd_EditFitNetModelGUI(varargin)
    % LVD_EDITFITNETMODELGUI MATLAB code for lvd_EditFitNetModelGUI.fig
    %      LVD_EDITFITNETMODELGUI, by itself, creates a new LVD_EDITFITNETMODELGUI or raises the existing
    %      singleton*.
    %
    %      H = LVD_EDITFITNETMODELGUI returns the handle to a new LVD_EDITFITNETMODELGUI or the handle to
    %      the existing singleton*.
    %
    %      LVD_EDITFITNETMODELGUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in LVD_EDITFITNETMODELGUI.M with the given input arguments.
    %
    %      LVD_EDITFITNETMODELGUI('Property','Value',...) creates a new LVD_EDITFITNETMODELGUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before lvd_EditFitNetModelGUI_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to lvd_EditFitNetModelGUI_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help lvd_EditFitNetModelGUI
    
    % Last Modified by GUIDE v2.5 23-Apr-2021 20:31:42
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @lvd_EditFitNetModelGUI_OpeningFcn, ...
        'gui_OutputFcn',  @lvd_EditFitNetModelGUI_OutputFcn, ...
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
    
    
    % --- Executes just before lvd_EditFitNetModelGUI is made visible.
function lvd_EditFitNetModelGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditFitNetModelGUI (see VARARGIN)
    
    % Choose default command line output for lvd_EditFitNetModelGUI
    handles.output = hObject;
    
    fitNetModel = varargin{1};
    setappdata(hObject,'fitNetModel',fitNetModel);
    
    setappdata(hObject,'plotDur',1.0);
    
    populateGUI(handles, fitNetModel);
    
    % Update handles structure
    guidata(hObject, handles);
    
    % UIWAIT makes lvd_EditFitNetModelGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditFitNetModelGUI);
    
function populateGUI(handles, fitNetModel)
    handles.constText.String = fullAccNum2Str(rad2deg(fitNetModel.const));
    handles.constOptCheckbox.Value = double(fitNetModel.varConst);
    handles.constLbText.String = fullAccNum2Str(rad2deg(fitNetModel.constLb));
    handles.constUbText.String = fullAccNum2Str(rad2deg(fitNetModel.constUb));
    
    constOptCheckbox_Callback(handles.constOptCheckbox, [], handles);
    
    fitNetListboxStr = fitNetModel.getListboxStr();
    handles.wbParamListbox.String = fitNetListboxStr;
    if(~isempty(fitNetListboxStr))
        handles.wbParamListbox.Value = 1;
    end
    
    populateWbParameterDefinition(handles, fitNetModel);
    
function populateWbParameterDefinition(handles, fitNetModel)   
    selInd = handles.wbParamListbox.Value;
    wbParams = fitNetModel.getWbParams();
    wbParam = wbParams(selInd);
    
    varWb = fitNetModel.varNetWB(selInd);
    ub = fitNetModel.netWbUb(selInd);
    lb = fitNetModel.netWbLb(selInd);
    
    handles.wbParamText.String = fullAccNum2Str(wbParam);
    handles.wbParamOptCheckbox.Value = double(varWb);
    handles.wbParamLbText.String = fullAccNum2Str(lb);
    handles.wbParamUbText.String = fullAccNum2Str(ub);
    wbParamOptCheckbox_Callback(handles.wbParamOptCheckbox, [], handles);  
       
   
    
    % --- Outputs from this function are returned to the command line.
function varargout = lvd_EditFitNetModelGUI_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        varargout{1} = true;
        close(handles.lvd_EditFitNetModelGUI);
    end
    
    
    % --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
    % hObject    handle to saveAndCloseButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    errMsg = {};
    if(isempty(errMsg))
        uiresume(handles.lvd_EditFitNetModelGUI);
    else
        msgbox(errMsg,'Errors were found while editing plugins.','error');
    end
    
    % --- Executes on selection change in wbParamListbox.
function wbParamListbox_Callback(hObject, eventdata, handles)
    % hObject    handle to wbParamListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns wbParamListbox contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from wbParamListbox
    fitNetModel = getappdata(handles.lvd_EditFitNetModelGUI,'fitNetModel');
    populateWbParameterDefinition(handles, fitNetModel);
    
    
    % --- Executes during object creation, after setting all properties.
function wbParamListbox_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to wbParamListbox (see GCBO)
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
    
    fitNetModel = getappdata(handles.lvd_EditFitNetModelGUI,'fitNetModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Constant Offset';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        fitNetModel.const = deg2rad(value);
    else
        hObject.String = fullAccNum2Str(rad2deg(fitNetModel.const));
        
        msgbox(errMsg,'Invalid Constant Offset','error');
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
    fitNetModel = getappdata(handles.lvd_EditFitNetModelGUI,'fitNetModel');
    fitNetModel.varConst = logical(hObject.Value);
    
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
    
    fitNetModel = getappdata(handles.lvd_EditFitNetModelGUI,'fitNetModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Constant Offset Lower Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        fitNetModel.constLb = deg2rad(value);
    else
        hObject.String = fullAccNum2Str(fitNetModel.constLb);
        
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
    
    fitNetModel = getappdata(handles.lvd_EditFitNetModelGUI,'fitNetModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Constant Offset Upper Bound';
    lb = fitNetModel.constLb;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        fitNetModel.constUb = deg2rad(value);
    else
        hObject.String = fullAccNum2Str(fitNetModel.constUb);
        
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
    
    
    
function wbParamText_Callback(hObject, eventdata, handles)
    % hObject    handle to wbParamText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of wbParamText as text
    %        str2double(get(hObject,'String')) returns contents of wbParamText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    selInd = handles.wbParamListbox.Value;
    fitNetModel = getappdata(handles.lvd_EditFitNetModelGUI,'fitNetModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Weight/Bias Parameter';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        fitNetModel.setWbParamAtInd(value, selInd);
        
        handles.wbParamListbox.String = fitNetModel.getListboxStr();
    else
        hObject.String = fullAccNum2Str(fitNetModel.getWbParamAtInd(selInd));
        
        msgbox(errMsg,'Invalid Weight/Bias Parameter','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function wbParamText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to wbParamText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in wbParamOptCheckbox.
function wbParamOptCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to wbParamOptCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of wbParamOptCheckbox
    selInd = handles.wbParamListbox.Value;
    fitNetModel = getappdata(handles.lvd_EditFitNetModelGUI,'fitNetModel');
    fitNetModel.varNetWB(selInd) = logical(hObject.Value);
    
    if(hObject.Value)
        handles.wbParamLbText.Enable = 'on';
        handles.wbParamUbText.Enable = 'on';
    else
        handles.wbParamLbText.Enable = 'off';
        handles.wbParamUbText.Enable = 'off';
    end
    
    
function wbParamLbText_Callback(hObject, eventdata, handles)
    % hObject    handle to wbParamLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of wbParamLbText as text
    %        str2double(get(hObject,'String')) returns contents of wbParamLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    selInd = handles.wbParamListbox.Value;
    fitNetModel = getappdata(handles.lvd_EditFitNetModelGUI,'fitNetModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Weight/Bias Parameter Lower Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        fitNetModel.netWbLb(selInd) = value;
    else
        hObject.String = fullAccNum2Str(fitNetModel.netWbLb(selInd));
        
        msgbox(errMsg,'Invalid Weight/Bias Parameter Lower Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function wbParamLbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to wbParamLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function wbParamUbText_Callback(hObject, eventdata, handles)
    % hObject    handle to wbParamUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of wbParamUbText as text
    %        str2double(get(hObject,'String')) returns contents of wbParamUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    selInd = handles.wbParamListbox.Value;
    fitNetModel = getappdata(handles.lvd_EditFitNetModelGUI,'fitNetModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Weight/Bias Parameter Upper Bound';
    lb = fitNetModel.netWbLb(selInd);
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        fitNetModel.netWbUb(selInd) = value;
    else
        hObject.String = fullAccNum2Str(fitNetModel.netWbUb(selInd));
        
        msgbox(errMsg,'Invalid Weight/Bias Parameter Upper Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function wbParamUbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to wbParamUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
% --- Executes on button press in plotPolynomialButton.
function plotPolynomialButton_Callback(hObject, eventdata, handles)
% hObject    handle to plotPolynomialButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fitNetModel = getappdata(handles.lvd_EditFitNetModelGUI,'fitNetModel');
    duration = str2double(handles.durationToPlot.String);
    
    hMsg = msgbox('Plotting from neural network, please wait...', 'Please Wait', 'help');
    
    t0 = fitNetModel.getT0();
    t = linspace(t0,t0+duration,500);
    y = NaN(1,length(t));
    
    for(i=1:length(t))
        y(i) = fitNetModel.getValueAtTime(t(i));
    end
    
    y = rad2deg(y);
    
    if(isvalid(hMsg))
        close(hMsg);
    end

    hAx = axes(figure());
    plot(hAx, t, y);
    grid(hAx,'minor');
    xlabel('DT [sec]');
    ylabel('Polynomial Value [deg]');
    
function durationToPlot_Callback(hObject, eventdata, handles)
% hObject    handle to durationToPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of durationToPlot as text
%        str2double(get(hObject,'String')) returns contents of durationToPlot as a double
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Duration to Plot';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(not(isempty(errMsg)))  
        oldPlotDur = getappdata(handles.lvd_EditFitNetModelGUI,'plotDur');
        handles.durationToPlot.String = fullAccNum2Str(oldPlotDur);
        
        msgbox(errMsg,'Invalid Plotting Duration','error');
    end

% --- Executes during object creation, after setting all properties.
function durationToPlot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to durationToPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function optimizeAllParametersMenu_Callback(hObject, eventdata, handles)
% hObject    handle to optimizeAllParametersMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fitNetModel = getappdata(handles.lvd_EditFitNetModelGUI,'fitNetModel');
    varNetWB = fitNetModel.varNetWB;
    varNetWB = true(size(varNetWB));
    fitNetModel.varNetWB = varNetWB;
    
    populateWbParameterDefinition(handles, fitNetModel);
    
% --------------------------------------------------------------------
function unoptimizeAllParametersMenu_Callback(hObject, eventdata, handles)
% hObject    handle to unoptimizeAllParametersMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fitNetModel = getappdata(handles.lvd_EditFitNetModelGUI,'fitNetModel');
    varNetWB = fitNetModel.varNetWB;
    varNetWB = false(size(varNetWB));
    fitNetModel.varNetWB = varNetWB;
    
    populateWbParameterDefinition(handles, fitNetModel);

% --------------------------------------------------------------------
function listboxContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to listboxContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
