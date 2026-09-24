classdef ZeroAreaLiftModelValidator < AbstractLaunchVehicleDataValidator
    properties
        lvdData LvdData
    end

    methods
        function obj = ZeroAreaLiftModelValidator(lvdData)
            obj.lvdData = lvdData;
        end

        function [errors, warnings] = validate(obj)
            errors = LaunchVehicleDataValidationError.empty(0,1);
            warnings = LaunchVehicleDataValidationWarning.empty(0,1);

            evts = obj.lvdData.script.evts;
            for(i=1:numel(evts))
                evt = evts(i);
                if(isempty(evt.propagatorObj) || ~isa(evt.propagatorObj, 'ForceModelPropagator'))
                    continue;
                end
                if(~any(evt.propagatorObj.forceModels == ForceModelsEnum.Lift))
                    continue;
                end

                entries = obj.lvdData.stateLog.getAllStateLogEntriesForEvent(evt);
                invalid = false;
                if(isempty(entries))
                    invalid = obj.hasZeroLiftArea(obj.lvdData.initStateModel.aero);
                else
                    for(j=1:numel(entries))
                        invalid = invalid || obj.hasZeroLiftArea(entries(j).aero);
                    end
                end

                if(invalid)
                    str = sprintf('Lift is enabled on Event %u with a zero-area lift model.', evt.getEventNum());
                    warnings(end+1) = LaunchVehicleDataValidationWarning(str);
                end
            end
        end
    end

    methods(Access=private)
        function tf = hasZeroLiftArea(~, aero)
            tf = false;
            if(isempty(aero) || isempty(aero.liftCoeffModel) || isempty(aero.liftCoeffModel.liftCoeffObj))
                return;
            end

            model = aero.liftCoeffModel.liftCoeffObj(1);
            if(isa(model, 'CylindricalLiftModel'))
                tf = model.cylinderRadius <= 0;
            end
        end
    end
end
