function startParallelPool(appFigure, writeOutput, numWorkers)
    p = gcp('nocreate');
    if(isempty(p) || p.NumWorkers ~= numWorkers)
        try
            beep off;
            %                     h = msgbox('Attempting to start parallel computing workers.  Please wait...','modal');
            h = uiprogressdlg(appFigure, 'Message', 'Attempting to start parallel computing workers.  Please wait...', ...
                'Title','Launch Vehicle Designer', ...
                'Indeterminate','on');

            if(not(isempty(p)))
                delete(p);
            end

            pp=parpool('local',numWorkers);
            pp.IdleTimeout = 99999; %we don't want the pool to shutdown
            if(isvalid(h))
                close(h);
            end
            writeOutput('Parallel optimization mode enabled.','append');
            beep on;
        catch ME
            if(ishandle(h))
                close(h);
            end
            msg = sprintf('Parallel mode start failed.  Optimization will run in serial.  Message:\n\n%s',ME.message);
            %                     msgbox(msg);
            uialert(appFigure, msg, 'Launch Vehicle Designer', "Icon",'warning');
            disp(ME.message);
            beep on;
        end
    else
        writeOutput('Parallel optimization mode enabled.','append');
    end
end