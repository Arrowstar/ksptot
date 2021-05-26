function varargout = lvd_EditLiftPropertiesGUI(varargin)
% LVD_EDITLIFTPROPERTIESGUI MATLAB code for lvd_EditLiftPropertiesGUI.fig
%      LVD_EDITLIFTPROPERTIESGUI, by itself, creates a new LVD_EDITLIFTPROPERTIESGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITLIFTPROPERTIESGUI returns the handle to a new LVD_EDITLIFTPROPERTIESGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITLIFTPROPERTIESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITLIFTPROPERTIESGUI.M with the given input arguments.
%
%      LVD_EDITLIFTPROPERTIESGUI('Property','Value',...) creates a new LVD_EDITLIFTPROPERTIESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditLiftPropertiesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditLiftPropertiesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditLiftPropertiesGUI

% Last Modified by GUIDE v2.5 03-Dec-2018 16:54:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditLiftPropertiesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditLiftPropertiesGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditLiftPropertiesGUI is made visible.
function lvd_EditLiftPropertiesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_EditLiftPropertiesGUI (see VARARGIN)

    % Choose default command line output for lvd_EditLiftPropertiesGUI
    handles.output = hObject;
    
    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditLiftPropertiesGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditLiftPropertiesGUI);

    
function populateGUI(handles, lvdData)
    initStateModel = lvdData.initStateModel;
    
    handles.useLiftForceCheckbox.Value = double(initStateModel.aero.useLift);
    handles.areaText.String = fullAccNum2Str(initStateModel.aero.areaLift);
    handles.liftCoeffText.String = fullAccNum2Str(initStateModel.aero.Cl_0);
    handles.liftVectXText.String = fullAccNum2Str(initStateModel.aero.bodyLiftVect(1));
    handles.liftVectYText.String = fullAccNum2Str(initStateModel.aero.bodyLiftVect(2));
    handles.liftVectZText.String = fullAccNum2Str(initStateModel.aero.bodyLiftVect(3));
    
    useLiftForceCheckbox_Callback(handles.useLiftForceCheckbox, [], handles);
    

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditLiftPropertiesGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
        varargout{2} = false;
        varargout{3} = false;
        varargout{4} = false;
        varargout{5} = false;
    else  
        lvdData = getappdata(handles.lvd_EditLiftPropertiesGUI,'lvdData');
        initStateModel = lvdData.initStateModel;
        
        initStateModel.aero.useLift = logical(handles.useLiftForceCheckbox.Value);
        initStateModel.aero.areaLift = str2double(handles.areaText.String);
        initStateModel.aero.Cl_0 = str2double(handles.liftCoeffText.String);
        initStateModel.aero.bodyLiftVect(1) = str2double(handles.liftVectXText.String);
        initStateModel.aero.bodyLiftVect(2) = str2double(handles.liftVectYText.String);
        initStateModel.aero.bodyLiftVect(3) = str2double(handles.liftVectZText.String);
        
        varargout{1} = true;
        varargout{2} = initStateModel.aero.useLift;
        varargout{3} = initStateModel.aero.areaLift;
        varargout{4} = initStateModel.aero.Cl_0;
        varargout{5} = initStateModel.aero.bodyLiftVect;
        close(handles.lvd_EditLiftPropertiesGUI);
    end



function errMsg = validateInputs(handles)
    errMsg = {};
    
    area = str2double(get(handles.areaText,'String'));
    enteredStr = get(handles.areaText,'String');
    numberName = 'Surface Area';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(area, numberName, lb, ub, isInt, errMsg, enteredStr);

    cD = str2double(get(handles.liftCoeffText,'String'));
    enteredStr = get(handles.liftCoeffText,'String');
    numberName = 'Lift Coefficient';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(cD, numberName, lb, ub, isInt, errMsg, enteredStr); 
    
    bodyX = str2double(get(handles.liftVectXText,'String'));
    enteredStr = get(handles.liftVectXText,'String');
    numberName = 'Lift Vector Body X';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(bodyX, numberName, lb, ub, isInt, errMsg, enteredStr); 
    
    bodyY = str2double(get(handles.liftVectYText,'String'));
    enteredStr = get(handles.liftVectYText,'String');
    numberName = 'Lift Vector Body Y';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(bodyY, numberName, lb, ub, isInt, errMsg, enteredStr); 

    bodyZ = str2double(get(handles.liftVectZText,'String'));
    enteredStr = get(handles.liftVectZText,'String');
    numberName = 'Lift Vector Body Z';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(bodyZ, numberName, lb, ub, isInt, errMsg, enteredStr); 
    

% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.lvd_EditLiftPropertiesGUI);
    else
        msgbox(errMsg,'Errors were found while editing lift properties.','error');
    end

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditLiftPropertiesGUI);


function areaText_Callback(hObject, eventdata, handles)
% hObject    handle to areaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of areaText as text
%        str2double(get(hObject,'String')) returns contents of areaText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function areaText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to areaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function liftCoeffText_Callback(hObject, eventdata, handles)
% hObject    handle to liftCoeffText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of liftCoeffText as text
%        str2double(get(hObject,'String')) returns contents of liftCoeffText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function liftCoeffText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to liftCoeffText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in useLiftForceCheckbox.
function useLiftForceCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to useLiftForceCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useLiftForceCheckbox
    if(get(hObject,'Value'))
        handles.areaText.Enable = 'on';
        handles.liftCoeffText.Enable = 'on';
        handles.liftVectXText.Enable = 'on';
        handles.liftVectYText.Enable = 'on';
        handles.liftVectZText.Enable = 'on';
    else
        handles.areaText.Enable = 'off';
        handles.liftCoeffText.Enable = 'off';
        handles.liftVectXText.Enable = 'off';
        handles.liftVectYText.Enable = 'off';
        handles.liftVectZText.Enable = 'off';
    end


function liftVectXText_Callback(hObject, eventdata, handles)
% hObject    handle to liftVectXText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of liftVectXText as text
%        str2double(get(hObject,'String')) returns contents of liftVectXText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function liftVectXText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to liftVectXText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function liftVectYText_Callback(hObject, eventdata, handles)
% hObject    handle to liftVectYText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of liftVectYText as text
%        str2double(get(hObject,'String')) returns contents of liftVectYText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function liftVectYText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to liftVectYText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function liftVectZText_Callback(hObject, eventdata, handles)
% hObject    handle to liftVectZText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of liftVectZText as text
%        str2double(get(hObject,'String')) returns contents of liftVectZText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function liftVectZText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to liftVectZText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on lvd_EditLiftPropertiesGUI or any of its controls.
function lvd_EditLiftPropertiesGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditLiftPropertiesGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            saveCloseButton_Callback(handles.saveCloseButton, [], handles);
        case 'enter'
            saveCloseButton_Callback(handles.saveCloseButton, [], handles);
        case 'escape'
            close(handles.lvd_EditLiftPropertiesGUI);
    end
