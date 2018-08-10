function varargout = ma_InsertDocking(varargin)
% MA_INSERTDOCKING MATLAB code for ma_InsertDocking.fig
%      MA_INSERTDOCKING, by itself, creates a new MA_INSERTDOCKING or raises the existing
%      singleton*.
%
%      H = MA_INSERTDOCKING returns the handle to a new MA_INSERTDOCKING or the handle to
%      the existing singleton*.
%
%      MA_INSERTDOCKING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_INSERTDOCKING.M with the given input arguments.
%
%      MA_INSERTDOCKING('Property','Value',...) creates a new MA_INSERTDOCKING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_InsertDocking_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_InsertDocking_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_InsertDocking

% Last Modified by GUIDE v2.5 19-Mar-2018 14:34:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_InsertDocking_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_InsertDocking_OutputFcn, ...
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


% --- Executes just before ma_InsertDocking is made visible.
function ma_InsertDocking_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_InsertDocking (see VARARGIN)

% Choose default command line output for ma_InsertDocking
handles.output = hObject;
handles.ma_MainGUI = varargin{1};

% Update handles structure
guidata(hObject, handles);

numOsc = populateOtherSCCombo(handles, handles.dockingOtherScCombo);
if(numOsc == 0)
    warndlg({'There are no other spacecraft available to dock to.', ...
             'To dock, please add an "Other Spacecraft" via the ', ...
             'Spacecraft -> Other Spacecraft menu.'},'No Other S/C','modal');
    close(handles.ma_InsertDocking);
    return;
end

if(length(varargin)>1) 
    event = varargin{2};
    setappdata(hObject,'lossConverts',event.massloss.lossConvert);
    populateGUIWithEvent(handles, event);
    set(hObject,'UserData',event);
else
    set(hObject,'UserData',[]);
    setappdata(hObject,'lossConverts',getDefaultLossConvert(handles));
end

% UIWAIT makes ma_InsertDocking wait for user response (see UIRESUME)
uiwait(handles.ma_InsertDocking);

function populateGUIWithEvent(handles, event)
    set(handles.titleLabel, 'String', 'Edit Docking');
    set(handles.ma_InsertDocking, 'Name', 'Edit Docking');
    set(handles.dockingNameText, 'String', event.name);

    colorStr = getStringFromLineSpecColor(event.lineColor);
    colorValue = findValueFromComboBox(colorStr, handles.coastLineColorCombo);
    set(handles.coastLineColorCombo,'value',colorValue);
    
    styleStr = getLineStyleFromString(event.lineStyle);
    styleValue = findValueFromComboBox(styleStr, handles.dockingLineStyleCombo);
 	set(handles.dockingLineStyleCombo,'Value',styleValue);

    undockTime = event.undockTime;
    set(handles.undockAfterText, 'String', fullAccNum2Str(undockTime));
    
    set(handles.massLossCheckbox,'Value',event.massloss.use);
    massLossCheckbox_Callback(handles.massLossCheckbox, [], handles);    

% --- Outputs from this function are returned to the command line.
function varargout = ma_InsertDocking_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        maData = getappdata(handles.ma_MainGUI,'ma_data');
        
        name = get(handles.dockingNameText, 'String');
        
        contents = cellstr(get(handles.coastLineColorCombo,'String'));
        colorStr = contents{get(handles.coastLineColorCombo,'Value')};
        lineSpecColor = getLineSpecColorFromString(colorStr);
        
        contents = cellstr(get(handles.dockingLineStyleCombo,'String'));
        lineStyleStr = contents{get(handles.dockingLineStyleCombo,'Value')};
        lineStyle = getLineStyleStrFromText(lineStyleStr);
        
        oScIndex = get(handles.dockingOtherScCombo,'Value');
        otherSC = maData.spacecraft.otherSC{oScIndex};
        oScId = otherSC.id;
        
        undockTime = str2double(get(handles.undockAfterText,'String'));
        
        massLoss = struct('use',logical(get(handles.massLossCheckbox,'Value')), 'lossConvert',getappdata(handles.dockingOtherScCombo,'lossConverts'));
        
        varargout{1} = ma_createDocking(name, oScId, undockTime, lineSpecColor, lineStyle, massLoss);
        close(handles.ma_InsertDocking);
    end
    
function dockingNameText_Callback(hObject, eventdata, handles)
% hObject    handle to dockingNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dockingNameText as text
%        str2double(get(hObject,'String')) returns contents of dockingNameText as a double


% --- Executes during object creation, after setting all properties.
function dockingNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dockingNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
   

% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.ma_InsertDocking);
    else
        msgbox(errMsg,'Errors were found while inserting a docking event.','error');
    end  

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.ma_InsertDocking);

function undockAfterText_Callback(hObject, eventdata, handles)
% hObject    handle to undockAfterText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of undockAfterText as text
%        str2double(get(hObject,'String')) returns contents of undockAfterText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function undockAfterText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to undockAfterText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in dockingOtherScCombo.
function dockingOtherScCombo_Callback(hObject, eventdata, handles)
% hObject    handle to dockingOtherScCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns dockingOtherScCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from dockingOtherScCombo


% --- Executes during object creation, after setting all properties.
function dockingOtherScCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dockingOtherScCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in massLossCheckbox.
function massLossCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to massLossCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of massLossCheckbox
    if(get(hObject,'Value')==1)
        set(handles.editLossConvertButton,'Enable','on');
    else
        set(handles.editLossConvertButton,'Enable','off');
    end

% --- Executes on button press in editLossConvertButton.
function editLossConvertButton_Callback(hObject, eventdata, handles)
% hObject    handle to editLossConvertButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    event = get(handles.ma_InsertDocking,'UserData');
    eventLossConvert = getappdata(handles.ma_InsertDocking,'lossConverts');
    if(~isempty(event) && isstruct(eventLossConvert) && ~isequal(eventLossConvert, getDefaultLossConvert(handles)))
        lossConverts = ma_MassLossesConversionsGUI(handles.ma_MainGUI, eventLossConvert);
    else
        lossConverts = ma_MassLossesConversionsGUI(handles.ma_MainGUI);
    end
    
    if(~isempty(lossConverts))
        setappdata(handles.ma_InsertDocking,'lossConverts',lossConverts);
    end
    
    setEditLossConvertButtonTooltipString(handles);
    
function setEditLossConvertButtonTooltipString(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    names = maData.spacecraft.propellant.names;
    
	lossConverts = getappdata(handles.ma_InsertDocking,'lossConverts');
    if(~isempty(lossConverts))
        maxNumRes = max(horzcat(lossConverts.resLost, lossConverts.resConvert));
        resRates = zeros(1,maxNumRes);
        
        for(i=1:length(lossConverts)) %#ok<*NO4LP>
            lossConvert = lossConverts(i);
            resRates(lossConvert.resLost) = resRates(lossConvert.resLost) - lossConvert.resLostRates(lossConvert.resLost);
            
            sumRates = sum(lossConvert.resLostRates);
            resRates(lossConvert.resConvert) = resRates(lossConvert.resConvert) + sumRates*lossConvert.resConvertPercent(lossConvert.resConvert);
        end
        
        str = 'Right Click for Copy/Paste\n\nTotal Resource Losses & Conversions\n-----------------------\n';
        for(i=1:length(resRates))           
            str = [str, ...
                   sprintf('%s: %1.6f mT/Hr\n', names{i}, resRates(i)*3600)];
        end
    else
        str = 'Right Click for Copy/Paste\n\nTotal Resource Losses & Conversions\n-----------------------\nNone!';
    end

    str = sprintf(str);
    set(handles.editLossConvertButton,'TooltipStr',str);
    
    
function errMsg = validateInputs(handles)
    errMsg = {};
    
    revs = str2double(get(handles.undockAfterText,'String'));
    enteredStr = get(handles.undockAfterText,'String');
    numberName = 'Undock After Time';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(revs, numberName, lb, ub, isInt, errMsg, enteredStr);


% --- Executes on selection change in coastLineColorCombo.
function coastLineColorCombo_Callback(hObject, eventdata, handles)
% hObject    handle to coastLineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns coastLineColorCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from coastLineColorCombo


% --- Executes during object creation, after setting all properties.
function coastLineColorCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to coastLineColorCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key release with focus on ma_InsertDocking or any of its controls.
function ma_InsertDocking_WindowKeyReleaseFcn(hObject, eventdata, handles)
% hObject    handle to ma_InsertDocking (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_InsertDocking);
    end


% --- Executes on selection change in dockingLineStyleCombo.
function dockingLineStyleCombo_Callback(hObject, eventdata, handles)
% hObject    handle to dockingLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns dockingLineStyleCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from dockingLineStyleCombo


% --- Executes during object creation, after setting all properties.
function dockingLineStyleCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dockingLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
