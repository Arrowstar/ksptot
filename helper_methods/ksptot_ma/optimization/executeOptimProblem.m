function executeOptimProblem(handles, problem, recorder)
    global number_state_log_entries_per_coast use_selective_soi_search options_gravParamType;

    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    writeOutput = getappdata(handles.ma_MainGUI,'write_to_output_func');
    
    pp=gcp('nocreate');
    if(problem.options.UseParallel && not(isempty(pp)))
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
end