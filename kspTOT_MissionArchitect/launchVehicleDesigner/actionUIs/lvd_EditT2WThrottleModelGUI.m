function varargout = lvd_EditT2WThrottleModelGUI(varargin)
% LVD_EDITT2WTHROTTLEMODELGUI MATLAB code for lvd_EditT2WThrottleModelGUI.fig
%      LVD_EDITT2WTHROTTLEMODELGUI, by itself, creates a new LVD_EDITT2WTHROTTLEMODELGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITT2WTHROTTLEMODELGUI returns the handle to a new LVD_EDITT2WTHROTTLEMODELGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITT2WTHROTTLEMODELGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITT2WTHROTTLEMODELGUI.M with the given input arguments.
%
%      LVD_EDITT2WTHROTTLEMODELGUI('Property','Value',...) creates a new LVD_EDITT2WTHROTTLEMODELGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditT2WThrottleModelGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditT2WThrottleModelGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditT2WThrottleModelGUI

% Last Modified by GUIDE v2.5 06-Dec-2018 17:15:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditT2WThrottleModelGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditT2WThrottleModelGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditT2WThrottleModelGUI is made visible.
function lvd_EditT2WThrottleModelGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_EditT2WThrottleModelGUI (see VARARGIN)

    % Choose default command line output for lvd_EditT2WThrottleModelGUI
    handles.output = hObject;
    
    action = varargin{1};
    setappdata(hObject,'action',action);
    
    lv = varargin{2};
    setappdata(hObject,'lv',lv);
    
    populateGUI(handles, action);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditT2WThrottleModelGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditT2WThrottleModelGUI);

    
function populateGUI(handles, action)
    throttleModel = action.throttleModel;
    
    handles.twRatioText.String = fullAccNum2Str(throttleModel.targetT2W);
    
    optVar = throttleModel.getExistingOptVar();
    if(isempty(optVar))
        useTf = false([1,1]);
        lb = zeros(size(useTf));
        ub = zeros(size(useTf));
    else
        useTf = optVar.getUseTfForVariable();
        optVar.setUseTfForVariable(true(size(useTf)));
        [lb, ub] = optVar.getBndsForVariable();
        optVar.setUseTfForVariable(useTf);
    end
    
    set(handles.twOptCheckbox,'Value',useTf);
    set(handles.twLbText,'String',fullAccNum2Str(lb));
    set(handles.twUbText,'String',fullAccNum2Str(ub));
    
    twOptCheckbox_Callback(handles.twOptCheckbox, [], handles);

% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditT2WThrottleModelGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else  
        lv = getappdata(hObject,'lv');
        lvdData = lv.lvdData;
        
        action = getappdata(hObject,'action');
        throttleModel = action.throttleModel;
        
        optVar = throttleModel.getExistingOptVar();
        if(not(isempty(optVar))) %need to remove existing var if it exists
            lvdData.optimizer.vars.removeVariable(optVar);
        end
        
        throttleModel.targetT2W = str2double(handles.twRatioText.String);
        
        if(isempty(optVar))
            optVar = throttleModel.getNewOptVar();
        end
        
        useTf = get(handles.twOptCheckbox,'Value');
        optVar.setUseTfForVariable(useTf);
        
        lb = str2double(get(handles.twLbText,'String'));
        ub = str2double(get(handles.twUbText,'String'));
        
        optVar.setUseTfForVariable(true(size(lb))); %need this to get the full lb/set in there
        optVar.setBndsForVariable(lb, ub);
        optVar.setUseTfForVariable(useTf);
        
        lvdData.optimizer.vars.addVariable(optVar);
        
        varargout{1} = true;
        close(handles.lvd_EditT2WThrottleModelGUI);
    end


% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.lvd_EditT2WThrottleModelGUI);
    else
        msgbox(errMsg,'Errors were found while editing the throttle model.','error');
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    twRatio = str2double(get(handles.twRatioText,'String'));
    enteredStr = get(handles.twRatioText,'String');
    numberName = sprintf('Thrust to Weight Ratio');
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(twRatio, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    twRatioLB = str2double(get(handles.twLbText,'String'));
    enteredStr = get(handles.twLbText,'String');
    numberName = sprintf('Thrust to Weight Ratio Lower Bound');
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(twRatioLB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    twRatioUB = str2double(get(handles.twUbText,'String'));
    enteredStr = get(handles.twUbText,'String');
    numberName = sprintf('Thrust to Weight Ratio Upper Bound');
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(twRatioUB, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        if(twRatioLB > twRatioUB)
            errMsg{end+1} = 'The lower bound must be less than or equal to the upper bound.';
        end
    end


% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditT2WThrottleModelGUI);


function twRatioText_Callback(hObject, eventdata, handles)
% hObject    handle to twRatioText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of twRatioText as text
%        str2double(get(hObject,'String')) returns contents of twRatioText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function twRatioText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to twRatioText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in twOptCheckbox.
function twOptCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to twOptCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of twOptCheckbox
    if(get(hObject,'Value')==1)
        set(handles.twLbText,'Enable','on');
        set(handles.twUbText,'Enable','on');
    else
        set(handles.twLbText,'Enable','off');
        set(handles.twUbText,'Enable','off');
    end


function twLbText_Callback(hObject, eventdata, handles)
% hObject    handle to twLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of twLbText as text
%        str2double(get(hObject,'String')) returns contents of twLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function twLbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to twLbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function twUbText_Callback(hObject, eventdata, handles)
% hObject    handle to twUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of twUbText as text
%        str2double(get(hObject,'String')) returns contents of twUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function twUbText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to twUbText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
