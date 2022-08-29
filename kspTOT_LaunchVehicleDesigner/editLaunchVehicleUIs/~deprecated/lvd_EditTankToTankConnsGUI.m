function varargout = lvd_EditTankToTankConnsGUI(varargin)
% LVD_EDITTANKTOTANKCONNSGUI MATLAB code for lvd_EditTankToTankConnsGUI.fig
%      LVD_EDITTANKTOTANKCONNSGUI, by itself, creates a new LVD_EDITTANKTOTANKCONNSGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITTANKTOTANKCONNSGUI returns the handle to a new LVD_EDITTANKTOTANKCONNSGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITTANKTOTANKCONNSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITTANKTOTANKCONNSGUI.M with the given input arguments.
%
%      LVD_EDITTANKTOTANKCONNSGUI('Property','Value',...) creates a new LVD_EDITTANKTOTANKCONNSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditTankToTankConnsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditTankToTankConnsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditTankToTankConnsGUI

% Last Modified by GUIDE v2.5 21-Jan-2019 11:37:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditTankToTankConnsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditTankToTankConnsGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditTankToTankConnsGUI is made visible.
function lvd_EditTankToTankConnsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditTankToTankConnsGUI (see VARARGIN)

    % Choose default command line output for lvd_EditTankToTankConnsGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditTankToTankConnsGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditTankToTanksConnsGUI);

function populateGUI(handles, lvdData)
    set(handles.connsListBox,'String',lvdData.launchVehicle.getTankToTankConnectionsListBoxStr());

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditTankToTankConnsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditTankToTanksConnsGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditTankToTanksConnsGUI);

% --- Executes on selection change in connsListBox.
function connsListBox_Callback(hObject, eventdata, handles)
% hObject    handle to connsListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns connsListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from connsListBox
    if(strcmpi(get(handles.lvd_EditTankToTanksConnsGUI,'SelectionType'),'open'))
        lvdData = getappdata(handles.lvd_EditTankToTanksConnsGUI,'lvdData');
        lv = lvdData.launchVehicle;

        [~,t2TConns] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
        
        if(~isempty(t2TConns))
            selT2TConn = get(handles.connsListBox,'Value');
            t2TConn = lv.getTankToTankForInd(selT2TConn);

            lvd_EditTankToTankConnGUI(t2TConn);
            
            lvState = lvdData.initStateModel.lvState;
            connState = lvState.getTank2TankConnStateForConn(t2TConn);
            connState.flowRate = t2TConn.initFlowRate;
            
            set(handles.connsListBox,'String',lvdData.launchVehicle.getTankToTankConnectionsListBoxStr());
        end
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
    lvdData = getappdata(handles.lvd_EditTankToTanksConnsGUI,'lvdData');
          
    tempSrcTank = lvdData.launchVehicle.getTankForInd(1);
    tempTgtTank = LaunchVehicleTank.empty(1,0);
    
    t2TConn = TankToTankConnection(tempSrcTank, tempTgtTank);
    useT2TConn = lvd_EditTankToTankConnGUI(t2TConn);
    
    if(useT2TConn)
        lvdData.launchVehicle.addTankToTankConnection(t2TConn);
        
        lvState = lvdData.initStateModel.lvState;
        connState = TankToTankConnState(t2TConn);
        connState.flowRate = t2TConn.initFlowRate;
        lvState.addT2TConnState(connState);
        
        set(handles.connsListBox,'String',lvdData.launchVehicle.getTankToTankConnectionsListBoxStr());
    end
    
% --- Executes on button press in removeConnButton.
function removeConnButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeConnButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditTankToTanksConnsGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selConn = get(handles.connsListBox,'Value');
    conn = lv.getTankToTankForInd(selConn);
    
    tf = conn.isInUse();

    if(tf == false)
        lvState = lvdData.initStateModel.lvState;
        lvState.removeT2TConnStateForConn(conn);
        
        lv.removeTankToTankConnection(conn);
        
        listBoxStr = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
        set(handles.connsListBox,'String',listBoxStr);

        numConns = length(listBoxStr);
        if(numConns == 0)
            handles.connsListBox.String = ' ';
            set(handles.connsListBox,'Value',1);
        elseif(selConn > numConns)
            set(handles.connsListBox,'Value',numConns);
        end
    else
        warndlg(sprintf('Could not delete the "%s" connection because it is in use as part of an event termination condition, event action, objective function, or constraint.  Remove the dependencies before attempting to delete the connection.', conn.getName()),'Cannot Delete Connection','modal');
    end


% --- Executes on key press with focus on lvd_EditTankToTankConnsGUI or any of its controls.
function lvd_EditTankToTanksConnsGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditTankToTankConnsGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditTankToTanksConnsGUI);
        case 'enter'
            uiresume(handles.lvd_EditTankToTanksConnsGUI);
        case 'escape'
            uiresume(handles.lvd_EditTankToTanksConnsGUI);
    end
