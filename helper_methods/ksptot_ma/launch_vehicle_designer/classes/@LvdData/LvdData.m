classdef LvdData < matlab.mixin.SetGet
    %LvdData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        script LaunchVehicleScript
        launchVehicle LaunchVehicle
        stateLog LaunchVehicleStateLog
        initStateModel InitialStateModel
        optimizer LvdOptimization
    end
    
    properties(Dependent)
        initialState LaunchVehicleStateLogEntry
    end
    
    
    methods(Access = private)
        function obj = LvdData()

        end
    end
    
    methods
        function initialState = get.initialState(obj)
            initialState = obj.initStateModel.getInitialStateLogEntry();
        end
        
        function tf = usesStage(obj, stage)
            tf = obj.script.usesStage(stage);
            tf = tf || obj.optimizer.usesStage(stage);
        end
        
        function tf = usesEngine(obj, engine)
            tf = obj.script.usesEngine(engine);
            tf = tf || obj.optimizer.usesEngine(engine);
        end
        
        function tf = usesTank(obj, tank)
            tf = obj.script.usesTank(tank);
            tf = tf || obj.optimizer.usesTank(tank);
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = obj.script.usesEngineToTankConn(engineToTank);
            tf = tf || obj.optimizer.usesEngineToTankConn(engineToTank);
        end
    end
    
    methods(Static)
        function lvdData = getEmptyLvdData()
            lvdData = LvdData();
        end
        
        function lvdData = getDefaultLvdData(celBodyData)
            lvdData = LvdData();
            
            simMaxDur = 20000;
            minAltitude = -1;
            simDriver = LaunchVehicleSimulationDriver(simMaxDur, minAltitude, celBodyData);
            
            %Set Up Initial Launch Vehicle
            lv = LaunchVehicle.createDefaultLaunchVehicle(lvdData);
            lvdData.launchVehicle = lv;
            
            %Set Up Initial State
            initStateModel = InitialStateModel.getDefaultInitialStateLogModelForLaunchVehicle(lvdData.launchVehicle, celBodyData.kerbin);
            initStateModel.stageStates(3).engineStates(1).active = true; %Turn on the first stage engine
            initStateModel.stageStates(2).engineStates(1).active = false; %Turn off the second stage engine
            lvdData.initStateModel = initStateModel;
            
            initStateLogEntry = initStateModel.getInitialStateLogEntry();
            
            %Set Up Mission Script
            script = LaunchVehicleScript(lvdData, simDriver);

            %Event 1
            evt1 = LaunchVehicleEvent(script);
            evt1.name = 'Propagate 5 seconds';
            evt1.termCond = EventDurationTermCondition(5);
            script.addEvent(evt1);
            
            %Event 2
            evt2 = LaunchVehicleEvent(script);
            evt2.name = 'Propagate to AoA = 0';
            evt2.termCond = AngleOfAttackTermCondition(0);
            evt2ActionStrMdl = AeroAnglesPolySteeringModel.getDefaultSteeringModel();
            evt2Action3 = SetSteeringModelAction(evt2ActionStrMdl);
            evt2.addAction(evt2Action3);
            script.addEvent(evt2);
            
            %Event 3
            %None
            
            %Event 4
            evt4 = LaunchVehicleEvent(script);
            evt4.name = 'Propagate to Stage One Burnout';

            evt4TcTank = lv.stages(3).tanks(1);
            evt4.termCond = TankMassTermCondition(evt4TcTank,0);

            evt4Action1 = SetStageActiveStateAction(lv.stages(3), false);
            evt4.addAction(evt4Action1);

            script.addEvent(evt4);
            
            %Event 4b
            evt4b = LaunchVehicleEvent(script);
            evt4b.name = 'Coast to Stage Two Ignition';
            evt4b.termCond = EventDurationTermCondition(120);
            
            evt4bAction2Eng = lv.stages(2).engines(1);
            evt4bAction2 = SetEngineActiveStateAction(evt4bAction2Eng, true);
            evt4b.addAction(evt4bAction2);
            
            script.addEvent(evt4b);
            
            %Event 5
            evt5 = LaunchVehicleEvent(script);
            evt5.name = 'Propagate to Stage Two Burnout';

            evt5TcTank = lv.stages(2).tanks(1);
            evt5.termCond = TankMassTermCondition(evt5TcTank,0);

            evt5Action1 = SetStageActiveStateAction(lv.stages(2), false);
            evt5.addAction(evt5Action1);

            script.addEvent(evt5);

            %Event 6
            evt6 = LaunchVehicleEvent(script);
            evt6.name = 'Propagate 1000 seconds';
            evt6.termCond = EventDurationTermCondition(1000);
            script.addEvent(evt6);
            
            lvdData.script = script;

            %State Log
            lvdData.stateLog = LaunchVehicleStateLog();
                      
            %Optimization
            lvdOptim = LvdOptimization(lvdData);
            
            %-Objective Function
            lvdOptim.objFcn = MaximizeLaunchVehicleMassObjectiveFcn(evt6, lvdOptim, lvdData);
            
            %-Variables
            rpyVars = SetRPYSteeringModelActionOptimVar(initStateLogEntry.steeringModel);
            rpyVars.varPitchLin = true;
            rpyVars.varPitchAccel = true;
            rpyVars.setBndsForVariable(deg2rad(-3)*ones([1,2]), deg2rad(+3)*ones([1,2]));
            lvdOptim.vars.addVariable(rpyVars);
            
            stage3DryMassVar = StageDryMassOptimizationVariable(lvdData.launchVehicle.stages(1));
            stage3DryMassVar.setUseTfForVariable(true);
            stage3DryMassVar.setBndsForVariable(0.001,10);
            lvdOptim.vars.addVariable(stage3DryMassVar);

            coastDurVar = EventDurationOptimizationVariable(evt4b.termCond);
            coastDurVar.setUseTfForVariable(true);
            coastDurVar.setBndsForVariable(0, 130);
            lvdOptim.vars.addVariable(coastDurVar);
            
            const1 = GenericMAConstraint('Eccentricity', evt6, 0, 0, struct.empty(1,0), struct.empty(1,0), celBodyData.kerbin);
            lvdOptim.constraints.addConstraint(const1);
            
%             const2 = GenericMAConstraint('Semi-major Axis', evt6, 700, 700, struct.empty(1,0), struct.empty(1,0), celBodyData.kerbin);
%             lvdOptim.constraints.addConstraint(const2);
            
            const3 = GenericMAConstraint('Altitude', evt6, 75, realmax, struct.empty(1,0), struct.empty(1,0), celBodyData.kerbin);
            lvdOptim.constraints.addConstraint(const3);
            
            lvdData.optimizer = lvdOptim;
        end
    end
end

