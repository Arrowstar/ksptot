classdef LogicalAndActionConditional < AbstractActionConditional
    %LogicalAndActionConditional Summary of this class goes here
    %   Detailed explanation goes here

    properties
        conditionals(1,:) AbstractActionConditional

        enum(1,1) ConditionalTypeEnum = ConditionalTypeEnum.LogicalAnd;
    end

    methods
        function obj = LogicalAndActionConditional(conditionals)
            obj.conditionals = conditionals;
        end

        function tf = evaluateConditional(obj, stateLogEntry)
            arguments(Input)
                obj(1,1) LogicalAndActionConditional
                stateLogEntry(1,1) LaunchVehicleStateLogEntry
            end

            arguments(Output)
                tf(1,1) logical
            end

            if(length(obj.conditionals) >= 1)
                tf = obj.conditionals(1).evaluateConditional(stateLogEntry);
                for(i=2:length(obj.conditionals))
                    tf = tf || obj.conditionals(i).evaluateConditional(stateLogEntry);
    
                    if(tf == false)
                        break;
                    end
                end
                
            else
                tf = true;
            end
        end

        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('AND Conditional (%u)', numel(obj.conditionals));
        end

        function addConditional(obj, newCond)
            arguments
                obj(1,1) LogicalAndActionConditional
                newCond(1,1) AbstractActionConditional
            end

            obj.conditionals(end+1) = newCond;
        end

        function removeConditional(obj, cond)
            arguments
                obj(1,1) LogicalAndActionConditional
                cond(1,1) AbstractActionConditional
            end

            obj.conditionals(obj.conditionals == cond) = [];
        end

        function substituteConditional(obj, oldCond, newCond)
            arguments
                obj(1,1) LogicalAndActionConditional
                oldCond(1,1) AbstractActionConditional
                newCond(1,1) AbstractActionConditional
            end

            ind = find(obj.conditionals == oldCond);

            preConditionals = obj.conditionals(1:ind-1);
            postConditionals = obj.conditionals(ind+1:end);

            obj.conditionals = [preConditionals, newCond, postConditionals];
        end

        function condStr = getConditionalString(obj)
            condStr = "";
            for(i=1:numel(obj.conditionals))
                condStr(i) = obj.conditionals(i).getConditionalString();
            end

            if(not(isempty(condStr)))
                condStr = strjoin(condStr, ' AND ');
            else
                condStr = 'TRUE';
            end
        end

        function nodes = getTreeNodes(obj, parent)
            nodes(1) = uitreenode(parent, 'Text','AND', 'NodeData',obj, 'Icon','ampersand.png');
            for(i=1:numel(obj.conditionals))
                newNodes = obj.conditionals(i).getTreeNodes(nodes(1)); 
                nodes = horzcat(nodes, newNodes(:)'); %#ok<AGROW>
            end
        end
    end
end