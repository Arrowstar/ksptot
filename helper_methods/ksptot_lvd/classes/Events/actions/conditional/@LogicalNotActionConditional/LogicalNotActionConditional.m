classdef LogicalNotActionConditional < AbstractActionConditional
    %LogicalNotActionConditional Negates a single child conditional.
    %
    %   With no child the inner value is taken as TRUE (matching the empty
    %   AND/OR conditionals), so an empty NOT evaluates FALSE.

    properties
        conditional(1,:) AbstractActionConditional

        enum(1,1) ConditionalTypeEnum = ConditionalTypeEnum.LogicalNot;
    end

    methods
        function obj = LogicalNotActionConditional(conditional)
            arguments
                conditional(1,:) AbstractActionConditional = AbstractActionConditional.empty(1,0)
            end

            obj.conditional = conditional;
        end

        function tf = evaluateConditional(obj, stateLogEntry)
            arguments(Input)
                obj(1,1) LogicalNotActionConditional
                stateLogEntry(1,1) LaunchVehicleStateLogEntry
            end

            arguments(Output)
                tf(1,1) logical
            end

            if(isempty(obj.conditional))
                innerTf = true;
            else
                innerTf = obj.conditional(1).evaluateConditional(stateLogEntry);
            end

            tf = not(innerTf);
        end

        function tf = hasConditional(obj)
            tf = not(isempty(obj.conditional));
        end

        function addConditional(obj, newCond)
            %addConditional Sets the (single) child conditional.
            arguments
                obj(1,1) LogicalNotActionConditional
                newCond(1,1) AbstractActionConditional
            end

            obj.conditional = newCond;
        end

        function removeConditional(obj, cond)
            arguments
                obj(1,1) LogicalNotActionConditional
                cond(1,1) AbstractActionConditional
            end

            if(not(isempty(obj.conditional)) && obj.conditional(1) == cond)
                obj.conditional = AbstractActionConditional.empty(1,0);
            end
        end

        function substituteConditional(obj, oldCond, newCond)
            arguments
                obj(1,1) LogicalNotActionConditional
                oldCond(1,1) AbstractActionConditional
                newCond(1,1) AbstractActionConditional
            end

            if(not(isempty(obj.conditional)) && obj.conditional(1) == oldCond)
                obj.conditional = newCond;
            end
        end

        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('NOT Conditional');
        end

        function condStr = getConditionalString(obj)
            if(isempty(obj.conditional))
                innerStr = 'TRUE';
            else
                innerStr = char(obj.conditional(1).getConditionalString());
            end

            condStr = sprintf('NOT (%s)', innerStr);
        end

        function tf = usesEvent(obj, event)
            tf = not(isempty(obj.conditional)) && obj.conditional(1).usesEvent(event);
        end

        function nodes = getTreeNodes(obj, parent)
            nodes(1) = uitreenode(parent, 'Text','NOT', 'NodeData',obj, 'Icon','stop(1).png');

            if(not(isempty(obj.conditional)))
                newNodes = obj.conditional(1).getTreeNodes(nodes(1));
                nodes = horzcat(nodes, newNodes(:)');
            end
        end
    end
end
