function varargout = lvd_EditSumOfPolynomialTermsModelGUI(varargin)
    % LVD_EDITSUMOFPOLYNOMIALTERMSMODELGUI MATLAB code for lvd_EditSumOfPolynomialTermsModelGUI.fig
    %      LVD_EDITSUMOFPOLYNOMIALTERMSMODELGUI, by itself, creates a new LVD_EDITSUMOFPOLYNOMIALTERMSMODELGUI or raises the existing
    %      singleton*.
    %
    %      H = LVD_EDITSUMOFPOLYNOMIALTERMSMODELGUI returns the handle to a new LVD_EDITSUMOFPOLYNOMIALTERMSMODELGUI or the handle to
    %      the existing singleton*.
    %
    %      LVD_EDITSUMOFPOLYNOMIALTERMSMODELGUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in LVD_EDITSUMOFPOLYNOMIALTERMSMODELGUI.M with the given input arguments.
    %
    %      LVD_EDITSUMOFPOLYNOMIALTERMSMODELGUI('Property','Value',...) creates a new LVD_EDITSUMOFPOLYNOMIALTERMSMODELGUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before lvd_EditSumOfPolynomialTermsModelGUI_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to lvd_EditSumOfPolynomialTermsModelGUI_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help lvd_EditSumOfPolynomialTermsModelGUI
    
    % Last Modified by GUIDE v2.5 23-Apr-2021 10:26:38
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @lvd_EditSumOfPolynomialTermsModelGUI_OpeningFcn, ...
        'gui_OutputFcn',  @lvd_EditSumOfPolynomialTermsModelGUI_OutputFcn, ...
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
    
    
    % --- Executes just before lvd_EditSumOfPolynomialTermsModelGUI is made visible.
function lvd_EditSumOfPolynomialTermsModelGUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to lvd_EditSumOfPolynomialTermsModelGUI (see VARARGIN)
    
    % Choose default command line output for lvd_EditSumOfPolynomialTermsModelGUI
    handles.output = hObject;
    
    sumOfPolyTerms = varargin{1};
    setappdata(hObject,'sumOfPolyTerms',sumOfPolyTerms);
    
    setappdata(hObject,'plotDur',1.0);
    
    populateGUI(handles, sumOfPolyTerms);
    
    % Update handles structure
    guidata(hObject, handles);
    
    % UIWAIT makes lvd_EditSumOfPolynomialTermsModelGUI wait for user response (see UIRESUME)
    uiwait(handles.lvd_EditSumOfPolynomialTermsModelGUI);
    
function populateGUI(handles, sumOfPolyTerms)
    handles.constText.String = fullAccNum2Str(rad2deg(sumOfPolyTerms.const));
    handles.constOptCheckbox.Value = double(sumOfPolyTerms.varConst);
    handles.constLbText.String = fullAccNum2Str(rad2deg(sumOfPolyTerms.constLb));
    handles.constUbText.String = fullAccNum2Str(rad2deg(sumOfPolyTerms.constUb));
    
    constOptCheckbox_Callback(handles.constOptCheckbox, [], handles);
    
    sineListboxStr = sumOfPolyTerms.getListboxStr();
    handles.termListbox.String = sineListboxStr;
    if(~isempty(sineListboxStr))
        handles.termListbox.Value = 1;
    end
    
    populateTermDefinition(handles, sumOfPolyTerms);
    
function populateTermDefinition(handles, sumOfPolyTerms)
    termModel = getSelectedTermModel(handles, sumOfPolyTerms);
    
    if(not(isempty(termModel)))
        setTermModelWidgetsEnable(handles, 'on');
        
        handles.coeffText.String = fullAccNum2Str(rad2deg(termModel.coeff));
        handles.coeffOptCheckbox.Value = double(termModel.varCoeff);
        handles.coeffLbText.String = fullAccNum2Str(rad2deg(termModel.coeffLb));
        handles.coeffUbText.String = fullAccNum2Str(rad2deg(termModel.coeffUb));
        coeffOptCheckbox_Callback(handles.coeffOptCheckbox, [], handles);
        
        handles.expText.String = fullAccNum2Str(termModel.exponent);
        handles.expOptCheckbox.Value = double(termModel.varExp);
        handles.expLbText.String = fullAccNum2Str(termModel.expLb);
        handles.expUbText.String = fullAccNum2Str(termModel.expUb);
        expOptCheckbox_Callback(handles.expOptCheckbox, [], handles);
        
    else
        setTermModelWidgetsEnable(handles, 'off');
    end
    
function setTermModelWidgetsEnable(handles, enableStr)
    handles.coeffText.Enable = enableStr;
    handles.coeffOptCheckbox.Enable = enableStr;
    handles.coeffLbText.Enable = enableStr;
    handles.coeffUbText.Enable = enableStr;
    
    handles.expText.Enable = enableStr;
    handles.expOptCheckbox.Enable = enableStr;
    handles.expLbText.Enable = enableStr;
    handles.expUbText.Enable = enableStr;
    
    
function termModel = getSelectedTermModel(handles, sumOfPolyTerms)
    numSines = sumOfPolyTerms.getNumTerms();
    
    if(numSines > 0)
        selTermInd = handles.termListbox.Value;
        termModel = sumOfPolyTerms.getTermAtInd(selTermInd);
    else
        termModel = PolynominalTermModel.empty(1,0);
    end
    
    
    % --- Outputs from this function are returned to the command line.
function varargout = lvd_EditSumOfPolynomialTermsModelGUI_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Get default command line output from handles structure
    if(isempty(handles))
        varargout{1} = false;
    else
        varargout{1} = true;
        close(handles.lvd_EditSumOfPolynomialTermsModelGUI);
    end
    
    
    % --- Executes on button press in saveAndCloseButton.
function saveAndCloseButton_Callback(hObject, eventdata, handles)
    % hObject    handle to saveAndCloseButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    errMsg = {};
    if(isempty(errMsg))
        uiresume(handles.lvd_EditSumOfPolynomialTermsModelGUI);
    else
        msgbox(errMsg,'Errors were found while editing plugins.','error');
    end
    
    % --- Executes on selection change in termListbox.
function termListbox_Callback(hObject, eventdata, handles)
    % hObject    handle to termListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns termListbox contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from termListbox
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    populateTermDefinition(handles, sumOfPolyTerms);
    
    
    % --- Executes during object creation, after setting all properties.
function termListbox_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to termListbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function constText_Callback(hObject, eventdata, handles)
    % hObject    handle to constText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of constText as text
    %        str2double(get(hObject,'String')) returns contents of constText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Constant Offset';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sumOfPolyTerms.const = deg2rad(value);
    else
        hObject.String = fullAccNum2Str(sumOfPolyTerms.const);
        
        msgbox(errMsg,'Invalid Sine Constant Offset','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function constText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to constText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in constOptCheckbox.
function constOptCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to constOptCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of constOptCheckbox
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    sumOfPolyTerms.varConst = logical(hObject.Value);
    
    if(hObject.Value)
        handles.constLbText.Enable = 'on';
        handles.constUbText.Enable = 'on';
    else
        handles.constLbText.Enable = 'off';
        handles.constUbText.Enable = 'off';
    end
    
    
function constLbText_Callback(hObject, eventdata, handles)
    % hObject    handle to constLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of constLbText as text
    %        str2double(get(hObject,'String')) returns contents of constLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Constant Offset Lower Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sumOfPolyTerms.constLb = deg2rad(value);
    else
        hObject.String = fullAccNum2Str(sumOfPolyTerms.constLb);
        
        msgbox(errMsg,'Invalid Sine Constant Offset Lower Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function constLbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to constLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function constUbText_Callback(hObject, eventdata, handles)
    % hObject    handle to constUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of constUbText as text
    %        str2double(get(hObject,'String')) returns contents of constUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Sine Constant Offset Upper Bound';
    lb = sumOfPolyTerms.constLb;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        sumOfPolyTerms.constUb = deg2rad(value);
    else
        hObject.String = fullAccNum2Str(sumOfPolyTerms.constUb);
        
        msgbox(errMsg,'Invalid Sine Constant Offset Upper Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function constUbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to constUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function coeffText_Callback(hObject, eventdata, handles)
    % hObject    handle to coeffText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of coeffText as text
    %        str2double(get(hObject,'String')) returns contents of coeffText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    termModel = getSelectedTermModel(handles, sumOfPolyTerms);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Term Coefficient';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        termModel.coeff = deg2rad(value);
        
        handles.termListbox.String = sumOfPolyTerms.getListboxStr();
    else
        hObject.String = fullAccNum2Str(termModel.coeff);
        
        msgbox(errMsg,'Invalid Term Coefficient','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function coeffText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to coeffText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in coeffOptCheckbox.
function coeffOptCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to coeffOptCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of coeffOptCheckbox
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    termModel = getSelectedTermModel(handles, sumOfPolyTerms);
    termModel.varCoeff = logical(hObject.Value);
    
    if(hObject.Value)
        handles.coeffLbText.Enable = 'on';
        handles.coeffUbText.Enable = 'on';
    else
        handles.coeffLbText.Enable = 'off';
        handles.coeffUbText.Enable = 'off';
    end
    
    
function coeffLbText_Callback(hObject, eventdata, handles)
    % hObject    handle to coeffLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of coeffLbText as text
    %        str2double(get(hObject,'String')) returns contents of coeffLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    termModel = getSelectedTermModel(handles, sumOfPolyTerms);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Term Coefficient Lower Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        termModel.coeffLb = deg2rad(value);
    else
        hObject.String = fullAccNum2Str(termModel.coeffLb);
        
        msgbox(errMsg,'Invalid Term Coefficient Lower Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function coeffLbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to coeffLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function coeffUbText_Callback(hObject, eventdata, handles)
    % hObject    handle to coeffUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of coeffUbText as text
    %        str2double(get(hObject,'String')) returns contents of coeffUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    termModel = getSelectedTermModel(handles, sumOfPolyTerms);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Term Coefficient Upper Bound';
    lb = termModel.coeffLb;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        termModel.coeffUb = deg2rad(value);
    else
        hObject.String = fullAccNum2Str(termModel.coeffUb);
        
        msgbox(errMsg,'Invalid Term Coefficient Upper Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function coeffUbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to coeffUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function expText_Callback(hObject, eventdata, handles)
    % hObject    handle to expText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of expText as text
    %        str2double(get(hObject,'String')) returns contents of expText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    termModel = getSelectedTermModel(handles, sumOfPolyTerms);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Term Exponent';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        termModel.exponent = value;
        
        handles.termListbox.String = sumOfPolyTerms.getListboxStr();
    else
        hObject.String = fullAccNum2Str(termModel.exponent);
        
        msgbox(errMsg,'Invalid Term Exponent','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function expText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to expText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in expOptCheckbox.
function expOptCheckbox_Callback(hObject, eventdata, handles)
    % hObject    handle to expOptCheckbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hint: get(hObject,'Value') returns toggle state of expOptCheckbox
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    termModel = getSelectedTermModel(handles, sumOfPolyTerms);
    termModel.varExp = logical(hObject.Value);
    
    if(hObject.Value)
        handles.expLbText.Enable = 'on';
        handles.expUbText.Enable = 'on';
    else
        handles.expLbText.Enable = 'off';
        handles.expUbText.Enable = 'off';
    end
    
    
function expLbText_Callback(hObject, eventdata, handles)
    % hObject    handle to expLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of expLbText as text
    %        str2double(get(hObject,'String')) returns contents of expLbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    termModel = getSelectedTermModel(handles, sumOfPolyTerms);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Term Exponent Lower Bound';
    lb = -Inf;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        termModel.expLb = value;
    else
        hObject.String = fullAccNum2Str(termModel.expLb);
        
        msgbox(errMsg,'Invalid Term Exponent Lower Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function expLbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to expLbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    
function expUbText_Callback(hObject, eventdata, handles)
    % hObject    handle to expUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of expUbText as text
    %        str2double(get(hObject,'String')) returns contents of expUbText as a double
    newInput = get(hObject,'String');
    newInput = attemptStrEval(newInput);
    set(hObject,'String', newInput);
    
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    termModel = getSelectedTermModel(handles, sumOfPolyTerms);
    
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Term Exponent Upper Bound';
    lb = termModel.expLb;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(isempty(errMsg))
        termModel.expUb = value;
    else
        hObject.String = fullAccNum2Str(termModel.expUb);
        
        msgbox(errMsg,'Invalid Term Exponent Upper Bound','error');
    end
    
    % --- Executes during object creation, after setting all properties.
function expUbText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to expUbText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in addTermButton.
function addTermButton_Callback(hObject, eventdata, handles)
    % hObject    handle to addTermButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    
    termModel = PolynominalTermModel(0, 1, 1);
    sumOfPolyTerms.addTerm(termModel);
    
    handles.termListbox.String = sumOfPolyTerms.getListboxStr();
    handles.termListbox.Value = sumOfPolyTerms.getNumTerms();
    
    populateTermDefinition(handles, sumOfPolyTerms);
    
    
    % --- Executes on button press in removeTermButton.
function removeTermButton_Callback(hObject, eventdata, handles)
    % hObject    handle to removeTermButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    termModel = getSelectedTermModel(handles, sumOfPolyTerms);
    
    if(not(isempty(termModel)))
        sumOfPolyTerms.removeTerm(termModel);
    end
    
    listBoxStr = sumOfPolyTerms.getListboxStr();
    handles.termListbox.String = listBoxStr;
    
    if(handles.termListbox.Value > length(listBoxStr))
        handles.termListbox.Value = length(listBoxStr);
    end
    
    populateTermDefinition(handles, sumOfPolyTerms);
    


% --- Executes on button press in plotPolynomialButton.
function plotPolynomialButton_Callback(hObject, eventdata, handles)
% hObject    handle to plotPolynomialButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    duration = str2double(handles.durationToPlot.String);
    
    t0 = sumOfPolyTerms.getT0();
    t = linspace(t0,t0+duration,500);
    y = NaN(1,length(t));
    
    for(i=1:length(t))
        y(i) = sumOfPolyTerms.getValueAtTime(t(i));
    end
    
    y = rad2deg(y);

    hAx = axes(figure());
    plot(hAx, t, y);
    grid(hAx,'minor');
    xlabel('DT [sec]');
    ylabel('Polynomial Value [deg]');
    


% --------------------------------------------------------------------
function copyTermMenu_Callback(hObject, eventdata, handles)
% hObject    handle to copyTermMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    sumOfPolyTerms = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'sumOfPolyTerms');
    termModel = getSelectedTermModel(handles, sumOfPolyTerms);
    
    newTermModel = termModel.deepCopy();
    sumOfPolyTerms.addTerm(newTermModel);
    
    listBoxStr = sumOfPolyTerms.getListboxStr();
    handles.termListbox.String = listBoxStr;
    handles.termListbox.Value = length(listBoxStr);
    
    populateTermDefinition(handles, sumOfPolyTerms);
    
% --------------------------------------------------------------------
function termListboxMenu_Callback(hObject, eventdata, handles)
% hObject    handle to termListboxMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function durationToPlot_Callback(hObject, eventdata, handles)
% hObject    handle to durationToPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of durationToPlot as text
%        str2double(get(hObject,'String')) returns contents of durationToPlot as a double
    errMsg = {};
    
    value = str2double(get(hObject,'String'));
    enteredStr = get(hObject,'String');
    numberName = 'Duration to Plot';
    lb = 0;
    ub = Inf;
    isInt = false;
    errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    
    if(not(isempty(errMsg)))  
        oldPlotDur = getappdata(handles.lvd_EditSumOfPolynomialTermsModelGUI,'plotDur');
        handles.durationToPlot.String = fullAccNum2Str(oldPlotDur);
        
        msgbox(errMsg,'Invalid Plotting Duration','error');
    end

% --- Executes during object creation, after setting all properties.
function durationToPlot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to durationToPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
