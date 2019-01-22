classdef GenericMAConstraint < AbstractConstraint
    %GenericMAConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        constraintType char = '';
        normFact = 1;
        event LaunchVehicleEvent
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
    end
    
    methods
        function obj = GenericMAConstraint(constraintType, event, lb, ub, refStation, refOtherSC, refBodyInfo)
            obj.constraintType = constraintType;
            obj.event = event;
            obj.lb = lb;
            obj.ub = ub;
            obj.refStation = refStation;
            obj.refOtherSC = refOtherSC;
            obj.refBodyInfo = refBodyInfo; 
            
             obj.id = rand();
        end
        
        function [lb, ub] = getBounds(obj)
            lb = obj.lb;
            ub = obj.ub;
        end
        
        function [c, ceq, value, lwrBnd, uprBnd, type, eventNum] = evalConstraint(obj, stateLog, celBodyData)           
            stateLogEntry = stateLog.getLastStateLogForEvent(obj.event).getMAFormattedStateLogMatrix();
            type = obj.constraintType;
            
            if(not(isempty(obj.refBodyInfo)))
                refBodyId = obj.refBodyInfo.id;
            else
                refBodyId = [];
            end
            
            oscId = -1;
            if(not(isempty(obj.refOtherSC)))
                oscId = obj.refOtherSC.id;
            end
            
            stnId = -1;
            if(not(isempty(obj.refStation)))
                stnId = obj.refStation.id;
            end
            
            maData.spacecraft = struct();
            propNames = obj.event.lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
%             propNames = {'Liquid Fuel/Ox','Monopropellant','Xenon'}; %placeholder only
            value = ma_getDepVarValueUnit(1, stateLogEntry, type, 0, refBodyId, oscId, stnId, propNames, maData, celBodyData, false);
                       
            if(obj.lb == obj.ub)
                c = [];
                ceq(1) = value - obj.ub;
            else
                c(1) = obj.lb - value;
                c(2) = value - obj.ub;
                ceq = [];
            end
            c = c/obj.normFact;
            ceq = ceq/obj.normFact;  
            
            lwrBnd = obj.lb;
            uprBnd = obj.ub;
            
            eventNum = obj.event.getEventNum();
        end
        
        function sF = getScaleFactor(obj)
            sF = obj.normFact;
        end
        
        function setScaleFactor(obj, sF)
            obj.normFact = sF;
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
        
        function tf = usesEvent(obj, event)
            tf = obj.event == event;
        end
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = false;
        end
        
        function tf = canUseSparseOutput(obj)
            tf = true;
        end
        
        function event = getConstraintEvent(obj)
            event = obj.event;
        end
        
        function type = getConstraintType(obj)
            type = obj.constraintType;
        end
                
        function name = getName(obj)
            name = sprintf('%s - Event %i', obj.getConstraintType(), obj.event.getEventNum());
        end
        
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            [unit, lbLim, ubLim, ~, ~, ~, ~, usesLbUb, usesCelBody, usesRefSc] = ma_getConstraintStaticDetails(obj.constraintType);           
        end
        
        function addConstraintTf = openEditConstraintUI(obj, lvdData)
            addConstraintTf = lvd_EditGenericMAConstraintGUI(obj, lvdData);
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(constraintType)            
            constraint = GenericMAConstraint(constraintType, LaunchVehicleEvent.empty(1,0), 0, 0, [], [], KSPTOT_BodyInfo.empty(1,0));
        end
    end
end