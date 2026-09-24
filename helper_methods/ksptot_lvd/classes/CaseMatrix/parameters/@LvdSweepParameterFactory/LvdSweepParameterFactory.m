classdef LvdSweepParameterFactory
    %LvdSweepParameterFactory Builds the list of everything in a mission that
    %a sweep or a dispersion run could vary.
    %
    %   This is what replaced the original case matrix's "you must create a
    %   plugin variable first" requirement.  Everything here is enumerated
    %   straight out of the mission, so a user can sweep a burn duration or a
    %   stage dry mass without writing any plugin code.

    methods(Static)
        function params = enumerate(lvdData, groups)
            %enumerate Every candidate parameter, in group order.
            %
            %   groups  cell array of group names to include; omit for all.
            %           The Monte Carlo window passes a subset, because a
            %           constraint bound is meaningless as a dispersion
            %           source -- a propagate-only case never evaluates
            %           constraints.
            arguments
                lvdData(1,1) LvdData
                groups(1,:) cell = {};
            end

            params = AbstractLvdSweepParameter.empty(1,0);

            if(LvdSweepParameterFactory.wantsGroup(groups, 'Plugin Variables'))
                params = [params, LvdSweepParameterFactory.enumeratePluginVars(lvdData)];
            end

            if(LvdSweepParameterFactory.wantsGroup(groups, 'Optimization Variables'))
                params = [params, LvdSweepParameterFactory.enumerateOptimVars(lvdData)];
            end

            if(LvdSweepParameterFactory.wantsGroup(groups, 'Vehicle Knobs'))
                params = [params, LvdSweepParameterFactory.enumerateVehicleKnobs(lvdData)];
            end

            if(LvdSweepParameterFactory.wantsGroup(groups, 'Constraint Bounds'))
                params = [params, LvdSweepParameterFactory.enumerateConstraintBounds(lvdData)];
            end
        end

        function groups = getDispersionGroups()
            %getDispersionGroups The groups a Monte Carlo run may disperse.
            groups = {'Plugin Variables', 'Optimization Variables', 'Vehicle Knobs'};
        end

        function params = enumeratePluginVars(lvdData)
            params = LvdSweepPluginVarParameter.empty(1,0);

            pluginVars = lvdData.pluginVars.getPluginVarsArray();
            for(i=1:length(pluginVars)) %#ok<*NO4LP>
                params(end+1) = LvdSweepPluginVarParameter(pluginVars(i)); %#ok<AGROW>
            end
        end

        function params = enumerateOptimVars(lvdData)
            %enumerateOptimVars One parameter per variable ELEMENT.
            %
            %   LvdOptimTableModel already produces exactly this list, with
            %   the display names, units and bounds the variable table shows,
            %   so the two views cannot disagree about what a variable is
            %   called.
            params = LvdSweepOptimVarParameter.empty(1,0);

            [data, meta] = LvdOptimTableModel.getVariableRows(lvdData);

            for(i=1:numel(meta))
                var = meta(i).var;

                %A plugin variable's backing optimization variable is already
                %listed under Plugin Variables; offering it twice would let a
                %user sweep the same number two different ways.
                if(lvdData.pluginVars.isVarAPluginVar(var))
                    continue;
                end

                name = sprintf('%s: %s', data{i,1}, data{i,2});

                params(end+1) = LvdSweepOptimVarParameter(var, meta(i).elemInd, name, meta(i).unitType); %#ok<AGROW>
            end
        end

        function params = enumerateConstraintBounds(lvdData)
            params = LvdSweepConstraintBoundParameter.empty(1,0);

            consts = lvdData.optimizer.constraints.consts;
            bounds = enumeration('LvdSweepBoundEnum');

            for(i=1:length(consts))
                if(not(isprop(consts(i), 'lb')) || not(isprop(consts(i), 'ub')))
                    continue;
                end

                for(j=1:numel(bounds))
                    params(end+1) = LvdSweepConstraintBoundParameter(consts(i), bounds(j)); %#ok<AGROW>
                end
            end
        end

        function params = enumerateVehicleKnobs(lvdData)
            params = LvdSweepVehicleKnobParameter.empty(1,0);

            lv = lvdData.launchVehicle;

            stages = lv.stages;
            for(i=1:length(stages))
                params(end+1) = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.StageDryMass, stages(i)); %#ok<AGROW>
            end

            [~, tanks] = lv.getTanksListBoxStr();
            for(i=1:length(tanks))
                params(end+1) = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.TankInitialMass, tanks(i)); %#ok<AGROW>
                params(end+1) = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.TankCapacity, tanks(i)); %#ok<AGROW>
            end

            [~, engines] = lv.getEnginesListBoxStr();
            for(i=1:length(engines))
                params(end+1) = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.EngineThrustMultiplier, engines(i)); %#ok<AGROW>
                params(end+1) = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.EngineIspMultiplier, engines(i)); %#ok<AGROW>
            end

            initDrag = lvdData.initStateModel.aero.dragCoeffModel;
            if(not(isempty(initDrag)))
                p = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.InitStateDragMultiplier, initDrag);
                p.targetName = 'Initial State';
                params(end+1) = p;
            end

            evts = LvdSweepVehicleKnobParameter.getAllEvents(lvdData);
            for(i=1:length(evts))
                actions = evts(i).actions;

                for(j=1:length(actions))
                    if(isa(actions(j), 'SetDragAeroPropertiesAction'))
                        p = LvdSweepVehicleKnobParameter(LvdSweepVehicleKnobEnum.EventDragMultiplier, actions(j));
                        p.targetName = sprintf('%s, action %u', evts(i).name, j);
                        params(end+1) = p; %#ok<AGROW>
                    end
                end
            end
        end

        function [groupNames, indsByGroup] = groupParameters(params)
            %groupParameters Group headings and the indices under each, for
            %the available-parameters tree.
            arguments
                params(1,:) AbstractLvdSweepParameter
            end

            allGroups = cell(1, numel(params));
            for(i=1:numel(params))
                allGroups{i} = params(i).getGroupName();
            end

            groupNames = unique(allGroups, 'stable');
            indsByGroup = cell(1, numel(groupNames));

            for(g=1:numel(groupNames))
                indsByGroup{g} = find(strcmp(allGroups, groupNames{g}));
            end
        end

        function tf = wantsGroup(groups, name)
            tf = isempty(groups) || ismember(name, groups);
        end
    end
end
