function varargout = rts_VesselSelectGUI(varargin)
% RTS_VESSELSELECTGUI MATLAB code for rts_VesselSelectGUI.fig
%      RTS_VESSELSELECTGUI, by itself, creates a new RTS_VESSELSELECTGUI or raises the existing
%      singleton*.
%
%      H = RTS_VESSELSELECTGUI returns the handle to a new RTS_VESSELSELECTGUI or the handle to
%      the existing singleton*.
%
%      RTS_VESSELSELECTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RTS_VESSELSELECTGUI.M with the given input arguments.
%
%      RTS_VESSELSELECTGUI('Property','Value',...) creates a new RTS_VESSELSELECTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rts_VesselSelectGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rts_VesselSelectGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help rts_VesselSelectGUI

% Last Modified by GUIDE v2.5 14-Dec-2013 21:53:39

% Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @rts_VesselSelectGUI_OpeningFcn, ...
                       'gui_OutputFcn',  @rts_VesselSelectGUI_OutputFcn, ...
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
end
% End initialization code - DO NOT EDIT


% --- Executes just before rts_VesselSelectGUI is made visible.
function rts_VesselSelectGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rts_VesselSelectGUI (see VARARGIN)
    global rHost;

    % Choose default command line output for rts_VesselSelectGUI
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);
    
    setappdata(hObject,'mainGUIFig',varargin{1});
    
    rHost = varargin{2};
    if(~isempty(rHost)) %should always be populated
        set(handles.remoteHostText,'String',rHost);
    end

    % UIWAIT makes rts_VesselSelectGUI wait for user response (see UIRESUME)
    uiwait(handles.rts_VesselSelectGUI);
end

function testConnection(handles)
    port = 8282;
    role = 'Client';
    rHost = get(handles.remoteHostText,'String');
    set(handles.couldNotConnectLabel,'Visible', 'off');
    drawnow;
    
    try
        resolveip(rHost);
    catch ME
        warndlg(['Could not resolve remote host: ', getReport(ME,'extended','hyperlinks','off')]);
        return;
    end
    
    try
        tcpipClient = createTcpIpClient(port, role, rHost);
        writeDataToKSPTOTConnect('ConnectionCheck', [1 2 3 4 5], 'd', tcpipClient);
        set(handles.couldNotConnectLabel,'Visible', 'off');
    catch ME
%         warndlg(['Connection check failed: ', getReport(ME,'extended','hyperlinks','off')]);
        set(handles.couldNotConnectLabel,'Visible', 'on');
        disp(getReport(ME,'extended','hyperlinks','off'))
        return;
    end
    
    populateVesselSelectCombo(handles);
    setappdata(handles.rts_VesselSelectGUI, 'RHost', rHost);
end

function populateVesselSelectCombo(handles)
    port = 8282;
    role = 'Client';
    rHost = get(handles.remoteHostText,'String');
    tcpipClient = createTcpIpClient(port, role, rHost);
    
    try
        guids = readManyStringsFromKSPTOTConnect('GetVesselIDList', '', 32, true, tcpipClient);
        if(isempty(guids))
            error('Error reading vessels from KSP.');
        end
        vesselNames = {};
        storageGUIDS = {};
        for(i=1:length(guids))
            guid = guids{i};
            fclose(tcpipClient);
            delete(tcpipClient);
            tcpipClient = createTcpIpClient(port, role, rHost);
            vesselNames{i} = [readStringFromKSPTOTConnect('GetVesselNameByGUID', guid, true, tcpipClient), ' - ', guid(1:4)];
            storageGUIDS{i} = guid;
        end

        hVesselComboBox = handles.vesselSelectComboBox;
        set(hVesselComboBox,'String',vesselNames);    

        vesselGUIDData = {storageGUIDS, vesselNames};
        set(handles.rts_VesselSelectGUI,'UserData',vesselGUIDData);
        
        set(handles.couldNotConnectLabel,'Visible', 'off');
        set(handles.vesselSelectComboBox, 'Enable', 'on');
        set(handles.connectToRealTimeSystemButton, 'Enable', 'on');
    catch ME
        set(handles.couldNotConnectLabel,'Visible', 'on');
        set(handles.connectToRealTimeSystemButton, 'Enable','off');
        set(handles.vesselSelectComboBox, 'Enable', 'off');
        disp(ME.message);
    end
end

% --- Outputs from this function are returned to the command line.
function varargout = rts_VesselSelectGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global rHost;
    
% Get default command line output from handles structure
    if(~isempty(handles))
        contents = cellstr(get(handles.vesselSelectComboBox,'String'));
        selVesselName = contents{get(handles.vesselSelectComboBox,'Value')};

        vesselGUIDData = get(handles.rts_VesselSelectGUI, 'UserData');
        vesselNames = vesselGUIDData{2};
        storageGUIDS = vesselGUIDData{1};
        selGUID = '';
        for(i=1:length(vesselNames)) %#ok<*NO4LP>
            if(strcmp(vesselNames{i}, selVesselName))
                selGUID = storageGUIDS{i};
                break;
            end
        end
        
        rHost = getappdata(handles.rts_VesselSelectGUI, 'RHost');
        mainGUIFig = getappdata(handles.rts_VesselSelectGUI,'mainGUIFig');
        updateAppOptions(mainGUIFig, 'ksptot', 'rtshostname', rHost);
        
        varargout{1} = selGUID;
        varargout{2} = rHost;
        close(hObject);
    else
        varargout{1} = [];
        varargout{2} = [];
    end
end

% --- Executes on selection change in vesselSelectComboBox.
function vesselSelectComboBox_Callback(hObject, eventdata, handles)
% hObject    handle to vesselSelectComboBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns vesselSelectComboBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vesselSelectComboBox
end

% --- Executes during object creation, after setting all properties.
function vesselSelectComboBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vesselSelectComboBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in connectToRealTimeSystemButton.
function connectToRealTimeSystemButton_Callback(hObject, eventdata, handles)
% hObject    handle to connectToRealTimeSystemButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.rts_VesselSelectGUI);
end


% --- Executes when user attempts to close rts_VesselSelectGUI.
function rts_VesselSelectGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to rts_VesselSelectGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
    if(~isempty(instrfind))
        fclose(instrfind);
        delete(instrfind);
    end
    
    delete(hObject);
end



function remoteHostText_Callback(hObject, eventdata, handles)
% hObject    handle to remoteHostText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of remoteHostText as text
%        str2double(get(hObject,'String')) returns contents of remoteHostText as a double
end

% --- Executes during object creation, after setting all properties.
function remoteHostText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to remoteHostText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

% --- Executes on button press in testConnectButton.
function testConnectButton_Callback(hObject, eventdata, handles)
% hObject    handle to testConnectButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    testConnection(handles);
end
