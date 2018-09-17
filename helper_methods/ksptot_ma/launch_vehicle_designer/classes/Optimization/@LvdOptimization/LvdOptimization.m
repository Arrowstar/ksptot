classdef LvdOptimization < matlab.mixin.SetGet
    %LvdOptimization Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
        
        vars(1,1) OptimizationVariableSet = OptimizationVariableSet()
        objFcn(1,1) AbstractObjectiveFcn = NoOptimizationObjectiveFcn()
        constraints(1,1) ConstraintSet =  ConstraintSet()
    end
    
    methods
        function obj = LvdOptimization(lvdData)
            obj.lvdData = lvdData;
            
            obj.vars = OptimizationVariableSet();
            obj.objFcn = NoOptimizationObjectiveFcn();
            obj.constraints = ConstraintSet(obj, lvdData);
        end
        
        function optimize(obj, maData)            
            objFuncWrapper = @(x) obj.objFcn.evalObjFcn(x, maData);
            x0All = obj.vars.getTotalXVector();
            [lbAll, ubAll] = obj.vars.getTotalBndsVector();
            nonlcon = @(x) obj.constraints.evalConstraints(x, maData);
            
            optimAlg = maData.settings.optimAlg;
            options = optimoptions('fmincon','Algorithm','sqp', 'Diagnostics','on', 'Display','iter-detailed','TolFun',1E-6,'TolX',1E-6,'TolCon',1E-6,'ScaleProblem','none','MaxIter',500,'UseParallel',false,'OutputFcn',[],'InitBarrierParam',1.0,'InitTrustRegionRadius',0.1,'HonorBounds',true,'MaxFunctionEvaluations',3000, 'PlotFcn', {@optimplotfval, @optimplotconstrviolation});
            problem = createOptimProblem('fmincon', 'objective',objFuncWrapper, 'x0', x0All, 'lb', lbAll, 'ub', ubAll, 'nonlcon', nonlcon, 'options', options);
            
            %TODO
%             celBodyData = maData.celBodyData;
%             recorder = ma_OptimRecorder();
%             outputFnc = @(x, optimValues, state) ma_OptimOutputFunc(x, optimValues, state, handles, problem, celBodyData, recorder);
%             problem.options.OutputFcn = outputFnc;
            
            try
%                 writeOutput('Beginning mission script optimization...','append');
                tt = tic;
        %         profile on;
                [x,~,exitflag,~] = fmincon(problem);
        %         profile viewer;

                execTime = toc(tt);
%                 writeOutput(sprintf('Mission script optimization finished in %0.3f sec with exit flag "%i".', execTime, exitflag),'append');
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

                throw(ME);
                
                return;
            end
            
            %%%%%%%
            % Ask if the user wants to keep the current solution or not.
            %%%%%%%
%             [~, x] = ma_OptimResultsScorecardGUI(recorder);

            if(~isempty(x))
%                 ma_UndoRedoAddState(handles, 'Optimize');
%                 writeOutput(sprintf('Optimization results accepted: merging with mission script.'),'append');

                %%%%%%%
                % Update existing script, reprocess
                %%%%%%%
                obj.vars.updateObjsWithVarValues(x);

%                 maData.optimizer.problem = problem; %used to be []
%                 setappdata(handles.ma_MainGUI,'ma_data',maData);
                obj.lvdData.script.executeScript();
%                 setappdata(handles.ma_MainGUI,'ma_data',maData);
            else
%                 writeOutput(sprintf('Optimization results discarded: reverting to previous script.'),'append');
            end 
            
            
        end
    end
end