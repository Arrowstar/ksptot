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
        geometry LvdGeometry
        graphAnalysis LvdGraphicalAnalysis
        sensors LvdSensorSet
        sensorTgts LvdSensorTargetSet
        
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
            obj.geometry = LvdGeometry(obj);
            obj.graphAnalysis = LvdGraphicalAnalysis(obj);
            obj.sensors = LvdSensorSet(obj);
            obj.sensorTgts = LvdSensorTargetSet(obj);
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
            tf = tf || obj.optimizer.usesExtremum(extremum);
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = obj.script.usesTankToTankConn(tankToTank);
        end
        
        function tf = usesGroundObj(obj, grdObj)
            tf = obj.optimizer.usesGroundObj(grdObj) || ...
                 obj.geometry.usesGroundObj(obj);
        end
        
        function tf = usesCalculusCalc(obj, calculusCalc)
            tf = obj.script.usesCalculusCalc(calculusCalc);
            
            tf = tf || obj.optimizer.usesCalculusCalc(calculusCalc);
        end
        
        function tf = usesPwrSink(obj, powerSink)
            tf = obj.script.usesPwrSink(powerSink);
%             tf = tf || obj.optimizer.usesPwrStorage(powerSink);
        end
        
        function tf = usesPwrSrc(obj, powerSrc)
            tf = obj.script.usesPwrSrc(powerSrc);
%             tf = tf || obj.optimizer.usesPwrStorage(powerSrc);
        end
        
        function tf = usesPwrStorage(obj, powerStorage)
            tf = obj.script.usesPwrStorage(powerStorage);
%             tf = tf || obj.optimizer.usesPwrStorage(powerStorage);
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = obj.optimizer.usesGeometricPoint(point);
            tf = tf || obj.geometry.usesGeometricPoint(point);
            tf = tf || obj.sensors.usesGeometricPoint(point);
            tf = tf || obj.sensorTgts.usesGeometricPoint(point);
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = obj.optimizer.usesGeometricVector(vector);
            tf = tf || obj.geometry.usesGeometricVector(vector);
            tf = tf || obj.sensors.usesGeometricVector(vector);
            tf = tf || obj.sensorTgts.usesGeometricVector(vector);
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = obj.optimizer.usesGeometricCoordSys(coordSys);
            tf = tf || obj.geometry.usesGeometricCoordSys(coordSys);
            tf = tf || obj.sensors.usesGeometricCoordSys(coordSys);
            tf = tf || obj.sensorTgts.usesGeometricCoordSys(coordSys);
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = obj.optimizer.usesGeometricRefFrame(refFrame);
            tf = tf || obj.geometry.usesGeometricRefFrame(refFrame);
            tf = tf || obj.graphAnalysis.usesGeometricRefFrame(refFrame);
            tf = tf || obj.sensors.usesGeometricRefFrame(refFrame);
            tf = tf || obj.sensorTgts.usesGeometricRefFrame(refFrame);
        end
        
        function tf = usesGeometricAngle(obj, angle)
            tf = obj.optimizer.usesGeometricAngle(angle);
            tf = tf || obj.geometry.usesGeometricAngle(angle);
            tf = tf || obj.sensors.usesGeometricAngle(angle);
            tf = tf || obj.sensorTgts.usesGeometricAngle(angle);
        end
        
        function tf = usesGeometricPlane(obj, plane)
            tf = obj.optimizer.usesGeometricPlane(plane);
            tf = tf || obj.geometry.usesGeometricPlane(plane);
            tf = tf || obj.sensors.usesGeometricPlane(plane);
            tf = tf || obj.sensorTgts.usesGeometricPlane(plane);
        end 

        function tf = usesPlugin(obj, plugin)
            tf = obj.optimizer.usesPlugin(plugin);
        end 
        
        function baseFrame = getBaseFrame(obj)
            topLevelBody = obj.celBodyData.getTopLevelBody();
            baseFrame = topLevelBody.getBodyCenteredInertialFrame();
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
            lvdData.viewSettings.selViewProfile.frame = lvdData.initialState.centralBody.getBodyCenteredInertialFrame();
            
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
            
            %%%add temp sensors
            vehiclePt = VehiclePoint('Vehicle');
            lvdData.geometry.points.addPoint(vehiclePt);
            
            %sensor 1
%             frame = initBody.getBodyCenteredInertialFrame();
%             steeringCoordSys = ParallelToFrameCoordSystem(frame, 'Kerbin Inertial', lvdData);
%             steeringModel = FixedInCoordSysSensorSteeringModel(deg2rad(0), deg2rad(0), 0, steeringCoordSys);
            steeringModel = FixedInVehicleFrameSensorSteeringModel(deg2rad(0), deg2rad(0), 0, lvdData);

            sensorRange = 3000;
            sensAng = deg2rad(5);
            sensor = ConicalSensor('Demo Conical Sensor 1', sensAng, sensorRange, vehiclePt, steeringModel, lvdData);
            lvdData.sensors.addSensor(sensor);
            lvdData.viewSettings.selViewProfile.sensorsToPlot = sensor;
            
            %sensor 2
            frame = initBody.getBodyCenteredInertialFrame();
            ke = KeplerianElementSet(0, 2000, 0, deg2rad(0), 0, 0, 0, frame);
            twoBodyPoint = TwoBodyPoint(ke, 'Two Body Point', lvdData);
            lvdData.geometry.points.addPoint(twoBodyPoint);
            
            sensorRange = 3000;
            sensAng = deg2rad(30);
            steeringCoordSys = ParallelToFrameCoordSystem(frame, 'Kerbin Inertial', lvdData);
            steeringModel = FixedInCoordSysSensorSteeringModel(deg2rad(0), deg2rad(0), 0, steeringCoordSys, lvdData);

            sensor = ConicalSensor('Demo Conical Sensor 2', sensAng, sensorRange, twoBodyPoint, steeringModel, lvdData);
            lvdData.sensors.addSensor(sensor);
            lvdData.viewSettings.selViewProfile.sensorsToPlot(end+1) = sensor;
            
            %add temp sensor target
            target1 = BodyFixedLatLongGridTargetModel('Demo Target 1', initBody, deg2rad(0), deg2rad(30), deg2rad(360), deg2rad(-30), 15, 15, 1, lvdData);
            lvdData.sensorTgts.addTarget(target1);
            lvdData.viewSettings.selViewProfile.sensorTgtsToPlot = target1;
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
            
            if(isempty(obj.geometry))
                obj.geometry = LvdGeometry(obj);
            end
            
            if(isempty(obj.graphAnalysis))
                obj.graphAnalysis = LvdGraphicalAnalysis(obj);
            end
            
            if(isempty(obj.sensors))
                obj.sensors = LvdSensorSet(obj);
            end
            
            if(isempty(obj.sensorTgts))
                obj.sensorTgts = LvdSensorTargetSet(obj);
            end
            
            evts = obj.script.evts;
            for(i=1:length(evts))
                evts(i).createUpdatedSetKinematicStateObjs();
            end
            
            nonSeqEvts = obj.script.nonSeqEvts.nonSeqEvts;
            for(i=1:length(nonSeqEvts))
                nonSeqEvts(i).evt.createUpdatedSetKinematicStateObjs();
            end
        end
        
        function obj = saveobj(obj)
            obj.stateLog.clearStateLog();
        end
    end
end