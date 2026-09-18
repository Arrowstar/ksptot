classdef LvdViewOverlaySettings < matlab.mixin.SetGet
    %LvdViewOverlaySettings The data overlay drawn on the LVD 3-D view (and
    %so into exported video and images): header lines (epoch, UT, mission
    %elapsed time, current event), a list of Graphical Analysis quantities,
    %and where/how the block is drawn.  Saved on the view profile.

    properties
        enabled(1,1) logical = false;

        %content
        title(1,:) char = '';
        showEpoch(1,1) logical = true;
        showUT(1,1) logical = false;
        showMet(1,1) logical = true;
        showEventName(1,1) logical = true;
        items(1,:) LvdViewOverlayItem = LvdViewOverlayItem.empty(1,0);

        %placement
        corner(1,1) string {mustBeMember(corner, ["Top Left", "Top Right", "Bottom Left", "Bottom Right"])} = "Top Left";
        marginFrac(1,1) double {mustBeInRange(marginFrac, 0, 0.45)} = 0.02;

        %style
        fontName(1,:) char = 'Helvetica';
        fontSize(1,1) double {mustBeInRange(fontSize, 4, 72)} = 12;
        fontWeight(1,1) string {mustBeMember(fontWeight, ["normal", "bold"])} = "normal";
        fontColor(1,3) double = [1 1 1];
        showBackground(1,1) logical = true;
        backgroundColor(1,3) double = [0 0 0];   %MATLAB text backgrounds are opaque (no alpha)
    end

    methods
        function obj = LvdViewOverlaySettings()

        end

        %% ------------------------------------------------------- items
        function item = addItem(obj, item)
            arguments
                obj(1,1) LvdViewOverlaySettings
                item(1,1) LvdViewOverlayItem
            end
            obj.items(end+1) = item;
        end

        function item = addQuantity(obj, taskStr, frame)
            %addQuantity Adds a Graphical Analysis task by name and frame.
            arguments
                obj(1,1) LvdViewOverlaySettings
                taskStr(1,:) char
                frame(1,1) AbstractReferenceFrame
            end
            item = LvdViewOverlayItem(GraphicalAnalysisTask(taskStr, frame));
            obj.addItem(item);
        end

        function removeItem(obj, itemOrInd)
            if(isa(itemOrInd, 'LvdViewOverlayItem'))
                obj.items(obj.items == itemOrInd) = [];
            else
                ind = round(itemOrInd);
                if(ind >= 1 && ind <= numel(obj.items))
                    obj.items(ind) = [];
                end
            end
        end

        function moveItemUp(obj, ind)
            if(ind > 1 && ind <= numel(obj.items))
                obj.items([ind-1, ind]) = obj.items([ind, ind-1]);
            end
        end

        function moveItemDown(obj, ind)
            if(ind >= 1 && ind < numel(obj.items))
                obj.items([ind, ind+1]) = obj.items([ind+1, ind]);
            end
        end

        function n = getNumItems(obj)
            n = numel(obj.items);
        end

        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            for(i=1:numel(obj.items)) %#ok<*NO4LP>
                if(obj.items(i).usesGeometricRefFrame(refFrame))
                    tf = true;
                    return;
                end
            end
        end

        function removeItemsUsingFrame(obj, refFrame)
            keep = true(1, numel(obj.items));
            for(i=1:numel(obj.items))
                keep(i) = not(obj.items(i).usesGeometricRefFrame(refFrame));
            end
            obj.items = obj.items(keep);
        end

        function tf = hasContent(obj)
            tf = not(isempty(strtrim(obj.title))) || obj.showEpoch || obj.showUT || obj.showMet || obj.showEventName || not(isempty(obj.items));
        end

        %% --------------------------------------------------- placement
        function [x, y, hAlign, vAlign] = getAnchor(obj)
            %getAnchor Normalized axes position and alignment of the block.
            m = obj.marginFrac;
            switch(obj.corner)
                case "Top Left"
                    x = m;     y = 1 - m; hAlign = 'left';  vAlign = 'top';
                case "Top Right"
                    x = 1 - m; y = 1 - m; hAlign = 'right'; vAlign = 'top';
                case "Bottom Left"
                    x = m;     y = m;     hAlign = 'left';  vAlign = 'bottom';
                otherwise %Bottom Right
                    x = 1 - m; y = m;     hAlign = 'right'; vAlign = 'bottom';
            end
        end

        function c = getBackgroundColorSpec(obj)
            %getBackgroundColorSpec RGB for the text background, or 'none'.
            if(obj.showBackground)
                c = obj.backgroundColor;
            else
                c = 'none';
            end
        end

        function newObj = copy(obj)
            newObj = LvdViewOverlaySettings();
            props = properties(obj);
            for(i=1:numel(props))
                if(strcmp(props{i}, 'items'))
                    continue;
                end
                newObj.(props{i}) = obj.(props{i});
            end
            for(i=1:numel(obj.items))
                newObj.items(end+1) = obj.items(i).copy();
            end
        end
    end

    methods(Static)
        function corners = getCorners()
            corners = ["Top Left", "Top Right", "Bottom Left", "Bottom Right"];
        end

        function names = getFontNames()
            names = {'Helvetica', 'Arial', 'Courier New', 'Consolas', 'Times New Roman'};
        end

        function obj = loadobj(obj)
            if(isstruct(obj))
                s = obj;
                obj = LvdViewOverlaySettings();
                props = properties(obj);
                for(i=1:numel(props))
                    if(isfield(s, props{i}))
                        try
                            obj.(props{i}) = s.(props{i});
                        catch
                        end
                    end
                end
            end
        end
    end
end
