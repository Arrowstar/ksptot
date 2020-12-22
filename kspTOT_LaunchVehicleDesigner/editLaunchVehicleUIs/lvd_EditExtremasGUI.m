function varargout = lvd_EditExtremasGUI(varargin)
% LVD_EDITEXTREMASGUI MATLAB code for lvd_EditExtremasGUI.fig
%      LVD_EDITEXTREMASGUI, by itself, creates a new LVD_EDITEXTREMASGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITEXTREMASGUI returns the handle to a new LVD_EDITEXTREMASGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITEXTREMASGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITEXTREMASGUI.M with the given input arguments.
%
%      LVD_EDITEXTREMASGUI('Property','Value',...) creates a new LVD_EDITEXTREMASGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditExtremasGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditExtremasGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditExtremasGUI

% Last Modified by GUIDE v2.5 14-Jan-2019 11:18:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditExtremasGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditExtremasGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditExtremasGUI is made visible.
function lvd_EditExtremasGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditExtremasGUI (see VARARGIN)

    % Choose default command line output for lvd_EditExtremasGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditExtremasGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditExtremasGUI);

function populateGUI(handles, lvdData)
    set(handles.extremasListBox,'String',lvdData.launchVehicle.getExtremaListBoxStr());
    
    numExtrema = length(get(handles.extremasListBox,'String'));
    if(numExtrema <= 0)
        handles.removeExtremaButton.Enable = 'off';
    end

    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditExtremasGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditExtremasGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditExtremasGUI);

% --- Executes on selection change in extremasListBox.
function extremasListBox_Callback(hObject, eventdata, handles)
% hObject    handle to extremasListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns extremasListBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from extremasListBox
    if(strcmpi(get(handles.lvd_EditExtremasGUI,'SelectionType'),'open'))
        lvdData = getappdata(handles.lvd_EditExtremasGUI,'lvdData');
        lv = lvdData.launchVehicle;

        selEx = get(handles.extremasListBox,'Value');
        extremum = lv.getExtremaForInd(selEx);
        
        lvd_EditExtremaGUI(extremum, lvdData);
        
        set(handles.extremasListBox,'String',lvdData.launchVehicle.getExtremaListBoxStr());
    end
    

% --- Executes during object creation, after setting all properties.
function extremasListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to extremasListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addExtremaButton.
function addExtremaButton_Callback(hObject, eventdata, handles)
% hObject    handle to addExtremaButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditExtremasGUI,'lvdData');
    
    extremum = LaunchVehicleExtrema(lvdData);
    useExtremum = lvd_EditExtremaGUI(extremum, lvdData);
    
    if(useExtremum)        
        lvdData.launchVehicle.addExtremum(extremum);
        
        set(handles.extremasListBox,'String',lvdData.launchVehicle.getExtremaListBoxStr());
        
        if(handles.extremasListBox.Value <= 0)
            handles.extremasListBox.Value = 1;
        end
        
        handles.removeExtremaButton.Enable = 'on';
    end
    
% --- Executes on button press in removeExtremaButton.
function removeExtremaButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeExtremaButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditExtremasGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selEx = get(handles.extremasListBox,'Value');
	extremum = lv.getExtremaForInd(selEx);
    
    tf = extremum.isInUse();
    
    if(tf == false)
        lv.removeExtremum(extremum);
        
        set(handles.extremasListBox,'String',lvdData.launchVehicle.getExtremaListBoxStr());
        
        numExa = length(handles.extremasListBox.String);
        if(selEx > numExa)
            set(handles.extremasListBox,'Value',numExa);
        end
        
        if(numExa <= 0)
            handles.removeExtremaButton.Enable = 'off';
        end
    else
        warndlg(sprintf('Could not delete the extremum "%s" because it is in use as part of an event termination condition, event action, objective function, or constraint.  Remove these extremum dependencies before attempting to delete the extremum.', extremum.getNameStr()),'Cannot Delete Extremum','modal');
    end


% --- Executes on key press with focus on lvd_EditExtremasGUI or any of its controls.
function lvd_EditExtremasGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditExtremasGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditExtremasGUI);
        case 'enter'
            uiresume(handles.lvd_EditExtremasGUI);
        case 'escape'
            uiresume(handles.lvd_EditExtremasGUI);
    end
