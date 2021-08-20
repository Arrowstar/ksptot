function varargout = lvd_EditGroundObjPointGUI(varargin)
% LVD_EDITGROUNDOBJPOINTGUI MATLAB code for lvd_EditGroundObjPointGUI.fig
%      LVD_EDITGROUNDOBJPOINTGUI, by itself, creates a new LVD_EDITGROUNDOBJPOINTGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITGROUNDOBJPOINTGUI returns the handle to a new LVD_EDITGROUNDOBJPOINTGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITGROUNDOBJPOINTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITGROUNDOBJPOINTGUI.M with the given input arguments.
%
%      LVD_EDITGROUNDOBJPOINTGUI('Property','Value',...) creates a new LVD_EDITGROUNDOBJPOINTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditGroundObjPointGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditGroundObjPointGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditGroundObjPointGUI

% Last Modified by GUIDE v2.5 10-Jan-2021 17:33:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditGroundObjPointGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditGroundObjPointGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditGroundObjPointGUI is made visible.
function lvd_EditGroundObjPointGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditGroundObjPointGUI (see VARARGIN)

    % Choose default command line output for lvd_EditGroundObjPointGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);

    point = varargin{1};
    setappdata(hObject, 'point', point);
    
	populateGUI(handles, point);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditGroundObjPointGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditGroundObjPointGUI);

function populateGUI(handles, point)
    set(handles.pointNameText,'String',point.getName());
    
    groundObj = point.groundObj;
    groundObjSet = groundObj.groundObjs;
    groundObjListboxStr = groundObjSet.getListboxStr();
    handles.groundObjCombo.String = groundObjListboxStr;
    handles.groundObjCombo.Value = groundObjSet.getIndsForGroundObjs(groundObj);
   

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditGroundObjPointGUI_OutputFcn(hObject, eventdata, handles) 
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
        
        point.groundObj = point.groundObj.groundObjs.getGroundObjAtInd(handles.groundObjCombo.Value);
        
        varargout{1} = true;
        close(handles.lvd_EditGroundObjPointGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_EditGroundObjPointGUI);
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
    close(handles.lvd_EditGroundObjPointGUI);


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



% --- Executes on key press with focus on lvd_EditGroundObjPointGUI or any of its controls.
function lvd_EditGroundObjPointGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditGroundObjPointGUI (see GCBO)
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
            close(handles.lvd_EditGroundObjPointGUI);
    end

    
% --- Executes on selection change in groundObjCombo.
function groundObjCombo_Callback(hObject, eventdata, handles)
% hObject    handle to groundObjCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns groundObjCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from groundObjCombo


% --- Executes during object creation, after setting all properties.
function groundObjCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to groundObjCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
