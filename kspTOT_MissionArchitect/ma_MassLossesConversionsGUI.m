function varargout = ma_MassLossesConversionsGUI(varargin)
% MA_MASSLOSSESCONVERSIONSGUI MATLAB code for ma_MassLossesConversionsGUI.fig
%      MA_MASSLOSSESCONVERSIONSGUI, by itself, creates a new MA_MASSLOSSESCONVERSIONSGUI or raises the existing
%      singleton*.
%
%      H = MA_MASSLOSSESCONVERSIONSGUI returns the handle to a new MA_MASSLOSSESCONVERSIONSGUI or the handle to
%      the existing singleton*.
%
%      MA_MASSLOSSESCONVERSIONSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_MASSLOSSESCONVERSIONSGUI.M with the given input arguments.
%
%      MA_MASSLOSSESCONVERSIONSGUI('Property','Value',...) creates a new MA_MASSLOSSESCONVERSIONSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_MassLossesConversionsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_MassLossesConversionsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_MassLossesConversionsGUI

% Last Modified by GUIDE v2.5 12-Jun-2016 21:07:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_MassLossesConversionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_MassLossesConversionsGUI_OutputFcn, ...
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


% --- Executes just before ma_MassLossesConversionsGUI is made visible.
function ma_MassLossesConversionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_MassLossesConversionsGUI (see VARARGIN)

% Choose default command line output for ma_MassLossesConversionsGUI
handles.output = hObject;
handles.ma_MainGUI = varargin{1};

%Setup GUI
setResListboxStrs(handles);
if(length(varargin)>1) 
    eventLossConvert = varargin{2};
    populateGUIWithEvent(handles, eventLossConvert);
else
    populateGUIWithNoEvent(handles);
end
lossConvertSelectCombo_Callback(handles.lossConvertSelectCombo, [], handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ma_MassLossesConversionsGUI wait for user response (see UIRESUME)
uiwait(handles.ma_MassLossesConversionsGUI);

function setResListboxStrs(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    names = maData.spacecraft.propellant.names;
    
    set(handles.massLossResourcesListbox,'String',names);
    set(handles.massConvertResourcesListbox,'String',names);
    
function populateGUIWithEvent(handles, eventLossConvert)
    set(handles.lossConvertSelectCombo,'String',{eventLossConvert.name});
    setappdata(handles.ma_MassLossesConversionsGUI,'lossConvert',eventLossConvert);
    
    if(length(eventLossConvert) <= 1)
        set(handles.deleteCurLossConvertButton,'Enable','off');
    end

function populateGUIWithNoEvent(handles)
    lossConvert = getDefaultLossConvert(handles);
    name = lossConvert.name;
    
    set(handles.lossConvertSelectCombo,'String',name);
    setappdata(handles.ma_MassLossesConversionsGUI,'lossConvert',lossConvert);
    
    if(length(lossConvert) <= 1)
        set(handles.deleteCurLossConvertButton,'Enable','off');
    end
    
% --- Outputs from this function are returned to the command line.
function varargout = ma_MassLossesConversionsGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        lossConverts = getappdata(handles.ma_MassLossesConversionsGUI,'lossConvert');
        varargout{1} = lossConverts;
        
        close(handles.ma_MassLossesConversionsGUI);
    end
    

% --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveAndCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.ma_MassLossesConversionsGUI);

    
% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.ma_MassLossesConversionsGUI);

% --- Executes on selection change in massConvertResourcesListbox.
function massConvertResourcesListbox_Callback(hObject, eventdata, handles)
% hObject    handle to massConvertResourcesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns massConvertResourcesListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from massConvertResourcesListbox
    lossConverts = getappdata(handles.ma_MassLossesConversionsGUI,'lossConvert');
    lossConvert = lossConverts(get(handles.lossConvertSelectCombo,'Value'));

	resourceConvertRate = lossConvert.resConvertPercent(get(handles.massConvertResourcesListbox,'Value'));
    set(handles.massConvertPercentText,'String', fullAccNum2Str(resourceConvertRate*100));
    

% --- Executes during object creation, after setting all properties.
function massConvertResourcesListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to massConvertResourcesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function massConvertPercentText_Callback(hObject, eventdata, handles)
% hObject    handle to massConvertPercentText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of massConvertPercentText as text
%        str2double(get(hObject,'String')) returns contents of massConvertPercentText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

    errMsg = {};
    
    rate = str2double(get(handles.massConvertPercentText,'String'));
    enteredStr = get(handles.massConvertPercentText,'String');
    numberName = 'Mass Convert Rate Percent';
    lb = 0;
    ub = 100;
    isInt = false;
    errMsg = validateNumber(rate, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    lossConverts = getappdata(handles.ma_MassLossesConversionsGUI,'lossConvert');
    lossConvert = lossConverts(get(handles.lossConvertSelectCombo,'Value'));
    
    if(isempty(errMsg))
        prevLossConvert = lossConvert;
        lossConvert.resConvertPercent(get(handles.massConvertResourcesListbox,'Value')) = rate/100;
        if(sum(lossConvert.resConvertPercent) > 1)
            lossConvert = prevLossConvert;
            
            set(hObject,'String', num2str(lossConvert.resConvertPercent(get(handles.massConvertResourcesListbox,'Value'))*100));
            
            errMsg{end+1} = sprintf('The entered mass rate conversion percentage (%1.6f %%) causes the total mass conversion rate to exceed 100 %%.',rate);
            msgbox(errMsg,'Errors were found in the entered mass conversion rate percentage.','error');
        end
        
        lossConverts(get(handles.lossConvertSelectCombo,'Value')) = lossConvert;
        setappdata(handles.ma_MassLossesConversionsGUI,'lossConvert',lossConverts);
    else
        msgbox(errMsg,'Errors were found in the entered mass conversion rate percentage.','error');
    end  
    
    totalRate = sum(lossConvert.resConvertPercent)*100;
    set(handles.massRateTotalConvertLabel,'String',sprintf('%1.6f %%',totalRate));
    set(handles.massRateTotalConvertLabel,'TooltipString',sprintf('Equates to %1.6f mT/Hr converted.',sum(lossConvert.resLostRates)*3600*sum(lossConvert.resConvertPercent)));
    set(handles.massConvertResourcesListbox,'TooltipString',getMassConversionTooltipStr(handles, lossConvert));
    
function str = getMassConversionTooltipStr(handles, lossConvert)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    names = maData.spacecraft.propellant.names;
    
    sumLossRates = sum(lossConvert.resLostRates)*3600;
    
    str = 'Resource Conversion Rates\n---------------------\n';
    for(i=1:length(lossConvert.resConvert)) %#ok<*NO4LP>
        resName = names{lossConvert.resConvert(i)};
        str = [str,...
               sprintf('\t%s: %1.6f &percent& (%1.6f mT/Hr)\n', resName, lossConvert.resConvertPercent(i)*100, sumLossRates*lossConvert.resConvertPercent(i))];
    end
    
    str = strrep(str,'&percent&','%%');
    str = sprintf(str');
    
% --- Executes during object creation, after setting all properties.
function massConvertPercentText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to massConvertPercentText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in massLossResourcesListbox.
function massLossResourcesListbox_Callback(hObject, eventdata, handles)
% hObject    handle to massLossResourcesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns massLossResourcesListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from massLossResourcesListbox
    lossConverts = getappdata(handles.ma_MassLossesConversionsGUI,'lossConvert');
    lossConvert = lossConverts(get(handles.lossConvertSelectCombo,'Value'));
    
    resourceLossRate = lossConvert.resLostRates(get(handles.massLossResourcesListbox,'Value'));
    set(handles.massRateText,'String', fullAccNum2Str(resourceLossRate*3600));

% --- Executes during object creation, after setting all properties.
function massLossResourcesListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to massLossResourcesListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function massRateText_Callback(hObject, eventdata, handles)
% hObject    handle to massRateText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of massRateText as text
%        str2double(get(hObject,'String')) returns contents of massRateText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
       
    errMsg = {};
    
    rate = str2double(get(handles.massRateText,'String'));
    enteredStr = get(handles.massRateText,'String');
    numberName = 'Mass Loss Rate';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(rate, numberName, lb, ub, isInt, errMsg, enteredStr);

    lossConverts = getappdata(handles.ma_MassLossesConversionsGUI,'lossConvert');
    lossConvert = lossConverts(get(handles.lossConvertSelectCombo,'Value'));
    
    if(isempty(errMsg))
        lossConvert.resLostRates(get(handles.massLossResourcesListbox,'Value')) = rate/3600;
        
        lossConverts(get(handles.lossConvertSelectCombo,'Value')) = lossConvert;
        setappdata(handles.ma_MassLossesConversionsGUI,'lossConvert',lossConverts);
    else
        msgbox(errMsg,'Errors were found in the entered mass loss rate.','error');
    end  
    
    totalRate = sum(lossConvert.resLostRates)*3600;
    set(handles.massRateTotalLossLabel,'String',sprintf('%1.6f mT/Hr',totalRate));
    set(handles.massLossResourcesListbox,'TooltipStr',getMasLossesTooltipStr(handles, lossConvert));
    
    massConvertPercentText_Callback(handles.massConvertPercentText, [], handles);
    
function str = getMasLossesTooltipStr(handles, lossConvert)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    names = maData.spacecraft.propellant.names;
    
    str = 'Resource Loss Rates\n---------------------\n';
    for(i=1:length(lossConvert.resLost))
        resName = names{lossConvert.resLost(i)};
        str = [str,...
               sprintf('\t%s: %1.6f mT/Hr\n',resName,lossConvert.resLostRates(i)*3600)]; %#ok<AGROW>
    end
    
    str = sprintf(str');

% --- Executes during object creation, after setting all properties.
function massRateText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to massRateText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lossConvertSelectCombo.
function lossConvertSelectCombo_Callback(hObject, eventdata, handles)
% hObject    handle to lossConvertSelectCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lossConvertSelectCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lossConvertSelectCombo
    lossConverts = getappdata(handles.ma_MassLossesConversionsGUI,'lossConvert');
    lossConvert = lossConverts(get(handles.lossConvertSelectCombo,'Value'));
    
    set(handles.lossConvertNameText,'String',lossConvert.name);
    
    massLossResourcesListbox_Callback(handles.massLossResourcesListbox, [], handles);
    massConvertResourcesListbox_Callback(handles.massConvertResourcesListbox, [], handles);
    
    massRateText_Callback(handles.massRateText, [], handles);

% --- Executes during object creation, after setting all properties.
function lossConvertSelectCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lossConvertSelectCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function lossConvertNameText_Callback(hObject, eventdata, handles)
% hObject    handle to lossConvertNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lossConvertNameText as text
%        str2double(get(hObject,'String')) returns contents of lossConvertNameText as a double
    lossConverts = getappdata(handles.ma_MassLossesConversionsGUI,'lossConvert');
    lossConvert = lossConverts(get(handles.lossConvertSelectCombo,'Value'));
    
    lossConvert.name = get(handles.lossConvertNameText,'String');
    lossConverts(get(handles.lossConvertSelectCombo,'Value')) = lossConvert;
    
    setappdata(handles.ma_MassLossesConversionsGUI,'lossConvert',lossConverts);
    set(handles.lossConvertSelectCombo,'String',{lossConverts.name});

% --- Executes during object creation, after setting all properties.
function lossConvertNameText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lossConvertNameText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addNewLossConvertButton.
function addNewLossConvertButton_Callback(hObject, eventdata, handles)
% hObject    handle to addNewLossConvertButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lossConverts = getappdata(handles.ma_MassLossesConversionsGUI,'lossConvert');
    lossConverts(end+1) = getDefaultLossConvert(handles);
    
    setappdata(handles.ma_MassLossesConversionsGUI,'lossConvert',lossConverts);
    set(handles.lossConvertSelectCombo,'String',{lossConverts.name});
    set(handles.lossConvertSelectCombo,'Value',length(lossConverts));
    lossConvertSelectCombo_Callback(handles.lossConvertSelectCombo, [], handles);
    
    if(length(lossConverts) > 1)
        set(handles.deleteCurLossConvertButton,'Enable','on');
    end

% --- Executes on button press in deleteCurLossConvertButton.
function deleteCurLossConvertButton_Callback(hObject, eventdata, handles)
% hObject    handle to deleteCurLossConvertButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lossConverts = getappdata(handles.ma_MassLossesConversionsGUI,'lossConvert');
    lossConverts(get(handles.lossConvertSelectCombo,'Value')) = [];
    
    if(get(handles.lossConvertSelectCombo,'Value') > length(lossConverts))
        set(handles.lossConvertSelectCombo,'Value',length(lossConverts));
    end
    
    setappdata(handles.ma_MassLossesConversionsGUI,'lossConvert',lossConverts);
    set(handles.lossConvertSelectCombo,'String',{lossConverts.name});
    lossConvertSelectCombo_Callback(handles.lossConvertSelectCombo, [], handles);
    
    if(length(lossConverts) <= 1)
        set(handles.deleteCurLossConvertButton,'Enable','off');
    end


% --- Executes on key press with focus on ma_MassLossesConversionsGUI or any of its controls.
function ma_MassLossesConversionsGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to ma_MassLossesConversionsGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'escape'
            close(handles.ma_MassLossesConversionsGUI);
    end
