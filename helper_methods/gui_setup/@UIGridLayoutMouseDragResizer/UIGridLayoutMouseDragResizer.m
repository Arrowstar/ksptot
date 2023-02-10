classdef UIGridLayoutMouseDragResizer < matlab.mixin.SetGet
    %UIGridLayoutMouseDragResizer Summary of this class goes here
    %   Detailed explanation goes here

    properties (Access = private)
        uiFigure matlab.ui.Figure
        gridLayout matlab.ui.container.GridLayout

        rowData(:,2) double
        colData(:,2) double
        rowSpaceData(:,2) double
        colSpaceData(:,2) double
        sumVarRowHeights(1,1) double
        sumVarColWidths(1,1) double

        movingRow(1,1) double = NaN
        movingCol(1,1) double = NaN
        
        moveStartPoint(2,1) double = NaN(2,1);
        moveStartRowHeights(1,:) cell = {};
        moveStartColWidths(1,:) cell = {};
    end

    methods
        function obj = UIGridLayoutMouseDragResizer(uiFigure, gridLayout)
            arguments
                uiFigure(1,1) matlab.ui.Figure
                gridLayout(1,1) matlab.ui.container.GridLayout
            end

            obj.uiFigure = uiFigure;
            obj.gridLayout = gridLayout;
        end

        function windowButtonMotionCallback(obj)
            [obj.rowData, obj.colData, obj.rowSpaceData, obj.colSpaceData, obj.sumVarRowHeights, obj.sumVarColWidths] = obj.computeRowColSizeInfo();

            cp = obj.uiFigure.CurrentPoint;
            if(isnan(obj.movingRow) && isnan(obj.movingCol)) %not moving rows or columns
                [isInRow, isInCol] = obj.isCursorinRowCol();

                if(isInRow && isInCol)
                    obj.uiFigure.Pointer = "cross";
                elseif(isInCol)
                    obj.uiFigure.Pointer = "left";
                elseif(isInRow)
                    obj.uiFigure.Pointer = "top";
                else
                    obj.uiFigure.Pointer = "arrow";
                end

            elseif(not(isnan(obj.movingRow)) && not(isnan(obj.movingCol)))
                obj.adjustRow(cp);
                obj.adjustColumn(cp);

            elseif(not(isnan(obj.movingRow))) %moving row size
                obj.adjustRow(cp);

            elseif(not(isnan(obj.movingCol))) %moving column size
                obj.adjustColumn(cp);
            end
        end

        function windowButtonDownCallback(obj)
            [isInRow, isInCol, row, col] = obj.isCursorinRowCol();

            obj.moveStartPoint = obj.uiFigure.CurrentPoint;
            if(isInCol && isInRow)
                obj.movingRow = row;
                obj.movingCol = col;

                obj.moveStartRowHeights = obj.gridLayout.RowHeight;
                obj.moveStartColWidths = obj.gridLayout.ColumnWidth;
            elseif(isInCol)
                obj.movingRow = NaN;
                obj.movingCol = col;

                obj.moveStartRowHeights = obj.gridLayout.RowHeight;
                obj.moveStartColWidths = obj.gridLayout.ColumnWidth;
            elseif(isInRow)
                obj.movingRow = row;
                obj.movingCol = NaN;

                obj.moveStartRowHeights = obj.gridLayout.RowHeight;
                obj.moveStartColWidths = obj.gridLayout.ColumnWidth;
            else
                obj.movingRow = NaN;
                obj.movingCol = NaN;
                obj.moveStartPoint = NaN(1,2);
                obj.moveStartRowHeights = {};
                obj.moveStartColWidths = {};
            end
        end

        function windowButtonUpCallback(obj)
            obj.movingRow = NaN;
            obj.movingCol = NaN;
            obj.moveStartPoint = NaN(1,2);
        end
    end

    methods(Access=private)
        function adjustRow(obj, cp)
            arguments
                obj(1,1) UIGridLayoutMouseDragResizer
                cp(2,1) double
            end

            gridPosition = obj.gridLayout.Position;
            gridHeight = gridPosition(4);
            gridPadding = obj.gridLayout.Padding;
            rowSpacing = obj.gridLayout.RowSpacing;

            thisMovingRow = obj.movingRow;
    
            sizeDelta = obj.moveStartPoint(2) - cp(2);
            rowHeights = obj.moveStartRowHeights;
    
            totalDimGridPad = gridPadding(2) + gridPadding(4);
            obj.gridLayout.RowHeight = obj.adjustGridDimensionSizes(rowHeights, thisMovingRow, sizeDelta, gridHeight, rowSpacing, totalDimGridPad);
        end

        function adjustColumn(obj, cp)
            arguments
                obj(1,1) UIGridLayoutMouseDragResizer
                cp(2,1) double
            end

            gridPosition = obj.gridLayout.Position;
            gridWidth = gridPosition(3);
            gridPadding = obj.gridLayout.Padding;
            colSpacing = obj.gridLayout.ColumnSpacing;

            thisMovingCol = obj.movingCol;

            sizeDelta = cp(1) - obj.moveStartPoint(1);
            colWidths = obj.moveStartColWidths;
                            
            totalDimGridPad = gridPadding(1) + gridPadding(3);
            obj.gridLayout.ColumnWidth = obj.adjustGridDimensionSizes(colWidths, thisMovingCol, sizeDelta, gridWidth, colSpacing, totalDimGridPad);
        end

        function [rowData, colData, rowSpaceData, colSpaceData, sumVarRowHeights, sumVarColWidths] = computeRowColSizeInfo(obj)
            gridPosition = obj.gridLayout.Position;
            gridWidth = gridPosition(3);
            gridHeight = gridPosition(4);

            gridPadding = obj.gridLayout.Padding;
            
            %Do columns
            colWidth = obj.gridLayout.ColumnWidth;
            isVarColWidth = cellfun(@ischar, colWidth);
            colSpacing = obj.gridLayout.ColumnSpacing;
            
            varColWidths = colWidth(isVarColWidth);
            sumVarColWidths = 0;
            for(i=1:numel(varColWidths)) %#ok<NO4LP>
                varColWidth = string(varColWidths{i});
                varColWidthDouble = str2double(varColWidth.erase('x'));
                sumVarColWidths = sumVarColWidths + varColWidthDouble;
            end

            totalColEmptySpace = gridPadding(1) + (numel(colWidth)-1)*colSpacing + gridPadding(3);
            if(all(not(isVarColWidth)))
                totalColGridSpace = sum([colWidth{:}]);
                excessGridColSpace = gridWidth - (totalColGridSpace + totalColEmptySpace);
            else
                excessGridColSpace = 0;
            end
            
            totalDefinedPixelColWidths = sum([colWidth{not(isVarColWidth)}]);
            totalVariableColWidthRemaining = gridWidth - totalColEmptySpace - totalDefinedPixelColWidths - excessGridColSpace;

            %Do rows
            rowHeight = obj.gridLayout.RowHeight;
            rowHeight = rowHeight(end:-1:1);
            isVarRowHeight = cellfun(@ischar, rowHeight);
            rowSpacing = obj.gridLayout.RowSpacing;

            varRowHeights = rowHeight(isVarRowHeight);
            sumVarRowHeights = 0;
            for(i=1:numel(varRowHeights)) %#ok<NO4LP>
                varRowHeight = string(varRowHeights{i});
                varRowHeightDouble = str2double(varRowHeight.erase('x'));
                sumVarRowHeights = sumVarRowHeights + varRowHeightDouble;
            end
            
            totalRowEmptySpace = gridPadding(2) + (numel(rowHeight)-1)*rowSpacing + gridPadding(4);
            if(all(not(isVarRowHeight)))
                totalRowGridSpace = sum([rowHeight{:}]);
                excessGridRowSpace = gridHeight - (totalRowGridSpace + totalRowEmptySpace);
            else
                excessGridRowSpace = 0;
            end

            totalDefinedPixelRowHeights = sum([rowHeight{not(isVarRowHeight)}]);
            totalVariableRowHeightRemaining = gridHeight - totalRowEmptySpace - totalDefinedPixelRowHeights - excessGridRowSpace;

            %Determine how big each row and column actually is
            for(i=1:numel(rowHeight)) %#ok<NO4LP>
                if(isVarRowHeight(i))
                    varRowHeight = string(rowHeight{i});
                    varRowHeight = str2double(varRowHeight.erase('x'));
        
                    fractionRowHeight = varRowHeight/sumVarRowHeights;

                    parsedRowHeight = round(fractionRowHeight * totalVariableRowHeightRemaining);
                else
                    parsedRowHeight = rowHeight{i};
                end

                if(i == 1)
                    lastEnd = gridPadding(2) + excessGridRowSpace;
                else
                    lastEnd = rowEnd(i-1) + rowSpacing;
                end

                rowStart(i) = lastEnd; %#ok<AGROW>
                rowEnd(i) = rowStart(i) + parsedRowHeight; %#ok<AGROW>
            end
            rowData = [rowStart; rowEnd]';
            rowSpaceData = [rowEnd(1:end-1); rowStart(2:end)]';

            for(i=1:numel(colWidth)) %#ok<NO4LP>
                if(isVarColWidth(i))
                    varColWidth = string(colWidth{i});
                    varColWidth = str2double(varColWidth.erase('x'));
        
                    fractionColWidth = varColWidth/sumVarColWidths;

                    parsedColWidth = round(fractionColWidth * totalVariableColWidthRemaining);
                else
                    parsedColWidth = colWidth{i};
                end

                if(i == 1)
                    lastEnd = gridPadding(1);
                else
                    lastEnd = colEnd(i-1) + colSpacing;
                end

                colStart(i) = lastEnd; %#ok<AGROW>
                colEnd(i) = colStart(i) + parsedColWidth; %#ok<AGROW>
            end
            colData = [colStart; colEnd]';
            colSpaceData = [colEnd(1:end-1); colStart(2:end)]';
        end
        
        function [isInRow, isInCol, row, col] = isCursorinRowCol(obj)
            cp = obj.uiFigure.CurrentPoint;
            
            boolCol = cp(1) >= obj.colSpaceData(:,1) & cp(1) <= obj.colSpaceData(:,2);
            boolRow = cp(2) >= obj.rowSpaceData(:,1) & cp(2) <= obj.rowSpaceData(:,2);
            boolRow = boolRow(end:-1:1);

            isInRow = false;
            row = [];
            isInCol = false;
            col = [];
            
            if(any(boolCol))
                isInCol = true;
                col = find(boolCol);
            end

            if(any(boolRow))
                isInRow = true;
                row = find(boolRow);
            end
        end

        function dimSizes = adjustGridDimensionSizes(~, dimSizes, thisMovingDim, sizeDelta, gridDimSize, gridDimSpacing, totalDimGridPad)
            tf = cellfun(@ischar, dimSizes);
            tfInds = find(tf);
            proVals = cellfun(@(x) str2double(erase(string(x),'x')), dimSizes(tf));
            initialProValsNorm = proVals./sum(proVals);

            initialTotalVarSpace = round(gridDimSize - totalDimGridPad - (numel(dimSizes)-1)*gridDimSpacing - sum([dimSizes{not(tf)}]));
            initialAbsValsNorm = round(initialProValsNorm * initialTotalVarSpace);

            finalAbsValsNorm = initialAbsValsNorm;
            if(isnumeric(dimSizes{thisMovingDim}) && isnumeric(dimSizes{thisMovingDim+1}))
                if(sizeDelta < 0 && dimSizes{thisMovingDim} + sizeDelta <= 1)
                    sizeDelta = -(dimSizes{thisMovingDim}-1);
                elseif(sizeDelta > 0 && dimSizes{thisMovingDim+1} - sizeDelta <= 1)
                    sizeDelta = dimSizes{thisMovingDim+1}-1;
                end

                dimSizes{thisMovingDim} = dimSizes{thisMovingDim} + sizeDelta;
                dimSizes{thisMovingDim+1} = dimSizes{thisMovingDim+1} - sizeDelta;

            elseif(isnumeric(dimSizes{thisMovingDim}) && ischar(dimSizes{thisMovingDim+1}))
                if(sizeDelta < 0 && dimSizes{thisMovingDim} + sizeDelta <= 1)
                    sizeDelta = -(dimSizes{thisMovingDim}-1);
                elseif(sizeDelta > 0 && initialAbsValsNorm(thisMovingDim+1 == tfInds) - sizeDelta <= 1)
                    sizeDelta = initialAbsValsNorm(thisMovingDim+1 == tfInds)-1;
                end

                dimSizes{thisMovingDim} = dimSizes{thisMovingDim} + sizeDelta;
                finalAbsValsNorm(thisMovingDim+1 == tfInds) = initialAbsValsNorm(thisMovingDim+1 == tfInds) - sizeDelta;

            elseif(ischar(dimSizes{thisMovingDim}) && isnumeric(dimSizes{thisMovingDim+1}))
                if(sizeDelta < 0 && initialAbsValsNorm(thisMovingDim == tfInds) + sizeDelta <= 1)
                    sizeDelta = -(initialAbsValsNorm(thisMovingDim == tfInds)-1);
                elseif(sizeDelta > 0 && dimSizes{thisMovingDim+1} - sizeDelta <= 1)
                    sizeDelta = dimSizes{thisMovingDim+1}-1;
                end

                finalAbsValsNorm(thisMovingDim == tfInds) = initialAbsValsNorm(thisMovingDim == tfInds) + sizeDelta;
                dimSizes{thisMovingDim+1} = dimSizes{thisMovingDim+1} - sizeDelta;

            elseif(ischar(dimSizes{thisMovingDim}) && ischar(dimSizes{thisMovingDim+1}))
                if(sizeDelta < 0 && initialAbsValsNorm(thisMovingDim == tfInds) + sizeDelta <= 1)
                    sizeDelta = -(initialAbsValsNorm(thisMovingDim == tfInds)-1);
                elseif(sizeDelta > 0 && initialAbsValsNorm(thisMovingDim+1 == tfInds) - sizeDelta <= 1)
                    sizeDelta = initialAbsValsNorm(thisMovingDim+1 == tfInds)-1;
                end

                finalAbsValsNorm(thisMovingDim == tfInds) = initialAbsValsNorm(thisMovingDim == tfInds) + sizeDelta;
                finalAbsValsNorm(thisMovingDim+1 == tfInds) = initialAbsValsNorm(thisMovingDim+1 == tfInds) - sizeDelta;
            end
            
            finalTotalVarSpace = sum(finalAbsValsNorm);

            finalProValsNorm = finalAbsValsNorm / finalTotalVarSpace;
            finalProValsStr = arrayfun(@(x) sprintf("%0.16fx",x), finalProValsNorm);
            finalProValsChar = convertStringsToChars(finalProValsStr);

            if(ischar(finalProValsChar))
                finalProValsChar = {finalProValsChar};
            end

            dimSizes(tf) = finalProValsChar;
        end
    end
end