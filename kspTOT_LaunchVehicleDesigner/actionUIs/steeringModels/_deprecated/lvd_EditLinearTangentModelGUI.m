function varargout = lvd_EditLinearTangentModelGUI(varargin)
    % LVD_EDITLINEARTANGENTMODELGUI MATLAB code for lvd_EditLinearTangentModelGUI.fig
    %      LVD_EDITLINEARTANGENTMODELGUI, by itself, creates a new LVD_EDITLINEARTANGENTMODELGUI or raises the existing
    %      singleton*.
    %
    %      H = LVD_EDITLINEARTANGENTMODELGUI returns the handle to a new LVD_EDITLINEARTANGENTMODELGUI or the handle to
    %      the existing singleton*.
    %
    %      LVD_EDITLINEARTANGENTMODELGUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in LVD_EDITLINEARTANGENTMODELGUI.M with the given input arguments.
    %
    %      LVD_EDITLINEARTANGENTMODELGUI('Property','Value',...) creates a new LVD_EDITLINEARTANGENTMODELGUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before lvd_EditLinearTangentModelGUI_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to lvd_EditLinearTangentModelGUI_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help lvd_EditLinearTangentModelGUI
    
    % Last Modified by GUIDE v2.5 23-Apr-2021 16:29:22
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @lvd_EditLinearTangentModelGUI_OpeningFcn, ...
        'gui_OutputFcn',  @lvd_EditLinearTangentModelGUI_OutputFcn, ...
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
    
    
    % --- Executes just before lvd_EditLinearTangentModelGUI is made visible.
function lvd_EditLinearTangentModelGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditLinearTangentModelGUI (see VARARGIN)
    
    % Choose default command line output for lvd_EditLinearTangentModelGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);
    
    linearTangentModel = varargin{1};
    setappdata(hObject,'linearTangentModel',linearTangentModel);
    
    setappdata(hObject,'plotDur',1.0);
    
    populateGUI(handles, linearTangentModel);
    
    % Update handles structure
    guidata(hObject, handles);
    
    % UIWAIT makes lvd_EditLinearTangentModelGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditLinearTangentModelGUI);
    
function populateGUI(handles, linearTangentModel)        
    handles.aText.String = fullAccNum2Str(linearTangentModel.a);
    handles.aOptCheckbox.Value = double(linearTangentModel.varA);
    handles.aLbText.String = fullAccNum2Str(linearTangentModel.aLb);
    handles.aUbText.String = fullAccNum2Str(linearTangentModel.aUb);
    aOptCheckbox_Callback(handles.aOptCheckbox, [], handles);

    handles.aDotText.String = fullAccNum2Str(linearTangentModel.a_dot);
    handles.aDotOptCheckbox.Value = double(linearTangentModel.varADot);
    handles.aDotLbText.String = fullAccNum2Str(linearTangentModel.aDotLb);
    handles.aDotUbText.String = fullAccNum2Str(linearTangentModel.aDotUb);
    aDotOptCheckbox_Callback(handles.aDotOptCheckbox, [], handles);

    handles.bText.String = fullAccNum2Str(linearTangentModel.b);
    handles.bOptCheckbox.Value = double(linearTangentModel.varB);
    handles.bLbText.String = fullAccNum2Str(linearTangentModel.bLb);
    handles.bUbText.String = fullAccNum2Str(linearTangentModel.bUb);
    bOptCheckbox_Callback(handles.bOptCheckbox, [], handles);
    
    handles.bDotText.String = fullAccNum2Str(linearTangentModel.b_dot);
    handles.bDotOptCheckbox.Value = double(linearTangentModel.varBDot);
    handles.bDotLbText.String = fullAccNum2Str(linearTangentModel.bDotLb);
    handles.bDotUbText.String = fullAccNum2Str(linearTangentModel.bDotUb);
    bDotOptCheckbox_Callback(handles.bDotOptCheckbox, [], handles);
       
    
    % --- Outputs from this function are returned to the command line.
function varargout = lvd_EditLinearTangentModelGUI_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        varargout{1} = true;
        close(handles.lvd_EditLinearTangentModelGUI);
    end
    
    
    % --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
    % hObject    handle to saveAndCloseButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    errMsg = {};
    if(isempty(errMsg))
        uiresume(handles.lvd_EditLinearTangentModelGUI);
    else
        msgbox(errMsg,'Errors were found while editing plugins.','error');
    end
    
    
function aText_Callback(hObject, eventdata, handles)
    % hObject    handle to aText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of aText as text
    %        str2double(get(hObject,'String')) returns contents of aText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'A Term';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        linearTangentModel.a = value;
    else
        hObject.String = fullAccNum2Str(linearTangentModel.a);
        
        msgbox(errMsg,'Invalid A Term','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function aText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to aText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in aOptCheckbox.
function aOptCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to aOptCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of aOptCheckbox
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    linearTangentModel.varA = logical(hObject.Value);
    
    if(hObject.Value)
        handles.aLbText.Enable = 'on';
        handles.aUbText.Enable = 'on';
    else
        handles.aLbText.Enable = 'off';
        handles.aUbText.Enable = 'off';
    end
    
    
function aLbText_Callback(hObject, eventdata, handles)
    % hObject    handle to aLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of aLbText as text
    %        str2double(get(hObject,'String')) returns contents of aLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'A Term Lower Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        linearTangentModel.aLb = value;
    else
        hObject.String = fullAccNum2Str(linearTangentModel.aLb);
        
        msgbox(errMsg,'Invalid A Term Lower Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function aLbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to aLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function aUbText_Callback(hObject, eventdata, handles)
    % hObject    handle to aUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of aUbText as text
    %        str2double(get(hObject,'String')) returns contents of aUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'A Term Upper Bound';
    lb = linearTangentModel.aLb;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        linearTangentModel.aUb = value;
    else
        hObject.String = fullAccNum2Str(linearTangentModel.aUb);
        
        msgbox(errMsg,'Invalid A Term Upper Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function aUbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to aUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function aDotText_Callback(hObject, eventdata, handles)
    % hObject    handle to aDotText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of aDotText as text
    %        str2double(get(hObject,'String')) returns contents of aDotText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'A Dot';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        linearTangentModel.a_dot = value;
    else
        hObject.String = fullAccNum2Str(linearTangentModel.a_dot);
        
        msgbox(errMsg,'Invalid A Dot','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function aDotText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to aDotText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in aDotOptCheckbox.
function aDotOptCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to aDotOptCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of aDotOptCheckbox
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    linearTangentModel.varADot = logical(hObject.Value);
    
    if(hObject.Value)
        handles.aDotLbText.Enable = 'on';
        handles.aDotUbText.Enable = 'on';
    else
        handles.aDotLbText.Enable = 'off';
        handles.aDotUbText.Enable = 'off';
    end
    
    
function aDotLbText_Callback(hObject, eventdata, handles)
    % hObject    handle to aDotLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of aDotLbText as text
    %        str2double(get(hObject,'String')) returns contents of aDotLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'A Dot Lower Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        linearTangentModel.aDotLb = value;
    else
        hObject.String = fullAccNum2Str(linearTangentModel.aDotLb);
        
        msgbox(errMsg,'Invalid A Dot Lower Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function aDotLbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to aDotLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function aDotUbText_Callback(hObject, eventdata, handles)
    % hObject    handle to aDotUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of aDotUbText as text
    %        str2double(get(hObject,'String')) returns contents of aDotUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'A Dot Upper Bound';
    lb = linearTangentModel.aDotLb;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        linearTangentModel.aDotUb = value;
    else
        hObject.String = fullAccNum2Str(linearTangentModel.aDotUb);
        
        msgbox(errMsg,'Invalid A Dot Upper Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function aDotUbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to aDotUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    

% --- Executes on button press in plotLinearTangentButton.
function plotLinearTangentButton_Callback(hObject, eventdata, handles)
% hObject    handle to plotLinearTangentButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    duration = str2double(handles.durationToPlot.String);
    
    t0 = linearTangentModel.getT0();
    t = linspace(t0,t0+duration,500);
    y = NaN(1,length(t));
    
    for(i=1:length(t))
        y(i) = linearTangentModel.getValueAtTime(t(i));
    end
    
    y = rad2deg(y);

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
        oldPlotDur = getappdata(handles.lvd_EditLinearTangentModelGUI,'plotDur');
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



function bText_Callback(hObject, eventdata, handles)
% hObject    handle to bText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bText as text
%        str2double(get(hObject,'String')) returns contents of bText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'B Term';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        linearTangentModel.b = value;
    else
        hObject.String = fullAccNum2Str(linearTangentModel.b);
        
        msgbox(errMsg,'Invalid B Term','error');
    end

% --- Executes during object creation, after setting all properties.
function bText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in bOptCheckbox.
function bOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to bOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of bOptCheckbox
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    linearTangentModel.varB = logical(hObject.Value);
    
    if(hObject.Value)
        handles.bLbText.Enable = 'on';
        handles.bUbText.Enable = 'on';
    else
        handles.bLbText.Enable = 'off';
        handles.bUbText.Enable = 'off';
    end


function bLbText_Callback(hObject, eventdata, handles)
% hObject    handle to bLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bLbText as text
%        str2double(get(hObject,'String')) returns contents of bLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'B Term Lower Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        linearTangentModel.bLb = value;
    else
        hObject.String = fullAccNum2Str(linearTangentModel.bLb);
        
        msgbox(errMsg,'Invalid B Term Lower Bound','error');
    end

% --- Executes during object creation, after setting all properties.
function bLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bUbText_Callback(hObject, eventdata, handles)
% hObject    handle to bUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bUbText as text
%        str2double(get(hObject,'String')) returns contents of bUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'B Term Upper Bound';
    lb = linearTangentModel.bLb;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        linearTangentModel.bUb = value;
    else
        hObject.String = fullAccNum2Str(linearTangentModel.bUb);
        
        msgbox(errMsg,'Invalid B Term Upper Bound','error');
    end

% --- Executes during object creation, after setting all properties.
function bUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bDotText_Callback(hObject, eventdata, handles)
% hObject    handle to bDotText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bDotText as text
%        str2double(get(hObject,'String')) returns contents of bDotText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'B Dot Term';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        linearTangentModel.b_dot = value;
    else
        hObject.String = fullAccNum2Str(linearTangentModel.b_dot);
        
        msgbox(errMsg,'Invalid B Dot Term','error');
    end

% --- Executes during object creation, after setting all properties.
function bDotText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bDotText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in bDotOptCheckbox.
function bDotOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to bDotOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of bDotOptCheckbox
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    linearTangentModel.varBDot = logical(hObject.Value);
    
    if(hObject.Value)
        handles.bDotLbText.Enable = 'on';
        handles.bDotUbText.Enable = 'on';
    else
        handles.bDotLbText.Enable = 'off';
        handles.bDotUbText.Enable = 'off';
    end


function bDotLbText_Callback(hObject, eventdata, handles)
% hObject    handle to bDotLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bDotLbText as text
%        str2double(get(hObject,'String')) returns contents of bDotLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'B Dot Term Lower Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        linearTangentModel.bDotLb = value;
    else
        hObject.String = fullAccNum2Str(linearTangentModel.bDot);
        
        msgbox(errMsg,'Invalid B Dot Term Lower Bound','error');
    end

% --- Executes during object creation, after setting all properties.
function bDotLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bDotLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bDotUbText_Callback(hObject, eventdata, handles)
% hObject    handle to bDotUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bDotUbText as text
%        str2double(get(hObject,'String')) returns contents of bDotUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    linearTangentModel = getappdata(handles.lvd_EditLinearTangentModelGUI,'linearTangentModel');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'B Dot Term Upper Bound';
    lb = linearTangentModel.bDotLb;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        linearTangentModel.bDotUb = value;
    else
        hObject.String = fullAccNum2Str(linearTangentModel.bDotUb);
        
        msgbox(errMsg,'Invalid B Dot Term Upper Bound','error');
    end

% --- Executes during object creation, after setting all properties.
function bDotUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bDotUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
