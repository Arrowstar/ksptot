function varargout = lvd_EditObjectiveFunctionGUI(varargin)
% LVD_EDITOBJECTIVEFUNCTIONGUI MATLAB code for lvd_EditObjectiveFunctionGUI.fig
%      LVD_EDITOBJECTIVEFUNCTIONGUI, by itself, creates a new LVD_EDITOBJECTIVEFUNCTIONGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITOBJECTIVEFUNCTIONGUI returns the handle to a new LVD_EDITOBJECTIVEFUNCTIONGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITOBJECTIVEFUNCTIONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITOBJECTIVEFUNCTIONGUI.M with the given input arguments.
%
%      LVD_EDITOBJECTIVEFUNCTIONGUI('Property','Value',...) creates a new LVD_EDITOBJECTIVEFUNCTIONGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditObjectiveFunctionGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditObjectiveFunctionGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditObjectiveFunctionGUI

% Last Modified by GUIDE v2.5 07-Nov-2018 19:57:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditObjectiveFunctionGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditObjectiveFunctionGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditObjectiveFunctionGUI is made visible.
function lvd_EditObjectiveFunctionGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditObjectiveFunctionGUI (see VARARGIN)

    % Choose default command line output for lvd_EditObjectiveFunctionGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditObjectiveFunctionGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditObjectiveFunctionGUI);

function populateGUI(handles, lvdData)
    objFcn = lvdData.optimizer.objFcn;
    
    params = objFcn.getParams();
    
    handles.objFcnCombo.String = ObjectiveFunctionEnum.getListBoxStr();
    handles.objFcnCombo.Value = ObjectiveFunctionEnum.getIndForClass(objFcn);
    
    handles.eventCombo.String = lvdData.script.getListboxStr();
    if(isempty(handles.eventCombo.String))
        handles.eventCombo.String = ' ';
    end
        
    if(params.usesEvents)
        eventNum = lvdData.script.getNumOfEvent(objFcn.getRefEvent());
        
        if(not(isempty(eventNum)))
            handles.eventCombo.Value = eventNum;
        else
            handles.eventCombo.Value = 1;
        end
        handles.eventCombo.Enable = 'on';
    else
        handles.eventCombo.Value = 1;
        handles.eventCombo.Enable = 'off';
    end
    
    populateBodiesCombo(lvdData.celBodyData, handles.refCelBodyCombo, false);
    if(params.usesBodies)
        bodyInfo = objFcn.getRefBody();
        value = findValueFromComboBox(bodyInfo.name, handles.refCelBodyCombo);
        handles.refCelBodyCombo.Value = value;
    else
        handles.refCelBodyCombo.Value = 1;
        handles.refCelBodyCombo.Enable = 'off';
    end
    

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditObjectiveFunctionGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be definepopulateBodiesCombod in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        lvdData = getappdata(hObject, 'lvdData');
        lvdOptim = lvdData.optimizer;
        
        m = enumeration('ObjectiveFunctionEnum');
        enum = m(handles.objFcnCombo.Value);
        
        params = eval(sprintf('%s.getParams()',enum.class));
        
        if(params.usesEvents)
            event = lvdData.script.getEventForInd(handles.eventCombo.Value);
        else
            event = LaunchVehicleEvent.empty(0,1);
        end
        
        if(params.usesBodies)
            celBodyData = lvdData.celBodyData;
            contents = cellstr(get(handles.refCelBodyCombo,'String'));
            selected = contents{get(handles.refCelBodyCombo,'Value')};
            refBodyInfo = celBodyData.(lower(strtrim(selected)));
        else
            refBodyInfo = KSPTOT_BodyInfo.empty(0,1);
        end
        
        newObjFcn = eval(sprintf('%s.getDefaultObjFcn(event, refBodyInfo, lvdOptim, lvdData)', enum.class));
        
        lvdData.optimizer.objFcn = newObjFcn;
        
        varargout{1} = true;
        close(handles.lvd_EditObjectiveFunctionGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)   
    uiresume(handles.lvd_EditObjectiveFunctionGUI);

  
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditObjectiveFunctionGUI);


function objFcnCombo_Callback(hObject, eventdata, handles)
% hObject    handle to objFcnCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of objFcnCombo as text
%        str2double(get(hObject,'String')) returns contents of objFcnCombo as a double
    m = enumeration('ObjectiveFunctionEnum');
    enum = m(handles.objFcnCombo.Value);
    params = eval(sprintf('%s.getParams()',enum.class));

    if(params.usesEvents)
        handles.eventCombo.Enable = 'on';
    else
        handles.eventCombo.Enable = 'off';
    end
    
    if(params.usesBodies)
        handles.refCelBodyCombo.Enable = 'on';
    else
        handles.refCelBodyCombo.Enable = 'off';
    end

% --- Executes during object creation, after setting all properties.
function objFcnCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to objFcnCombo see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in eventCombo.
function eventCombo_Callback(hObject, eventdata, handles)
% hObject    handle to eventCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns eventCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from eventCombo


% --- Executes during object creation, after setting all properties.
function eventCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eventCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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
