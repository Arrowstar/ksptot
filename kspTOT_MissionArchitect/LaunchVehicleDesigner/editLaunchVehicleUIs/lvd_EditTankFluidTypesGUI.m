function varargout = lvd_EditTankFluidTypesGUI(varargin)
% LVD_EDITTANKFLUIDTYPESGUI MATLAB code for lvd_EditTankFluidTypesGUI.fig
%      LVD_EDITTANKFLUIDTYPESGUI, by itself, creates a new LVD_EDITTANKFLUIDTYPESGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITTANKFLUIDTYPESGUI returns the handle to a new LVD_EDITTANKFLUIDTYPESGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITTANKFLUIDTYPESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITTANKFLUIDTYPESGUI.M with the given input arguments.
%
%      LVD_EDITTANKFLUIDTYPESGUI('Property','Value',...) creates a new LVD_EDITTANKFLUIDTYPESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditTankFluidTypesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditTankFluidTypesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditTankFluidTypesGUI

% Last Modified by GUIDE v2.5 22-Jan-2019 11:46:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditTankFluidTypesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditTankFluidTypesGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditTankFluidTypesGUI is made visible.
function lvd_EditTankFluidTypesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditTankFluidTypesGUI (see VARARGIN)

    % Choose default command line output for lvd_EditTankFluidTypesGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditTankFluidTypesGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditTankFluidTypesGUI);

function populateGUI(handles, lvdData)
    set(handles.moveTypeUpButton,'String','<html>&uarr;');
    set(handles.moveTypeDownButton,'String','<html>&darr;');
    set(handles.typesListbox,'String',lvdData.launchVehicle.tankTypes.getListboxStr());
    
    numTypes = length(get(handles.typesListbox,'String'));
    if(numTypes <= 3)
        handles.removeRemoveTypeButton.Enable = 'off';
    end

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditTankFluidTypesGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        close(handles.lvd_EditTankFluidTypesGUI);
    end


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_EditTankFluidTypesGUI);

% --- Executes on selection change in typesListbox.
function typesListbox_Callback(hObject, eventdata, handles)
% hObject    handle to typesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns typesListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from typesListbox
    if(strcmpi(get(handles.lvd_EditTankFluidTypesGUI,'SelectionType'),'open'))
        lvdData = getappdata(handles.lvd_EditTankFluidTypesGUI,'lvdData');
        lv = lvdData.launchVehicle;

        selType = get(handles.typesListbox,'Value');
        type = lv.tankTypes.getTypeForInd(selType);
        askAndSetNewNameForType(type);

        set(handles.typesListbox,'String',lvdData.launchVehicle.tankTypes.getListboxStr());
    end
    
function askAndSetNewNameForType(type)
    answer = inputdlg('Enter a new name for the fluid:','Edit Fluid Type',1,{type.name});
    answer = strtrim(answer);
    if(not(isempty(answer)))
        type.name = answer;
    else
        errordlg('The input name for the fluid type must contain more than whitespace and must not be zero length.');
    end
    

% --- Executes during object creation, after setting all properties.
function typesListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to typesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addTypeButton.
function addTypeButton_Callback(hObject, eventdata, handles)
% hObject    handle to addTypeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditTankFluidTypesGUI,'lvdData');
    lv = lvdData.launchVehicle;
       
    type = TankFluidType('New Fluid');
    askAndSetNewNameForType(type);
    
    lv.tankTypes.addType(type);
    listboxStr = lv.tankTypes.getListboxStr();
    
    set(handles.typesListbox,'String',listboxStr);
    set(handles.typesListbox,'Value',length(listboxStr));
    
    handles.removeRemoveTypeButton.Enable = 'on';
    
% --- Executes on button press in removeRemoveTypeButton.
function removeRemoveTypeButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeRemoveTypeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditTankFluidTypesGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selType = get(handles.typesListbox,'Value');
    type = lv.tankTypes.getTypeForInd(selType);
    
    tf = type.isInUse(lvdData);
    
    if(tf == false) 
        lv.tankTypes.removeType(type);

        listboxStr = lv.tankTypes.getListboxStr();
        set(handles.typesListbox,'String',listboxStr);

        numTypes = length(listboxStr);
        if(selType > numTypes)
            set(handles.typesListbox,'Value',numTypes);
        end
        
        if(numTypes <= 3)
            handles.removeRemoveTypeButton.Enable = 'off';
        end
    else
        warndlg(sprintf('Could not delete the fluid type "%s" because it is in use on an existing tank.  Set any tanks that use this fluid type to a different fluid type before deleting.', type.name),'Cannot Delete Fluid Type','modal');
    end
    
% --- Executes on button press in moveTypeUpButton.
function moveTypeUpButton_Callback(hObject, eventdata, handles)
% hObject    handle to moveTypeUpButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditTankFluidTypesGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selType = get(handles.typesListbox,'Value');
    type = lv.tankTypes.getTypeForInd(selType);

    lv.tankTypes.moveTypeUp(type);
    
    if(selType>1)
        set(handles.typesListbox,'Value',selType-1);
    end
    
    set(handles.typesListbox,'String',lv.tankTypes.getListboxStr());

% --- Executes on button press in moveTypeDownButton.
function moveTypeDownButton_Callback(hObject, eventdata, handles)
% hObject    handle to moveTypeDownButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditTankFluidTypesGUI,'lvdData');
    lv = lvdData.launchVehicle;
    
    selType = get(handles.typesListbox,'Value');
    type = lv.tankTypes.getTypeForInd(selType);

    lv.tankTypes.moveTypeDown(type);
    listboxStr = lv.tankTypes.getListboxStr();
    
    numTypes = length(listboxStr);
    if(selType<numTypes)
        set(handles.typesListbox,'Value',selType+1);
    end
    
    set(handles.typesListbox,'String',listboxStr);


% --- Executes on key press with focus on lvd_EditTankFluidTypesGUI or any of its controls.
function lvd_EditTankFluidTypesGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditTankFluidTypesGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            uiresume(handles.lvd_EditTankFluidTypesGUI);
        case 'enter'
            uiresume(handles.lvd_EditTankFluidTypesGUI);
        case 'escape'
            uiresume(handles.lvd_EditTankFluidTypesGUI);
    end
