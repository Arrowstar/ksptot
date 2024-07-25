function [exitflag, message] = lvd_executeOptimProblem(celBodyData, writeOutput, problem, recorder, callOutputFcn)
    global options_gravParamType;
    initX = []; %#ok<NASGU>
    
    try
        useParallel = problem.options.UseParallel;
    catch ME %#ok<NASGU>
        if(isprop(problem.options,'UseParallel') || isfield(struct(problem.options),'UseParallel'))
            useParallel = problem.options.UseParallel;
        else
            useParallel = problem.UseParallel;
        end
    end
    
    if(useParallel)
        pp=gcp('nocreate');
        
        if(not(isempty(pp)))
            fnc3 = @() setGravParamTypeForWorker(options_gravParamType);
            pp.parfevalOnAll(fnc3, 0);
        end
    end
    
    lvdData = problem.lvdData;
    initX = lvdData.optimizer.vars.getTotalScaledXVector();

    writeOutput('Beginning mission script optimization...','append');
    tt = tic;
    if(strcmpi(problem.solver,'fmincon'))
        [x,fval,exitflag,output,lambda,grad,hessian] = fmincon(problem);
        message = output.message;
        
    elseif(strcmpi(problem.solver,'sqp'))
        problem = rmfield(problem,'lvdData');
        problem.options.MaxLineSearchFun = 300;
        problem.options.Scale = 1;
        [x,out,v,H,exitflag] = sqp(problem);
        message = out.status;

    elseif(strcmpi(problem.solver,'patternsearch'))
        [x,fval,exitflag,output] = patternsearch(problem);
        message = output.message;
        
    elseif(strcmpi(problem.solver,'nomad'))   
        %This block is needed for NOMAD v4.3+
        %We need to turn every option value into a character array.
        o = problem.options;
        f = fields(o);
        for(i=1:numel(f)) %#ok<*NO4LP> 
            if(not(isa(o.(f{i}),'function_handle'))) %don't try to convert function handles
                o.(f{i}) = char(string(o.(f{i}))); 
            end

            if(isempty(o.(f{i})))
                o = rmfield(o, f{i});
            end
        end

        if(isfield(o,'iterfun'))
            iterFun = o.iterfun;
            o = rmfield(o,'iterfun');
        else
            iterFun = [];
        end

%         [x,fval,exitflag,iter,nfval] = nomad(problem.objective, problem.x0, problem.lb, problem.ub, problem.options);
        [x,fval,exitflag,iter,nfval] = nomadOpt(problem.objective, problem.x0, problem.lb, problem.ub, o, iterFun);
        message = nomadExitFlagMessageLookup(exitflag);

    elseif(strcmpi(problem.solver,'ipopt'))
        [x,info] = ipopt(problem.x0, problem.funcs, problem.options);
        exitflag = info.status;
        message = ipoptExitFlagMessageLookup(exitflag);
       
    elseif(strcmpi(problem.solver,'surrogateopt'))
        [x,fval,exitflag,output,trials] = surrogateopt(problem);
        message = output.message;
        
    else
        error('Unknown optimizer function: %s', problem.solver);
    end

    execTime = toc(tt);
    writeOutput(sprintf('Mission script optimization finished in %0.3f sec with exit flag "%i".', execTime, exitflag),'append');
    
    %%%%%%%
    % Ask if the user wants to keep the current solution or not.
    %%%%%%%
    if(callOutputFcn)
%         [~, x] = ma_OptimResultsScorecardGUI(recorder);
        out = AppDesignerGUIOutput({[],[]});
        ma_OptimResultsScorecardGUI_App(recorder, out);
        x = out.output{2};
    end
    
    if(~isempty(x))
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