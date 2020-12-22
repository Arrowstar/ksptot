function varargout = uploadManeuverToKSP(varargin)
% UPLOADMANEUVERTOKSP MATLAB code for uploadManeuverToKSP.fig
%      UPLOADMANEUVERTOKSP, by itself, creates a new UPLOADMANEUVERTOKSP or raises the existing
%      singleton*.
%
%      H = UPLOADMANEUVERTOKSP returns the handle to a new UPLOADMANEUVERTOKSP or the handle to
%      the existing singleton*.
%
%      UPLOADMANEUVERTOKSP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UPLOADMANEUVERTOKSP.M with the given input arguments.
%
%      UPLOADMANEUVERTOKSP('Property','Value',...) creates a new UPLOADMANEUVERTOKSP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before uploadManeuverToKSP_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to uploadManeuverToKSP_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help uploadManeuverToKSP

% Last Modified by GUIDE v2.5 02-Dec-2013 20:14:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @uploadManeuverToKSP_OpeningFcn, ...
                   'gui_OutputFcn',  @uploadManeuverToKSP_OutputFcn, ...
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

% --- Executes just before uploadManeuverToKSP is made visible.
function uploadManeuverToKSP_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to uploadManeuverToKSP (see VARARGIN)

    % Choose default command line output for uploadManeuverToKSP
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);

    %Possible fix for people with display issues.
    checkForCharUnitsInGUI(hObject);
    
    if(nargin > 0)
        if(nargin == 4)
            data = varargin{1};
            if(~isempty(data))
                set(handles.utText, 'String', fullAccNum2Str(data(2)));
                set(handles.progradeDVText, 'String', fullAccNum2Str(data(3)));
                set(handles.normalDVText, 'String', fullAccNum2Str(data(4)));
                set(handles.radialDVText, 'String', fullAccNum2Str(data(5)));

                if(data(1) == 0)
                    set(handles.timeTypeBtnGroup, 'SelectedObject', handles.utTimeRadioBtn);
                    eventdata.NewValue = handles.utTimeRadioBtn;
                elseif(data(1) == 1)
                    set(handles.timeTypeBtnGroup, 'SelectedObject', handles.timePastPeriRadioBtn);
                    eventdata.NewValue = handles.timePastPeriRadioBtn;
                else
                    set(handles.timeTypeBtnGroup, 'SelectedObject', handles.utTimeRadioBtn);
                    eventdata.NewValue = handles.utTimeRadioBtn;
                end

                timeTypeBtnGroup_SelectionChangeFcn([], eventdata, handles);
            else
                eventdata.NewValue = handles.utTimeRadioBtn;
                timeTypeBtnGroup_SelectionChangeFcn([], eventdata, handles);
            end
        end
    else 
        eventdata.NewValue = handles.utTimeRadioBtn;
        timeTypeBtnGroup_SelectionChangeFcn([], eventdata, handles);
    end
    
    checkConnectionWKSP(handles.statusText, true);

    % UIWAIT makes uploadManeuverToKSP wait for user response (see UIRESUME)
    % uiwait(handles.uploadManeuver2KSP);
end

% --- Outputs from this function are returned to the command line.
function varargout = uploadManeuverToKSP_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    varargout{1} = handles.output;
end


function statusText_Callback(hObject, eventdata, handles)
% hObject    handle to statusText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of statusText as text
%        str2double(get(hObject,'String')) returns contents of statusText as a double
end

% --- Executes during object creation, after setting all properties.
function statusText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to statusText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function utText_Callback(hObject, eventdata, handles)
% hObject    handle to utText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of utText as text
%        str2double(get(hObject,'String')) returns contents of utText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);
end

% --- Executes during object creation, after setting all properties.
function utText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to utText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function progradeDVText_Callback(hObject, eventdata, handles)
% hObject    handle to progradeDVText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of progradeDVText as text
%        str2double(get(hObject,'String')) returns contents of progradeDVText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);
end

% --- Executes during object creation, after setting all properties.
function progradeDVText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to progradeDVText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function normalDVText_Callback(hObject, eventdata, handles)
% hObject    handle to normalDVText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of normalDVText as text
%        str2double(get(hObject,'String')) returns contents of normalDVText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);
end

% --- Executes during object creation, after setting all properties.
function normalDVText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to normalDVText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function radialDVText_Callback(hObject, eventdata, handles)
% hObject    handle to radialDVText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of radialDVText as text
%        str2double(get(hObject,'String')) returns contents of radialDVText as a double
newInput = attemptStrEval(get(hObject,'String'));
set(hObject, 'String', newInput);
end
% --- Executes during object creation, after setting all properties.
function radialDVText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radialDVText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in uploadManButton.
function uploadManButton_Callback(hObject, eventdata, handles)
% hObject    handle to uploadManButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    writeToOutput(handles.statusText,'*** Generating Maneuver Node... ***','append');
    
    ut = str2double(get(handles.utText, 'String'));
    pDV = str2double(get(handles.progradeDVText, 'String'));
    nDV = str2double(get(handles.normalDVText, 'String'));
    rDV = str2double(get(handles.radialDVText, 'String'));
    
    hSelected = get(handles.timeTypeBtnGroup, 'SelectedObject');
    hSelTag = get(hSelected,'Tag');
    
    if(strcmpi(hSelTag, 'utTimeRadioBtn'))
        dataType = 'NodeData';
    elseif(strcmpi(hSelTag, 'timePastPeriRadioBtn')) 
        dataType = 'NodeDataWRTPeri';
    end
    
    data = [ut pDV nDV rDV];
    
    try 
        tcpipClient = createTcpIpClient(8282, 'Client');
        writeDataToKSPTOTConnect(dataType, data, 'd', tcpipClient);
        failed = false;
    catch ME
        msg = ['Connection to KSPTOT Connect failed: ', ME.message];
        failed = true;
    end
    
    if(failed == false)
        msg = 'Maneuver Node created!';
    end
    
    writeToOutput(handles.statusText,msg,'append');
end

function checkConnectionWKSP(hStatusText, first) 
    if(first == true)
        writeToOutput(hStatusText,'*** Checking Connection Status ***','append');
    else 
        writeToOutput(hStatusText,'*** Checking Connection Status ***','append');
    end
    
    dataType = 'ConnectionCheck';
    data = [1 2 3 4 5];
    
    try 
        writeDataToKSPTOTConnect(dataType, data);
        failed = false;
    catch ME
        msg = ['Connection to KSPTOT Connect failed: ', ME.message];
        failed = true;
    end
    
    if(failed == false)
        msg = 'Connection to KSPTOT Connect succeeded!';
    end
    
    writeToOutput(hStatusText,msg,'append');
end


% --- Executes on button press in testConnectionButton.
function testConnectionButton_Callback(hObject, eventdata, handles)
% hObject    handle to testConnectionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    checkConnectionWKSP(handles.statusText, false);
end


% --------------------------------------------------------------------
function enterUTAsDateTime_Callback(hObject, eventdata, handles)
% hObject    handle to enterUTAsDateTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    secUT = enterUTAsDateTimeGUI(str2double(get(gco, 'String')));
    if(secUT >= 0)
        set(gco, 'String', num2str(secUT));
        utText_Callback(handles.utText, eventdata, handles);
    end
end


% --- Executes when selected object is changed in timeTypeBtnGroup.
function timeTypeBtnGroup_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in timeTypeBtnGroup 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
    hSelected = eventdata.NewValue;
    tagSelected = get(hSelected, 'tag');

    if(strcmpi(tagSelected,'utTimeRadioBtn'))
        set(handles.timeTypeLabel,'String','Univ. Time (UT)');
        set(handles.timeTypeLabel,'TooltipString','Universal game time');
        set(handles.utText,'TooltipString','Universal game time');
    elseif(strcmpi(tagSelected,'timePastPeriRadioBtn'))
        set(handles.timeTypeLabel,'String','Time Past Peri.');
        set(handles.timeTypeLabel,'TooltipString','Time past upcoming periapse');
        set(handles.utText,'TooltipString','Time past upcoming periapse');
    end
end
