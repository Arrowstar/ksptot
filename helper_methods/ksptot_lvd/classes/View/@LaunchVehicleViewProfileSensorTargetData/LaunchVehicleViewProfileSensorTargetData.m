classdef LaunchVehicleViewProfileSensorTargetData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileSensorTargetData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        target AbstractSensorTarget
        
        markerPlot = matlab.graphics.GraphicsPlaceholder.empty(1,0)
        viewFrame AbstractReferenceFrame
    end
    
    methods
        function obj = LaunchVehicleViewProfileSensorTargetData(target, viewFrame)
            obj.target = target;
            obj.viewFrame = viewFrame;
        end
        
        function plotTargetResults(obj, results, hAx)
            result = results(results.target == obj.target);
            [bool, rVects] = result.getTargetResultsInFrame(obj.viewFrame);
            
            if(isempty(obj.markerPlot))
                shape = obj.target.getMarkerShape().shape;
                foundMarkerFaceColor = obj.target.getFoundMarkerFaceColor().color;
                foundMarkerEdgeolor = obj.target.getFoundMarkerEdgeColor().color;
                notFoundMarkerFaceColor = obj.target.getNotFoundMarkerFaceColor().color;
                notFoundMarkerEdgeolor = obj.target.getNotFoundMarkerEdgeColor().color;
                markerSize = obj.target.getMarkerSize();
                
                hold(hAx,'on'); 
                if(any(bool))
                    obj.markerPlot(1) = plot3(hAx, rVects(bool,1), rVects(bool,2), rVects(bool,3), 'LineStyle','none', 'Marker',shape, 'MarkerFaceColor',foundMarkerFaceColor, 'MarkerEdgeColor',foundMarkerEdgeolor, 'MarkerSize',markerSize);
                else
                    obj.markerPlot(1) = plot3(hAx, NaN, NaN, NaN, 'LineStyle','none', 'Marker',shape, 'MarkerFaceColor',foundMarkerFaceColor, 'MarkerEdgeColor',foundMarkerEdgeolor, 'MarkerSize',markerSize);
                end
                
                if(any(~bool))
                    obj.markerPlot(2) = plot3(hAx, rVects(~bool,1), rVects(~bool,2), rVects(~bool,3), 'LineStyle','none', 'Marker',shape, 'MarkerFaceColor',notFoundMarkerFaceColor, 'MarkerEdgeColor',notFoundMarkerEdgeolor, 'MarkerSize',markerSize);
                else
                    obj.markerPlot(2) = plot3(hAx, NaN, NaN, NaN, 'LineStyle','none', 'Marker',shape, 'MarkerFaceColor',notFoundMarkerFaceColor, 'MarkerEdgeColor',notFoundMarkerEdgeolor, 'MarkerSize',markerSize);
                end
                
                hold(hAx,'off');
            else
                obj.markerPlot(1).XData = rVects(bool,1);
                obj.markerPlot(1).YData = rVects(bool,2);
                obj.markerPlot(1).ZData = rVects(bool,3);
                
                obj.markerPlot(2).XData = rVects(~bool,1);
                obj.markerPlot(2).YData = rVects(~bool,2);
                obj.markerPlot(2).ZData = rVects(~bool,3);
            end
        end
    end
end