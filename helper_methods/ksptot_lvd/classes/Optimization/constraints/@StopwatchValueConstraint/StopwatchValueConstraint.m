classdef StopwatchValueConstraint < AbstractConstraint
    %StopwatchValueConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        normFact = 1;
        event LaunchVehicleEvent
        stopwatch LaunchVehicleStopwatch
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
    end
    
    methods
        function obj = StopwatchValueConstraint(event, lb, ub)
            obj.event = event;
            obj.lb = lb;
            obj.ub = ub;   
            
             obj.id = rand();
        end
        
        function [lb, ub] = getBounds(obj)
            lb = obj.lb;
            ub = obj.ub;
        end
        
        function [c, ceq, value, lwrBnd, uprBnd, type, eventNum] = evalConstraint(obj, stateLog, celBodyData)           
            type = obj.getConstraintType();
            stateLogEntry = stateLog.getLastStateLogForEvent(obj.event);
            stopWatchStates = stateLogEntry.getAllStopwatchStates();
            stopWatchState = stopWatchStates(stopWatchStates.stopwatch == obj.stopwatch);
            
            value = stopWatchState.value;
                       
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
            tf = obj.stopwatch == stopwatch;
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
            type = 'Stopwatch Value';
        end
        
%         function name = getName(obj)
%             name = sprintf('%s - Event %i', obj.getConstraintType(), obj.event.getEventNum());
%         end
        
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            unit = 'sec';
            lbLim = -Inf;
            ubLim = Inf;
            usesLbUb = true;
            usesCelBody = false;
            usesRefSc = false;
        end
        
        function addConstraintTf = openEditConstraintUI(obj, lvdData)
%             [listBoxStr, stopwatches] = lvdData.launchVehicle.getStopwatchesListBoxStr();
% 
%             if(isempty(stopwatches))
%                 addConstraintTf = false;
%                 
%                 warndlg('Cannot create stopwatch value constraint: no stopwatches have been created.  Create a stopwatch first.','Stopwatch Value Constraint','modal');
%             else
%                 [Selection,ok] = listdlg('PromptString',{'Select the stopwatch','to constraint:'},...
%                                 'SelectionMode','single',...
%                                 'Name','Stopwatch',...
%                                 'ListString',listBoxStr);
%                             
%                 if(ok == 0)
%                     addConstraintTf = false;
%                 else
%                     sw = stopwatches(Selection);
%                     obj.stopwatch = sw;
%                     
%                     addConstraintTf = lvd_EditGenericMAConstraintGUI(obj, lvdData);
%                 end
%             end

            sw = obj.selectConstraintObj(lvdData);
            
            if(not(isempty(sw)))
                obj.stopwatch = sw;
                addConstraintTf = lvd_EditGenericMAConstraintGUI(obj, lvdData);
            else
                addConstraintTf = false;
            end
        end
        
        function sw = selectConstraintObj(obj, lvdData)
            [listBoxStr, stopwatches] = lvdData.launchVehicle.getStopwatchesListBoxStr();

            if(isempty(stopwatches))                
                warndlg('Cannot create stopwatch value object: no stopwatches have been created.  Create a stopwatch first.','Stopwatch Value Constraint','modal');
            else
                [Selection,ok] = listdlg('PromptString',{'Select the stopwatch:'},...
                                'SelectionMode','single',...
                                'Name','Stopwatch',...
                                'ListString',listBoxStr);
                            
                if(ok == 0)
                    sw = [];
                else
                    sw = stopwatches(Selection);
                end
            end
        end
        
        function setupForUseAsObjectiveFcn(obj,lvdData)
            sw = obj.selectConstraintObj(lvdData);
            
            if(not(isempty(sw)))
                obj.stopwatch = sw;
            end
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~, ~)            
            constraint = StopwatchValueConstraint(LaunchVehicleEvent.empty(1,0),0,0);
        end
    end
end