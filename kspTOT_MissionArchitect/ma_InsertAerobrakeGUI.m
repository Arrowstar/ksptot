function varargout = ma_InsertAerobrakeGUI(varargin)
% MA_INSERTAEROBRAKE MATLAB code for ma_InsertAerobrake.fig
%      MA_INSERTAEROBRAKE, by itself, creates a new MA_INSERTAEROBRAKE or raises the existing
%      singleton*.
%
%      H = MA_INSERTAEROBRAKE returns the handle to a new MA_INSERTAEROBRAKE or the handle to
%      the existing singleton*.
%
%      MA_INSERTAEROBRAKE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_INSERTAEROBRAKE.M with the given input arguments.
%
%      MA_INSERTAEROBRAKE('Property','Value',...) creates a new MA_INSERTAEROBRAKE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_InsertAerobrake_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_InsertAerobrake_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_InsertAerobrake

% Last Modified by GUIDE v2.5 20-Jan-2019 16:22:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_InsertAerobrake_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_InsertAerobrake_OutputFcn, ...
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


% --- Executes just before ma_InsertAerobrake is made visible.
function ma_InsertAerobrake_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_InsertAerobrake (see VARARGIN)

% Choose default command line output for ma_InsertAerobrake
handles.output = hObject;
handles.ma_MainGUI = varargin{1};

% Update handles structure
guidata(hObject, handles);

if(length(varargin)>1)
    event = varargin{2};
    populateGUIWithEvent(handles, event);
end

dragModelCombo_Callback(handles.dragModelCombo, [], handles);

% UIWAIT makes ma_InsertAerobrake wait for user response (see UIRESUME)
uiwait(handles.ma_InsertAerobrakeGUI);


function populateGUIWithEvent(handles, event)    
    set(handles.titleLabel, 'String', 'Edit Aerobrake');
    set(handles.ma_InsertAerobrakeGUI, 'Name', 'Edit Aerobrake');
    set(handles.nameText, 'String', event.name);
    
    set(handles.dragCoeffText,'String', num2str(event.dragCoeff,10));
    
    colorStr = getStringFromLineSpecColor(event.lineColor);
    colorValue = findValueFromComboBox(colorStr, handles.lineColorCombo);
    set(handles.lineColorCombo,'value',colorValue);
    
    styleStr = getLineStyleFromString(event.lineStyle);
    styleValue = findValueFromComboBox(styleStr, handles.aerobrakeLineStyleCombo);
 	set(handles.aerobrakeLineStyleCombo,'Value',styleValue);
    
    contents = handles.lineWidthCombo.String;
    contentsDouble = str2double(contents);
    ind = find(contentsDouble == event.lineWidth);
    set(handles.lineWidthCombo,'Value',ind);
    
    if(~isfield(event,'dragModel'))
        event.dragModel = 'Stock';
    end
    value = findValueFromComboBox(event.dragModel, handles.dragModelCombo);
    set(handles.dragModelCombo,'Value',value);


% --- Outputs from this function are returned to the command line.
function varargout = ma_InsertAerobrake_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        name = get(handles.nameText,'String');
        dragCoeff = str2double(get(handles.dragCoeffText,'String'));
        
        contents = cellstr(get(handles.dragModelCombo,'String'));
        dragModel = contents{get(handles.dragModelCombo,'Value')};
        
        contents = cellstr(get(handles.lineColorCombo,'String'));
        colorStr = contents{get(handles.lineColorCombo,'Value')};
        lineSpecColor = getLineSpecColorFromString(colorStr);
        
        contents = cellstr(get(handles.aerobrakeLineStyleCombo,'String'));
        lineStyleStr = contents{get(handles.aerobrakeLineStyleCombo,'Value')};
        lineStyle = getLineStyleStrFromText(lineStyleStr);
        
        contents = handles.lineWidthCombo.String;
        contentsDouble = str2double(contents);
        contensInd = get(handles.lineWidthCombo,'Value');
        lineWidth = contentsDouble(contensInd);
        
        varargout{1} = ma_createAerobrake(name, dragCoeff, dragModel, lineSpecColor, lineStyle, lineWidth);
        close(handles.ma_InsertAerobrakeGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.ma_InsertAerobrakeGUI);
    else
        msgbox(errMsg,'Errors were found while inserting an aerobrake.','error');
    end
    
    
function errMsg = validateInputs(handles)
    errMsg = {};
    
    dragCoeff = str2double(get(handles.dragCoeffText,'String'));
    enteredStr = get(handles.dragCoeffText,'String');
    numberName = 'Drag Coefficient';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(dragCoeff, numberName, lb, ub, isInt, errMsg, enteredStr);
    

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.ma_InsertAerobrakeGUI);


function nameText_Callback(hObject, eventdata, handles)
% hObject    handle to nameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nameText as text
%        str2double(get(hObject,'String')) returns contents of nameText as a double


% --- Executes during object creation, after setting all properties.
function nameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dragCoeffText_Callback(hObject, eventdata, handles)
% hObject    handle to dragCoeffText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dragCoeffText as text
%        str2double(get(hObject,'String')) returns contents of dragCoeffText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function dragCoeffText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dragCoeffText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on ma_InsertAerobrakeGUI or any of its controls.
function ma_InsertAerobrakeGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_InsertAerobrakeGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            saveAndCloseButton_Callback(handles.saveAndCloseButton, [], handles);
        case 'enter'
            saveAndCloseButton_Callback(handles.saveAndCloseButton, [], handles);
        case 'escape'
            close(handles.ma_InsertAerobrakeGUI);
    end


% --- Executes on button press in openCdCalcButton.
function openCdCalcButton_Callback(hObject, eventdata, handles)
% hObject    handle to openCdCalcButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ma_AerobrakingCdCalcGUI(handles.ma_MainGUI);


% --- Executes on selection change in dragModelCombo.
function dragModelCombo_Callback(hObject, eventdata, handles)
% hObject    handle to dragModelCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns dragModelCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from dragModelCombo
    contents = cellstr(get(hObject,'String'));
    dragModel = contents{get(hObject,'Value')};
    
    switch(dragModel)
        case 'Stock'
%             set(handles.cdLabel,'String','');
            set(handles.cdLabel,'String','m^2');
        case 'FAR'
            set(handles.cdLabel,'String','m^2');
        case 'NEAR'
            set(handles.cdLabel,'String','m^2');
    end

% --- Executes during object creation, after setting all properties.
function dragModelCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dragModelCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lineColorCombo.
function lineColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to lineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lineColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lineColorCombo


% --- Executes during object creation, after setting all properties.
function lineColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in aerobrakeLineStyleCombo.
function aerobrakeLineStyleCombo_Callback(hObject, eventdata, handles)
% hObject    handle to aerobrakeLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns aerobrakeLineStyleCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from aerobrakeLineStyleCombo


% --- Executes during object creation, after setting all properties.
function aerobrakeLineStyleCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to aerobrakeLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lineWidthCombo.
function lineWidthCombo_Callback(hObject, eventdata, handles)
% hObject    handle to lineWidthCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lineWidthCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lineWidthCombo


% --- Executes during object creation, after setting all properties.
function lineWidthCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lineWidthCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
