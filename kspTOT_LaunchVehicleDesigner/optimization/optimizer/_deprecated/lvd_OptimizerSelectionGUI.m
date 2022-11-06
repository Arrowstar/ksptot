function varargout = lvd_OptimizerSelectionGUI(varargin)
    % LVD_OPTIMIZERSELECTIONGUI MATLAB code for lvd_OptimizerSelectionGUI.fig
    %      LVD_OPTIMIZERSELECTIONGUI, by itself, creates a new LVD_OPTIMIZERSELECTIONGUI or raises the existing
    %      singleton*.
    %
    %      H = LVD_OPTIMIZERSELECTIONGUI returns the handle to a new LVD_OPTIMIZERSELECTIONGUI or the handle to
    %      the existing singleton*.
    %
    %      LVD_OPTIMIZERSELECTIONGUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in LVD_OPTIMIZERSELECTIONGUI.M with the given input arguments.
    %
    %      LVD_OPTIMIZERSELECTIONGUI('Property','Value',...) creates a new LVD_OPTIMIZERSELECTIONGUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before lvd_OptimizerSelectionGUI_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to lvd_OptimizerSelectionGUI_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help lvd_OptimizerSelectionGUI
    
    % Last Modified by GUIDE v2.5 25-Jan-2020 16:16:14
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @lvd_OptimizerSelectionGUI_OpeningFcn, ...
        'gui_OutputFcn',  @lvd_OptimizerSelectionGUI_OutputFcn, ...
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
    
    
    % --- Executes just before lvd_OptimizerSelectionGUI is made visible.
function lvd_OptimizerSelectionGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_OptimizerSelectionGUI (see VARARGIN)
    
    % Choose default command line output for lvd_OptimizerSelectionGUI
    handles.output = hObject;
    
    centerUIFigure(hObject);
    
    lvdData = varargin{1};
    setappdata(hObject, 'lvdData', lvdData);
    
    handles = populateGUI(lvdData, handles);
    
    % Update handles structure
    guidata(hObject, handles);
    
    % UIWAIT makes lvd_OptimizerSelectionGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_OptimizerSelectionGUI);
    
function handles = populateGUI(lvdData, handles)
    lvdOpt = lvdData.optimizer;
    optAlgoStrs = LvdOptimizerAlgoEnum.getListBoxStr();
    gradAlgoStrs = LvdOptimizerGradientCalculationAlgoEnum.getListBoxStr();
    
    handles.gradientSelCombo.String = gradAlgoStrs;
    handles.gradientSelCombo.Value = LvdOptimizerGradientCalculationAlgoEnum.getIndForName(lvdOpt.gradAlgo.name);
    gradientSelCombo_Callback(handles.gradientSelCombo, [], handles);
    
    handles.optimizerSelectionCombo.String = optAlgoStrs;
    handles.optimizerSelectionCombo.Value = LvdOptimizerAlgoEnum.getIndForName(lvdOpt.optAlgo.name);
    optimizerSelectionCombo_Callback(handles.optimizerSelectionCombo, [], handles);
    
    
    % --- Outputs from this function are returned to the command line.
function varargout = lvd_OptimizerSelectionGUI_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = [];
    else
        lvdData = getappdata(handles.lvd_OptimizerSelectionGUI, 'lvdData');
        lvdOpt = lvdData.optimizer;
        
        gradAlgoStrs = LvdOptimizerGradientCalculationAlgoEnum.getListBoxStr();
        optGradInd = handles.gradientSelCombo.Value;
        gradAlgoEnum = LvdOptimizerGradientCalculationAlgoEnum.getEnumForListboxStr(gradAlgoStrs{optGradInd});
        lvdOpt.gradAlgo = gradAlgoEnum;
        
        optAlgoStrs = LvdOptimizerAlgoEnum.getListBoxStr();
        optAlgoInd = handles.optimizerSelectionCombo.Value;
        optAlgoEnum = LvdOptimizerAlgoEnum.getEnumForListboxStr(optAlgoStrs{optAlgoInd});
        lvdOpt.optAlgo = optAlgoEnum;
        
        varargout{1} = [];
        close(handles.lvd_OptimizerSelectionGUI);
    end
    
    
    % --- Executes on selection change in optimizerSelectionCombo.
function optimizerSelectionCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to optimizerSelectionCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns optimizerSelectionCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from optimizerSelectionCombo
    optAlgoStrs = LvdOptimizerAlgoEnum.getListBoxStr();
    enum = LvdOptimizerAlgoEnum.getEnumForListboxStr(optAlgoStrs{get(hObject,'Value')});
    handles.optimAlgDescTextLbl.String = enum.desc;
    
    if(enum.reqGrad)
        handles.gradientSelCombo.Enable = 'on';
        handles.editSelectedGradAlgoOptions.Enable = 'on';
        gradientSelCombo_Callback(handles.gradientSelCombo, [], handles);
    else
        handles.gradientSelCombo.Enable = 'off';
        handles.editSelectedGradAlgoOptions.Enable = 'off';
    end
    
    % --- Executes during object creation, after setting all properties.
function optimizerSelectionCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to optimizerSelectionCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
    % hObject    handle to saveAndCloseButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    uiresume(handles.lvd_OptimizerSelectionGUI);
    
    % --- Executes on selection change in gradientSelCombo.
function gradientSelCombo_Callback(hObject, eventdata, handles)
    % hObject    handle to gradientSelCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns gradientSelCombo contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from gradientSelCombo
    gradAlgoStrs = LvdOptimizerGradientCalculationAlgoEnum.getListBoxStr();
    enum = LvdOptimizerGradientCalculationAlgoEnum.getEnumForListboxStr(gradAlgoStrs{get(hObject,'Value')});
    handles.optimGradAlgDescTextLbl.String = enum.desc;
    
    if(enum.disableOptions)
        handles.editSelectedGradAlgoOptions.Enable = 'off';
    else
        handles.editSelectedGradAlgoOptions.Enable = 'on';
    end
    
    % --- Executes during object creation, after setting all properties.
function gradientSelCombo_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to gradientSelCombo (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in editSelectedGradAlgoOptions.
function editSelectedGradAlgoOptions_Callback(hObject, eventdata, handles)
    % hObject    handle to editSelectedGradAlgoOptions (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_OptimizerSelectionGUI, 'lvdData');
    
    gradAlgoStrs = LvdOptimizerGradientCalculationAlgoEnum.getListBoxStr();
    gradAlgoInd = handles.gradientSelCombo.Value;
    gradAlgoEnum = LvdOptimizerGradientCalculationAlgoEnum.getEnumForListboxStr(gradAlgoStrs{gradAlgoInd});
    
    lvdOpt = lvdData.optimizer;
    gradAlgo = lvdOpt.getGradAlgoForEnum(gradAlgoEnum);
    gradAlgo.openOptionsDialog();
    
    % --- Executes on button press in editSelectedOptimizerOptionsButton.
function editSelectedOptimizerOptionsButton_Callback(hObject, eventdata, handles)
    % hObject    handle to editSelectedOptimizerOptionsButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    lvdData = getappdata(handles.lvd_OptimizerSelectionGUI, 'lvdData');
    
    optAlgoStrs = LvdOptimizerAlgoEnum.getListBoxStr();
    optAlgoInd = handles.optimizerSelectionCombo.Value;
    optAlgoEnum = LvdOptimizerAlgoEnum.getEnumForListboxStr(optAlgoStrs{optAlgoInd});
    
    lvdOpt = lvdData.optimizer;
    optimizer = lvdOpt.getOptimizerForEnum(optAlgoEnum);
    optimizer.openOptionsDialog();
