function findBestIntegrator(lvdData, app)
    arguments
        lvdData(1,1) LvdData
        app ma_LvdMainGUI_App = ma_LvdMainGUI_App.empty(1,0);
    end

    if(not(isempty(app)))
        p = uiprogressdlg(app.ma_LvdMainGUI, "ShowPercentage","on", "Title","Optimize Integrator Selection", "Message","Determining Best Integrator for each Event...");
    else
        p = [];
    end

    numIntegratorsToTests = 5;
    numEvents = length(lvdData.script.evts);
    totalRuns = numIntegratorsToTests * numEvents;
    totalRunsComplete = 0;
    for(i=1:numEvents)
        evt = lvdData.script.evts(i);
        options = getArrayFromByteStream(getByteStreamFromArray(lvdData.script.evts(i).integratorObj.options));

        if(not(isempty(p)))
            p.Message = sprintf("Determining Best Integrator for Event %u...", i);
        end

        evt.integratorObj = evt.ode45Integrator;
        evt.integratorObj.options = options;
        runTimeOde45 = runAndTimeScript(lvdData);
        totalRunsComplete = totalRunsComplete + 1;
        if(not(isempty(p)))
            p.Value = totalRunsComplete/totalRuns;
        end

        evt.integratorObj = evt.ode113Integrator;
        evt.integratorObj.options = options;
        runTimeOde113 = runAndTimeScript(lvdData);
        totalRunsComplete = totalRunsComplete + 1;
        if(not(isempty(p)))
            p.Value = totalRunsComplete/totalRuns;
        end

        evt.integratorObj = evt.ode23Integrator;
        evt.integratorObj.options = options;
        runTimeOde23 = runAndTimeScript(lvdData);
        totalRunsComplete = totalRunsComplete + 1;
        if(not(isempty(p)))
            p.Value = totalRunsComplete/totalRuns;
        end

        evt.integratorObj = evt.ode78Integrator;
        evt.integratorObj.options = options;
        runTimeOde78 = runAndTimeScript(lvdData);
        totalRunsComplete = totalRunsComplete + 1;
        if(not(isempty(p)))
            p.Value = totalRunsComplete/totalRuns;
        end

        evt.integratorObj = evt.ode89Integrator;
        evt.integratorObj.options = options;
        runTimeOde89 = runAndTimeScript(lvdData);
        totalRunsComplete = totalRunsComplete + 1;
        if(not(isempty(p)))
            p.Value = totalRunsComplete/totalRuns;
        end

        data(i,:) = [runTimeOde45, runTimeOde113, runTimeOde23, runTimeOde78, runTimeOde89]; %#ok<AGROW>
        minRunTime = min(data(i,:));
        switch minRunTime
            case runTimeOde45
                evt.integratorObj = evt.ode45Integrator;

            case runTimeOde113
                evt.integratorObj = evt.ode113Integrator;

            case runTimeOde23
                evt.integratorObj = evt.ode23Integrator;

            case runTimeOde78
                evt.integratorObj = evt.ode78Integrator;

            case runTimeOde89
                evt.integratorObj = evt.ode89Integrator;
        end

        fprintf('Done with event %u of %u (Current Run Time: %0.3f s).\n', i, length(lvdData.script.evts), minRunTime);
    end

    % disp(runAndTimeScript(lvdData));
    % disp(data);
end

function runTime = runAndTimeScript(lvdData)
    for(i=1:10)
        t = tic;
        lvdData.script.executeScript(false, lvdData.script.evts(1), true, false, false, false);
        runTimes = toc(t);
    end
    runTime = min(runTimes);
end