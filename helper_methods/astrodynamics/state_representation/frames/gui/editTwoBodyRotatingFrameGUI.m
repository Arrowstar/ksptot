function varargout = editTwoBodyRotatingFrameGUI(varargin)
    % EDITTWOBODYROTATINGFRAMEGUI MATLAB code for editTwoBodyRotatingFrameGUI.fig
    %      EDITTWOBODYROTATINGFRAMEGUI, by itself, creates a new EDITTWOBODYROTATINGFRAMEGUI or raises the existing
    %      singleton*.
    %
    %      H = EDITTWOBODYROTATINGFRAMEGUI returns the handle to a new EDITTWOBODYROTATINGFRAMEGUI or the handle to
    %      the existing singleton*.
    %
    %      EDITTWOBODYROTATINGFRAMEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in EDITTWOBODYROTATINGFRAMEGUI.M with the given input arguments.
    %
    %      EDITTWOBODYROTATINGFRAMEGUI('Property','Value',...) creates a new EDITTWOBODYROTATINGFRAMEGUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before editTwoBodyRotatingFrameGUI_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to editTwoBodyRotatingFrameGUI_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help editTwoBodyRotatingFrameGUI
    
    % Last Modified by GUIDE v2.5 05-Jul-2020 12:57:52
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @editTwoBodyRotatingFrameGUI_OpeningFcn, ...
        'gui_OutputFcn',  @editTwoBodyRotatingFrameGUI_OutputFcn, ...
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
    
    
    % --- Executes just before editTwoBodyRotatingFrameGUI is made visible.
function editTwoBodyRotatingFrameGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to editTwoBodyRotatingFrameGUI (see VARARGIN)
    
    % Choose default command line output for editTwoBodyRotatingFrameGUI
    handles.output = hObject;
    
    frame = varargin{1};
    setappdata(hObject,'frame',frame);
    
    handles = populateGUI(frame, handles);
    
    % Update handles structure
    guidata(hObject, handles);
    
    % UIWAIT makes editTwoBodyRotatingFrameGUI wait for user response (see UIRESUME)
    uiwait(handles.editTwoBodyRotatingFrameGUI);
    
function handles = populateGUI(frame, handles)
    celBodyData = frame.celBodyData;
    [bodiesStr, sortedBodyInfo] = ma_getSortedBodyNames(celBodyData);
    
    for(i=1:length(sortedBodyInfo))
        sortedBodyInfoArr(i) = sortedBodyInfo{i}; %#ok<AGROW>
    end
    
    handles.primaryBodyCombo.String = bodiesStr;
    ind = find(frame.primaryBodyInfo == sortedBodyInfoArr,1,'first');
    handles.primaryBodyCombo.Value = ind;
    
    handles.secondaryBodyCombo.String = bodiesStr;
    ind = find(frame.secondaryBodyInfo == sortedBodyInfoArr,1,'first');
    handles.secondaryBodyCombo.Value = ind;
    
    handles.frameOriginCombo.String = TwoBodyRotatingFrameOriginEnum.getListBoxStr();
    handles.frameOriginCombo.Value = TwoBodyRotatingFrameOriginEnum.getIndForName(frame.originPt.name);
    
    % --- Outputs from this function are returned to the command line.
function varargout = editTwoBodyRotatingFrameGUI_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        frame = getappdata(hObject,'frame');
        
        celBodyData = frame.celBodyData;
        [~, sortedBodyInfo] = ma_getSortedBodyNames(celBodyData);
        
        frame.primaryBodyInfo = sortedBodyInfo{handles.primaryBodyCombo.Value};
        frame.secondaryBodyInfo = sortedBodyInfo{handles.secondaryBodyCombo.Value};
        
        contents = cellstr(get(handles.frameOriginCombo,'String'));
        originPtName = contents{get(handles.frameOriginCombo,'Value')};
        frame.originPt = TwoBodyRotatingFrameOriginEnum.getEnumForListboxStr(originPtName);
        
        varargout{1} = true;
        close(handles.editTwoBodyRotatingFrameGUI);
    end
    
    
    % --- Executes on selection change in primaryBodyCombo.
function primaryBodyCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to primaryBodyCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns primaryBodyCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from primaryBodyCombo
    
    
    % --- Executes during object creation, after setting all properties.
function primaryBodyCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to primaryBodyCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on selection change in frameOriginCombo.
function frameOriginCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to frameOriginCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns frameOriginCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from frameOriginCombo
    
    
    % --- Executes during object creation, after setting all properties.
function frameOriginCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to frameOriginCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on selection change in text2.
function secondaryBodyCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to text2 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns text2 contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from text2
    
    
    % --- Executes during object creation, after setting all properties.
function secondaryBodyCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to text2 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
    % hObject    handle to saveAndCloseButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.editTwoBodyRotatingFrameGUI);
    else
        msgbox(errMsg,'Invalid Two-Body Rotating Frame Inputs','error');
    end
    
function errMsg = validateInputs(handles)
    errMsg = {};
    
    frame = getappdata(handles.editTwoBodyRotatingFrameGUI,'frame');

    celBodyData = frame.celBodyData;
    [~, sortedBodyInfo] = ma_getSortedBodyNames(celBodyData);

    primaryBodyInfo = sortedBodyInfo{handles.primaryBodyCombo.Value};
    secondaryBodyInfo = sortedBodyInfo{handles.secondaryBodyCombo.Value};
        
    if(primaryBodyInfo == secondaryBodyInfo)
        errMsg{end+1} = 'The primary body must be different than the secondary body.';
    end
    
    % --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
    % hObject    handle to cancelButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    close(handles.editTwoBodyRotatingFrameGUI);
