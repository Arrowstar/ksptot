function varargout = lvd_editLaunchVehicle(varargin)
% LVD_EDITLAUNCHVEHICLE MATLAB code for lvd_editLaunchVehicle.fig
%      LVD_EDITLAUNCHVEHICLE, by itself, creates a new LVD_EDITLAUNCHVEHICLE or raises the existing
%      singleton*.
%
%      H = LVD_EDITLAUNCHVEHICLE returns the handle to a new LVD_EDITLAUNCHVEHICLE or the handle to
%      the existing singleton*.
%
%      LVD_EDITLAUNCHVEHICLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITLAUNCHVEHICLE.M with the given input arguments.
%
%      LVD_EDITLAUNCHVEHICLE('Property','Value',...) creates a new LVD_EDITLAUNCHVEHICLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_editLaunchVehicle_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_editLaunchVehicle_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_editLaunchVehicle

% Last Modified by GUIDE v2.5 03-Dec-2018 17:15:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_editLaunchVehicle_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_editLaunchVehicle_OutputFcn, ...
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


    % --- Executes just before lvd_editLaunchVehicle is made visible.
    function lvd_editLaunchVehicle_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_editLaunchVehicle (see VARARGIN)

    % Choose default command line output for lvd_editLaunchVehicle
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject, 'lvdData', lvdData);

    populateGUI(handles, lvdData);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_editLaunchVehicle wait for user response (see UIRESUME)
    uiwait(handles.lvd_editLaunchVehicle);

function populateGUI(handles, lvdData)
    jScrollPane = findjobj(handles.lvSummaryText);
    jViewPort = jScrollPane.getViewport;
    jEditbox = jViewPort.getComponent(0);
    jEditbox.setWrapping(false);
    jScrollPane.setHorizontalScrollBarPolicy(32);
    jEditbox.revalidate();
    setSummText(handles.lvSummaryText, lvdData.launchVehicle);
    
function setSummText(hSummText, lv)
    set(hSummText, 'String', lv.getLvSummaryStr());


% --- Outputs from this function are returned to the command line.
function varargout = lvd_editLaunchVehicle_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_editLaunchVehicle);
    end



function lvSummaryText_Callback(hObject, eventdata, handles)
% hObject    handle to lvSummaryText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lvSummaryText as text
%        str2double(get(hObject,'String')) returns contents of lvSummaryText as a double


% --- Executes during object creation, after setting all properties.
function lvSummaryText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lvSummaryText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in editStagesButton.
function editStagesButton_Callback(hObject, eventdata, handles)
% hObject    handle to editStagesButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_editLaunchVehicle, 'lvdData');
    lvd_EditStagesGUI(lvdData);
    setSummText(handles.lvSummaryText, lvdData.launchVehicle);

% --- Executes on button press in editEnginesButton.
function editEnginesButton_Callback(hObject, eventdata, handles)
% hObject    handle to editEnginesButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_editLaunchVehicle, 'lvdData');
    lvd_EditEnginesGUI(lvdData);
    setSummText(handles.lvSummaryText, lvdData.launchVehicle);

% --- Executes on button press in editTanksButton.
function editTanksButton_Callback(hObject, eventdata, handles)
% hObject    handle to editTanksButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_editLaunchVehicle, 'lvdData');
    lvd_EditTanksGUI(lvdData);
    setSummText(handles.lvSummaryText, lvdData.launchVehicle);

% --- Executes on button press in editEngineToTankConnsButton.
function editEngineToTankConnsButton_Callback(hObject, eventdata, handles)
% hObject    handle to editEngineToTankConnsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_editLaunchVehicle, 'lvdData');
    lvd_EditEngineToTanksConnsGUI(lvdData);
    setSummText(handles.lvSummaryText, lvdData.launchVehicle);

% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_editLaunchVehicle);


% --- Executes on key press with focus on lvd_editLaunchVehicle or any of its controls.
function lvd_editLaunchVehicle_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_editLaunchVehicle (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_editLaunchVehicle);
        case 'enter'
            uiresume(handles.lvd_editLaunchVehicle);
        case 'escape'
            uiresume(handles.lvd_editLaunchVehicle);
    end
