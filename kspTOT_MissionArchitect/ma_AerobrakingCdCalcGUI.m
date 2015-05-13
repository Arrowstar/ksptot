function varargout = ma_AerobrakingCdCalcGUI(varargin)
% MA_AEROBRAKINGCDCALCGUI MATLAB code for ma_AerobrakingCdCalcGUI.fig
%      MA_AEROBRAKINGCDCALCGUI, by itself, creates a new MA_AEROBRAKINGCDCALCGUI or raises the existing
%      singleton*.
%
%      H = MA_AEROBRAKINGCDCALCGUI returns the handle to a new MA_AEROBRAKINGCDCALCGUI or the handle to
%      the existing singleton*.
%
%      MA_AEROBRAKINGCDCALCGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_AEROBRAKINGCDCALCGUI.M with the given input arguments.
%
%      MA_AEROBRAKINGCDCALCGUI('Property','Value',...) creates a new MA_AEROBRAKINGCDCALCGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_AerobrakingCdCalcGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_AerobrakingCdCalcGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_AerobrakingCdCalcGUI

% Last Modified by GUIDE v2.5 30-Oct-2014 21:31:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_AerobrakingCdCalcGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_AerobrakingCdCalcGUI_OutputFcn, ...
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


% --- Executes just before ma_AerobrakingCdCalcGUI is made visible.
function ma_AerobrakingCdCalcGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_AerobrakingCdCalcGUI (see VARARGIN)

% Choose default command line output for ma_AerobrakingCdCalcGUI
handles.output = hObject;
handles.ma_MainGUI = varargin{1};

%GUI setup
populateBodiesCombo(handles, handles.bodiesCombo);
dragModelCombo_Callback(handles.dragModelCombo, [], handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ma_AerobrakingCdCalcGUI wait for user response (see UIRESUME)
% uiwait(handles.ma_AerobrakingCdCalcGUI);


function populateBodiesCombo(handles, hBodiesCombo)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    bodies = fields(celBodyData);
    
    bodiesStr = cell(length(bodies),1);
    for(i = 1:length(bodies)) %#ok<*NO4LP>
        body = bodies{i};
        bodiesStr{i} = celBodyData.(body).name;
    end
    
    set(hBodiesCombo, 'String', bodiesStr);
    if(length(bodiesStr) >= 5)
        set(hBodiesCombo, 'value', 5);
    elseif(length(bodiesStr) >= 1)
        set(hBodiesCombo, 'value', 1);
    end


% --- Outputs from this function are returned to the command line.
function varargout = ma_AerobrakingCdCalcGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in bodiesCombo.
function bodiesCombo_Callback(hObject, eventdata, handles)
% hObject    handle to bodiesCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns bodiesCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from bodiesCombo


% --- Executes during object creation, after setting all properties.
function bodiesCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bodiesCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function preAeroRpText_Callback(hObject, eventdata, handles)
% hObject    handle to preAeroSmaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of preAeroSmaText as text
%        str2double(get(hObject,'String')) returns contents of preAeroSmaText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function preAeroRpText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to preAeroSmaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function preAeroSmaText_Callback(hObject, eventdata, handles)
% hObject    handle to preAeroSmaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of preAeroSmaText as text
%        str2double(get(hObject,'String')) returns contents of preAeroSmaText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function preAeroSmaText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to preAeroSmaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function postAeroSmaText_Callback(hObject, eventdata, handles)
% hObject    handle to postAeroSmaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of postAeroSmaText as text
%        str2double(get(hObject,'String')) returns contents of postAeroSmaText as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function postAeroSmaText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to postAeroSmaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dragCoeffAnsText_Callback(hObject, eventdata, handles)
% hObject    handle to dragCoeffAnsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dragCoeffAnsText as text
%        str2double(get(hObject,'String')) returns contents of dragCoeffAnsText as a double


% --- Executes during object creation, after setting all properties.
function dragCoeffAnsText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dragCoeffAnsText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in calcCdButton.
function calcCdButton_Callback(hObject, eventdata, handles)
% hObject    handle to calcCdButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(handles.dragCoeffAnsText,'String','<Computing>'); drawnow;

    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        computeDragCoefficient(handles);
    else
        set(handles.dragCoeffAnsText,'String','');
        msgbox(errMsg,'Errors were found while computing the drag coefficient.','error');
    end

function errMsg = validateInputs(handles)
    errMsg = {};

    rawDouble = str2double(get(handles.preAeroRpText,'String'));
    enteredStr = get(handles.preAeroSmaText,'String');
    numberName = 'Pre-Aerobrake Periapsis Altitude';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(rawDouble, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    rawDouble = str2double(get(handles.preAeroSmaText,'String'));
    enteredStr = get(handles.preAeroSmaText,'String');
    numberName = 'Pre-Aerobrake Semi-major Axis';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(rawDouble, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    rawDouble = str2double(get(handles.postAeroSmaText,'String'));
    enteredStr = get(handles.postAeroSmaText,'String');
    numberName = 'Post-Aerobrake Semi-major Axis';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(rawDouble, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    rawDouble = str2double(get(handles.incText,'String'));
    enteredStr = get(handles.incText,'String');
    numberName = 'Orbital Inclination';
    lb = 0;
    ub = 180;
    isInt = false;
    errMsg = validateNumber(rawDouble, numberName, lb, ub, isInt, errMsg, enteredStr);

	contents = cellstr(get(handles.dragModelCombo,'String'));
	dragModel = contents{get(handles.dragModelCombo,'Value')};
    
    if(~strcmpi(dragModel,'Stock'))
        rawDouble = str2double(get(handles.preAeroMass,'String'));
        enteredStr = get(handles.preAeroMass,'String');
        numberName = 'Pre-Aerobraking Mass';
        lb = eps;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(rawDouble, numberName, lb, ub, isInt, errMsg, enteredStr);
    end
    
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    
    contents = cellstr(get(handles.bodiesCombo,'String'));
	selBody = contents{get(handles.bodiesCombo,'Value')};
    bodyInfo = celBodyData.(lower(selBody));
    
    preSMA = str2double(get(handles.preAeroSmaText,'String'));
    postSMA = str2double(get(handles.postAeroSmaText,'String'));
    
    preEnergy = -bodyInfo.gm/(2*preSMA);
    postEnergy = -bodyInfo.gm/(2*postSMA);
    if(postEnergy >= preEnergy)
        errMsg{end+1} = 'The entered post-aerobrake SMA does not represent a loss in orbital energy w.r.t. the pre-aerobrake SMA.  Your orbital energy must decrease through the aerobrake.';
    end
    
    preRpAlt = str2double(get(handles.preAeroRpText,'String'));
    if(preRpAlt >= bodyInfo.atmohgt)
        errMsg{end+1} = sprintf('Pre-Aerobrake Periapsis is located outside the atmosphere (%f km).  Lower the  pre-aerobrake periapsis altitude to below %f km and above 0 km.', bodyInfo.atmohgt, bodyInfo.atmohgt);
    end
    

function computeDragCoefficient(handles)
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');

    contents = cellstr(get(handles.dragModelCombo,'String'));
	dragModel = contents{get(handles.dragModelCombo,'Value')};
    
    contents = cellstr(get(handles.bodiesCombo,'String'));
	selBody = contents{get(handles.bodiesCombo,'Value')};
    bodyInfo = celBodyData.(lower(selBody));

    preRp = str2double(get(handles.preAeroRpText,'String')) + bodyInfo.radius;
    preSMA = str2double(get(handles.preAeroSmaText,'String'));
    postSMA = str2double(get(handles.postAeroSmaText,'String'));
    inc = deg2rad(str2double(get(handles.incText,'String')));
%     mass = 1000 * str2double(get(handles.preAeroMass,'String'));
    mass = str2double(get(handles.preAeroMass,'String'));

    preEcc = getEccFromRpAndSma(preSMA, preRp);   %we assume that Rp remains constant
%     postEcc = getEccFromRpAndSma(postSMA, preRp); %we assume that Rp remains constant
    
    raan = 0; %arbitary here
    arg = 0;  %arbitary here
    tru = -computeTrueAFromRadiusEcc(bodyInfo.radius+bodyInfo.atmohgt, preSMA, preEcc)-0.001;  %NOT ARBITRARY, SET JUST OUTSIDE ATMOSPHERE
    
    [rVect,vVectPre]=getStatefromKepler(preSMA, preEcc, inc, raan, arg, tru, bodyInfo.gm);
%     [~,vVectPost]=getStatefromKepler(postSMA, postEcc, inc, raan, arg, tru, bodyInfo.gm);
    %%%
    initialState = buildInitialState(rVect, vVectPre, mass, bodyInfo.id);
    aeroFun = @(dragCoeff) aerobrakeFunc(dragCoeff, initialState, dragModel, postSMA, bodyInfo.gm, celBodyData);
    
    if(strcmpi(dragModel,'Stock'))
        x0 = 0.2;
    else
        x0 = mass;
    end
    
    options = optimset('Display','iter');
    [Cd, fval] = fzero(aeroFun, x0, options);
    
    if(fval > 1E-4)
        set(handles.dragCoeffAnsText,'String', '<Error>');
    else
        set(handles.dragCoeffAnsText,'String', num2str(Cd, 10));
    end

function dSma = aerobrakeFunc(dragCoeff, initialState, dragModel, postSMADesired, gmu, celBodyData)
    aerobrake = ma_createAerobrake('NA', dragCoeff, dragModel);
    eventLog = ma_executeAerobrake(initialState, -1, aerobrake, celBodyData);
    
    newRVect = eventLog(end,2:4);
    newVVect = eventLog(end,5:7);
    [postSMAActual, ~, ~, ~, ~, ~] = getKeplerFromState(newRVect,newVVect,gmu);
    dSma = postSMAActual - postSMADesired;
    
function initialState = buildInitialState(rVect, vVect, mass, bodyId) 
    rVect = reshape(rVect,1,3);
    vVect = reshape(vVect,1,3);

    initialState = zeros(1,13);
    initialState(1,:) = [0 rVect vVect bodyId mass 0 0 0 1];
    

% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)
% hObject    handle to closeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.ma_AerobrakingCdCalcGUI);

% --- Executes on key press with focus on ma_AerobrakingCdCalcGUI or any of its controls.
function ma_AerobrakingCdCalcGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_AerobrakingCdCalcGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            calcCdButton_Callback(handles.calcCdButton, [], handles);
        case 'enter'
            calcCdButton_Callback(handles.calcCdButton, [], handles);
        case 'escape'
            close(handles.ma_AerobrakingCdCalcGUI);
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


% --- Executes on selection change in dragModelCombo.
function dragModelCombo_Callback(hObject, eventdata, handles)
% hObject    handle to dragModelCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns dragModelCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from dragModelCombo
    contents = cellstr(get(hObject,'String'));
    dragModel = contents{get(hObject,'Value')};

    if(strcmpi(dragModel,'Stock'))
%         set(handles.preAeroMass,'Enable','off');
%         set(handles.cdLabel,'String','');
        set(handles.preAeroMass,'Enable','on');
        set(handles.cdLabel,'String','m^2');
    elseif(strcmpi(dragModel,'FAR'))
        set(handles.preAeroMass,'Enable','on');
        set(handles.cdLabel,'String','m^2');
    elseif(strcmpi(dragModel,'NEAR'))
        set(handles.preAeroMass,'Enable','on');
        set(handles.cdLabel,'String','m^2');
    else
        error(['Invalid drag model in aerobraking DV calculations: ', dragModel]);
    end

% --- Executes during object creation, after setting all properties.
function dragModelCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dragModelCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function preAeroMass_Callback(hObject, eventdata, handles)
% hObject    handle to preAeroMass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of preAeroMass as text
%        str2double(get(hObject,'String')) returns contents of preAeroMass as a double
newInput = get(hObject,'String');
newInput = attemptStrEval(newInput);
set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function preAeroMass_CreateFcn(hObject, eventdata, handles)
% hObject    handle to preAeroMass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
