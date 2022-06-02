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
        pluginVars LvdPluginOptimVarSet
        viewSettings LaunchVehicleViewSettings
        groundObjs LaunchVehicleGroundObjectSet
        geometry LvdGeometry
        graphAnalysis LvdGraphicalAnalysis
        sensors LvdSensorSet
        sensorTgts LvdSensorTargetSet
        
        celBodyData 
        ksptotVer char

        userData

        id(1,1) double
    end
    
    properties(Dependent)
        initialState LaunchVehicleStateLogEntry
    end
    
    methods(Access = private)
        function obj = LvdData()
            obj.stateLog = LaunchVehicleStateLog(obj);
            obj.validation = LaunchVehicleDataValidation(obj);
            obj.settings = LvdSettings();
            obj.plugins = LvdPluginSet(obj);
            obj.pluginVars = LvdPluginOptimVarSet(obj);
            obj.viewSettings = LaunchVehicleViewSettings(obj);
            obj.groundObjs = LaunchVehicleGroundObjectSet(obj);
            obj.geometry = LvdGeometry(obj);
            obj.graphAnalysis = LvdGraphicalAnalysis(obj);
            obj.sensors = LvdSensorSet(obj);
            obj.sensorTgts = LvdSensorTargetSet(obj);

            obj.id = rand();
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
        
        function tf = usesSensor(obj, sensor)
            tf = obj.script.usesSensor(sensor);
        end
        
        function baseFrame = getBaseFrame(obj)
            topLevelBody = obj.celBodyData.getTopLevelBody();
            baseFrame = topLevelBody.getBodyCenteredInertialFrame();
        end
        
        function createContinuityConstraints(obj, evt, selEvt, refBodyInfo, useTime, timeScale, usePos, posScale, useVel, velScale, useAtt, attScale, useTankMass, tankMassScale)
            arguments
                obj(1,1) LvdData
                evt(1,1) LaunchVehicleEvent
                selEvt(1,1) LaunchVehicleEvent
                refBodyInfo = [];
                
                useTime(1,1) logical = true;
                timeScale(1,1) double = 1.0;
                
                usePos(1,1) logical = true;
                posScale(1,1) double = 1.0;
                
                useVel(1,1) logical = true;
                velScale(1,1) double = 1.0;
                
                useAtt(1,1) logical = false;
                attScale(1,1) double = 1.0;
                
                useTankMass(1,1) logical = false;
                tankMassScale(1,1) double = 1.0;
            end
            
            eventNum = evt.getEventNum();
            selEvtNum = selEvt.getEventNum();
            
            if(eventNum > selEvtNum)
                refEvt = evt;
                constrEvt = selEvt;
            else
                refEvt = selEvt;
                constrEvt = evt;
            end

            if(isempty(refBodyInfo))
                stateLogEntry = obj.stateLog.getLastStateLogForEvent(refEvt);
                refBodyInfo = stateLogEntry.centralBody;
            end
            frame = refBodyInfo.getBodyCenteredInertialFrame();

            cs = AbstractConstraint.empty(1,0);

            %time
            if(useTime)
                c = GenericMAConstraint('Universal Time', refEvt, 0, 0, [], [], refBodyInfo);
                c.setScaleFactor(timeScale);
                cs(end+1) = c;
            end
            
            %position
            if(usePos)
                c = GenericMAConstraint('Position Vector (X)', refEvt, 0, 0, [], [], refBodyInfo);
                c.setScaleFactor(posScale);
                cs(end+1) = c;

                c = GenericMAConstraint('Position Vector (Y)', refEvt, 0, 0, [], [], refBodyInfo);
                c.setScaleFactor(posScale);
                cs(end+1) = c;
                
                c = GenericMAConstraint('Position Vector (Z)', refEvt, 0, 0, [], [], refBodyInfo);
                c.setScaleFactor(posScale);
                cs(end+1) = c;
            end

            %velocity
            if(useVel)
                c = GenericMAConstraint('Velocity Vector (X)', refEvt, 0, 0, [], [], refBodyInfo);
                c.setScaleFactor(velScale);
                cs(end+1) = c;
                
                c = GenericMAConstraint('Velocity Vector (Y)', refEvt, 0, 0, [], [], refBodyInfo);
                c.setScaleFactor(velScale);
                cs(end+1) = c;
                
                c = GenericMAConstraint('Velocity Vector (Z)', refEvt, 0, 0, [], [], refBodyInfo);
                c.setScaleFactor(velScale);
                cs(end+1) = c;
            end
            
            %attitude
            if(useAtt)
                c = RollAngleConstraint(refEvt, 0, 0);
                c.setScaleFactor(attScale);
                cs(end+1) = c;
                
                c = PitchAngleConstraint(refEvt, 0, 0);
                c.setScaleFactor(attScale);
                cs(end+1) = c;
                
                c = YawAngleConstraint(refEvt, 0, 0);
                c.setScaleFactor(attScale);
                cs(end+1) = c;
            end
            
            %tank masses
            if(useTankMass)
                [~,tanks] = obj.launchVehicle.getTanksListBoxStr();
                
                for(i=1:length(tanks))
                    c = TankMassConstraint(tanks(i), refEvt, 0, 0);
                    c.setScaleFactor(tankMassScale);
                    cs(end+1) = c; %#ok<AGROW>
                end
            end

            for(i=1:length(cs))
                c = cs(i);
                c.evalType = ConstraintEvalTypeEnum.StateComparison;
                c.stateCompType = ConstraintStateComparisonTypeEnum.Equals;
                c.stateCompEvent = constrEvt;
                c.frame = frame;

                obj.optimizer.constraints.addConstraint(c);
            end
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
            lvdData.stateLog = LaunchVehicleStateLog(lvdData);
                      
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
        end
        
        function lvdData = getLvdDataFromMfmsOutputs(mfmsOutputs)
            lvdData = LvdData.getDefaultLvdData(mfmsOutputs.celBodyData);
            lvdOptim = lvdData.optimizer;
            
            wayPtBodies = [mfmsOutputs.wayPtBodies{:}];
            
            [~, colorEnums] = ColorSpecEnum.getListboxStr();
            
            %Xfer orbit data
            xferOrbits = mfmsOutputs.xferOrbits; %sma ecc inc raan arg tru tru2 t1 t2 gmu
            xferOrbitDurations = xferOrbits(:,9) - xferOrbits(:,8);
            
            %Set critical settings
            maxSimDur = 10*(max(xferOrbits(:,9)) - min(xferOrbits(:,8)));
            lvdData.settings.simMaxDur = maxSimDur;
            lvdData.settings.maxScriptPropTime = 10;
            
            %Set up view profile
            cBodyInfo = wayPtBodies(1).getParBodyInfo();
            
            viewProfile = lvdData.viewSettings.selViewProfile;
            viewProfile.name = sprintf('%s-centered Inertial Frame', cBodyInfo.name);
            viewProfile.frame = cBodyInfo.getBodyCenteredInertialFrame();
            viewProfile.bodiesToPlot = wayPtBodies;
            
            %Set Initial State
            departBody = wayPtBodies(1);
            frame = departBody.getBodyCenteredInertialFrame();
            time = xferOrbits(1,8);
            orbit = mfmsOutputs.eOrbit;
            kepElemSet = KeplerianElementSet(time, orbit(1), orbit(2), orbit(3), orbit(4), orbit(5), orbit(8), frame);
            
            lvdData.initStateModel.orbitModel = kepElemSet;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Setup Departure Event
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            event = lvdData.script.evts(1);
            event.name = sprintf('Departure from %s (+)', departBody.name);
            event.execActionsNode = ActionExecNodeEnum.BeforeProp;
            event.colorLineSpec.color = colorEnums(1);
            event.integratorObj = event.ode113Integrator;
            event.integratorObj.options.AbsTol = 1E-7;
            event.integratorObj.options.RelTol = 1E-7;
            event.integratorObj.options.NormControl = false;
            
            %%%Set up termination condition
            dur = xferOrbitDurations(1)/2;
            termCond = EventDurationTermCondition(dur); %/2 so that we can meet a patch point in the middle
            event.termCond = termCond;
            
            var = termCond.getNewOptVar();
            lvdOptim.vars.addVariable(var);
            
            var.lb = 0.50*dur;
            var.ub = 1.50*dur;
            var.useTf = true;
            
            %%%Set up delta-v action
            deltaV = mfmsOutputs.dVDepartVectNTW;
            deltaVAction = AddDeltaVAction(deltaV, DeltaVFrameEnum.OrbitNtw, true);
            event.addAction(deltaVAction);
            deltaVAction.event = event;
            
            var = AddDeltaVActionVariable(deltaVAction);
            lvdOptim.vars.addVariable(var);
            var.lb = deltaV - 0.50*abs(deltaV);
            var.ub = deltaV + 0.50*abs(deltaV);
            var.varDVx = true;
            var.varDVy = true;
            var.varDVz = true;
            
            %%%Generate active vars cache
            event.clearActiveOptVarsCache();
            event.hasActiveOptVars();
            
            %%%Set previous forward prop event
            prevFwdPropEvent = event;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Do gravity assist maneuvers
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            for(i=2:length(wayPtBodies)-1)
                bodyInfo = wayPtBodies(i);
                frame = bodyInfo.getBodyCenteredInertialFrame();
                time = xferOrbits(i,8);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Set up periapsis state event
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                eventPeri = LaunchVehicleEvent(lvdData.script);
                lvdData.script.addEvent(eventPeri);
                eventPeri.name = sprintf('%s Periapsis State', bodyInfo.name);
                eventPeri.execActionsNode = ActionExecNodeEnum.BeforeProp;
                eventPeri.plotMethod = EventPlottingMethodEnum.DoNotPlot;
                eventPeri.propDir = PropagationDirectionEnum.Forward;
                
                %%%Event line color
                colorI = mod(2*(i-1), length(colorEnums));
                eventPeri.colorLineSpec.color = colorEnums(colorI);
                
                %%%Set up termination condition
                termCond = EventDurationTermCondition(0); %/2 so that we can meet a patch point in the middle
                eventPeri.termCond = termCond;
                
                %%%Set up Set Kinematic State Action
                orbitIn = mfmsOutputs.orbitsIn(i-1,:);
                orbitModel = KeplerianElementSet(time, orbitIn(1), orbitIn(2), orbitIn(3), angleNegPiToPi(orbitIn(4)), angleNegPiToPi(orbitIn(5)), 0, frame);
                orbitModel = orbitModel.convertToUniversalElementSet();
                action = SetKinematicStateAction(lvdData.stateLog, orbitModel);
                
                action.inheritStateElems = true;
                action.inheritStateElemsFrom = InheritStateEnum.InheritFromLastState;
                eventPeri.addAction(action);
                action.event = eventPeri;
                action.generateLvComponentElements();
                
                %%%Set up Set Kinematic State variable
                var = SetKinematicStateActionVariable(action);
                lvdOptim.vars.addVariable(var);
                
                var.lb = 0.50*time;
                var.ub = 1.50*time;
                var.useTf = true;
                
                var.orbitVar.lb = [min(1.0001,0.75*orbitModel.c3), ...
                                   max(0.75*orbitModel.rP,bodyInfo.radius+bodyInfo.atmohgt), ...
                                   0, ...
                                   -2*pi, ...
                                   -2*pi, ...
                                   0];
                               
                var.orbitVar.ub = [1.25*orbitModel.c3, ...
                                   1.25*orbitModel.rP, ...
                                   pi, ...
                                   2*pi, ...
                                   2*pi, ...
                                   0];
                               
                var.orbitVar.varC3 = true;
                var.orbitVar.varRp = true;
                var.orbitVar.varInc = true;
                var.orbitVar.varRaan = true;
                var.orbitVar.varArg = true;
                var.orbitVar.varTau = false;
                
                %%%Generate active vars cache
                eventPeri.clearActiveOptVarsCache();
                eventPeri.hasActiveOptVars();
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Set up event that props backwards from peri state
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                eventMinus = LaunchVehicleEvent(lvdData.script);
                lvdData.script.addEvent(eventMinus);
                eventMinus.name = sprintf('Coast from %s Periapsis (-)', bodyInfo.name);
                eventMinus.plotMethod = EventPlottingMethodEnum.PlotContinuous;
                eventMinus.propDir = PropagationDirectionEnum.Backward;
                eventMinus.integratorObj = eventMinus.ode113Integrator;
                eventMinus.integratorObj.options.AbsTol = 1E-7;
                eventMinus.integratorObj.options.RelTol = 1E-7;
                eventMinus.integratorObj.options.NormControl = false;
                
                %%%Event line color
                colorI = mod(2*(i-1), length(colorEnums));
                eventMinus.colorLineSpec.color = colorEnums(colorI);
                
                %%%Set up termination condition
                dur = xferOrbitDurations(i-1)/2;
                termCond = EventDurationTermCondition(dur); %/2 so that we can meet a patch point in the middle
                eventMinus.termCond = termCond;

                var = termCond.getNewOptVar();
                lvdOptim.vars.addVariable(var);
                var.lb = 0.50*dur;
                var.ub = 1.50*dur;
                var.useTf = true;
                
                %%%Create continuity constraint
                lvdData.createContinuityConstraints(eventMinus, prevFwdPropEvent, cBodyInfo, true, 1, true, 1, true, 1, false, 1, false, 1);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Set up periapsis state event and propagate FORWARDS
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                eventPlus = LaunchVehicleEvent(lvdData.script);
                lvdData.script.addEvent(eventPlus);
                eventPlus.name = sprintf('Coast from %s Periapsis (+)', bodyInfo.name);
                eventPlus.execActionsNode = ActionExecNodeEnum.BeforeProp;
                eventPlus.plotMethod = EventPlottingMethodEnum.SkipFirstState;
                eventPlus.propDir = PropagationDirectionEnum.Forward;
                eventPlus.integratorObj = eventPlus.ode113Integrator;
                eventPlus.integratorObj.options.AbsTol = 1E-7;
                eventPlus.integratorObj.options.RelTol = 1E-7;
                eventPlus.integratorObj.options.NormControl = false;
                
                %%%Event line color
                colorI = mod(2*(i-1)+1, length(colorEnums));
                eventPlus.colorLineSpec.color = colorEnums(colorI);
                
                %%%Set up termination condition
                dur = xferOrbitDurations(i)/2; %/2 so that we can meet a patch point in the middle
                termCond = EventDurationTermCondition(dur); 
                eventPlus.termCond = termCond;

                var = termCond.getNewOptVar();
                lvdOptim.vars.addVariable(var);
                
                var.lb = 0.50*dur;
                var.ub = 1.50*dur;
                var.useTf = true;
                
                %%%Set up Set Kinematic State Action
                orbitModel = KeplerianElementSet(time, orbitIn(1), orbitIn(2), orbitIn(3), angleNegPiToPi(orbitIn(4)), angleNegPiToPi(orbitIn(5)), 0, frame);
                orbitModel = orbitModel.convertToUniversalElementSet();
                
                action = SetKinematicStateAction(lvdData.stateLog, orbitModel);
                eventPlus.addAction(action);
                action.event = eventPlus;
                
                action.inheritTime = true;
                action.inheritTimeFrom = InheritStateEnum.InheritFromSpecifiedEvent;
                action.inheritTimeFromEvent = eventPeri;

                action.inheritPosVel = true;
                action.inheritPosVelFrom = InheritStateEnum.InheritFromSpecifiedEvent;
                action.inheritPosVelFromEvent = eventPeri;

                action.inheritStateElems = true;
                action.inheritStateElemsFrom = InheritStateEnum.InheritFromSpecifiedEvent;
                action.inheritStateElemsFromEvent = eventPeri;
                
                action.generateLvComponentElements();
                
                %%%Set up delta-v action
                deltaV = mfmsOutputs.deltaVVectNTW(:,i-1);
                action = AddDeltaVAction(deltaV, DeltaVFrameEnum.OrbitNtw, true);
                eventPlus.addAction(action);
                action.event = eventPlus;

                var = AddDeltaVActionVariable(action);
                lvdOptim.vars.addVariable(var);
                var.lb = deltaV - 0.50*abs(deltaV);
                var.ub = deltaV + 0.50*abs(deltaV);
                var.varDVx = true;
                var.varDVy = false;
                var.varDVz = false;
                
                %%%Generate active vars cache
                eventPlus.clearActiveOptVarsCache();
                eventPlus.hasActiveOptVars();
                
                %%%Set previous forward prop event
                prevFwdPropEvent = eventPlus;
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Set up periapsis state for arrive body
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            arriveBodyInfo = wayPtBodies(end);
            frame = arriveBodyInfo.getBodyCenteredInertialFrame();
            time = xferOrbits(end,9);
            
            %Compute an inbound orbit
            vInfArriveIn = mfmsOutputs.vInfArrive;
            vInfArriveMag = norm(vInfArriveIn);
            
            gmu = arriveBodyInfo.gm;
            sma = -gmu / vInfArriveMag^2;
            rP = arriveBodyInfo.radius + arriveBodyInfo.atmohgt + 0.1*arriveBodyInfo.radius;
            ecc = 1 - rP/sma;
            
            turnAngle = 2*acos(-1/ecc);
            R = rotz(rad2deg(turnAngle));
            vInfArriveOut = R * vInfArriveIn;
            
            [~, ~, hHat, sHat, ~, ~, ~] = computeMultiFlyByParameters(vInfArriveIn, vInfArriveOut, gmu);
            [hSMAIn, hEccIn, hIncIn, hRAANIn, hArgIn, ~, ~, ~] = computeHyperOrbitFromMultiFlybyParams(sma, ecc, hHat, sHat, true);
            
            %Create event
            event = LaunchVehicleEvent(lvdData.script);
            lvdData.script.addEvent(event);
            event.name = sprintf('%s Periapsis State', arriveBodyInfo.name);
            event.execActionsNode = ActionExecNodeEnum.BeforeProp;
            event.plotMethod = EventPlottingMethodEnum.SkipFirstState;
            event.propDir = PropagationDirectionEnum.Backward;
            event.integratorObj.options.AbsTol = 1E-7;
            event.integratorObj.options.RelTol = 1E-7;
            event.integratorObj.options.NormControl = false;
            
            %%%Event line color
            event.colorLineSpec.color = ColorSpecEnum.Blue;
                
            %%%Set up termination condition
            dur = 0; %/2 so that we can meet a patch point in the middle
            termCond = EventDurationTermCondition(dur); %/2 so that we can meet a patch point in the middle
            event.termCond = termCond;

            %%%Set up Set Kinematic State Action
            orbitModel = KeplerianElementSet(time, hSMAIn, hEccIn, hIncIn, angleNegPiToPi(hRAANIn), angleNegPiToPi(hArgIn), 0, frame);
            orbitModel = orbitModel.convertToUniversalElementSet();
            action = SetKinematicStateAction(lvdData.stateLog, orbitModel);

            action.inheritStateElems = true;
            action.inheritStateElemsFrom = InheritStateEnum.InheritFromLastState;
            event.addAction(action);
            action.event = event;
            
            action.generateLvComponentElements();
            
            %%%Set up Set Kinematic State variable
            var = SetKinematicStateActionVariable(action);
            lvdOptim.vars.addVariable(var);

            var.lb = 0.50*time;
            var.ub = 1.50*time;
            var.useTf = true;

            var.orbitVar.lb = [min(1.0001,0.75*orbitModel.c3), ...
                               max(0.75*orbitModel.rP,arriveBodyInfo.radius+arriveBodyInfo.atmohgt), ...
                               0, ...
                               -2*pi, ...
                               -2*pi, ...
                               0];

            var.orbitVar.ub = [1.25*orbitModel.c3, ...
                               1.25*orbitModel.rP, ...
                               pi, ...
                               2*pi, ...
                               2*pi, ...
                               0];

            var.orbitVar.varC3 = true;
            var.orbitVar.varRp = true;
            var.orbitVar.varInc = true;
            var.orbitVar.varRaan = true;
            var.orbitVar.varArg = true;
            var.orbitVar.varTau = false;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Prop BACKWARDS from periapsis state for arrive body
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Create event
            event = LaunchVehicleEvent(lvdData.script);
            lvdData.script.addEvent(event);
            event.name = sprintf('Coast from %s Arrival (-)', arriveBodyInfo.name);
            event.execActionsNode = ActionExecNodeEnum.BeforeProp;
            event.plotMethod = EventPlottingMethodEnum.SkipFirstState;
            event.propDir = PropagationDirectionEnum.Backward;
            event.integratorObj.options.AbsTol = 1E-7;
            event.integratorObj.options.RelTol = 1E-7;
            event.integratorObj.options.NormControl = false;
            
            %%%Event line color
            event.colorLineSpec.color = ColorSpecEnum.Blue;
            
            %%%Set up termination condition
            dur = xferOrbitDurations(end)/2; %/2 so that we can meet a patch point in the middle
            termCond = EventDurationTermCondition(dur); %/2 so that we can meet a patch point in the middle
            event.termCond = termCond;
            
            var = termCond.getNewOptVar();
            lvdOptim.vars.addVariable(var);

            var.lb = 0.50*dur;
            var.ub = 1.50*dur;
            var.useTf = true;
            
            %%%Create continuity constraint
            lvdData.createContinuityConstraints(event, prevFwdPropEvent, cBodyInfo, true, 1, true, 1, true, 1, false, 1, false, 1);
            
            %Set up objective function
            fcn = GenericMAConstraint('Total Spacecraft Mass', event, 0, 0, [], [], cBodyInfo);
            objFcn = GenericObjectiveFcn(event, cBodyInfo.getBodyCenteredInertialFrame(), fcn, 1, lvdOptim, lvdData);
            lvdOptim.objFcn.addObjFunc(objFcn);
            lvdOptim.objFcn.dirType = ObjFcnDirectionTypeEnum.Maximize;
        end
        
        function initBody = getDefaultInitialBodyInfo(celBodyData)           
            if(isfield(celBodyData,'kerbin'))
                initBody = celBodyData.kerbin;
            elseif(isfield(celBodyData,'earth'))
                initBody = celBodyData.earth;
            else
                fields = fieldnames(celBodyData);
                initBody = celBodyData.(fields{1});
            end            
        end
        
        function obj = loadobj(obj)
            arguments
                obj LvdData
            end

            obj.validation = LaunchVehicleDataValidation(obj);
            
            if(isempty(obj.stateLog))
                obj.stateLog = LaunchVehicleStateLog(obj);
            end

            if(isempty(obj.stateLog.lvdData))
                obj.stateLog.lvdData = obj;
            end
            
            if(isempty(obj.plugins))
                obj.plugins = LvdPluginSet(obj);
            end

            if(isempty(obj.pluginVars))
                obj.pluginVars = LvdPluginOptimVarSet(obj);
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
            for(i=1:length(evts)) %#ok<*NO4LP> 
                evts(i).createUpdatedSetKinematicStateObjs();
            end
            
            nonSeqEvts = obj.script.nonSeqEvts.nonSeqEvts;
            for(i=1:length(nonSeqEvts))
                nonSeqEvts(i).evt.createUpdatedSetKinematicStateObjs();
            end

            if(isempty(obj.id) || obj.id == 0)
                obj.id = rand();
            end
        end
        
        function obj = saveobj(obj)
            obj.stateLog.clearStateLog();
        end
    end
end