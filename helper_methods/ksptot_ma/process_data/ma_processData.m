function ma_processData(handles, varargin)
%ma_processData Summary of this function goes here
%   Detailed explanation goes here3

    if(~isempty(varargin))
        maData = varargin{1};
        celBodyData = varargin{2};
    else
        maData = getappdata(handles.ma_MainGUI,'ma_data');
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    end
    
    %%%%%%%%%%
    % Redraw plots
    %%%%%%%%%%
    set(handles.plotWorkingLbl,'Visible','on');
    drawnow;
    [az,el] = view(handles.dispAxes);
    ma_updateDispAxis(handles, maData.stateLog, get(handles.dispAxes,'UserData'));
    view(handles.dispAxes, [az,el]);
    set(handles.plotWorkingLbl,'Visible','off');
    drawnow;
    
    %%%%%%%%%%
    % Update script listbox
    %%%%%%%%%%
    ma_updateScriptListbox(handles.scriptListbox, maData.script);
    drawnow;
    
    %%%%%%%%%%
    % Update State Readouts
    %%%%%%%%%%
    ma_UpdateStateReadout(handles.initialStateReadoutLabel, 'initial', maData.spacecraft.propellant.names, maData.stateLog, celBodyData);
    ma_UpdateStateReadout(handles.finalStateReadoutLabel, 'final', maData.spacecraft.propellant.names, maData.stateLog, celBodyData);
    drawnow;
end

