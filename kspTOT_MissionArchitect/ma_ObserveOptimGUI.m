function varargout = ma_ObserveOptimGUI(varargin)
% MA_OBSERVEOPTIMGUI MATLAB code for ma_ObserveOptimGUI.fig
%      MA_OBSERVEOPTIMGUI, by itself, creates a new MA_OBSERVEOPTIMGUI or raises the existing
%      singleton*.
%
%      H = MA_OBSERVEOPTIMGUI returns the handle to a new MA_OBSERVEOPTIMGUI or the handle to
%      the existing singleton*.
%
%      MA_OBSERVEOPTIMGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MA_OBSERVEOPTIMGUI.M with the given input arguments.
%
%      MA_OBSERVEOPTIMGUI('Property','Value',...) creates a new MA_OBSERVEOPTIMGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ma_ObserveOptimGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ma_ObserveOptimGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ma_ObserveOptimGUI

% Last Modified by GUIDE v2.5 06-Feb-2014 18:19:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ma_ObserveOptimGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ma_ObserveOptimGUI_OutputFcn, ...
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


% --- Executes just before ma_ObserveOptimGUI is made visible.
function ma_ObserveOptimGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ma_ObserveOptimGUI (see VARARGIN)

% Choose default command line output for ma_ObserveOptimGUI
handles.output = hObject;

handles.ma_MainGUI = varargin{1};
problem = varargin{2};

% Update handles structure
guidata(hObject, handles);

set(hObject, 'Visible','on');
set(handles.cancelButton,'UserData',false);
drawnow;

set(handles.dispAxes,'XTickLabel',[]);
set(handles.dispAxes,'YTickLabel',[]);
set(handles.dispAxes,'ZTickLabel',[]);
set(handles.dispAxes,'Visible','off');
drawnow;

celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
recorder = ma_OptimRecorder();
outputFnc = @(x, optimValues, state) ma_OptimOutputFunc(x, optimValues, state, handles, problem, celBodyData, recorder);
problem.options.OutputFcn = outputFnc;
executeOptimProblem(handles, problem, recorder);

close(handles.ma_ObserveOptimGUI);

% UIWAIT makes ma_ObserveOptimGUI wait for user response (see UIRESUME)
% uiwait(handles.ma_ObserveOptimGUI);

function executeOptimProblem(handles, problem, recorder)
    global number_state_log_entries_per_coast use_selective_soi_search options_gravParamType;

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
    
    if(problem.options.UseParallel)
        pp=gcp('nocreate');
        fnc1 = @() setNumStateLogEntryPerCoastForWorker(number_state_log_entries_per_coast);
        fnc2 = @() setUseSelectiveSoISearchForWorker(use_selective_soi_search);
        fnc3 = @() setGravParamTypeForWorker(options_gravParamType);
        
        pp.parfevalOnAll(fnc1, 0);
        pp.parfevalOnAll(fnc2, 0);
        pp.parfevalOnAll(fnc3, 0);
    end

    try
        writeOutput('Beginning mission script optimization...','append');
        tt = tic;
%         profile on;
        [x,~,exitflag,~] = fmincon(problem);
%         profile viewer;
        
        execTime = toc(tt);
        writeOutput(sprintf('Mission script optimization finished in %0.3f sec with exit flag "%i".', execTime, exitflag),'append');
    catch ME
        errorStr = {};
        errorStr{end+1} = 'There was an error optimizing the mission script: ';
        errorStr{end+1} = ' ';
        errorStr{end+1} = ME.message;
        errordlg(char(errorStr),'Optimizer Error','modal');
        
        disp('############################################################');
        disp(['MA fmincon Error: ', datestr(now(),'yyyy-mm-dd HH:MM:SS')]);
        disp('############################################################');
        disp(ME.message);
        disp('############################################################');
        try
            disp(ME.cause{1}.message);
            disp('############################################################');
        catch
        end
        for(i=1:length(ME.stack)) %#ok<*NO4LP>
            disp(['Index: ', num2str(i)]);
            disp(['File: ',ME.stack(i).file]);
            disp(['Name: ',ME.stack(i).name]);
            disp(['Line: ',num2str(ME.stack(i).line)]);
            disp('####################');
        end
        
        return;
    end
    
    %%%%%%%
    % Ask if the user wants to keep the current solution or not.
    %%%%%%%
%     userMsg = 'Optimization has finished.  Keep Solution?';
%     button = questdlg(userMsg,'Optimization Finished','Yes','No','Yes'); 
    [~, x] = ma_OptimResultsScorecardGUI(recorder);
    
    if(~isempty(x))
        ma_UndoRedoAddState(handles, 'Optimize');
        writeOutput(sprintf('Optimization results accepted: merging with mission script.'),'append');
        
        %%%%%%%
        % Update existing script, reprocess
        %%%%%%%
        maData.script = ma_updateOptimScript(x, maData.script, maData.optimizer.variables{2});
        
        maData.optimizer.problem = problem; %used to be []
        setappdata(handles.ma_MainGUI,'ma_data',maData);
        maData.stateLog = ma_executeScript(maData.script,handles,celBodyData,findobj('Tag','scriptWorkingLbl'));
        setappdata(handles.ma_MainGUI,'ma_data',maData);
    else
        writeOutput(sprintf('Optimization results discarded: reverting to previous script.'),'append');
    end 
        

% --- Outputs from this function are returned to the command line.
function varargout = ma_ObserveOptimGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = [];


% --- Executes on button press in pauseButton.
function pauseButton_Callback(hObject, eventdata, handles)
% hObject    handle to pauseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    h = msgbox('Optimization has been paused.  Push OK to continue.','Paused','help','modal');
    uiwait(h);

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(handles.cancelButton,'UserData',true);
