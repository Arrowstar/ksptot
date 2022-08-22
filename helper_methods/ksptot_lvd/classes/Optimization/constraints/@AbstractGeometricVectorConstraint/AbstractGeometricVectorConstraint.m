classdef(Abstract) AbstractGeometricVectorConstraint < AbstractConstraint
    %AbstractGeometricVectorConstraint Summary of this class goes here
    %   Detailed explanation goes here

    properties
        normFact = 1;
        vector AbstractGeometricVector
        event LaunchVehicleEvent
        eventNode(1,1) ConstraintStateComparisonNodeEnum = ConstraintStateComparisonNodeEnum.FinalState;
        
        lb(1,1) double = 0;
        ub(1,1) double = 0;

        type(1,:) char
        
        evalType(1,1) ConstraintEvalTypeEnum = ConstraintEvalTypeEnum.FixedBounds;
        stateCompType(1,1) ConstraintStateComparisonTypeEnum = ConstraintStateComparisonTypeEnum.Equals;
        stateCompEvent LaunchVehicleEvent
        stateCompNode(1,1) ConstraintStateComparisonNodeEnum = ConstraintStateComparisonNodeEnum.FinalState;
    end

    methods
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
            
            value = lvd_GeometricVectorTasks(stateLogEntry, obj.type, obj.vector, frame);
            
            if(obj.evalType == ConstraintEvalTypeEnum.StateComparison)
                switch obj.stateCompNode
                    case ConstraintStateComparisonNodeEnum.FinalState
                        stateLogEntryStateComp = stateLog.getLastStateLogForEvent(obj.stateCompEvent);

                    case ConstraintStateComparisonNodeEnum.InitialState
                        stateLogEntryStateComp = stateLog.getFirstStateLogForEvent(obj.stateCompEvent);

                    otherwise
                        error('Unknown event node.');
                end

                valueStateComp = lvd_GeometricVectorTasks(stateLogEntryStateComp, obj.type, obj.vector, frame);
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
        
        function tf = usesGeometricVector(obj, vector)
            tf = obj.vector == vector;
        end
        
        function tf = canUseSparseOutput(obj)
            tf = true;
        end
        
        function event = getConstraintEvent(obj)
            event = obj.event;
        end
                
        function [unit, lbLim, ubLim, usesLbUb, usesCelBody, usesRefSc] = getConstraintStaticDetails(obj)
            unit = '';
            lbLim = 0;
            ubLim = Inf;
            usesLbUb = true;
            usesCelBody = false;
            usesRefSc = false;
        end
        
        function addConstraintTf = openEditConstraintUI(obj, lvdData)
            if(lvdData.geometry.vectors.getNumVectors() >= 1)
%                 addConstraintTf = lvd_EditGeometricVectorConstraintGUI(obj, lvdData);

                output = AppDesignerGUIOutput({false});
                lvd_EditGeometricVectorConstraintGUI_App(obj, lvdData, output);
                addConstraintTf = output.output{1};
            else
                errordlg('There are currently no geometric vectors in this scenario.  Add at least one new vector first.');
                
                addConstraintTf = false;
            end
        end
        
        function vector = selectConstraintObj(obj, lvdData)
            [listBoxStr, vectors] = lvdData.geometry.vectors.getListboxStr();

            vector = [];
            if(isempty(vectors))                
                warndlg('Cannot create vector value object: no vectors have been created.  Create a vector first.','Vector Value Constraint','modal');
            else
                [Selection,ok] = listdlg('PromptString',{'Select a vector:'},...
                                'SelectionMode','single',...
                                'Name','Vectors',...
                                'ListString',listBoxStr);
                            
                if(ok == 0)
                    vector = [];
                else
                    vector = vectors(Selection);
                end
            end
        end
        
        function useObjFcn = setupForUseAsObjectiveFcn(obj,lvdData)
            vectorSel = obj.selectConstraintObj(lvdData);
            
            if(not(isempty(vectorSel)))
                obj.vector = vectorSel;
                useObjFcn = true;
            else
                useObjFcn = false;
            end
        end
    end
end