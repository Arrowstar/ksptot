classdef LvdSweepVehicleKnobParameter < AbstractLvdSweepParameter
    %LvdSweepVehicleKnobParameter Sweeps a vehicle or environment quantity
    %that is not an optimization variable.
    %
    %   See LvdSweepVehicleKnobEnum for what the knobs are.  The interesting
    %   case is the two engine multipliers.  They scale the thrust or Isp
    %   pressure curve, and they apply ABSOLUTELY against a baseline that is
    %   captured from the pristine template before the run starts:
    %
    %       elems(k).depVar = baseline(k) * multiplier
    %
    %   rather than elems(k).depVar = elems(k).depVar * multiplier.  That
    %   matters because a case in Optimize mode does not start from the
    %   template -- it starts from a clone of the nearest already completed
    %   case, whose curves have already been scaled once.  A relative apply
    %   would compound (1.1 applied to an already-1.1-scaled curve gives
    %   1.21) and every case after the first would be silently wrong.

    properties
        knob(1,1) LvdSweepVehicleKnobEnum = LvdSweepVehicleKnobEnum.StageDryMass;

        targetId(1,1) double = 0;
        targetName(1,:) char = '';

        %Captured from the template at run start for the multiplier knobs.
        baseline(1,:) double = [];
    end

    properties(Transient)
        target
    end

    methods
        function obj = LvdSweepVehicleKnobParameter(knob, target)
            arguments
                knob(1,1) LvdSweepVehicleKnobEnum = LvdSweepVehicleKnobEnum.StageDryMass;
                target = [];
            end

            obj.knob = knob;

            if(not(isempty(target)))
                obj.target = target;
                obj.targetName = LvdSweepVehicleKnobParameter.getTargetDisplayName(target);
                obj.isResolved = true;

                %The initial state's drag model is a singleton reached by
                %path rather than by id, so it has no id to record.
                if(isprop(target, 'id'))
                    obj.targetId = target.id;
                end
            end

            obj.id = rand();
        end

        function name = getName(obj)
            if(isempty(obj.targetName))
                name = obj.knob.name;
            else
                name = sprintf('%s - "%s"', obj.knob.name, obj.targetName);
            end
        end

        function unit = getUnit(obj)
            unit = obj.knob.unit;
        end

        function group = getGroupName(~)
            group = 'Vehicle Knobs';
        end

        function tf = isPinnable(obj)
            %A stage dry mass or tank initial mass can also be an
            %optimization variable (they own optVar handles), so those DO
            %get pinned; the multipliers and drag knobs have nothing to pin.
            tf = ismember(obj.knob, [LvdSweepVehicleKnobEnum.StageDryMass, ...
                                     LvdSweepVehicleKnobEnum.TankInitialMass]);
        end

        function tf = resolve(obj, lvdData)
            arguments
                obj(1,1) LvdSweepVehicleKnobParameter
                lvdData(1,1) LvdData
            end

            obj.target = [];
            obj.isResolved = false;

            switch obj.knob.targetKind
                case 'stage'
                    stages = lvdData.launchVehicle.stages;
                    obj.target = LvdSweepVehicleKnobParameter.findById(stages, obj.targetId);

                case 'tank'
                    [~, tanks] = lvdData.launchVehicle.getTanksListBoxStr();
                    obj.target = LvdSweepVehicleKnobParameter.findById(tanks, obj.targetId);

                case 'engine'
                    [~, engines] = lvdData.launchVehicle.getEnginesListBoxStr();
                    obj.target = LvdSweepVehicleKnobParameter.findById(engines, obj.targetId);

                case 'initState'
                    obj.target = lvdData.initStateModel.aero.dragCoeffModel;

                case 'action'
                    obj.target = LvdSweepVehicleKnobParameter.findActionById(lvdData, obj.targetId);
            end

            obj.isResolved = not(isempty(obj.target));
            tf = obj.isResolved;
        end

        function captureBaseline(obj, lvdData)
            %captureBaseline Records the template's unscaled curve so the
            %multiplier knobs have something absolute to scale.  Re-taken at
            %every run start, so editing a curve between runs cannot leave a
            %stale baseline behind.
            if(not(obj.knob.isMultiplier()))
                return;
            end

            if(not(obj.resolve(lvdData)))
                obj.baseline = [];
                return;
            end

            curve = obj.getEngineCurve();
            obj.baseline = [curve.elems.depVar];
        end

        function value = getCurrentValue(obj)
            if(isempty(obj.target))
                value = NaN;
                return;
            end

            switch obj.knob
                case LvdSweepVehicleKnobEnum.StageDryMass
                    value = obj.target.dryMass;

                case LvdSweepVehicleKnobEnum.TankInitialMass
                    value = obj.target.initialMass;

                case LvdSweepVehicleKnobEnum.TankCapacity
                    value = obj.target.capacity;

                case {LvdSweepVehicleKnobEnum.EngineThrustMultiplier, ...
                      LvdSweepVehicleKnobEnum.EngineIspMultiplier}
                    value = obj.getCurrentMultiplier();

                case {LvdSweepVehicleKnobEnum.InitStateDragMultiplier, ...
                      LvdSweepVehicleKnobEnum.EventDragMultiplier}
                    value = obj.getDragCoeffModel().globalDragMultiplier;

                otherwise
                    value = NaN;
            end
        end

        function applyValue(obj, value)
            if(isempty(obj.target))
                error('LvdSweepParameter:unresolved', ...
                      'The target of vehicle knob "%s" could not be found in this mission.', obj.getName());
            end

            switch obj.knob
                case LvdSweepVehicleKnobEnum.StageDryMass
                    obj.target.dryMass = value;
                    obj.deactivateOptVar(obj.target);

                case LvdSweepVehicleKnobEnum.TankInitialMass
                    obj.target.initialMass = value;
                    obj.deactivateOptVar(obj.target);

                case LvdSweepVehicleKnobEnum.TankCapacity
                    obj.target.capacity = max(value, 0);

                case {LvdSweepVehicleKnobEnum.EngineThrustMultiplier, ...
                      LvdSweepVehicleKnobEnum.EngineIspMultiplier}
                    obj.applyCurveMultiplier(value);

                case {LvdSweepVehicleKnobEnum.InitStateDragMultiplier, ...
                      LvdSweepVehicleKnobEnum.EventDragMultiplier}
                    obj.getDragCoeffModel().globalDragMultiplier = value;
            end
        end

        function [lb, ub] = getSuggestedBounds(obj)
            if(obj.knob.isMultiplier())
                lb = 0.95;
                ub = 1.05;
                return;
            end

            [lb, ub] = getSuggestedBounds@AbstractLvdSweepParameter(obj);
        end
    end

    methods(Access=private)
        function curve = getEngineCurve(obj)
            if(obj.knob == LvdSweepVehicleKnobEnum.EngineThrustMultiplier)
                curve = obj.target.thrustPressCurve;
            else
                curve = obj.target.ispPressCurve;
            end
        end

        function m = getCurrentMultiplier(obj)
            curve = obj.getEngineCurve();
            y = [curve.elems.depVar];

            if(isempty(obj.baseline) || numel(obj.baseline) ~= numel(y))
                m = 1;
                return;
            end

            nzTf = obj.baseline ~= 0;
            if(not(any(nzTf)))
                m = 1;
            else
                m = mean(y(nzTf) ./ obj.baseline(nzTf));
            end
        end

        function applyCurveMultiplier(obj, value)
            curve = obj.getEngineCurve();

            if(isempty(obj.baseline))
                %No baseline was captured (the parameter was applied outside
                %a run).  Take one now off whatever the curve currently is,
                %so the apply is at least self consistent.
                obj.baseline = [curve.elems.depVar];
            end

            n = min(numel(obj.baseline), numel(curve.elems));
            for(k = 1:n) %#ok<*NO4LP>
                curve.elems(k).depVar = obj.baseline(k) * value;
            end

            curve.generateCurve();
        end

        function dcm = getDragCoeffModel(obj)
            if(obj.knob == LvdSweepVehicleKnobEnum.InitStateDragMultiplier)
                dcm = obj.target;
            else
                dcm = obj.target.dragCoeffModel;
            end
        end

        function deactivateOptVar(~, target)
            %A stage dry mass or tank initial mass may also be an active
            %optimization variable, in which case the optimizer would simply
            %move it back off the swept value.
            if(isprop(target, 'optVar') && not(isempty(target.optVar)))
                useTf = target.optVar.getUseTfForVariable();
                target.optVar.setUseTfForVariable(false(size(useTf)));
            end
        end
    end

    methods(Static)
        function name = getTargetDisplayName(target)
            if(isprop(target, 'name') && not(isempty(target.name)))
                name = char(target.name);
            elseif(ismethod(target, 'getName'))
                name = char(target.getName());
            else
                name = class(target);
            end
        end

        function found = findById(candidates, targetId)
            found = [];

            for(i=1:length(candidates))
                if(candidates(i).id == targetId)
                    found = candidates(i);
                    return;
                end
            end
        end

        function found = findActionById(lvdData, targetId)
            %findActionById Walks every event's action list looking for the
            %drag action with this id.
            found = [];

            evts = LvdSweepVehicleKnobParameter.getAllEvents(lvdData);

            for(i=1:length(evts))
                actions = evts(i).actions;

                for(j=1:length(actions))
                    if(actions(j).id == targetId)
                        found = actions(j);
                        return;
                    end
                end
            end
        end

        function evts = getAllEvents(lvdData)
            %getAllEvents Every LaunchVehicleEvent in the mission, sequential
            %and non-sequential.  The container's evts getter already unwraps
            %the LaunchVehicleNonSeqEvent wrappers, so what comes back are
            %LaunchVehicleEvents ready to read actions off.
            evts = lvdData.script.evts;

            if(not(isempty(lvdData.script.nonSeqEvts)))
                nonSeqEvts = lvdData.script.nonSeqEvts.evts;

                for(i=1:length(nonSeqEvts))
                    evts(end+1) = nonSeqEvts(i); %#ok<AGROW>
                end
            end
        end
    end
end
