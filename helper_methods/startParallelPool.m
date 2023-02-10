function startParallelPool(appFigure, writeOutput, numWorkers)
    arguments
        appFigure matlab.ui.Figure
        writeOutput(1,1)
        numWorkers(1,1) double {mustBeInteger(numWorkers), mustBeGreaterThanOrEqual(numWorkers,1)}
    end

    p = gcp('nocreate');
    numCores = feature('numcores');
    
    if(numWorkers > numCores)
        warning('Cannot create parallel pool with more workers (%u) than exist physical CPU cores on this PC (%u).', numWorkers, numCores);
    end
    numWorkers = min(numWorkers, numCores);

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
            pp.IdleTimeout = Inf; %we don't want the pool to shutdown
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