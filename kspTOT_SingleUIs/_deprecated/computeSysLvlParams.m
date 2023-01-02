function varargout = computeSysLvlParams(varargin)
% COMPUTESYSLVLPARAMS MATLAB code for computeSysLvlParams.fig
%      COMPUTESYSLVLPARAMS, by itself, creates a new COMPUTESYSLVLPARAMS or raises the existing
%      singleton*.
%
%      H = COMPUTESYSLVLPARAMS returns the handle to a new COMPUTESYSLVLPARAMS or the handle to
%      the existing singleton*.
%
%      COMPUTESYSLVLPARAMS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COMPUTESYSLVLPARAMS.M with the given input arguments.
%
%      COMPUTESYSLVLPARAMS('Property','Value',...) creates a new COMPUTESYSLVLPARAMS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before computeSysLvlParams_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to computeSysLvlParams_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help computeSysLvlParams

% Last Modified by GUIDE v2.5 21-Aug-2013 19:44:37

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @computeSysLvlParams_OpeningFcn, ...
                       'gui_OutputFcn',  @computeSysLvlParams_OutputFcn, ...
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
end

% --- Executes just before computeSysLvlParams is made visible.
function computeSysLvlParams_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to computeSysLvlParams (see VARARGIN)

    % Choose default command line output for computeSysLvlParams
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);
    
    %Possible fix for people with display issues.
    checkForCharUnitsInGUI(hObject);

    enginesParams = varargin{1};
    set(hObject,'UserData', enginesParams);
    updateListBoxStr(hObject, handles.engineSumListbox);
    
    form = '%9.3f';
    [totThrust, avgIsp] = computeSysLvlParamsFromListBox(handles.computeSysLvlParamsGUI);
    set(handles.totThrustLabel,'String',num2str(totThrust/1000, form));
    set(handles.avgIspLabel,'String',num2str(avgIsp, form));

    % UIWAIT makes computeSysLvlParams wait for user response (see UIRESUME)
    uiwait(handles.computeSysLvlParamsGUI);
end

% --- Outputs from this function are returned to the command line.
function varargout = computeSysLvlParams_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    try 
        [thrust, isp] = computeSysLvlParamsFromListBox(handles.computeSysLvlParamsGUI); 
        engineParams = get(handles.computeSysLvlParamsGUI, 'UserData');
        varargout{1} = thrust/1000;
        varargout{2} = isp;
        varargout{3} = engineParams;
        close(hObject);
    catch ME
        varargout{1} = [];
        varargout{2} = [];
        varargout{3} = [];
    end
end

% --- Executes on selection change in engineSumListbox.
function engineSumListbox_Callback(hObject, eventdata, handles)
% hObject    handle to engineSumListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns engineSumListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from engineSumListbox
end

% --- Executes during object creation, after setting all properties.
function engineSumListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to engineSumListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function numEnginesText_Callback(hObject, eventdata, handles)
% hObject    handle to numEnginesText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numEnginesText as text
%        str2double(get(hObject,'String')) returns contents of numEnginesText as a double
end

% --- Executes during object creation, after setting all properties.
function numEnginesText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numEnginesText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function thrustText_Callback(hObject, eventdata, handles)
% hObject    handle to thrustText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of thrustText as text
%        str2double(get(hObject,'String')) returns contents of thrustText as a double
end

% --- Executes during object creation, after setting all properties.
function thrustText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to thrustText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function ispText_Callback(hObject, eventdata, handles)
% hObject    handle to ispText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ispText as text
%        str2double(get(hObject,'String')) returns contents of ispText as a double
end

% --- Executes during object creation, after setting all properties.
function ispText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ispText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes on button press in addEngineButton.
function addEngineButton_Callback(hObject, eventdata, handles)
% hObject    handle to addEngineButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    engineParams = get(handles.computeSysLvlParamsGUI, 'UserData');

    errMsg = {};

    numEng = str2double(get(handles.numEnginesText, 'String'));
    enteredStr = get(handles.numEnginesText,'String');
    numberName = 'Number of engines';
    lb = 1;
    ub = Inf;
    isInt = true;
    errMsg = validateNumber(numEng, numberName, lb, ub, isInt, errMsg, enteredStr);

    thrust = str2double(get(handles.thrustText, 'String'));
    enteredStr = get(handles.thrustText,'String');
    numberName = 'Thrust';
    lb = 0.001;
    ub = Inf;
    isInt = true;
    errMsg = validateNumber(thrust, numberName, lb, ub, isInt, errMsg, enteredStr);
    thrust = thrust*1000;
    
    isp = str2double(get(handles.ispText, 'String'));
    enteredStr = get(handles.ispText,'String');
    numberName = 'Thrust';
    lb = 0.001;
    ub = Inf;
    isInt = true;
    errMsg = validateNumber(isp, numberName, lb, ub, isInt, errMsg, enteredStr);

    if(isempty(errMsg))

        engineParams(end+1,:) = [numEng thrust isp];
        set(handles.computeSysLvlParamsGUI, 'UserData', engineParams);

        form = '%9.3f';
        [totThrust, avgIsp] = computeSysLvlParamsFromListBox(handles.computeSysLvlParamsGUI);
        set(handles.totThrustLabel,'String',num2str(totThrust/1000, form));
        set(handles.avgIspLabel,'String',num2str(avgIsp, form));
        
        updateListBoxStr(handles.computeSysLvlParamsGUI, handles.engineSumListbox);
    else
        msgbox(errMsg,'Errors were found in orbit change calculation inputs','error');
    end
    
end
% --- Executes on button press in removeEngineButton.
function removeEngineButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeEngineButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    selInd = get(handles.engineSumListbox, 'Value');
    if(isempty(selInd) || selInd < 1 || size(selInd,1) > 1 || size(selInd,2) > 1)
        return;
    end

%     listBoxStr = get(handles.engineSumListbox, 'String');
%     listBoxStr(selInd) = [];
%     set(handles.engineSumListbox, 'String', listBoxStr);
    
    engineParams = get(handles.computeSysLvlParamsGUI, 'UserData');
    if(isempty(engineParams) && selInd==1)
        return;
    end    
    
    engineParams(selInd,:) = [];
    set(handles.computeSysLvlParamsGUI, 'UserData', engineParams);
    
    form = '%9.3f';
    [totThrust, avgIsp] = computeSysLvlParamsFromListBox(handles.computeSysLvlParamsGUI);
    set(handles.totThrustLabel,'String',num2str(totThrust/1000, form));
    set(handles.avgIspLabel,'String',num2str(avgIsp, form));
    
    updateListBoxStr(handles.computeSysLvlParamsGUI, handles.engineSumListbox);   
end

% --- Executes on button press in saveExitButton.
function saveExitButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveExitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.computeSysLvlParamsGUI);
end

function [thrust, isp] = computeSysLvlParamsFromListBox(hFig) 
    engineParams = get(hFig, 'UserData');
    thrust = 0;
    isp = 0;
    mdot = 0;

    g0 = 9.80665;

    for(i=1:size(engineParams,1))
        curEntry = engineParams(i,:);

        numEng = curEntry(1);
        curThrust = curEntry(2);
        curIsp = curEntry(3);

        curMdot = curThrust/(g0*curIsp);

        thrust = thrust + numEng*curThrust;
        mdot = mdot + numEng*curMdot;
    end

    if(thrust>0 && mdot>0) 
        isp = thrust/(g0*mdot);
    end
end


function updateListBoxStr(hFig, hEngineSumListbox)
    engineParams = get(hFig, 'UserData');
    
    listBoxStr = {};
    formDbl = '%9.1f';
    formInt = '%9.0f';
    
    for(i=1:size(engineParams,1))
        curEntry = engineParams(i,:);

        numEng = curEntry(1);
        curThrust = curEntry(2);
        curIsp = curEntry(3);
        
        numEngStr = num2str(numEng, formInt);
        curThrustStr = num2str(curThrust/1000, formDbl);
        curIspStr = num2str(curIsp, formDbl);
        
        curStr = [numEngStr, 'x Engines: ', curThrustStr, ' kN, ', curIspStr, ' sec'];
        listBoxStr{end+1} = curStr;
    end
    
    selInd = get(hEngineSumListbox, 'Value');
    if(selInd > size(engineParams, 1))
        set(hEngineSumListbox, 'Value', size(engineParams, 1));
    elseif(selInd < 1)
        set(hEngineSumListbox, 'Value', 1);
    end
    
    set(hEngineSumListbox, 'String', listBoxStr);
end


% --- Executes on key press with focus on computeSysLvlParamsGUI and none of its controls.
function computeSysLvlParamsGUI_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to computeSysLvlParamsGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
	if(strcmpi(eventdata.Key, 'return') || strcmpi(eventdata.Key, 'enter'))
        addEngineButton_Callback(handles.addEngineButton, [], handles);
    end
end
