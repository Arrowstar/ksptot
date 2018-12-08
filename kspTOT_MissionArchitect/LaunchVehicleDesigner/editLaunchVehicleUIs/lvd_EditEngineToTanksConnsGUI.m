function varargout = lvd_EditEngineToTanksConnsGUI(varargin)
% LVD_EDITENGINETOTANKSCONNSGUI MATLAB code for lvd_EditEngineToTanksConnsGUI.fig
%      LVD_EDITENGINETOTANKSCONNSGUI, by itself, creates a new LVD_EDITENGINETOTANKSCONNSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITENGINETOTANKSCONNSGUI returns the handle to a new LVD_EDITENGINETOTANKSCONNSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITENGINETOTANKSCONNSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITENGINETOTANKSCONNSGUI.M with the given input arguments.
%
%      LVD_EDITENGINETOTANKSCONNSGUI('Property','Value',...) creates a new LVD_EDITENGINETOTANKSCONNSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditEngineToTanksConnsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditEngineToTanksConnsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditEngineToTanksConnsGUI

% Last Modified by GUIDE v2.5 03-Dec-2018 17:13:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditEngineToTanksConnsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditEngineToTanksConnsGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditEngineToTanksConnsGUI is made visible.
function lvd_EditEngineToTanksConnsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditEngineToTanksConnsGUI (see VARARGIN)

    % Choose default command line output for lvd_EditEngineToTanksConnsGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditEngineToTanksConnsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditEngineToTanksConnsGUI);

function populateGUI(handles, lvdData)
    set(handles.connsListBox,'String',lvdData.launchVehicle.getEngineToTankConnectionsListBoxStr());

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditEngineToTanksConnsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditEngineToTanksConnsGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditEngineToTanksConnsGUI);

% --- Executes on selection change in connsListBox.
function connsListBox_Callback(hObject, eventdata, handles)
% hObject    handle to connsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns connsListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from connsListBox
    if(strcmpi(get(handles.lvd_EditEngineToTanksConnsGUI,'SelectionType'),'open'))
        lvdData = getappdata(handles.lvd_EditEngineToTanksConnsGUI,'lvdData');
        lv = lvdData.launchVehicle;

        selE2TConn = get(handles.connsListBox,'Value');
        e2TConn = lv.getEngineToTankForInd(selE2TConn);
        
        lvd_EditEngineToTanksConnGUI(e2TConn);
        set(handles.connsListBox,'String',lvdData.launchVehicle.getEngineToTankConnectionsListBoxStr());
    end

% --- Executes during object creation, after setting all properties.
function connsListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to connsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addConnButton.
function addConnButton_Callback(hObject, eventdata, handles)
% hObject    handle to addConnButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditEngineToTanksConnsGUI,'lvdData');
          
    tempEngine = lvdData.launchVehicle.getEngineForInd(1);
    tempTank = lvdData.launchVehicle.getTankForInd(1);
    
    e2TConn = EngineToTankConnection(tempTank, tempEngine);
    useE2TConn = lvd_EditEngineToTanksConnGUI(e2TConn);
    
    if(useE2TConn)
        lvdData.launchVehicle.addEngineToTankConnection(e2TConn);
        
        lvState = lvdData.initStateModel.lvState;
        connState = EngineToTankConnState(e2TConn);
        lvState.addE2TConnState(connState);
        
        set(handles.connsListBox,'String',lvdData.launchVehicle.getEngineToTankConnectionsListBoxStr());
    end
    
% --- Executes on button press in removeConnButton.
function removeConnButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeConnButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditEngineToTanksConnsGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selConn = get(handles.connsListBox,'Value');
    conn = lv.getEngineToTankForInd(selConn);
    
    tf = conn.isInUse();
    
    if(tf == false)
        lvState = lvdData.initStateModel.lvState;
        lvState.removeE2TConnStateForConn(conn);
        
        lv.removeEngineToTankConnection(conn);
        
        listBoxStr = lvdData.launchVehicle.getEngineToTankConnectionsListBoxStr();
        set(handles.connsListBox,'String',listBoxStr);

        numConns = length(listBoxStr);
        if(selConn > numConns)
            set(handles.connsListBox,'Value',numConns);
        end
    else
        warndlg(sprintf('Could not delete the "%s" connection because it is in use as part of an event termination condition, event action, objective function, or constraint.  Remove the dependencies before attempting to delete the connection.', conn.getName()),'Cannot Delete Connection','modal');
    end


% --- Executes on key press with focus on lvd_EditEngineToTanksConnsGUI or any of its controls.
function lvd_EditEngineToTanksConnsGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditEngineToTanksConnsGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditEngineToTanksConnsGUI);
        case 'enter'
            uiresume(handles.lvd_EditEngineToTanksConnsGUI);
        case 'escape'
            uiresume(handles.lvd_EditEngineToTanksConnsGUI);
    end
