classdef GeometricAngleMagConstraint < AbstractConstraint
    %GeometricAngleMagConstraint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        normFact = 1;
        angle AbstractGeometricAngle
        useAbsValue(1,1) logical = false;
        event LaunchVehicleEvent
        eventNode(1,1) ConstraintStateComparisonNodeEnum = ConstraintStateComparisonNodeEnum.FinalState;
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;

        evalType(1,1) ConstraintEvalTypeEnum = ConstraintEvalTypeEnum.FixedBounds;
        stateCompType(1,1) ConstraintStateComparisonTypeEnum = ConstraintStateComparisonTypeEnum.Equals;
        stateCompEvent LaunchVehicleEvent
        stateCompNode(1,1) ConstraintStateComparisonNodeEnum = ConstraintStateComparisonNodeEnum.FinalState;
    end
    
    methods
        function obj = GeometricAngleMagConstraint(angle, event, lb, ub)
            obj.angle = angle;
            obj.event = event;
            obj.lb = lb;
            obj.ub = ub;   
            
             obj.id = rand();
        end
        
        function [lb, ub] = getBounds(obj)
            lb = obj.lb;
            ub = obj.ub;
        end
        
        function [c, ceq, value, lwrBnd, uprBnd, type, eventNum, valueStateComp] = evalConstraint(obj, stateLog, celBodyData)           
            type = obj.getConstraintType();
            
            switch obj.eventNode
                case ConstraintStateComparisonNodeEnum.FinalState
                    stateLogEntry = stateLog.getLastStateLogForEvent(obj.event);
                    
                case ConstraintStateComparisonNodeEnum.InitialState
                    stateLogEntry = stateLog.getFirstStateLogForEvent(obj.event);
                
                otherwise
                    error('Unknown event node.');
            end

            if(not(isempty(obj.frame)))
                frame = obj.frame;
            else
                frame = stateLogEntry.centralBody.getBodyCenteredInertialFrame();
            end
            
            value = lvd_GeometricAngleTasks(stateLogEntry, 'Mag', obj.angle, frame);
            if(obj.useAbsValue)
                value = abs(value);
            end
            
            if(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                switch obj.stateCompNode
                    case ConstraintStateComparisonNodeEnum.FinalState
                        stateLogEntryStateComp = stateLog.getLastStateLogForEvent(obj.stateCompEvent);

                    case ConstraintStateComparisonNodeEnum.InitialState
                        stateLogEntryStateComp = stateLog.getFirstStateLogForEvent(obj.stateCompEvent);

                    otherwise
                        error('Unknown event node.');
                end

                valueStateComp = lvd_GeometricAngleTasks(stateLogEntryStateComp, 'Mag', obj.angle, frame);
                if(obj.useAbsValue)
                    valueStateComp = abs(valueStateComp);
                end
            else
                valueStateComp = NaN;
            end
            
            [c, ceq] = obj.computeCAndCeqValues(value, valueStateComp); 
            
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
            if(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                tf = tf || obj.stateCompEvent == event;
            end
        end
        
        function tf = usesStopwatch(~, ~)
            tf = false;
        end
        
        function tf = usesExtremum(~, ~)
            tf = false;
        end
        
        function tf = usesGroundObj(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricAngle(obj, angle)
            tf = obj.angle == angle;
        end
        
        function tf = canUseSparseOutput(obj)
            tf = true;
        end
        
        function event = getConstraintEvent(obj)
            event = obj.event;
        end
        
        function type = getConstraintType(obj)
            type = 'Geometric Angle Magnitude';
        end
        
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            unit = 'deg';
            lbLim = -Inf;
            ubLim = Inf;
            usesLbUb = true;
            usesCelBody = false;
            usesRefSc = false;
        end
        
        function addConstraintTf = openEditConstraintUI(obj, lvdData)
            if(lvdData.geometry.angles.getNumAngles() >= 1)
                addConstraintTf = lvd_EditGeometricAngleConstraintGUI(obj, lvdData);
            else
                errordlg('There are currently no geometric angles in this scenario.  Add at least one new angle first.');
                
                addConstraintTf = false;
            end
        end
        
        function angle = selectConstraintObj(obj, lvdData)
            [listBoxStr, angles] = lvdData.geometry.angles.getListboxStr();

            angle = [];
            if(isempty(angles))                
                warndlg('Cannot create angle value object: no angles have been created.  Create an angle first.','Angle Value Constraint','modal');
            else
                [Selection,ok] = listdlg('PromptString',{'Select an angle:'},...
                                'SelectionMode','single',...
                                'Name','Angles',...
                                'ListString',listBoxStr);
                            
                if(ok == 0)
                    angle = [];
                else
                    angle = angles(Selection);
                end
            end
        end
        
        function useObjFcn = setupForUseAsObjectiveFcn(obj,lvdData)
            angleSel = obj.selectConstraintObj(lvdData);
            
            if(not(isempty(angleSel)))
                obj.angle = angleSel;
                useObjFcn = true;
            else
                useObjFcn = false;
            end
        end
    end
    
    methods(Static)
        function constraint = getDefaultConstraint(~, ~)            
            constraint = GeometricAngleMagConstraint(AbstractGeometricAngle.empty(1,0), LaunchVehicleEvent.empty(1,0), 0, 0);
        end
    end
end