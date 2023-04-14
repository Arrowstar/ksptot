classdef LogicalOrActionConditional < AbstractActionConditional
    %LogicalOrActionConditional Summary of this class goes here
    %   Detailed explanation goes here

    properties
        conditionals(1,:) AbstractActionConditional

        enum(1,1) ConditionalTypeEnum = ConditionalTypeEnum.LogicalOr;
    end

    methods
        function obj = LogicalOrActionConditional(conditionals)
            obj.conditionals = conditionals;
        end

        function tf = evaluateConditional(obj, stateLogEntry)
            arguments(Input)
                obj(1,1) LogicalOrActionConditional
                stateLogEntry(1,1) LaunchVehicleStateLogEntry
            end

            arguments(Output)
                tf(1,1) logical
            end

            if(length(obj.conditionals) >= 1)
                tf = obj.conditionals(1).evaluateConditional(stateLogEntry);
                for(i=2:length(obj.conditionals))
                    tf = tf || obj.conditionals(i).evaluateConditional(stateLogEntry);
    
                    if(tf == true)
                        break;
                    end
                end
                
            else
                tf = true;
            end
        end

        function addConditional(obj, newCond)
            arguments
                obj(1,1) LogicalOrActionConditional
                newCond(1,1) AbstractActionConditional
            end

            obj.conditionals(end+1) = newCond;
        end

        function removeConditional(obj, cond)
            arguments
                obj(1,1) LogicalOrActionConditional
                cond(1,1) AbstractActionConditional
            end

            obj.conditionals(obj.conditionals == cond) = [];
        end

        function substituteConditional(obj, oldCond, newCond)
            arguments
                obj(1,1) LogicalOrActionConditional
                oldCond(1,1) AbstractActionConditional
                newCond(1,1) AbstractActionConditional
            end
            
            ind = find(obj.conditionals == oldCond);
            
            preConditionals = obj.conditionals(1:ind-1);
            postConditionals = obj.conditionals(ind+1:end);

            obj.conditionals = [preConditionals, newCond, postConditionals];
        end

        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('OR Conditional (%u)', numel(obj.conditionals));
        end

        function condStr = getConditionalString(obj)
            condStr = "";
            for(i=1:numel(obj.conditionals))
                condStr(i) = obj.conditionals(i).getConditionalString();
            end

            if(not(isempty(condStr)))
                condStr = strjoin(condStr, ' OR ');
            else
                condStr = 'TRUE';
            end
        end

        function nodes = getTreeNodes(obj, parent)
            nodes(1) = uitreenode(parent, 'Text','OR', 'NodeData',obj);
            for(i=1:numel(obj.conditionals))
                newNodes = obj.conditionals(i).getTreeNodes(nodes(1)); 
                nodes = horzcat(nodes, newNodes(:)'); %#ok<AGROW>
            end
        end
    end
end