function varargout = ma_OtherSpacecraftGUI(varargin)
% MA_OTHERSPACECRAFTGUI MATLAB code for ma_OtherSpacecraftGUI.fig
%      MA_OTHERSPACECRAFTGUI, by itself, creates a new MA_OTHERSPACECRAFTGUI or raises the existing
%      singleton*.
%
%      H = MA_OTHERSPACECRAFTGUI returns the handle to a new MA_OTHERSPACECRAFTGUI or the handle to
%      the existing singleton*.
%
%      MA_OTHERSPACECRAFTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_OTHERSPACECRAFTGUI.M with the given input arguments.
%
%      MA_OTHERSPACECRAFTGUI('Property','Value',...) creates a new MA_OTHERSPACECRAFTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_OtherSpacecraftGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_OtherSpacecraftGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_OtherSpacecraftGUI

% Last Modified by GUIDE v2.5 01-Jul-2015 17:13:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_OtherSpacecraftGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_OtherSpacecraftGUI_OutputFcn, ...
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


% --- Executes just before ma_OtherSpacecraftGUI is made visible.
function ma_OtherSpacecraftGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_OtherSpacecraftGUI (see VARARGIN)

% Choose default command line output for ma_OtherSpacecraftGUI
handles.output = hObject;
handles.ma_MainGUI = varargin{1};
handles.ksptotMainGUI = varargin{2};

populateBodiesCombo(handles, handles.centralBodyCombo);
bodyComboValue = findValueFromComboBox('Kerbin', handles.centralBodyCombo);
if(isempty(bodyComboValue))
    bodyComboValue = 1;
end
set(handles.centralBodyCombo,'Value',bodyComboValue);

setupGUI(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ma_OtherSpacecraftGUI wait for user response (see UIRESUME)
uiwait(handles.ma_OtherSpacecraftGUI);


function setupGUI(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    if(~isfield(maData.spacecraft,'otherSC'))
        maData.spacecraft.otherSC = cell(0,1);
        setappdata(handles.ma_MainGUI,'ma_data',maData);
    end
    
    if(isempty(maData.spacecraft.otherSC))
        set(handles.otherSCListbox,'String','');
        updateOSCListbox(handles);
    else
        oSCValue = get(handles.otherSCListbox,'Value');
        oSC = maData.spacecraft.otherSC{oSCValue};
        
        populateSpacecraft(handles,oSC);
        updateOSCListbox(handles);
        otherSCListbox_Callback(handles.otherSCListbox, [], handles);
    end
    
    
function populateSpacecraft(handles,oSC)
    set(handles.scNameText,'String',oSC.name);

    set(handles.epochText,'String',num2str(oSC.epoch));
    set(handles.smaText,'String',num2str(oSC.sma));
    set(handles.eccText,'String',num2str(oSC.ecc));
    set(handles.incText,'String',num2str(oSC.inc));
    set(handles.raanText,'String',num2str((oSC.raan)));
    set(handles.argText,'String',num2str(oSC.arg));
    set(handles.truText,'String',num2str(rad2deg(computeTrueAnomFromMean(deg2rad(oSC.mean), oSC.ecc))));
    set(handles.maxCommRangeText,'String',num2str(oSC.maxCommRange));
	
    bodyComboValue = findValueFromComboBox(oSC.parent, handles.centralBodyCombo);
    if(isempty(bodyComboValue))
        bodyComboValue = 1;
    end
    set(handles.centralBodyCombo,'Value',bodyComboValue);
    
    colorComboStr = getStringFromLineSpecColor(oSC.color);
	value = findValueFromComboBox(colorComboStr, handles.otherSCColor);
    set(handles.otherSCColor,'Value',value);
    
    if(isfield(oSC,'linestyle'))
        lineStyle = getLineStyleFromString(oSC.linestyle);
        
        value = findValueFromComboBox(lineStyle, handles.otherSCLineStyle);
        set(handles.otherSCLineStyle,'Value',value);
    else
        set(handles.otherSCLineStyle,'Value',2);
    end
        


% --- Outputs from this function are returned to the command line.
function varargout = ma_OtherSpacecraftGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    varargout{1} = [];


% --- Executes on selection change in otherSCListbox.
function otherSCListbox_Callback(hObject, eventdata, handles)
% hObject    handle to otherSCListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns otherSCListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from otherSCListbox
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    otherSC = maData.spacecraft.otherSC;
    oSCValue = get(handles.otherSCListbox,'Value');
    
    if(~isempty(otherSC) && ~isempty(oSCValue))
        oSC = otherSC{oSCValue};
        populateSpacecraft(handles,oSC);
        
        if(strcmpi(get(handles.ma_OtherSpacecraftGUI,'SelectionType'),'open'))
            celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
            bodyInfo = getBodyInfoByNumber(oSC.parentID, celBodyData);
            tru = computeTrueAnomFromMean(deg2rad(oSC.mean), oSC.ecc);
            [rVect,vVect]=getStatefromKepler(oSC.sma, oSC.ecc, deg2rad(oSC.inc), deg2rad(oSC.raan), deg2rad(oSC.arg), tru, bodyInfo.gm);
            
            UT = oSC.epoch;
            
            rX = rVect(1);
            rY = rVect(2);
            rZ = rVect(3);
            
            vX = vVect(1);
            vY = vVect(2);
            vZ = vVect(3);
            
            state = [UT, rX, rY, rZ, vX, vY, vZ, oSC.parentID, 0 0 0 0 1];
            viewSpacecraftStatePopupGUI(handles.ma_MainGUI, state, 1);
        end
    end

% --- Executes during object creation, after setting all properties.
function otherSCListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to otherSCListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in updateSCButton.
function updateSCButton_Callback(hObject, eventdata, handles)
% hObject    handle to updateSCButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    if(~isempty(errMsg))
        msgbox(errMsg,'Errors were found while updating a spacecraft.','error');
        return;
    end

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    if(isempty(get(handles.otherSCListbox,'String')))
        return;
    end
    oscLBValue = get(handles.otherSCListbox,'Value');
    
    oldOtherSC = maData.spacecraft.otherSC{oscLBValue};
    oldID = oldOtherSC.id;
    
    ecc = str2double(get(handles.eccText,'String'));
    tru = deg2rad(str2double(get(handles.truText,'String')));
    mean = rad2deg(computeMeanFromTrueAnom(tru, ecc));
    
    contents = cellstr(get(handles.otherSCColor,'String'));
    oSCColorStr = contents{get(handles.otherSCColor,'Value')};
    oscColor = getLineSpecColorFromString(oSCColorStr);  
    
    contents = cellstr(get(handles.otherSCLineStyle,'String'));
	oscLineStyle = contents{get(handles.otherSCLineStyle,'Value')};
    lineStyle = getLineStyleStrFromText(oscLineStyle);
%     switch oscLineStyle
%         case 'Solid Line'
%             lineStyle = '-';
%         case 'Dashed Line'
%             lineStyle = '--';
%         case 'Dotted Line'
%             lineStyle = ':';
%         case 'Dashed-dot Line'
%             lineStyle = '-.';
%         otherwise
%             lineStyle = '--';
%     end
    
    otherSC = struct();
    
    otherSC.name = get(handles.scNameText,'String');
    
    otherSC.epoch = str2double(get(handles.epochText,'String'));
    otherSC.sma = str2double(get(handles.smaText,'String'));
    otherSC.ecc = ecc;
    otherSC.inc = str2double(get(handles.incText,'String'));
    otherSC.raan = str2double(get(handles.raanText,'String'));
    otherSC.arg = str2double(get(handles.argText,'String'));
    otherSC.mean = mean;
    otherSC.maxCommRange = str2double(get(handles.maxCommRangeText,'String'));

    contents = cellstr(get(handles.centralBodyCombo,'String'));
    cbName = strtrim(contents{get(handles.centralBodyCombo,'Value')});
    bodyInfo = celBodyData.(strtrim(lower(cbName)));
    otherSC.parent = cbName;
    otherSC.parentID = bodyInfo.id;
    
    otherSC.id = oldID;
    otherSC.color = oscColor;
    otherSC.linestyle = lineStyle;
    
    maData.spacecraft.otherSC{oscLBValue} = otherSC;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
    
    updateOSCListbox(handles);
    
    

% --- Executes on button press in addSCButton.
function addSCButton_Callback(hObject, eventdata, handles)
% hObject    handle to addSCButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    oscColor = 'r';
    lineStyle = '-';
    
    otherSC = struct();
    
    otherSC.name = 'New Spacecraft';
    
    otherSC.epoch = 0.0;
    otherSC.sma = 7000;
    otherSC.ecc = 0.0;
    otherSC.inc = 0.0;
    otherSC.raan = 0.0;
    otherSC.arg = 0.0;
    otherSC.mean = 0.0;
    otherSC.maxCommRange = Inf;

    contents = cellstr(get(handles.centralBodyCombo,'String'));
    cbName = contents{1};
    bodyInfo = celBodyData.(strtrim(lower(cbName)));
    otherSC.parent = cbName;
    otherSC.parentID = bodyInfo.id;

    otherSC.id = rand();
    otherSC.color = oscColor;
    otherSC.linestyle = lineStyle;
    
    maData.spacecraft.otherSC{end+1} = otherSC;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
       
    updateOSCListbox(handles);
    set(handles.otherSCListbox,'Value',length(maData.spacecraft.otherSC));
    otherSCListbox_Callback(handles.otherSCListbox, [], handles);
    
    
function updateOSCListbox(handles)
	maData = getappdata(handles.ma_MainGUI,'ma_data');
    
    if(isempty(maData.spacecraft.otherSC))
        enableUI('off', maData, handles);
    else
        enableUI('on', maData, handles);
    end
    
    otherSC = maData.spacecraft.otherSC;
    otherSCStr = cell(0,1);
    for(i=1:length(otherSC)) %#ok<*NO4LP>
        otherSCStr{end+1} = otherSC{i}.name; %#ok<AGROW>
    end
    
    if(isempty(otherSC))
        enableUI('off', maData, handles)
    else
        enableUI('on', maData, handles)
    end
    
	if(isempty(get(handles.otherSCListbox,'Value')))
        set(handles.otherSCListbox,'Value',1);
    elseif(get(handles.otherSCListbox,'Value') > length(otherSC))
        set(handles.otherSCListbox,'Value',length(otherSC));
    elseif(get(handles.otherSCListbox,'Value') == 0 && ~isempty(otherSC))
        set(handles.otherSCListbox,'Value',1);
	end
    
    set(handles.otherSCListbox,'String',otherSCStr);
    
% --- Executes on button press in removeSCButton.
function removeSCButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeSCButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    oSCValue = get(handles.otherSCListbox,'Value');
    
    otherSC = maData.spacecraft.otherSC;
    
    script = maData.script;
    for(i=1:length(script))
        event = script{i};
        
        if(strcmpi(event.type,'Docking'))
            if(event.oScId == otherSC{oSCValue}.id)
                warnstr = sprintf('Cannot delete other spacecraft "%s".  This spacecraft is in use by event %u "%s".', otherSC{oSCValue}.name, i, event.name);
                warndlg(warnstr,'Cannot Delete Spacecraft', 'modal');
                
                return;
            end
        end
    end
    
    otherSC(oSCValue) = [];
    maData.spacecraft.otherSC = otherSC;
    setappdata(handles.ma_MainGUI,'ma_data',maData);
   
    updateOSCListbox(handles);
    otherSCListbox_Callback(handles.otherSCListbox, [], handles);
    
    
function enableUI(enable, maData, handles)
    set(handles.otherSCListbox,'Enable',enable)
    set(handles.scNameText,'Enable',enable)
    set(handles.otherSCColor,'Enable',enable)
    set(handles.otherSCLineStyle,'Enable',enable)
    set(handles.centralBodyCombo,'Enable',enable)
    set(handles.epochText,'Enable',enable)
    set(handles.smaText,'Enable',enable)
    set(handles.eccText,'Enable',enable)
    set(handles.incText,'Enable',enable)
    set(handles.raanText,'Enable',enable)
    set(handles.scNameText,'Enable',enable)
    set(handles.argText,'Enable',enable)
    set(handles.truText,'Enable',enable)
    set(handles.maxCommRangeText,'Enable',enable)
    
	if(isempty(maData.spacecraft.otherSC))
        set(handles.removeSCButton,'Enable','off')
    else
        set(handles.removeSCButton,'Enable','on')
	end
    

function scNameText_Callback(hObject, eventdata, handles)
% hObject    handle to scNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of scNameText as text
%        str2double(get(hObject,'String')) returns contents of scNameText as a double
    updateSCButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function scNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in centralBodyCombo.
function centralBodyCombo_Callback(hObject, eventdata, handles)
% hObject    handle to centralBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns centralBodyCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from centralBodyCombo
    updateSCButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function centralBodyCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to centralBodyCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function epochText_Callback(hObject, eventdata, handles)
% hObject    handle to epochText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of epochText as text
%        str2double(get(hObject,'String')) returns contents of epochText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    updateSCButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function epochText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to epochText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function smaText_Callback(hObject, eventdata, handles)
% hObject    handle to smaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of smaText as text
%        str2double(get(hObject,'String')) returns contents of smaText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    updateSCButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function smaText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eccText_Callback(hObject, eventdata, handles)
% hObject    handle to eccText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eccText as text
%        str2double(get(hObject,'String')) returns contents of eccText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    updateSCButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function eccText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eccText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function incText_Callback(hObject, eventdata, handles)
% hObject    handle to incText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of incText as text
%        str2double(get(hObject,'String')) returns contents of incText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    updateSCButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function incText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to incText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function raanText_Callback(hObject, eventdata, handles)
% hObject    handle to raanText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of raanText as text
%        str2double(get(hObject,'String')) returns contents of raanText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    updateSCButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function raanText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to raanText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function argText_Callback(hObject, eventdata, handles)
% hObject    handle to argText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of argText as text
%        str2double(get(hObject,'String')) returns contents of argText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    updateSCButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function argText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to argText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function truText_Callback(hObject, eventdata, handles)
% hObject    handle to truText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of truText as text
%        str2double(get(hObject,'String')) returns contents of truText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    updateSCButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function truText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to truText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function errMsg = validateInputs(handles)
    errMsg = {};

    eEcc = str2double(get(handles.eccText,'String'));
    enteredStr = get(handles.eccText,'String');
    numberName = 'Orbit Eccentricity';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(eEcc, numberName, lb, ub, isInt, errMsg, enteredStr);

    if(not(isempty(errMsg))) 
        msgbox(errMsg,'Errors were found while creating the spacecraft orbit.','error');
        return;
    end

    epoch = str2double(get(handles.epochText,'String'));
    enteredStr = get(handles.epochText,'String');
    numberName = 'Orbit Epoch';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(epoch, numberName, lb, ub, isInt, errMsg, enteredStr);

    eSMA = str2double(get(handles.smaText,'String'));
    enteredStr = get(handles.smaText,'String');
    if(eEcc < 1.0)
        lb = 1;
        ub = Inf;
        numberName = 'Eccentric Orbit Semi-Major Axis';
    else
        lb = -Inf;
        ub = -1;
        numberName = 'Hyperbolic Orbit Semi-Major Axis';
    end
    isInt = false;
    errMsg = validateNumber(eSMA, numberName, lb, ub, isInt, errMsg, enteredStr);

    eInc = str2double(get(handles.incText,'String'));
    enteredStr = get(handles.incText,'String');
    numberName = 'Orbit Inclination';
    lb = 0;
    ub = 180;
    isInt = false;
    errMsg = validateNumber(eInc, numberName, lb, ub, isInt, errMsg, enteredStr);

    eRAAN = str2double(get(handles.raanText,'String'));
    enteredStr = get(handles.raanText,'String');
    numberName = 'Orbit RAAN';
    lb = 0;
    ub = 360;
    isInt = false;
    errMsg = validateNumber(eRAAN, numberName, lb, ub, isInt, errMsg, enteredStr);

    eArg = str2double(get(handles.argText,'String'));
    enteredStr = get(handles.argText,'String');
    numberName = 'Orbit Argument of Periapse';
    lb = 0;
    ub = 360;
    isInt = false;
    errMsg = validateNumber(eArg, numberName, lb, ub, isInt, errMsg, enteredStr);

    eTru = str2double(get(handles.truText,'String'));
    enteredStr = get(handles.truText,'String');
    numberName = 'Orbit True Anomaly';
    lb = -180;
    ub = 360;
    isInt = false;
    errMsg = validateNumber(eTru, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    maxCommRange = str2double(get(handles.maxCommRangeText,'String'));
    enteredStr = get(handles.maxCommRangeText,'String');
    numberName = 'Max Comm. Range';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(maxCommRange, numberName, lb, ub, isInt, errMsg, enteredStr);
    

% --------------------------------------------------------------------
function getOrbitFromSFSFileContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromSFSFileContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [refBodyID, scName] = orbitPanelGetOrbitFromSFSContextCallBack(handles.ksptotMainGUI, handles.smaText, handles.eccText, handles.incText, handles.raanText, handles.argText, handles.truText, handles.epochText);
    tru = computeTrueAnomFromMean(deg2rad(str2double(get(handles.truText,'String'))), str2double(get(handles.eccText,'String')));
    set(handles.truText,'String',num2str(rad2deg(tru)));

    if(~isempty(refBodyID) && isnumeric(refBodyID))
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.centralBodyCombo);
        set(handles.centralBodyCombo,'Value',value);
        
        updateSCButton_Callback([], [], handles);
    end
    
    if(~isempty(scName))
        set(handles.scNameText,'String',scName);
    end

% --------------------------------------------------------------------
function getOrbitFromKSPTOTConnectContextMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromKSPTOTConnectContextMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [refBodyID, scName] = orbitPanelGetOrbitFromKSPTOTConnectCallBack(handles.smaText, handles.eccText, handles.incText, handles.raanText, handles.argText, handles.truText, handles.epochText);
    tru = computeTrueAnomFromMean(deg2rad(str2double(get(handles.truText,'String'))), str2double(get(handles.eccText,'String')));
    set(handles.truText,'String',num2str(rad2deg(tru)));
    
    if(~isempty(refBodyID) && isnumeric(refBodyID))
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.centralBodyCombo);
        set(handles.centralBodyCombo,'Value',value);
        
        updateSCButton_Callback([], [], handles);
    end
    
    if(~isempty(scName))
        set(handles.scNameText,'String',scName);
    end

% --- Executes on selection change in otherSCColor.
function otherSCColor_Callback(hObject, eventdata, handles)
% hObject    handle to otherSCColor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns otherSCColor contents as cell array
%        contents{get(hObject,'Value')} returns selected item from otherSCColor
    updateSCButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function otherSCColor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to otherSCColor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function copyOrbitToClipboardMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyOrbitToClipboardMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    oscLBValue = get(handles.otherSCListbox,'Value');
    oldOtherSC = maData.spacecraft.otherSC{oscLBValue};

    copyOrbitToClipboardFromText(handles.epochText, handles.smaText, handles.eccText, ...
                                 handles.incText, handles.raanText, handles.argText, ...
                                 handles.truText, true, oldOtherSC.parentID);

% --------------------------------------------------------------------
function pasteOrbitFromClipboardMenu_Callback(hObject, eventdata, handles)
% hObject    handle to pasteOrbitFromClipboardMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    pasteOrbitFromClipboard(handles.epochText, handles.smaText, handles.eccText, ...
                                 handles.incText, handles.raanText, handles.argText, ...
                                 handles.truText, true, handles.centralBodyCombo, celBodyData);
                             
    updateSCButton_Callback([], [], handles);


% --- Executes on key press with focus on ma_OtherSpacecraftGUI or any of its controls.
function ma_OtherSpacecraftGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_OtherSpacecraftGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_OtherSpacecraftGUI);
    end


% --- Executes on selection change in otherSCLineStyle.
function otherSCLineStyle_Callback(hObject, eventdata, handles)
% hObject    handle to otherSCLineStyle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns otherSCLineStyle contents as cell array
%        contents{get(hObject,'Value')} returns selected item from otherSCLineStyle
    updateSCButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function otherSCLineStyle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to otherSCLineStyle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function getOrbitFromKSPActiveVesselMenu_Callback(hObject, eventdata, handles)
% hObject    handle to getOrbitFromKSPActiveVesselMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [refBodyID, scName] = orbitPanelGetOrbitFromKSPTOTConnectActiveVesselCallBack(handles.smaText, handles.eccText, handles.incText, handles.raanText, handles.argText, handles.truText, handles.epochText);
    tru = computeTrueAnomFromMean(deg2rad(str2double(get(handles.truText,'String'))), str2double(get(handles.eccText,'String')));
    set(handles.truText,'String',fullAccNum2Str(rad2deg(tru)));
    
    if(~isempty(refBodyID) && isnumeric(refBodyID))
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        bodyInfo = getBodyInfoByNumber(refBodyID, celBodyData);
        value = findValueFromComboBox(bodyInfo.name, handles.centralBodyCombo);
        set(handles.centralBodyCombo,'Value',value);
        
        updateSCButton_Callback([], [], handles);
    end
    
    if(~isempty(scName))
        set(handles.scNameText,'String',scName);
    end



function maxCommRangeText_Callback(hObject, eventdata, handles)
% hObject    handle to maxCommRangeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxCommRangeText as text
%        str2double(get(hObject,'String')) returns contents of maxCommRangeText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    updateSCButton_Callback([], [], handles);

% --- Executes during object creation, after setting all properties.
function maxCommRangeText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxCommRangeText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
