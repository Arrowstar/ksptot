classdef SetPowerStorageActiveStateAction < AbstractEventAction
    %SetPowerStorageActiveStateAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        storage AbstractLaunchVehicleElectricalPowerStorage
        activeStateToSet(1,1) logical = false;
    end
    
    properties(Constant)
        emptyVarArr = AbstractOptimizationVariable.empty(0,1);
    end
    
    methods
        function obj = SetPowerStorageActiveStateAction(storage, activeStateToSet)
            if(nargin > 0)
                obj.storage = storage;
                obj.activeStateToSet = activeStateToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry; 
            stageStates = newStateLogEntry.stageStates;

            pwrStorageStates = AbstractLaunchVehicleEpsStorageState.empty(1,0);
            for(i=1:length(stageStates)) %#ok<*NO4LP>
                pwrStorageStates = horzcat(pwrStorageStates, stageStates(i).powerStorageStates); %#ok<AGROW>
            end

            pwrStorages = AbstractLaunchVehicleElectricalPowerStorage.empty(1,0);
            for(i=1:length(pwrStorageStates))
                pwrStorages = horzcat(pwrStorages, pwrStorageStates(i).getEpsStorageComponent()); %#ok<AGROW>
            end

            pwrStorageInd = find(pwrStorages == obj.storage,1,'first');
            pwrStorageState = pwrStorageStates(pwrStorageInd);
            
            pwrStorageState.setActiveState(obj.activeStateToSet);
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)
            if(obj.activeStateToSet)
                tf = 'Active';
            else
                tf = 'Inactive';
            end
            
            name = sprintf('Set Power Storage State (%s = %s)',obj.storage.getName(),tf);
        end
        
        function tf = usesStage(obj, stage)
            tf = false;
        end
        
        function tf = usesEngine(obj, engine)
            tf = false;
        end
        
        function tf = usesTank(obj, tank)
            tf = false;
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
        end

        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = false;
        end
        
        function tf = usesPwrSink(obj, powerSink)
            tf = false;
        end
        
        function tf = usesPwrSrc(obj, powerSrc)
            tf = false;
        end
        
        function tf = usesPwrStorage(obj, powerStorage)
            tf = [obj.storage] == powerStorage;
        end
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = obj.emptyVarArr;
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
            [~, powerStorages] = lv.getPowerStoragesListBoxStr();
            
            if(not(isempty(powerStorages)))
%                 addActionTf = lvd_EditActionSetPwrStorageStateGUI(action, lv);

                output = AppDesignerGUIOutput({false});
                lvd_EditActionSetPwrStorageStateGUI_App(action, lv, output);
                addActionTf = output.output{1};
            else
                addActionTf = false;
                warndlg('There are no power storage components on the vehicle.  Create one first.','Cannot Create Action','modal');
            end
        end
    end
end