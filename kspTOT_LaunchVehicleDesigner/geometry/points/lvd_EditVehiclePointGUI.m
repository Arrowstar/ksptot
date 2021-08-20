function varargout = lvd_EditVehiclePointGUI(varargin)
% LVD_EDITVEHICLEPOINTGUI MATLAB code for lvd_EditVehiclePointGUI.fig
%      LVD_EDITVEHICLEPOINTGUI, by itself, creates a new LVD_EDITVEHICLEPOINTGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITVEHICLEPOINTGUI returns the handle to a new LVD_EDITVEHICLEPOINTGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITVEHICLEPOINTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITVEHICLEPOINTGUI.M with the given input arguments.
%
%      LVD_EDITVEHICLEPOINTGUI('Property','Value',...) creates a new LVD_EDITVEHICLEPOINTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditVehiclePointGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditVehiclePointGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditVehiclePointGUI

% Last Modified by GUIDE v2.5 12-Jan-2021 17:14:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditVehiclePointGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditVehiclePointGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditVehiclePointGUI is made visible.
function lvd_EditVehiclePointGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditVehiclePointGUI (see VARARGIN)

    % Choose default command line output for lvd_EditVehiclePointGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);

    point = varargin{1};
    setappdata(hObject, 'point', point);
    
	populateGUI(handles, point);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditVehiclePointGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditVehiclePointGUI);

function populateGUI(handles, point)
    set(handles.pointNameText,'String',point.getName());

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditVehiclePointGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        point = getappdata(hObject, 'point');
        
        point.setName(handles.pointNameText.String);
        
        varargout{1} = true;
        close(handles.lvd_EditVehiclePointGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditVehiclePointGUI);
    else
        msgbox(errMsg,'Invalid Point Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    if(isempty(strtrim(handles.pointNameText.String)))
        errMsg = {'Point name must contain more than white space and must not be empty.'};
    end

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditVehiclePointGUI);


function pointNameText_Callback(hObject, eventdata, handles)
% hObject    handle to pointNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pointNameText as text
%        str2double(get(hObject,'String')) returns contents of pointNameText as a double


% --- Executes during object creation, after setting all properties.
function pointNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pointNameText see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on key press with focus on lvd_EditVehiclePointGUI or any of its controls.
function lvd_EditVehiclePointGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditVehiclePointGUI (see GCBO)
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
            close(handles.lvd_EditVehiclePointGUI);
    end
