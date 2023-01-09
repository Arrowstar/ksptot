function varargout = lvd_AddDeltaVActionGUI(varargin)
% LVD_ADDDELTAVACTIONGUI MATLAB code for lvd_AddDeltaVActionGUI.fig
%      LVD_ADDDELTAVACTIONGUI, by itself, creates a new LVD_ADDDELTAVACTIONGUI or raises the existing
%      singleton*.
%
%      H = LVD_ADDDELTAVACTIONGUI returns the handle to a new LVD_ADDDELTAVACTIONGUI or the handle to
%      the existing singleton*.
%
%      LVD_ADDDELTAVACTIONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_ADDDELTAVACTIONGUI.M with the given input arguments.
%
%      LVD_ADDDELTAVACTIONGUI('Property','Value',...) creates a new LVD_ADDDELTAVACTIONGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_AddDeltaVActionGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_AddDeltaVActionGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_AddDeltaVActionGUI

% Last Modified by GUIDE v2.5 15-Dec-2019 15:55:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_AddDeltaVActionGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_AddDeltaVActionGUI_OutputFcn, ...
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


% --- Executes just before lvd_AddDeltaVActionGUI is made visible.
function lvd_AddDeltaVActionGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_AddDeltaVActionGUI (see VARARGIN)

    % Choose default command line output for lvd_AddDeltaVActionGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);

    action = varargin{1};
    setappdata(hObject, 'action', action);
    
    lvdData = varargin{2};
    setappdata(hObject, 'lvdData', lvdData);
    
	populateGUI(handles, action, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_AddDeltaVActionGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_AddDeltaVActionGUI);

function populateGUI(handles, action, lvdData)
    handles.dvFrameCombo.String = DeltaVFrameEnum.getListBoxStr();
    handles.dvFrameCombo.Value = DeltaVFrameEnum.getIndForName(action.frame.nameStr);
    
    handles.dvXCompText.String = fullAccNum2Str(action.deltaVVect(1)*1000);
    handles.dvYCompText.String = fullAccNum2Str(action.deltaVVect(2)*1000);
    handles.dvZCompText.String = fullAccNum2Str(action.deltaVVect(3)*1000);
    
    optVar = action.optVar;
	if(isempty(optVar))
        optVar = AddDeltaVActionVariable(action);
	end
    
    tf = optVar.getUseTfForVariable();
    handles.optCheckbox1.Value = double(tf(1));
    handles.optCheckbox2.Value = double(tf(2));
    handles.optCheckbox3.Value = double(tf(3));
    
    [lb, ub] = optVar.getAllBndsForVariable();
    lb = lb * 1000;
    ub = ub * 1000;
    
    handles.lbText1.String = fullAccNum2Str(lb(1));
    handles.ubText1.String = fullAccNum2Str(ub(1));
    
    handles.lbText2.String = fullAccNum2Str(lb(2));
    handles.ubText2.String = fullAccNum2Str(ub(2));
    
    handles.lbText3.String = fullAccNum2Str(lb(3));
    handles.ubText3.String = fullAccNum2Str(ub(3));
    
    dvFrameCombo_Callback(handles.dvFrameCombo, [], handles);
    optCheckbox1_Callback(handles.optCheckbox1, [], handles);
    optCheckbox2_Callback(handles.optCheckbox2, [], handles);
    optCheckbox3_Callback(handles.optCheckbox3, [], handles);
    
    handles.subtractMassCheckbox.Value = double(action.useDeltaMass);

% --- Outputs from this function are returned to the command line.
function varargout = lvd_AddDeltaVActionGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        action = getappdata(handles.lvd_AddDeltaVActionGUI, 'action');
        lvdData = getappdata(handles.lvd_AddDeltaVActionGUI, 'lvdData');
        
        dvVect = [str2double(handles.dvXCompText.String);
                  str2double(handles.dvYCompText.String);
                  str2double(handles.dvZCompText.String)]/1000; %store as km/s
        
        action.deltaVVect = dvVect;
        
        contents = cellstr(get(handles.dvFrameCombo,'String'));
        frameEnum = DeltaVFrameEnum.getEnumForListboxStr(contents{get(handles.dvFrameCombo,'Value')});
        action.frame = frameEnum;
        
        action.useDeltaMass = logical(handles.subtractMassCheckbox.Value);
        
        optVar = action.optVar;
        if(not(isempty(optVar))) %need to remove existing var if it exists
            lvdData.optimizer.vars.removeVariable(optVar);
        end
                
        %Set Opt T/F
        useTf = [get(handles.optCheckbox1,'Value'), ...
                 get(handles.optCheckbox2,'Value'), ...
                 get(handles.optCheckbox3,'Value')];
        
%         if(isempty(optVar))
%             optVar = AddDeltaVActionVariable(action);
%         end
        optVar = action.optVar;
        if(not(isempty(optVar)))
            lvdData.optimizer.vars.removeVariable(optVar);
        end
        optVar = AddDeltaVActionVariable(action);
        
        optVar.setUseTfForVariable(useTf);
        
        %Bnds
        lb = [str2double(get(handles.lbText1,'String')), ...
              str2double(get(handles.lbText2,'String')), ...
              str2double(get(handles.lbText3,'String'))]/1000; %store as km/s
        
        ub = [str2double(get(handles.ubText1,'String')), ...
              str2double(get(handles.ubText2,'String')), ...
              str2double(get(handles.ubText3,'String'))]/1000; %store as km/s
        
        optVar.setUseTfForVariable(true(size(lb))); %need this to get the full lb/set in there
        optVar.setBndsForVariable(lb, ub);
        optVar.setUseTfForVariable(useTf);
               
        lvdData.optimizer.vars.addVariable(optVar);
        
        varargout{1} = true;
        close(handles.lvd_AddDeltaVActionGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);
    
    if(isempty(errMsg))
        uiresume(handles.lvd_AddDeltaVActionGUI);
    else
        msgbox(errMsg,'Invalid Delta-V Inputs','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    contents = cellstr(get(handles.dvFrameCombo,'String'));
    compNames = DeltaVFrameEnum.getEnumForListboxStr(contents{get(handles.dvFrameCombo,'Value')}).compNames;
    
    %Component 1
    val = str2double(get(handles.dvXCompText,'String'));
    enteredStr = get(handles.dvXCompText,'String');
    numberName = sprintf('Delta-V: %s', compNames{1});
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    lwrBnd = str2double(get(handles.lbText1,'String'));
    enteredStr = get(handles.lbText1,'String');
    numberName = sprintf('Delta-V: %s (Lower Bound)', compNames{1});
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(lwrBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    uprBnd = str2double(get(handles.ubText1,'String'));
    enteredStr = get(handles.ubText1,'String');
    numberName = sprintf('Delta-V: %s (Upper Bound)', compNames{1});
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(uprBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        uprBnd = str2double(get(handles.ubText1,'String'));
        enteredStr = get(handles.ubText1,'String');
        numberName = sprintf('Delta-V: %s (Upper Bound)', compNames{1});
        lb = lwrBnd;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(uprBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    end
    
    %Component 2
    val = str2double(get(handles.dvYCompText,'String'));
    enteredStr = get(handles.dvYCompText,'String');
    numberName = sprintf('Delta-V: %s', compNames{2});
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    lwrBnd = str2double(get(handles.lbText2,'String'));
    enteredStr = get(handles.lbText2,'String');
    numberName = sprintf('Delta-V: %s (Lower Bound)', compNames{2});
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(lwrBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    uprBnd = str2double(get(handles.ubText2,'String'));
    enteredStr = get(handles.ubText2,'String');
    numberName = sprintf('Delta-V: %s (Upper Bound)', compNames{2});
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(uprBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        uprBnd = str2double(get(handles.ubText2,'String'));
        enteredStr = get(handles.ubText2,'String');
        numberName = sprintf('Delta-V: %s (Upper Bound)', compNames{2});
        lb = lwrBnd;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(uprBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    end
    
    %Component 3
    val = str2double(get(handles.dvZCompText,'String'));
    enteredStr = get(handles.dvZCompText,'String');
    numberName = sprintf('Delta-V: %s', compNames{3});
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(val, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    lwrBnd = str2double(get(handles.lbText3,'String'));
    enteredStr = get(handles.lbText3,'String');
    numberName = sprintf('Delta-V: %s (Lower Bound)', compNames{3});
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(lwrBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    uprBnd = str2double(get(handles.ubText3,'String'));
    enteredStr = get(handles.ubText3,'String');
    numberName = sprintf('Delta-V: %s (Upper Bound)', compNames{3});
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(uprBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        uprBnd = str2double(get(handles.ubText3,'String'));
        enteredStr = get(handles.ubText3,'String');
        numberName = sprintf('Delta-V: %s (Upper Bound)', compNames{3});
        lb = lwrBnd;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(uprBnd, numberName, lb, ub, isInt, errMsg, enteredStr);
    end
    

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_AddDeltaVActionGUI);



function dvXCompText_Callback(hObject, eventdata, handles)
% hObject    handle to dvXCompText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dvXCompText as text
%        str2double(get(hObject,'String')) returns contents of dvXCompText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function dvXCompText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dvXCompText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on selection change in dvFrameCombo.
function dvFrameCombo_Callback(hObject, eventdata, handles)
% hObject    handle to dvFrameCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns dvFrameCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from dvFrameCombo
    contents = cellstr(get(hObject,'String'));
    compNames = DeltaVFrameEnum.getEnumForListboxStr(contents{get(hObject,'Value')}).compNames;
    
    handles.xCompLabel.String = compNames{1};
    handles.yCompLabel.String = compNames{2};
    handles.zCompLabel.String = compNames{3};

% --- Executes during object creation, after setting all properties.
function dvFrameCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dvFrameCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in optCheckbox1.
function optCheckbox1_Callback(hObject, eventdata, handles)
% hObject    handle to optCheckbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optCheckbox1
    if(get(hObject,'Value'))
        handles.lbText1.Enable = 'on';
        handles.ubText1.Enable = 'on';
    else
        handles.lbText1.Enable = 'off';
        handles.ubText1.Enable = 'off';
    end


function lbText1_Callback(hObject, eventdata, handles)
% hObject    handle to lbText1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lbText1 as text
%        str2double(get(hObject,'String')) returns contents of lbText1 as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function lbText1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbText1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ubText1_Callback(hObject, eventdata, handles)
% hObject    handle to ubText1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ubText1 as text
%        str2double(get(hObject,'String')) returns contents of ubText1 as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function ubText1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ubText1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function dvYCompText_Callback(hObject, eventdata, handles)
% hObject    handle to dvYCompText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dvYCompText as text
%        str2double(get(hObject,'String')) returns contents of dvYCompText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function dvYCompText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dvYCompText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in optCheckbox2.
function optCheckbox2_Callback(hObject, eventdata, handles)
% hObject    handle to optCheckbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optCheckbox2
    if(get(hObject,'Value'))
        handles.lbText2.Enable = 'on';
        handles.ubText2.Enable = 'on';
    else
        handles.lbText2.Enable = 'off';
        handles.ubText2.Enable = 'off';
    end



function lbText2_Callback(hObject, eventdata, handles)
% hObject    handle to lbText2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lbText2 as text
%        str2double(get(hObject,'String')) returns contents of lbText2 as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function lbText2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbText2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ubText2_Callback(hObject, eventdata, handles)
% hObject    handle to ubText2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ubText2 as text
%        str2double(get(hObject,'String')) returns contents of ubText2 as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function ubText2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ubText2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dvZCompText_Callback(hObject, eventdata, handles)
% hObject    handle to dvZCompText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dvZCompText as text
%        str2double(get(hObject,'String')) returns contents of dvZCompText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function dvZCompText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dvZCompText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in optCheckbox3.
function optCheckbox3_Callback(hObject, eventdata, handles)
% hObject    handle to optCheckbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of optCheckbox3
    if(get(hObject,'Value'))
        handles.lbText3.Enable = 'on';
        handles.ubText3.Enable = 'on';
    else
        handles.lbText3.Enable = 'off';
        handles.ubText3.Enable = 'off';
    end



function lbText3_Callback(hObject, eventdata, handles)
% hObject    handle to lbText3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lbText3 as text
%        str2double(get(hObject,'String')) returns contents of lbText3 as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function lbText3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbText3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ubText3_Callback(hObject, eventdata, handles)
% hObject    handle to ubText3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ubText3 as text
%        str2double(get(hObject,'String')) returns contents of ubText3 as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function ubText3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ubText3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in subtractMassCheckbox.
function subtractMassCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to subtractMassCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of subtractMassCheckbox


% --- Executes on key press with focus on lvd_AddDeltaVActionGUI or any of its controls.
function lvd_AddDeltaVActionGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_AddDeltaVActionGUI (see GCBO)
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
            close(handles.lvd_AddDeltaVActionGUI);
    end
