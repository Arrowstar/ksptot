classdef ExtremumValueConstraint < AbstractConstraint
    %ExtremumValueConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        normFact = 1;
        event LaunchVehicleEvent
        extremum LaunchVehicleExtrema
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;
    end
    
    methods
        function obj = ExtremumValueConstraint(event, lb, ub)
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
            extremaStates = stateLogEntry.getAllExtremaStates();
            extremaState = extremaStates(extremaStates.extrema == obj.extremum);
            
            value = extremaState.value;
                       
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
            tf = [obj.extremum] == extremum;
        end
        
        function tf = canUseSparseOutput(obj)
            tf = false;
        end
        
        function event = getConstraintEvent(obj)
            event = obj.event;
        end
        
        function type = getConstraintType(obj)
            type = 'Extremum Value';
        end
        
%         function name = getName(obj)
%             name = sprintf('%s - Event %i', obj.getConstraintType(), obj.event.getEventNum());
%         end
        
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            unit = obj.extremum.unitStr;
            lbLim = -Inf;
            ubLim = Inf;
            usesLbUb = true;
            usesCelBody = false;
            usesRefSc = false;
        end
        
        function addConstraintTf = openEditConstraintUI(obj, lvdData)
%             [listBoxStr, extrema] = lvdData.launchVehicle.getExtremaListBoxStr();
% 
%             if(isempty(extrema))
%                 addConstraintTf = false;
%                 
%                 warndlg('Cannot create extrema value object: no extrema have been created.  Create an extremum first.','Extremum Value Constraint','modal');
%             else
%                 [Selection,ok] = listdlg('PromptString',{'Select an extremum:'},...
%                                 'SelectionMode','single',...
%                                 'Name','Extremum',...
%                                 'ListString',listBoxStr);
%                             
%                 if(ok == 0)
%                     addConstraintTf = false;
%                 else
%                     ex = extrema(Selection);
%                     obj.extremum = ex;
%                     
%                     addConstraintTf = lvd_EditGenericMAConstraintGUI(obj, lvdData);
%                 end
%             end

            ex = obj.selectConstraintObj(lvdData);
            
            if(not(isempty(ex)))
                obj.extremum = ex;
                addConstraintTf = lvd_EditGenericMAConstraintGUI(obj, lvdData);
            else
                addConstraintTf = false;
            end
        end
        
        function ex = selectConstraintObj(obj, lvdData)
            [listBoxStr, extrema] = lvdData.launchVehicle.getExtremaListBoxStr();

            ex = [];
            if(isempty(extrema))                
                warndlg('Cannot create extrema value object: no extrema have been created.  Create an extremum first.','Extremum Value Constraint','modal');
            else
                [Selection,ok] = listdlg('PromptString',{'Select an extremum:'},...
                                'SelectionMode','single',...
                                'Name','Extremum',...
                                'ListString',listBoxStr);
                            
                if(ok == 0)
                    ex = [];
                else
                    ex = extrema(Selection);
                end
            end
        end
        
        function setupForUseAsObjectiveFcn(obj,lvdData)
            ex = obj.selectConstraintObj(lvdData);
            
            if(not(isempty(ex)))
                obj.extremum = ex;
            end
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~, ~)            
            constraint = ExtremumValueConstraint(LaunchVehicleEvent.empty(1,0),0,0);
        end
    end
end