classdef CompositeObjectiveFcn < AbstractObjectiveFcn
    %CompositeObjectiveFcn Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        objFcns GenericObjectiveFcn 
        dirType(1,1) ObjFcnDirectionTypeEnum = ObjFcnDirectionTypeEnum.Minimize;
        compositeMethod(1,1) ObjFcnCompositeMethodEnum = ObjFcnCompositeMethodEnum.Sum;
        
        lvdOptim LvdOptimization
        lvdData LvdData
    end
    
    methods
        function obj = CompositeObjectiveFcn(objFcns, dirType, compositeMethod, lvdOptim, lvdData)
            if(nargin > 0)
                obj.objFcns = objFcns;
                obj.dirType = dirType;
                obj.compositeMethod = compositeMethod;
                obj.lvdOptim = lvdOptim;
                obj.lvdData = lvdData;
            end
        end
        
        function listBoxStr = getListBoxStr(obj)
            listBoxStr = {};
            for(i=1:length(obj.objFcns))
                listBoxStr{end+1} = obj.objFcns(i).getListBoxStr(); %#ok<AGROW>
            end
        end
        
        function [f, stateLog] = evalObjFcn(obj, x, evtToStartScriptExecAt)
            if(isempty(obj.lvdOptim))
                obj.lvdOptim = obj.lvdData.optimizer;
            end
            
            obj.lvdOptim.vars.updateObjsWithScaledVarValues(x);
            useSparse = obj.canUseSparseOutput();
            stateLog = obj.lvdData.script.executeScript(useSparse, evtToStartScriptExecAt, false, true, false);
            
            numObjFcns = length(obj.objFcns);
            if(numObjFcns == 0)
                f = 0;
            else
                fArr = NaN(1, numObjFcns);
                for(i=1:numObjFcns)
                    fArr(i) = obj.objFcns(i).evalObjFcn(stateLog);
                end
                
                switch obj.compositeMethod
                    case ObjFcnCompositeMethodEnum.Sum
                        f = sum(fArr);
                        
                    case ObjFcnCompositeMethodEnum.RSS
                        f = sqrt(sum(fArr.^2));
                        
                    case ObjFcnCompositeMethodEnum.MaxJ
                        f = max(fArr);
                        
                    case ObjFcnCompositeMethodEnum.MinJ
                        f = min(fArr);
                        
                    otherwise
                        error('Unknown objective function compositing method: %s', ...
                              matlab.unittest.diagnostics.ConstraintDiagnostic.getDisplayableString(obj.compositeMethod));
                end
                
                if(obj.dirType == ObjFcnDirectionTypeEnum.Maximize)
                    f = -1*f;
                end
            end
        end
        
        function addObjFunc(obj, objFunc)
            obj.objFcns(end+1) = objFunc;
        end
        
        function removeObjFunc(obj, objFunc)
            obj.objFcns(obj.objFcns == objFunc) = [];
        end      
        
        function genObjFunc = getObjFuncForInd(obj, ind)
            genObjFunc = GenericObjectiveFcn.empty(1,0);
            
            if(ind >= 1 && ind <= length(obj.objFcns))
                genObjFunc = obj.objFcns(ind);
            end
        end
        
        function numObjFuncs = getNumberObjFuncs(obj)
            numObjFuncs = length(obj.objFcns);
        end
        
        function tf = usesStage(obj, stage)
            tf = false;
            for(i=1:length(obj.objFcns))
                tf = tf || obj.objFcns(i).usesStage(stage);
            end
        end
        
        function tf = usesEngine(obj, engine)
            tf = false;
            for(i=1:length(obj.objFcns))
                tf = tf || obj.objFcns(i).usesEngine(engine);
            end
        end
        
        function tf = usesTank(obj, tank)
            tf = false;
            for(i=1:length(obj.objFcns))
                tf = tf || obj.objFcns(i).usesTank(tank);
            end
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
            for(i=1:length(obj.objFcns))
                tf = tf || obj.objFcns(i).usesEngineToTankConn(engineToTank);
            end
        end
        
        function tf = usesEvent(obj, event)
            tf = false;
            for(i=1:length(obj.objFcns))
                tf = tf || obj.objFcns(i).usesEvent(event);
            end
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
            for(i=1:length(obj.objFcns))
                tf = tf || obj.objFcns(i).usesExtremum(extremum);
            end
        end
        
        function tf = usesGroundObj(obj, grdObj)
            tf = false;
            for(i=1:length(obj.objFcns))
                tf = tf || obj.objFcns(i).usesGroundObj(grdObj);
            end
        end
        
        function tf = usesCalculusCalc(obj, calculusCalc)
            tf = false;
            for(i=1:length(obj.objFcns))
                tf = tf || obj.objFcns(i).usesCalculusCalc(calculusCalc);
            end
        end
        
        function event = getRefEvent(obj)
            for(i=1:length(obj.objFcns))
                event(i) = obj.objFcns(i).event; %#ok<AGROW>
            end
        end
        
        function bodyInfo = getRefBody(obj)
            for(i=1:length(obj.objFcns))
                bodyInfo(i) = obj.objFcns(i).targetBodyInfo; %#ok<AGROW>
            end
        end
        
        function tf = canUseSparseOutput(obj)
            tf = true;
            
            for(i=1:length(obj.objFcns)) %#ok<*NO4LP>
                tf = tf && obj.objFcns(i).fcn.canUseSparseOutput();
            end
        end
        
        function evts = getObjFuncEvents(obj)
            evts = LaunchVehicleEvent.empty(1,0);
            
            for(i=1:length(obj.objFcns))
                evts(i) = obj.objFcns(i).getRefEvent();
            end
        end
    end

    methods(Static)
        function objFcn = getDefaultObjFcn(event, refBodyInfo, lvdOptim, lvdData)
            objFcn = CompositeObjectiveFcn(GenericObjectiveFcn.empty(1,0), lvdOptim, lvdData);
        end
        
        function params = getParams()
            params = struct();
            
            params.usesEvents = true;
            params.usesBodies = true;
        end
        
        function objFcn = upgradeExistingObjFuncs(oldObjFunc, lvdOptim, lvdData)
            if(isa(oldObjFunc,'MaximizeLaunchVehicleMassObjectiveFcn')) 
                event = oldObjFunc.event;
                fcn = GenericMAConstraint('Total Spacecraft Mass', event, 0, 0, struct([]), struct([]), KSPTOT_BodyInfo.empty(1,0));
                genObjFunc = GenericObjectiveFcn(event, KSPTOT_BodyInfo.empty(1,0), fcn, 1, lvdOptim, lvdData);
                
                objFcn = CompositeObjectiveFcn(genObjFunc, ObjFcnDirectionTypeEnum.Maximize, ObjFcnCompositeMethodEnum.Sum, lvdOptim, lvdData);
            
            elseif(isa(oldObjFunc,'MinDistanceToBodyObjectiveFcn'))
                event = oldObjFunc.event;
                targetBodyInfo = oldObjFunc.targetBodyInfo;
                fcn = GenericMAConstraint('Distance to Ref. Celestial Body', event, 0, 0, struct([]), struct([]), targetBodyInfo);
                genObjFunc = GenericObjectiveFcn(event, targetBodyInfo, fcn, 1, lvdOptim, lvdData);
                
                objFcn = CompositeObjectiveFcn(genObjFunc, ObjFcnDirectionTypeEnum.Minimize, ObjFcnCompositeMethodEnum.Sum, lvdOptim, lvdData);
                
            elseif(isa(oldObjFunc,'NoOptimizationObjectiveFcn'))
                objFcn = CompositeObjectiveFcn(GenericObjectiveFcn.empty(1,0), ObjFcnDirectionTypeEnum.Minimize, ObjFcnCompositeMethodEnum.Sum, lvdOptim, lvdData);
            
            else
                objFcn = oldObjFunc;
            end
        end
    end
end