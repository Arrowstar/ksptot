function varargout = lvd_EditDragPropertiesGUI(varargin)
% LVD_EDITDRAGPROPERTIESGUI MATLAB code for lvd_EditDragPropertiesGUI.fig
%      LVD_EDITDRAGPROPERTIESGUI, by itself, creates a new LVD_EDITDRAGPROPERTIESGUI or raises the existing
%      singleton*.
%
%      H = LVD_EDITDRAGPROPERTIESGUI returns the handle to a new LVD_EDITDRAGPROPERTIESGUI or the handle to
%      the existing singleton*.
%
%      LVD_EDITDRAGPROPERTIESGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LVD_EDITDRAGPROPERTIESGUI.M with the given input arguments.
%
%      LVD_EDITDRAGPROPERTIESGUI('Property','Value',...) creates a new LVD_EDITDRAGPROPERTIESGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before lvd_EditDragPropertiesGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to lvd_EditDragPropertiesGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help lvd_EditDragPropertiesGUI

% Last Modified by GUIDE v2.5 04-Mar-2020 20:15:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @lvd_EditDragPropertiesGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @lvd_EditDragPropertiesGUI_OutputFcn, ...
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


% --- Executes just before lvd_EditDragPropertiesGUI is made visible.
function lvd_EditDragPropertiesGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to lvd_EditDragPropertiesGUI (see VARARGIN)

    % Choose default command line output for lvd_EditDragPropertiesGUI
    handles.output = hObject;

    lvdData = varargin{1};
    setappdata(hObject,'lvdData',lvdData);
    
    populateGUI(handles, lvdData);
    
    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes lvd_EditDragPropertiesGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditDragPropertiesGUI);

function populateGUI(handles, lvdData)
    initStateModel = lvdData.initStateModel;
    aero = initStateModel.aero;
    
    handles.dragAreaText.String = fullAccNum2Str(aero.area);
%     handles.dragCoeffText.String = fullAccNum2Str(initStateModel.aero.Cd);
    
    handles.indepVarCombo.String = AeroIndepVar.getListBoxStr();
    handles.indepVarCombo.Value = AeroIndepVar.getIndForName(aero.CdIndepVar.name);
    
    handles.interpMethodCombo.String = GriddedInterpolantMethodEnum.getListBoxStr();
    handles.interpMethodCombo.Value = GriddedInterpolantMethodEnum.getIndForName(aero.CdInterpMethod.name);
    
    handles.ptsListbox.String = aero.CdInterpPts.getListboxStr();
    setRemoveEnableState(handles);
    
    
% --- Outputs from this function are returned to the command line.
function varargout = lvd_EditDragPropertiesGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
        varargout{2} = false;
        varargout{3} = false;
    else  
        lvdData = getappdata(handles.lvd_EditDragPropertiesGUI,'lvdData');
        initStateModel = lvdData.initStateModel;
        aero = initStateModel.aero;
        
        uiArea = str2double(handles.dragAreaText.String);
        
        aero.area = uiArea;
        
        strs = handles.indepVarCombo.String();
        str = strs{handles.indepVarCombo.Value};
        aeroIndepVarEnum = AeroIndepVar.getEnumForListboxStr(str);
        
        strs = handles.interpMethodCombo.String();
        str = strs{handles.interpMethodCombo.Value};
        interpMethodEnum = GriddedInterpolantMethodEnum.getEnumForListboxStr(str);

        aero.CdIndepVar = aeroIndepVarEnum;
        aero.CdInterpMethod = interpMethodEnum;
        
        gI = aero.CdInterpPts.getGriddedInterpFromPoints(interpMethodEnum, GriddedInterpolantMethodEnum.Nearest);
        aero.CdInterp = gI;
        
        varargout{1} = true;
        varargout{2} = aero;
        varargout{3} = uiArea;
        close(handles.lvd_EditDragPropertiesGUI);
    end


function errMsg = validateInputs(handles)
    errMsg = {};
    
    area = str2double(get(handles.dragAreaText,'String'));
    enteredStr = get(handles.dragAreaText,'String');
    numberName = 'Frontal Area';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(area, numberName, lb, ub, isInt, errMsg, enteredStr);

%     cD = str2double(get(handles.dragCoeffText,'String'));
%     enteredStr = get(handles.dragCoeffText,'String');
%     numberName = 'Drag Coefficient';
%     lb = 0;
%     ub = Inf;
%     isInt = false;
%     errMsg = validateNumber(cD, numberName, lb, ub, isInt, errMsg, enteredStr);   

% --- Executes on button press in saveCloseButton.
function saveCloseButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveCloseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    errMsg = validateInputs(handles);

    if(isempty(errMsg))
        uiresume(handles.lvd_EditDragPropertiesGUI);
    else
        msgbox(errMsg,'Errors were found while editing drag properties.','error');
    end

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.lvd_EditDragPropertiesGUI);


function dragAreaText_Callback(hObject, eventdata, handles)
% hObject    handle to dragAreaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dragAreaText as text
%        str2double(get(hObject,'String')) returns contents of dragAreaText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);

% --- Executes during object creation, after setting all properties.
function dragAreaText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dragAreaText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on lvd_EditDragPropertiesGUI or any of its controls.
function lvd_EditDragPropertiesGUI_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to lvd_EditDragPropertiesGUI (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    switch(eventdata.Key)
        case 'return'
            saveCloseButton_Callback(handles.saveCloseButton, [], handles);
        case 'enter'
            saveCloseButton_Callback(handles.saveCloseButton, [], handles);
        case 'escape'
            close(handles.lvd_EditDragPropertiesGUI);
    end


% --- Executes on selection change in indepVarCombo.
function indepVarCombo_Callback(hObject, eventdata, handles)
% hObject    handle to indepVarCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns indepVarCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from indepVarCombo


% --- Executes during object creation, after setting all properties.
function indepVarCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to indepVarCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ptsListbox.
function ptsListbox_Callback(hObject, eventdata, handles)
% hObject    handle to ptsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ptsListbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ptsListbox
    if(strcmpi(get(handles.lvd_EditDragPropertiesGUI,'SelectionType'),'open'))
        lvdData = getappdata(handles.lvd_EditDragPropertiesGUI,'lvdData');
        initStateModel = lvdData.initStateModel;
        aero = initStateModel.aero;

        indToModify = handles.ptsListbox.Value;
        pointToModify = aero.CdInterpPts.getPointByIndex(indToModify);

        prompt = {'Enter the indepenent variable value:', ...
                  'Enter the drag coefficient value at the independent variable value:'};
        dlg_title = 'New Drag Coefficient Point';
        num_lines = 1;
        defAns = {fullAccNum2Str(pointToModify.x), fullAccNum2Str(pointToModify.v)};

        answer = inputdlg(prompt,dlg_title,num_lines,defAns);
        if(not(isempty(answer)))
            errMsg = {};

            x = str2double(answer{1});
            enteredStr = answer{1};
            numberName = 'Indepedent Var Value';
            lb = -Inf;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(x, numberName, lb, ub, isInt, errMsg, enteredStr);

            v = str2double(answer{2});
            enteredStr = answer{1};
            numberName = 'Cd Value';
            lb = 0;
            ub = Inf;
            isInt = false;
            errMsg = validateNumber(v, numberName, lb, ub, isInt, errMsg, enteredStr);

            [allX, ~] = aero.CdInterpPts.getPointVectors();
            allX(allX == pointToModify.x) = [];
            if(ismember(x, allX))
                errMsg{end+1} = sprintf('A point at entered independent variable (%0.3G) already exists in the table.', x);
            end

            if(isempty(errMsg))
                pointToModify.x = x;
                pointToModify.v = v;
                handles.ptsListbox.String = aero.CdInterpPts.getListboxStr();
            else
                msgbox(errMsg,'Errors were found while adding a Cd value.','error');
            end
        end

        setRemoveEnableState(handles);
    end

% --- Executes during object creation, after setting all properties.
function ptsListbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ptsListbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addPointToCurveButton.
function addPointToCurveButton_Callback(hObject, eventdata, handles)
% hObject    handle to addPointToCurveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    prompt = {'Enter the indepenent variable value:', ...
              'Enter the drag coefficient value at the independent variable value:'};
    dlg_title = 'New Drag Coefficient Point';
    num_lines = 1;
    defAns = {'0.0', '0.3'};
    
    answer = inputdlg(prompt,dlg_title,num_lines,defAns);
    if(not(isempty(answer)))
        lvdData = getappdata(handles.lvd_EditDragPropertiesGUI,'lvdData');
        initStateModel = lvdData.initStateModel;
        aero = initStateModel.aero;
        
        errMsg = {};
        
        x = str2double(answer{1});
        enteredStr = answer{1};
        numberName = 'Indepedent Var Value';
        lb = -Inf;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(x, numberName, lb, ub, isInt, errMsg, enteredStr);
        
        v = str2double(answer{2});
        enteredStr = answer{1};
        numberName = 'Cd Value';
        lb = 0;
        ub = Inf;
        isInt = false;
        errMsg = validateNumber(v, numberName, lb, ub, isInt, errMsg, enteredStr);
        
        [allX, ~] = aero.CdInterpPts.getPointVectors();
        if(ismember(x, allX))
            errMsg{end+1} = sprintf('A point at entered independent variable (%0.3G) already exists in the table.', x);
        end
        
        if(isempty(errMsg))            
            newPoint = GriddedInterpolantPoint(x,v);
            newInd = aero.CdInterpPts.addPoint(newPoint);
            
            handles.ptsListbox.String = aero.CdInterpPts.getListboxStr();
            handles.ptsListbox.Value = newInd;
        else
            msgbox(errMsg,'Errors were found while adding a Cd value.','error');
        end
    end
    
    setRemoveEnableState(handles);
    

% --- Executes on button press in removePointFromCurveButton.
function removePointFromCurveButton_Callback(hObject, eventdata, handles)
% hObject    handle to removePointFromCurveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditDragPropertiesGUI,'lvdData');
    initStateModel = lvdData.initStateModel;
    aero = initStateModel.aero;

    oldListBoxValue = handles.ptsListbox.Value;
    
    indToRemove = handles.ptsListbox.Value;
    pointToRemove = aero.CdInterpPts.getPointByIndex(indToRemove);
    aero.CdInterpPts.removePoint(pointToRemove);
    
    handles.ptsListbox.String = aero.CdInterpPts.getListboxStr();
    
    newNumPts = aero.CdInterpPts.getNumPoints();
    
    if(newNumPts < oldListBoxValue)
        handles.ptsListbox.Value = newNumPts;
    end
    
    setRemoveEnableState(handles);
    
function setRemoveEnableState(handles)
    lvdData = getappdata(handles.lvd_EditDragPropertiesGUI,'lvdData');
    initStateModel = lvdData.initStateModel;
    aero = initStateModel.aero;
    numPts = aero.CdInterpPts.getNumPoints();
    
    if(numPts <= 2)
        handles.removePointFromCurveButton.Enable = 'off';
    else
        handles.removePointFromCurveButton.Enable = 'on';
    end

% --- Executes on button press in plotCurveButton.
function plotCurveButton_Callback(hObject, eventdata, handles)
% hObject    handle to plotCurveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_EditDragPropertiesGUI,'lvdData');
    initStateModel = lvdData.initStateModel;
    aero = initStateModel.aero;

    strs = handles.indepVarCombo.String();
    str = strs{handles.indepVarCombo.Value};
    aeroIndepVarEnum = AeroIndepVar.getEnumForListboxStr(str);

    strs = handles.interpMethodCombo.String();
    str = strs{handles.interpMethodCombo.Value};
    interpMethodEnum = GriddedInterpolantMethodEnum.getEnumForListboxStr(str);
    
    cDInterpPts = aero.CdInterpPts;
    
    gI = cDInterpPts.getGriddedInterpFromPoints(interpMethodEnum, GriddedInterpolantMethodEnum.Nearest);
    numPts = cDInterpPts.getNumPoints();
    numPtsToPlot = 25*numPts;
    
    [x, v] = cDInterpPts.getPointVectors();
    xMin = min(x);
    xMax = max(x);
    xWidth = xMax - xMin;
    
    xPtsToPlot = linspace(xMin - 0.1*xWidth, xMax + 0.1*xWidth, numPtsToPlot);
    vPtsToPlot = gI(xPtsToPlot);
    vPtsToPlot = vPtsToPlot(:);
    vPtsToPlot = max(horzcat(vPtsToPlot, zeros(length(vPtsToPlot), 1)), [], 2);
    
    hFig = figure();
    hAx = axes(hFig);
    hold(hAx,'on');
    hAx.Color = 'k';
    
    plot(hAx, xPtsToPlot, vPtsToPlot, '--w');
    plot(hAx, x, v, 'dg', 'MarkerFaceColor','g');
    
    xlabel(aeroIndepVarEnum.getAxesLabelStr());
    ylabel('Drag Coefficient');
    
    grid minor;
    
    ylim(hAx, [-0.05, 1.1*max(v)]);
    
    whitebg(hFig);
    hold(hAx,'off');

    
% --- Executes on selection change in interpMethodCombo.
function interpMethodCombo_Callback(hObject, eventdata, handles)
% hObject    handle to interpMethodCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns interpMethodCombo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from interpMethodCombo


% --- Executes during object creation, after setting all properties.
function interpMethodCombo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to interpMethodCombo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
