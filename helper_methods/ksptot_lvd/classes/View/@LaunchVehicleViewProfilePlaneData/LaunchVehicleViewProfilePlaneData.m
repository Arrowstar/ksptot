classdef LaunchVehicleViewProfilePlaneData < matlab.mixin.SetGet
    %LaunchVehicleViewProfilePlaneData Summary of this class goes here
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
        plane AbstractGeometricPlane
        viewFrame AbstractReferenceFrame
    end
    
    methods
        function obj = LaunchVehicleViewProfilePlaneData(plane, viewFrame)
            obj.plane = plane;
            obj.viewFrame = viewFrame;
        end
        
        function addData(obj, times, rVects, vVects)
            obj.timesArr{end+1} = times;
            
            if(length(times) >= 3)
                method = 'spline';
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
        
        function plotPlaneAtTime(obj, time, hAx)
            [origin, normvect] = obj.getPlaneAtTime(time);
            
            if(isempty(obj.markerPlot))
                hold(hAx,'on'); 
                for(i=1:size(normvect,2))
                    xform = hgtransform(hAx);
                    obj.markerPlot(i) = xform;
                    
                    edgeLength = obj.plane.edgeLength;
                    p1 = [edgeLength/2,   edgeLength/2, 0];
                    p2 = [edgeLength/2,  -edgeLength/2, 0];
                    p3 = [-edgeLength/2, -edgeLength/2, 0];
                    p4 = [-edgeLength/2   edgeLength/2, 0];
                    
                    color = obj.plane.lineColor.color;
                    alpha = obj.plane.alpha;
                    linestyle = obj.plane.lineSpec.linespec;
                    patch('Faces',1:4,'Vertices',[p1;p2;p3;p4], 'Parent',xform, 'FaceColor',color, 'EdgeColor',color, 'FaceAlpha',alpha, 'LineStyle',linestyle);
                end
                hold(hAx,'off');
            end
            
            for(i=1:length(obj.markerPlot))
                a = [0;0;1];
                b = normvect(:,i);
                r = vrrotvec(a,b);
                t = origin(:,i);
                M = makehgtform('translate',t, 'axisrotate',r(1:3),r(4));
                obj.markerPlot(i).Matrix = M;
            end
        end
    end
    
    methods(Access=private)
        function [origin, normvect] = getPlaneAtTime(obj, time)
            origin = [];
            normvect = [];
            for(i=1:length(obj.timesArr))
                times = obj.timesArr{i};
                
                if(time >= min(floor(times)) && time <= max(ceil(times)))                    
                    xInterp = obj.xInterps{i};
                    x = xInterp(time);
                    
                    yInterp = obj.yInterps{i};
                    y = yInterp(time);
                    
                    zInterp = obj.zInterps{i};
                    z = zInterp(time);
                    
                    vxInterp = obj.vxInterps{i};
                    vx = vxInterp(time);
                    
                    vyInterp = obj.vyInterps{i};
                    vy = vyInterp(time);
                    
                    vzInterp = obj.vzInterps{i};
                    vz = vzInterp(time);
                    
                    vehElemSet = CartesianElementSet(time, [x;y;z], [vx;vy;vz], obj.viewFrame);
                    
                    normvect(:,end+1) = obj.plane.getPlaneNormVectAtTime(time, vehElemSet, obj.viewFrame); %#ok<AGROW>
                    
                    oCart = obj.plane.getPlaneOriginPtAtTime(time, vehElemSet, obj.viewFrame);
                    origin(:,end+1) = oCart.rVect; %#ok<AGROW>
                end
            end
        end
    end
end