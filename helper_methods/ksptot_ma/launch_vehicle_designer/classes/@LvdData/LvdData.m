classdef LvdData < matlab.mixin.SetGet
    %LvdData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        script LaunchVehicleScript
        launchVehicle LaunchVehicle
        stateLog LaunchVehicleStateLog
        initialState LaunchVehicleStateLogEntry
        optimizer LvdOptimization
    end
    
    methods(Access = private)
        function obj = LvdData()

        end
    end
    
    methods(Static)
        function lvdData = getDefaultLvdData(celBodyData)
            lvdData = LvdData();
            
            simMaxDur = 20000;
            minAltitude = -1;
            simDriver = LaunchVehicleSimulationDriver(simMaxDur, minAltitude, celBodyData);
            
            %Set Up Initial Launch Vehicle
            lv = LaunchVehicle.createDefaultLaunchVehicle();
            lvdData.launchVehicle = lv;
            
            %Set Up Initial State
            initStateLogEntry = LaunchVehicleStateLogEntry.getDefaultStateLogEntryForLaunchVehicle(lvdData.launchVehicle, celBodyData.kerbin);
            initStateLogEntry.stageStates(3).engineStates(1).active = true; %Turn on the first stage engine
            initStateLogEntry.stageStates(2).engineStates(1).active = false; %Turn off the second stage engine
            lvdData.initialState = initStateLogEntry;
            
            %Set Up Mission Script
            script = LaunchVehicleScript(lvdData, simDriver);

            %Event 1
            evt1 = LaunchVehicleEvent(script);
            evt1.name = 'Propagate 5 seconds';
            evt1.termCond = EventDurationTermCondition(5);
            script.addEvent(evt1);

            %Event 2
            evt2 = LaunchVehicleEvent(script);
            evt2.name = 'Propagate to Stage One Burnout';

            evt2TcTank = lv.stages(3).tanks(1);
            evt2.termCond = TankMassTermCondition(evt2TcTank,0);

            evt2Action1 = SetStageActiveStateAction(lv.stages(3), false);
            evt2.addAction(evt2Action1);

            evt2Action2Eng = lv.stages(2).engines(1);
            evt2Action2 = SetEngineActiveStateAction(evt2Action2Eng, true);
            evt2.addAction(evt2Action2);

%             evt2ActionStrMdl = AeroAnglesPolySteeringModel.getDefaultSteeringModel();
%             evt2Action3 = SetSteeringModelAction(evt2ActionStrMdl);
%             evt2.addAction(evt2Action3);

            script.addEvent(evt2);

            %Event 3
            evt3 = LaunchVehicleEvent(script);
            evt3.name = 'Propagate to Stage Two Burnout';

            evt3TcTank = lv.stages(2).tanks(1);
            evt3.termCond = TankMassTermCondition(evt3TcTank,0);

            evt3Action1 = SetStageActiveStateAction(lv.stages(2), false);
            evt3.addAction(evt3Action1);

            script.addEvent(evt3);

            %Event 4
            evt4 = LaunchVehicleEvent(script);
            evt4.name = 'Propagate 1000 seconds';
            evt4.termCond = EventDurationTermCondition(1000);
            script.addEvent(evt4);
            
            lvdData.script = script;

            %State Log
            lvdData.stateLog = LaunchVehicleStateLog();
                      
            %Optimization
            lvdOptim = LvdOptimization(lvdData);
            lvdOptim.objFcn = LaunchVehicleMassObjectiveFcn(evt4, lvdOptim, lvdData);
            
            rpyVars = SetRPYSteeringModelActionOptimVar(initStateLogEntry.steeringModel);
            rpyVars.varRollConst = false;
            rpyVars.varPitchConst = false;
            rpyVars.varYawConst = false;
            rpyVars.varRollLin = false;
            rpyVars.varRollAccel = false;
            rpyVars.varYawLin = false;
            rpyVars.varYawAccel = false;
            rpyVars.lb = deg2rad(-5)*ones([1,2]);
            rpyVars.ub = deg2rad(+5)*ones([1,2]);
            lvdOptim.vars.addVariable(rpyVars);
            
            const1 = GenericMAConstraint('Eccentricity', evt4, 0, 0, struct.empty(1,0), struct.empty(1,0), celBodyData.kerbin);
            lvdOptim.constraints.addConstraint(const1);
            
            const2 = GenericMAConstraint('Semi-major Axis', evt4, 700, 700, struct.empty(1,0), struct.empty(1,0), celBodyData.kerbin);
            lvdOptim.constraints.addConstraint(const2);
            
            const3 = GenericMAConstraint('Altitude', evt4, 75, realmax, struct.empty(1,0), struct.empty(1,0), celBodyData.kerbin);
            lvdOptim.constraints.addConstraint(const3);
            
            lvdData.optimizer = lvdOptim;
        end
    end
end

