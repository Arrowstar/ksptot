classdef LvdSweepResponse < matlab.mixin.SetGet
    %LvdSweepResponse One number harvested out of every case of a sweep.
    %
    %   A response is any graphical analysis quantity -- the same list the
    %   plot window offers -- read at a chosen node of a chosen event, or of
    %   the whole mission.  That is what makes the results of a sweep a table
    %   of numbers rather than a pile of mission files.
    %
    %   Evaluation deliberately does NOT go through
    %   LvdGraphicalAnalysis.executeTasks: that method wraps every point in a
    %   try/catch and substitutes the value -1 for anything that throws,
    %   which in a table of results is indistinguishable from a real answer
    %   of -1.  Here a failure is NaN plus a message the results window can
    %   show.

    properties
        task(1,1) GraphicalAnalysisTask = GraphicalAnalysisTask('', AbstractReferenceFrame.empty(1,0));
        node(1,1) LvdSweepResponseNodeEnum = LvdSweepResponseNodeEnum.FinalState;

        %0 means the whole mission.  Events have no id, so the scope is the
        %event NUMBER, which survives a byte stream clone just as well.
        eventNum(1,1) double = 0;

        %Display label override; empty means build one from the task.
        label(1,:) char = '';

        id(1,1) double = 0;
    end

    methods
        function obj = LvdSweepResponse(task, node, eventNum)
            arguments
                task(1,1) GraphicalAnalysisTask = GraphicalAnalysisTask('', AbstractReferenceFrame.empty(1,0));
                node(1,1) LvdSweepResponseNodeEnum = LvdSweepResponseNodeEnum.FinalState;
                eventNum(1,1) double = 0;
            end

            obj.task = task;
            obj.node = node;
            obj.eventNum = eventNum;

            obj.id = rand();
        end

        function name = getName(obj)
            if(not(isempty(obj.label)))
                name = obj.label;
                return;
            end

            if(obj.eventNum > 0)
                scopeStr = sprintf('Event %u', obj.eventNum);
            else
                scopeStr = 'Mission';
            end

            name = sprintf('%s %s of %s', scopeStr, obj.node.name, obj.task.getListBoxStr());
        end

        function [value, unit, msg] = evaluate(obj, lvdData)
            %evaluate The response's value for an already propagated mission.
            %
            %   Returns NaN and an explanatory message rather than throwing,
            %   because one unevaluable response must not lose the rest of a
            %   case's results.
            arguments
                obj(1,1) LvdSweepResponse
                lvdData(1,1) LvdData
            end

            value = NaN;
            unit = '';
            msg = '';

            try
                entries = obj.getScopedEntries(lvdData);

                if(isempty(entries))
                    msg = 'No state log entries in scope (was the mission propagated?).';
                    return;
                end

                if(not(obj.node.needsWholeSpan()))
                    if(obj.node == LvdSweepResponseNodeEnum.InitialState)
                        entries = entries(1);
                    else
                        entries = entries(end);
                    end
                end

                maTaskList = ma_getGraphAnalysisTaskList(getLvdGAExcludeList());
                propNames = lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
                celBodyData = lvdData.celBodyData;

                values = NaN(1, numel(entries));
                prevDistTraveled = 0;

                for(i=1:numel(entries)) %#ok<*NO4LP>
                    [depVarValue, depVarUnit, prevDistTraveled] = ...
                        obj.task.executeTask(entries(i), maTaskList, prevDistTraveled, [], [], propNames, celBodyData);

                    values(i) = depVarValue;

                    if(isempty(unit))
                        unit = depVarUnit;
                    end
                end

                value = obj.node.reduce(values);

            catch ME
                value = NaN;
                msg = ME.message;
            end
        end

        function entries = getScopedEntries(obj, lvdData)
            %getScopedEntries The state log span this response reads over.
            stateLog = lvdData.stateLog;

            if(obj.eventNum <= 0)
                entries = stateLog.getAllEntries();
                return;
            end

            evt = lvdData.script.getEventForInd(obj.eventNum);

            if(isempty(evt))
                entries = [];
            else
                entries = stateLog.getAllStateLogEntriesForEvent(evt);
            end
        end
    end

    methods(Static)
        function obj = loadobj(obj)
            if(obj.id == 0)
                obj.id = rand();
            end
        end
    end

    methods(Sealed)
        function tf = eq(A, B)
            tf = [A.id] == [B.id];
        end

        function tf = ne(A, B)
            tf = [A.id] ~= [B.id];
        end
    end
end
