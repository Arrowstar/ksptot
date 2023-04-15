classdef ConditionalAction < AbstractEventAction
    %ConditionalAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ifCondition(1,1) AbstractActionConditional = AlwaysTrueActionCondition();
        ifActions(1,:) AbstractEventAction

        elseifConditions(1,:) AbstractActionConditional
        elseifActions(1,1) dictionary

        elseActions(1,:) AbstractEventAction
    end
    
    methods
        function obj = ConditionalAction()
            if(nargin > 0)
                
            end

            obj.elseifActions = dictionary(AbstractActionConditional.empty(1,0), {AbstractEventAction.empty(1,0)});
            
            obj.id = rand();
        end

        function addIfAction(obj, action)
            obj.ifActions(end+1) = action;
        end

        function removeIfAction(obj, action)
            obj.ifActions(obj.ifActions == action) = [];
        end

        function addElseIfConditional(obj, cond)
            obj.elseifConditions(end+1) = cond;
            obj.elseifActions{cond} = AbstractEventAction.empty(1,0);
        end

        function removeElseIfConditional(obj, cond)
            obj.elseifConditions(obj.elseifConditions == cond) = [];
            obj.elseifActions{cond} = [];
        end

        function substituteElseIfConditional(obj, oldCond, newCond)
            ind = find(obj.elseifConditions == oldCond);
            obj.elseifConditions(ind) = newCond;

            obj.elseifActions(newCond) = obj.elseifActions(oldCond);
            obj.elseifActions(oldCond) = [];
        end

        function addElseIfAction(obj, elseIfCond, action)
            if(obj.elseifActions.isKey(elseIfCond))
                elseIfActions = obj.elseifActions{elseIfCond};

                if(iscell(elseIfActions))
                    elseIfActions = [elseIfActions{:}];
                end

                if(iscell(action))
                    action = [action{:}];
                end

                if(not(isempty(action)))
                    elseIfActions(end+1) = action;
                end

                obj.elseifActions{elseIfCond} = elseIfActions;
            else
                error('Unknown key in else if action dictionary!');
            end
        end

        function removeElseIfAction(obj, elseIfCond, action)
            if(obj.elseifActions.isKey(elseIfCond))
                elseIfActions = obj.elseifActions{elseIfCond};
                elseIfActions(elseIfActions == action) = [];
                obj.elseifActions{elseIfCond} = elseIfActions;
            else
                error('Unknown key in else if action dictionary!');
            end
        end

        function addElseAction(obj, action)
            obj.elseActions(end+1) = action;
        end

        function removeElseAction(obj, action)
            obj.elseActions(obj.elseActions == action) = [];
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            arguments
                obj(1,1) ConditionalAction
                stateLogEntry(1,1) LaunchVehicleStateLogEntry
            end

            newStateLogEntry = stateLogEntry.deepCopy();

            %IF
            if(obj.ifCondition.evaluateConditional(newStateLogEntry))
                for(i=1:length(obj.ifActions))
                    newStateLogEntry = obj.ifActions(i).executeAction(newStateLogEntry);
                end

                return;
            end

            %ELSE IF
            for(i=1:length(obj.elseifConditions))
                elseIfCondition = obj.elseifConditions(i);
                if(elseIfCondition.evaluateConditional(newStateLogEntry))
                    theseElseIfActions = obj.elseifActions{elseIfCondition};

                    for(j=1:length(theseElseIfActions))
                        newStateLogEntry = theseElseIfActions(j).executeAction(newStateLogEntry);
                    end

                    return;
                end
            end

            %ELSE
            for(i=1:length(obj.elseActions))
                newStateLogEntry = obj.elseActions(i).executeAction(newStateLogEntry);
            end
        end
        
        function initAction(obj, initialStateLogEntry)
            event = initialStateLogEntry.event;

            %IF
            for(i=1:length(obj.ifActions))
                obj.ifActions(i).event = event;
                obj.ifActions(i).initAction(initialStateLogEntry);
            end

            %ELSE IF
            for(i=1:length(obj.elseifConditions))
                elseIfCondition = obj.elseifConditions(i);
                theseElseIfActions = obj.elseifActions{elseIfCondition};
                    
                for(j=1:length(theseElseIfActions))
                    theseElseIfActions(j).event = event;
                    theseElseIfActions(j).initAction(initialStateLogEntry);
                end                
            end

            %ELSE
            for(i=1:length(obj.elseActions))
                obj.elseActions(i).event = event;
                obj.elseActions(i).initAction(initialStateLogEntry);
            end
        end
        
        function name = getName(obj)            
            name = sprintf('Conditional Action');
        end
                        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);

            %IF
            for(i=1:numel(obj.ifActions))
                [thisTf, theseVars] = obj.ifActions(i).hasActiveOptimVar();

                tf = tf || thisTf;
                vars = horzcat(vars, theseVars(:)'); %#ok<AGROW>
            end

            %ELSE IF
            for(i=1:numel(obj.elseifConditions))
                elseifCondition = obj.elseifConditions(i);
                condElseIfActions = obj.elseifActions(elseifCondition);

                for(j=1:nume(condElseIfActions))
                    [thisTf, theseVars] = condElseIfActions(j).hasActiveOptimVar();
    
                    tf = tf || thisTf;
                    vars = horzcat(vars, theseVars(:)'); %#ok<AGROW>
                end
            end

            %ELSE
            for(i=1:numel(obj.elseActions))
                [thisTf, theseVars] = obj.elseActions(i).hasActiveOptimVar();

                tf = tf || thisTf;
                vars = horzcat(vars, theseVars(:)'); %#ok<AGROW>
            end
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)      
            arguments
                action(1,1) ConditionalAction
                lv(1,1) LaunchVehicle
            end

            output = AppDesignerGUIOutput({false});
            lvd_EditConditionalActionGUI_App(action, lv.lvdData, output);
            addActionTf = output.output{1};
        end
    end
end