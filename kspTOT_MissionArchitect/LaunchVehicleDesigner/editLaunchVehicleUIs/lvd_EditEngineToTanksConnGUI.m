function varargout = lvd_EditEngineToTanksConnGUI(varargin)
% LVD_EDITENGINETOTANKSCONNGUI MATLAB code for lvd_EditEngineToTanksConnGUI.fig
%      LVD_EDITENGINETOTANKSCONNGUI, by itself, creates a new LVD_EDITENGINETOTANKSCONNGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITENGINETOTANKSCONNGUI returns the handle to a new LVD_EDITENGINETOTANKSCONNGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITENGINETOTANKSCONNGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITENGINETOTANKSCONNGUI.M with the given input arguments.
%
%      LVD_EDITENGINETOTANKSCONNGUI('Property','Value',...) creates a new LVD_EDITENGINETOTANKSCONNGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditEngineToTanksConnGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditEngineToTanksConnGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditEngineToTanksConnGUI

% Last Modified by GUIDE v2.5 03-Dec-2018 17:12:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditEngineToTanksConnGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditEngineToTanksConnGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditEngineToTanksConnGUI is made visible.
function lvd_EditEngineToTanksConnGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditEngineToTanksConnGUI (see VARARGIN)

    % Choose default command line output for lvd_EditEngineToTanksConnGUI
    handles.output = hObject;

    e2TConn = varargin{1};
    setappdata(hObject, 'e2TConn', e2TConn);
    
	populateGUI(handles, e2TConn);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditEngineToTanksConnGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditEngineToTanksConnGUI);

function populateGUI(handles, e2TConn)
    lv = e2TConn.engine.stage.launchVehicle;
    
    [tanksListStr, ~] = lv.getTanksListBoxStr();
    indTank = lv.getListBoxIndForTank(e2TConn.tank);
    if(isempty(indTank))
        indTank = 1;
    end
    
    [enginesListStr, ~] = lv.getEnginesListBoxStr();
    indEngine = lv.getListBoxIndForEngine(e2TConn.engine);
    if(isempty(indEngine))
        indEngine = 1;
    end
    
    set(handles.tankCombo,'String',tanksListStr);
    set(handles.tankCombo,'Value',indTank);
    set(handles.engineCombo,'String',enginesListStr);
    set(handles.engineCombo,'Value',indEngine);

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditEngineToTanksConnGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        e2TConn = getappdata(hObject, 'e2TConn');
        lv = e2TConn.engine.stage.launchVehicle;
        
        tank = lv.getTankForInd(handles.tankCombo.Value);
        engine = lv.getEngineForInd(handles.engineCombo.Value);
        
        e2TConn.tank = tank;
        e2TConn.engine = engine;
        
        varargout{1} = true;
        close(handles.lvd_EditEngineToTanksConnGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)   
    uiresume(handles.lvd_EditEngineToTanksConnGUI);

  
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditEngineToTanksConnGUI);


function engineCombo_Callback(hObject, eventdata, handles)
% hObject    handle to engineCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of engineCombo as text
%        str2double(get(hObject,'String')) returns contents of engineCombo as a double


% --- Executes during object creation, after setting all properties.
function engineCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to engineCombo see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in tankCombo.
function tankCombo_Callback(hObject, eventdata, handles)
% hObject    handle to tankCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tankCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tankCombo


% --- Executes during object creation, after setting all properties.
function tankCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tankCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on lvd_EditEngineToTanksConnGUI or any of its controls.
function lvd_EditEngineToTanksConnGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditEngineToTanksConnGUI (see GCBO)
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
            close(handles.lvd_EditEngineToTanksConnGUI);
    end
