function lvd_executeOptimProblem(celBodyData, writeOutput, problem, recorder)
    initX = [];
    
    try
        lvdData = problem.lvdData;
        initX = lvdData.optimizer.vars.getTotalScaledXVector();
        
        writeOutput('Beginning mission script optimization...','append');
        tt = tic;
%         profile on;
        [x,fval,exitflag,output,lambda,grad,hessian] = fmincon(problem);
%         gs = GlobalSearch('NumTrialPoints',201, 'StartPointsToRun','bounds');
%         [x,fval,exitflag,output,solutions] = run(gs,problem);
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
        
        if(not(isempty(initX)))
            lvdData.optimizer.vars.updateObjsWithScaledVarValues(initX); %basically revert to the initial x vector if we run into problems
        end
        
        return;
    end
    
    %%%%%%%
    % Ask if the user wants to keep the current solution or not.
    %%%%%%%
    [~, x] = ma_OptimResultsScorecardGUI(recorder);
    
    if(~isempty(x))
%         ma_UndoRedoAddState(handles, 'Optimize');
        writeOutput(sprintf('Optimization results accepted: merging with mission script.'),'append');
        
        %%%%%%%
        % Update existing script, reprocess
        %%%%%%%
        
        lvdData.optimizer.vars.updateObjsWithScaledVarValues(x);
    else
        writeOutput(sprintf('Optimization results discarded: reverting to previous script.'),'append');
        
        lvdData.optimizer.vars.updateObjsWithScaledVarValues(initX);
    end 
end