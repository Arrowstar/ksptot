function varargout = lvd_EditDragPropertiesGUI(varargin)
% LVD_EDITDRAGPROPERTIESGUI MATLAB code for lvd_EditDragPropertiesGUI.fig
%      LVD_EDITDRAGPROPERTIESGUI, by itself, creates a new LVD_EDITDRAGPROPERTIESGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITDRAGPROPERTIESGUI returns the handle to a new LVD_EDITDRAGPROPERTIESGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITDRAGPROPERTIESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITDRAGPROPERTIESGUI.M with the given input arguments.
%
%      LVD_EDITDRAGPROPERTIESGUI('Property','Value',...) creates a new LVD_EDITDRAGPROPERTIESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditDragPropertiesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditDragPropertiesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditDragPropertiesGUI

% Last Modified by GUIDE v2.5 17-Nov-2018 14:34:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditDragPropertiesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditDragPropertiesGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditDragPropertiesGUI is made visible.
function lvd_EditDragPropertiesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_EditDragPropertiesGUI (see VARARGIN)

    % Choose default command line output for lvd_EditDragPropertiesGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditDragPropertiesGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditDragPropertiesGUI);

function populateGUI(handles, lvdData)
    initStateModel = lvdData.initStateModel;
    
    handles.dragAreaText.String = fullAccNum2Str(initStateModel.aero.area);
    handles.dragCoeffText.String = fullAccNum2Str(initStateModel.aero.Cd);
    
    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditDragPropertiesGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
        varargout{2} = false;
        varargout{3} = false;
    else  
        lvdData = getappdata(handles.lvd_EditDragPropertiesGUI,'lvdData');
        initStateModel = lvdData.initStateModel;
        
        uiArea = str2double(handles.dragAreaText.String);
        uiCd = str2double(handles.dragCoeffText.String);
        
        initStateModel.aero.area = uiArea;
        initStateModel.aero.Cd = uiCd;
        
        varargout{1} = true;
        varargout{2} = uiCd;
        varargout{3} = uiArea;
        close(handles.lvd_EditDragPropertiesGUI);
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    area = str2double(get(handles.dragAreaText,'String'));
    enteredStr = get(handles.dragAreaText,'String');
    numberName = 'Frontal Area';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(area, numberName, lb, ub, isInt, errMsg, enteredStr);

    cD = str2double(get(handles.dragCoeffText,'String'));
    enteredStr = get(handles.dragCoeffText,'String');
    numberName = 'Drag Coefficient';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(cD, numberName, lb, ub, isInt, errMsg, enteredStr);   

% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.lvd_EditDragPropertiesGUI);
    else
        msgbox(errMsg,'Errors were found while editing drag properties.','error');
    end

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditDragPropertiesGUI);


function dragAreaText_Callback(hObject, eventdata, handles)
% hObject    handle to dragAreaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dragAreaText as text
%        str2double(get(hObject,'String')) returns contents of dragAreaText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function dragAreaText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dragAreaText (see GCBO)
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
