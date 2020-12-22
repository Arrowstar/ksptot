function varargout = lvd_EditCalculusObjGUI(varargin)
% LVD_EDITCALCULUSOBJGUI MATLAB code for lvd_EditCalculusObjGUI.fig
%      LVD_EDITCALCULUSOBJGUI, by itself, creates a new LVD_EDITCALCULUSOBJGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITCALCULUSOBJGUI returns the handle to a new LVD_EDITCALCULUSOBJGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITCALCULUSOBJGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITCALCULUSOBJGUI.M with the given input arguments.
%
%      LVD_EDITCALCULUSOBJGUI('Property','Value',...) creates a new LVD_EDITCALCULUSOBJGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditCalculusObjGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditCalculusObjGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditCalculusObjGUI

% Last Modified by GUIDE v2.5 23-Jul-2020 20:30:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditCalculusObjGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditCalculusObjGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditCalculusObjGUI is made visible.
function lvd_EditCalculusObjGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditCalculusObjGUI (see VARARGIN)

    % Choose default command line output for lvd_EditCalculusObjGUI
    handles.output = hObject;

    calcObj = varargin{1};
    setappdata(hObject, 'calcObj', calcObj);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, calcObj, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditCalculusObjGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditCalculusObjGUI);

function populateGUI(handles, calcObj, lvdData)
    exclude = getLvdGAExcludeList();
    exclude{end+1} = 'Distance Traveled';
    [extremaGAStr, ~] = lvdData.launchVehicle.getExtremaGraphAnalysisTaskStrs();
    exclude = horzcat(exclude,extremaGAStr);
    taskList = lvd_getGraphAnalysisTaskList(lvdData, exclude);
    
    handles.calcObjQuantCombo.String = taskList;
    if(isempty(calcObj.quantStr))
        value = 1;
    else
        value = findValueFromComboBox(calcObj.quantStr, handles.calcObjQuantCombo);
    end
    handles.calcObjQuantCombo.Value = value;
    
    populateBodiesCombo(lvdData.celBodyData, handles.refCelBodyCombo);
    if(isempty(calcObj.refBody))
        value = 1;
    else
        value = findValueFromComboBox(calcObj.refBody.name, handles.refCelBodyCombo);
    end
    handles.refCelBodyCombo.Value = value;

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditCalculusObjGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        calcObj = getappdata(hObject, 'calcObj');
        lvdData = getappdata(hObject, 'lvdData');
                
        quantityStrs = handles.calcObjQuantCombo.String;
        quantity = strtrim(quantityStrs{handles.calcObjQuantCombo.Value});
        calcObj.quantStr = quantity;
        
        celBodyStrs = handles.refCelBodyCombo.String;
        celBodyStr = celBodyStrs{handles.refCelBodyCombo.Value};
        calcObj.refBody = lvdData.celBodyData.(strtrim(lower(celBodyStr)));
        
        varargout{1} = true;
        close(handles.lvd_EditCalculusObjGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditCalculusObjGUI);

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditCalculusObjGUI);


function calcObjQuantCombo_Callback(hObject, eventdata, handles)
% hObject    handle to calcObjQuantCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of calcObjQuantCombo as text
%        str2double(get(hObject,'String')) returns contents of calcObjQuantCombo as a double


% --- Executes during object creation, after setting all properties.
function calcObjQuantCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to calcObjQuantCombo see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on lvd_EditCalculusObjGUI or any of its controls.
function lvd_EditCalculusObjGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditCalculusObjGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
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
            close(handles.lvd_EditCalculusObjGUI);
    end


% --- Executes on selection change in refCelBodyCombo.
function refCelBodyCombo_Callback(hObject, eventdata, handles)
% hObject    handle to refCelBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns refCelBodyCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from refCelBodyCombo


% --- Executes during object creation, after setting all properties.
function refCelBodyCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refCelBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
