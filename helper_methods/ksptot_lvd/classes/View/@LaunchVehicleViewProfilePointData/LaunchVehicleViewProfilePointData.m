classdef LaunchVehicleViewProfilePointData < matlab.mixin.SetGet
    %LaunchVehicleViewProfilePointData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %these are for vehicle trajectory data and not the point itself!
        timesArr(1,:) cell = {};
        xInterps(1,:) cell = {};
        yInterps(1,:) cell = {};
        zInterps(1,:) cell = {};
        vxInterps(1,:) cell = {};
        vyInterps(1,:) cell = {};
        vzInterps(1,:) cell = {};
        
        markerPlot = matlab.graphics.GraphicsPlaceholder.empty(1,0)
        trajLine = matlab.graphics.GraphicsPlaceholder.empty(1,0)
        point AbstractGeometricPoint
        viewFrame AbstractReferenceFrame
    end
    
    methods
        function obj = LaunchVehicleViewProfilePointData(point, viewFrame)
            obj.point = point;
            obj.viewFrame = viewFrame;
        end
        
        function addData(obj, times, rVects, vVects)
            obj.timesArr{end+1} = times;
            
            if(length(times) >= 3)
                method = 'pchip';
            else
                method = 'linear';
            end
            
            obj.xInterps{end+1} = griddedInterpolant(times, rVects(:,1), method, 'linear');
            obj.yInterps{end+1} = griddedInterpolant(times, rVects(:,2), method, 'linear');
            obj.zInterps{end+1} = griddedInterpolant(times, rVects(:,3), method, 'linear');
            obj.vxInterps{end+1} = griddedInterpolant(times, vVects(:,1), method, 'linear');
            obj.vyInterps{end+1} = griddedInterpolant(times, vVects(:,2), method, 'linear');
            obj.vzInterps{end+1} = griddedInterpolant(times, vVects(:,3), method, 'linear');
        end
        
        function plotPointAtTime(obj, time, hAx)   
            rVect = obj.getPositionAtTime(time);
            if(isempty(obj.markerPlot))
                hold(hAx,'on');
                if(obj.point.plotTrkLine)
                    rVectsToPlot = obj.getAllRVectsToPlot();
                    obj.trajLine = plot3(hAx, rVectsToPlot(1,:), rVectsToPlot(2,:), rVectsToPlot(3,:), 'Color',obj.point.trkLineColor.color, 'LineStyle',obj.point.trkLineSpec.linespec);
                end
                
                obj.markerPlot = plot3(hAx, rVect(1), rVect(2), rVect(3), 'MarkerFaceColor',obj.point.markerColor.color, 'Marker',obj.point.markerShape.shape, 'MarkerEdgeColor','k');
                hold(hAx,'off');
            else
                obj.markerPlot.XData = rVect(1);
                obj.markerPlot.YData = rVect(2);
                obj.markerPlot.ZData = rVect(3);
            end
        end
        
        function rVectsToPlot = getAllRVectsToPlot(obj)
            totalTimesArr = [];
            for(i=1:length(obj.timesArr))
                totalTimesArr = [totalTimesArr(:); obj.timesArr{i}(:)]; 
            end
            
            totalTimesArr = sort(totalTimesArr);
            
%             rVectsToPlot = NaN(3,length(totalTimesArr));
            rVectsToPlot = obj.getPositionAtTime(totalTimesArr);
        end
    end
    
    methods(Access=private)
        function rVect = getPositionAtTime(obj, time)
            vehElemSet = repmat(CartesianElementSet.getDefaultElements(), [1, length(time)]);
            for(i=1:length(obj.timesArr))
                times = obj.timesArr{i};
                
                bool = time >= min(floor(times)) & time <= max(ceil(times));
                if(any(bool))  
                    boolTimes = time(bool);
                    
                    xInterp = obj.xInterps{i};
                    x = xInterp(boolTimes);
                    
                    yInterp = obj.yInterps{i};
                    y = yInterp(boolTimes);
                    
                    zInterp = obj.zInterps{i};
                    z = zInterp(boolTimes);
                    
                    vxInterp = obj.vxInterps{i};
                    vx = vxInterp(time);
                    
                    vyInterp = obj.vyInterps{i};
                    vy = vyInterp(time);
                    
                    vzInterp = obj.vzInterps{i};
                    vz = vzInterp(time);
                    
                    rVect = [x(:)'; y(:)'; z(:)'];
                    vVect = [vx(:)'; vy(:)'; vz(:)'];
                    
                    subCartElems = CartesianElementSet(boolTimes, rVect, vVect, obj.viewFrame);
%                     subCartElems = repmat(CartesianElementSet.getDefaultElements(), [1, length(boolTimes)]);
%                     for(j=1:length(boolTimes))
%                         subCartElems(j) = CartesianElementSet(boolTimes(j), [x(j);y(j);z(j)], [0;0;0], obj.viewFrame);
%                     end

                    vehElemSet(bool) = subCartElems;
                end
            end
            
            elemSet = obj.point.getPositionAtTime(time, vehElemSet, obj.viewFrame);
            elemSet = convertToCartesianElementSet(elemSet);
            rVect = [elemSet.rVect]; 
        end
    end
end