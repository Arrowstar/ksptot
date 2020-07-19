classdef LvdData < matlab.mixin.SetGet
    %LvdData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        script LaunchVehicleScript
        launchVehicle LaunchVehicle
        stateLog LaunchVehicleStateLog
        initStateModel InitialStateModel
        optimizer LvdOptimization
        validation LaunchVehicleDataValidation
        settings LvdSettings
        notes char
        plugins LvdPluginSet
        viewSettings LaunchVehicleViewSettings
        groundObjs LaunchVehicleGroundObjectSet
        
        celBodyData 
        ksptotVer char
    end
    
    properties(Dependent)
        initialState LaunchVehicleStateLogEntry
    end
    
    methods(Access = private)
        function obj = LvdData()
            obj.validation = LaunchVehicleDataValidation(obj);
            obj.settings = LvdSettings();
            obj.plugins = LvdPluginSet(obj);
            obj.viewSettings = LaunchVehicleViewSettings(obj);
            obj.groundObjs = LaunchVehicleGroundObjectSet(obj);
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
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = obj.script.usesStopwatch(stopwatch);
            tf = tf || obj.optimizer.constraints.usesStopwatch(stopwatch);
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = obj.script.usesExtremum(extremum);
            tf = tf || obj.optimizer.constraints.usesExtremum(extremum);
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = obj.script.usesTankToTankConn(tankToTank);
        end
    end
    
    methods(Static)        
        function lvdData = getEmptyLvdData()
            lvdData = LvdData();
            lvdData.ksptotVer = getKSPTOTVersionNumStr();
        end
        
        function lvdData = getDefaultLvdData(celBodyData)
            lvdData = LvdData();
            
            lvdData.celBodyData = celBodyData;

            simDriver = LaunchVehicleSimulationDriver(lvdData);
            
            %Set Up Initial Launch Vehicle
            lv = LaunchVehicle.createDefaultLaunchVehicle(lvdData);
            lvdData.launchVehicle = lv;
            
            %Set Up Initial State
            initBody = LvdData.getDefaultInitialBodyInfo(celBodyData);

            initStateModel = InitialStateModel.getDefaultInitialStateLogModelForLaunchVehicle(lvdData.launchVehicle, initBody);
            lvdData.initStateModel = initStateModel;
                        
            %Set Up Mission Script
            script = LaunchVehicleScript(lvdData, simDriver);
            script.addEvent(LaunchVehicleEvent.getDefaultEvent(script));
            
            lvdData.script = script;

            %State Log
            lvdData.stateLog = LaunchVehicleStateLog();
                      
            %Optimization
            lvdOptim = LvdOptimization(lvdData);
            
            %Objective Function
%             lvdOptim.objFcn = NoOptimizationObjectiveFcn(lvdOptim, lvdData);
            lvdOptim.objFcn = CompositeObjectiveFcn(GenericObjectiveFcn.empty(1,0), ...
                                                    ObjFcnDirectionTypeEnum.Minimize, ...
                                                    ObjFcnCompositeMethodEnum.Sum, ...
                                                    lvdData.optimizer, lvdData);
            
            lvdData.optimizer = lvdOptim;
            
            %set up view profile
            lvdData.viewSettings.selViewProfile.frame = BodyCenteredInertialFrame(lvdData.initialState.centralBody, lvdData.celBodyData);
            
            %set up ground objects
            grndObj = LaunchVehicleGroundObject.getDefaultObj(celBodyData);
            lvdData.groundObjs.addGroundObj(grndObj);
            grndObj.name = 'KSC';
            grndObj.desc = "Kerbin Space Center";
            
            bfFrame = grndObj.centralBodyInfo.getBodyFixedFrame();
            
            durToNextWayPt = 3600;
            elemSet = GeographicElementSet(grndObj.initialTime + durToNextWayPt, deg2rad(-0.1025), deg2rad(285.42472), 0.06841, 0, 0, 0, bfFrame);
            wayPt = LaunchVehicleGroundObjectWayPt(elemSet, durToNextWayPt);
            grndObj.wayPts = wayPt;
        end
        
        function initBody = getDefaultInitialBodyInfo(celBodyData)
            if(isfield(celBodyData,'kerbin'))
                initBody = celBodyData.kerbin;
            else
                fields = fieldnames(celBodyData);
                initBody = celBodyData.(fields{1});
            end            
        end
        
        function obj = loadobj(obj)
            obj.validation = LaunchVehicleDataValidation(obj);
            
            if(isempty(obj.stateLog))
                obj.stateLog = LaunchVehicleStateLog();
            end
            
            if(isempty(obj.plugins))
                obj.plugins = LvdPluginSet(obj);
            end
            
            if(isempty(obj.viewSettings))
                obj.viewSettings = LaunchVehicleViewSettings(obj);
                
                for(i=1:length(obj.viewSettings.viewProfiles))
                    profile = obj.viewSettings.viewProfiles(i);

                    if(isempty(profile.frame))
                        originBodyInfo = obj.getDefaultInitialBodyInfo(obj.celBodyData);
                        profile.frame = originBodyInfo.getBodyCenteredInertialFrame();
                    end
                end
            end
            
            if(isempty(obj.groundObjs))
                obj.groundObjs = LaunchVehicleGroundObjectSet(obj);
            end
        end
        
        function obj = saveobj(obj)
            obj.stateLog.clearStateLog();
        end
    end
end