function varargout = ma_InsertLandingGUI(varargin)
% MA_INSERTLANDINGGUI MATLAB code for ma_InsertLandingGUI.fig
%      MA_INSERTLANDINGGUI, by itself, creates a new MA_INSERTLANDINGGUI or raises the existing
%      singleton*.
%
%      H = MA_INSERTLANDINGGUI returns the handle to a new MA_INSERTLANDINGGUI or the handle to
%      the existing singleton*.
%
%      MA_INSERTLANDINGGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_INSERTLANDINGGUI.M with the given input arguments.
%
%      MA_INSERTLANDINGGUI('Property','Value',...) creates a new MA_INSERTLANDINGGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_InsertLandingGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_InsertLandingGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_InsertLandingGUI

% Last Modified by GUIDE v2.5 20-Jan-2019 16:36:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_InsertLandingGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_InsertLandingGUI_OutputFcn, ...
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


% --- Executes just before ma_InsertLandingGUI is made visible.
function ma_InsertLandingGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_InsertLandingGUI (see VARARGIN)

% Choose default command line output for ma_InsertLandingGUI
handles.output = hObject;
handles.ma_MainGUI = varargin{1};

% Update handles structure
guidata(hObject, handles);

if(length(varargin)>1) 
    event = varargin{2};
    setappdata(hObject,'lossConverts',event.massloss.lossConvert);
    populateGUIWithEvent(handles, event);
    set(hObject,'UserData',event);
else
    set(hObject,'UserData',[]);
    setappdata(hObject,'lossConverts',getDefaultLossConvert(handles));
end

% UIWAIT makes ma_InsertLandingGUI wait for user response (see UIRESUME)
uiwait(handles.ma_InsertLanding);

function populateGUIWithEvent(handles, event)
    set(handles.titleLabel, 'String', 'Edit Landing');
    set(handles.ma_InsertLanding, 'Name', 'Edit Landing');
    set(handles.landingNameText, 'String', event.name);

    colorStr = getStringFromLineSpecColor(event.lineColor);
    colorValue = findValueFromComboBox(colorStr, handles.coastLineColorCombo);
    set(handles.coastLineColorCombo,'value',colorValue);
    
    styleStr = getLineStyleFromString(event.lineStyle);
    styleValue = findValueFromComboBox(styleStr, handles.landingLineStyleCombo);
 	set(handles.landingLineStyleCombo,'Value',styleValue);
    
    contents = handles.lineWidthCombo.String;
    contentsDouble = str2double(contents);
    ind = find(contentsDouble == event.lineWidth);
    set(handles.lineWidthCombo,'Value',ind);

    landingDuration = event.landingDuration;
    set(handles.landedDurationText, 'String', fullAccNum2Str(landingDuration));
    
    set(handles.massLossCheckbox,'Value',event.massloss.use);
    massLossCheckbox_Callback(handles.massLossCheckbox, [], handles);    

% --- Outputs from this function are returned to the command line.
function varargout = ma_InsertLandingGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        name = get(handles.landingNameText, 'String');
        
        contents = cellstr(get(handles.coastLineColorCombo,'String'));
        colorStr = contents{get(handles.coastLineColorCombo,'Value')};
        lineSpecColor = getLineSpecColorFromString(colorStr);
        
        contents = cellstr(get(handles.landingLineStyleCombo,'String'));
        lineStyleStr = contents{get(handles.landingLineStyleCombo,'Value')};
        lineStyle = getLineStyleStrFromText(lineStyleStr);
               
        contents = handles.lineWidthCombo.String;
        contentsDouble = str2double(contents);
        contensInd = get(handles.lineWidthCombo,'Value');
        lineWidth = contentsDouble(contensInd);
        
        landingDuration = str2double(get(handles.landedDurationText,'String'));
        
        massLoss = struct('use',logical(get(handles.massLossCheckbox,'Value')), 'lossConvert',getappdata(handles.ma_InsertLanding,'lossConverts'));
        
        varargout{1} = ma_createLanding(name, landingDuration, lineSpecColor, lineStyle, lineWidth, massLoss);
        close(handles.ma_InsertLanding);
    end
    
function landingNameText_Callback(hObject, eventdata, handles)
% hObject    handle to landingNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of landingNameText as text
%        str2double(get(hObject,'String')) returns contents of landingNameText as a double


% --- Executes during object creation, after setting all properties.
function landingNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to landingNameText (see GCBO)
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
        uiresume(handles.ma_InsertLanding);
    else
        msgbox(errMsg,'Errors were found while inserting a landing event.','error');
    end  

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.ma_InsertLanding);

function landedDurationText_Callback(hObject, eventdata, handles)
% hObject    handle to landedDurationText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of landedDurationText as text
%        str2double(get(hObject,'String')) returns contents of landedDurationText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function landedDurationText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to landedDurationText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
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
    event = get(handles.ma_InsertLanding,'UserData');
    eventLossConvert = getappdata(handles.ma_InsertLanding,'lossConverts');
    if(~isempty(event) && isstruct(eventLossConvert) && ~isequal(eventLossConvert, getDefaultLossConvert(handles)))
        lossConverts = ma_MassLossesConversionsGUI(handles.ma_MainGUI, eventLossConvert);
    else
        lossConverts = ma_MassLossesConversionsGUI(handles.ma_MainGUI);
    end
    
    if(~isempty(lossConverts))
        setappdata(handles.ma_InsertLanding,'lossConverts',lossConverts);
    end
    
    setEditLossConvertButtonTooltipString(handles);
    
function setEditLossConvertButtonTooltipString(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    names = maData.spacecraft.propellant.names;
    
	lossConverts = getappdata(handles.ma_InsertLanding,'lossConverts');
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
    
    revs = str2double(get(handles.landedDurationText,'String'));
    enteredStr = get(handles.landedDurationText,'String');
    numberName = 'Landing Duration';
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


% --- Executes on key release with focus on ma_InsertLanding or any of its controls.
function ma_InsertLanding_WindowKeyReleaseFcn(hObject, eventdata, handles)
% hObject    handle to ma_InsertLanding (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_InsertLanding);
    end


% --- Executes on selection change in landingLineStyleCombo.
function landingLineStyleCombo_Callback(hObject, eventdata, handles)
% hObject    handle to landingLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns landingLineStyleCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from landingLineStyleCombo


% --- Executes during object creation, after setting all properties.
function landingLineStyleCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to landingLineStyleCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lineWidthCombo.
function lineWidthCombo_Callback(hObject, eventdata, handles)
% hObject    handle to lineWidthCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lineWidthCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lineWidthCombo


% --- Executes during object creation, after setting all properties.
function lineWidthCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lineWidthCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
