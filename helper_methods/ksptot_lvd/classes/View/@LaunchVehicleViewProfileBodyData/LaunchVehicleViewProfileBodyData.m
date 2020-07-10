classdef LaunchVehicleViewProfileBodyData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileBodyData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo KSPTOT_BodyInfo
        
        timesArr(1,:) cell = {};
        xInterps(1,:) cell = {};
        yInterps(1,:) cell = {};
        zInterps(1,:) cell = {};
        
        plotStyle(1,1) ViewProfileBodyPlottingStyle = ViewProfileBodyPlottingStyle.Dot;
        markerPlot = matlab.graphics.GraphicsPlaceholder.empty(1,0)
        showSoI(1,1) logical = false;
    end
    
    methods
        function obj = LaunchVehicleViewProfileBodyData(bodyInfo, plotStyle, showSoI)
            obj.bodyInfo = bodyInfo;
            obj.plotStyle = plotStyle;
            obj.showSoI = showSoI;
        end
        
        function addData(obj, times, rVects)
            obj.timesArr(end+1) = {times};
            
            obj.xInterps{end+1} = griddedInterpolant(times, rVects(1,:), 'spline', 'linear');
            obj.yInterps{end+1} = griddedInterpolant(times, rVects(2,:), 'spline', 'linear');
            obj.zInterps{end+1} = griddedInterpolant(times, rVects(3,:), 'spline', 'linear');
        end
        
        function plotBodyMarkerAtTime(obj, time, hAx)           
            for(i=1:length(obj.timesArr))
                times = obj.timesArr{i};
                
                if(time >= min(floor(times)) && time <= max(ceil(times)))
                    bColorRGB = obj.bodyInfo.getBodyRGB();
                    
                    xInterp = obj.xInterps{i};
                    x = xInterp(time);
                    
                    yInterp = obj.yInterps{i};
                    y = yInterp(time);
                    
                    zInterp = obj.zInterps{i};
                    z = zInterp(time);
                    
                    if(obj.plotStyle == ViewProfileBodyPlottingStyle.Dot)
                        if(not(isempty(obj.markerPlot)) && isvalid(obj.markerPlot) && isa(obj.markerPlot, 'matlab.graphics.primitive.Transform'))
                            M = makehgtform('translate',[x,y,z]);
                            set(obj.markerPlot,'Matrix',M);
                            
                        else
                            hold(hAx,'on');   
                            obj.markerPlot = hgtransform('Parent', hAx);
                            hBM = plot3(hAx, 0,0,0, 'o', 'MarkerEdgeColor','k', 'MarkerFaceColor',bColorRGB);  
                            set(hBM,'Parent',obj.markerPlot);    
                            
                            obj.createSoIRadii(hAx);
                            
                            M = makehgtform('translate',[x,y,z]);
                            set(obj.markerPlot,'Matrix',M);
                            
                            hold(hAx,'off');
                        end
                    elseif(obj.plotStyle == ViewProfileBodyPlottingStyle.MeshSphere)
                        if(not(isempty(obj.markerPlot)) && isvalid(obj.markerPlot) && isa(obj.markerPlot, 'matlab.graphics.primitive.Transform'))
                            M = makehgtform('translate',[x,y,z]);
                            set(obj.markerPlot,'Matrix',M);
                            
                        else
                            hold(hAx,'on');
                            
                            dRad = obj.bodyInfo.radius;
                            [X,Y,Z] = sphere(30);
                            CData = getCDataForSphereWithColormap(Z, obj.bodyInfo.bodycolor);

                            obj.markerPlot = hgtransform('Parent', hAx);
                            hS = surf(hAx, dRad*X, dRad*Y, dRad*Z, 'CData',CData, 'EdgeAlpha',0.20);
                            set(hS,'Parent',obj.markerPlot);
                            
                            obj.createSoIRadii(hAx);
                            
                            M = makehgtform('translate',[x,y,z]);
                            set(obj.markerPlot,'Matrix',M);
                            
                            hold(hAx,'off');
                        end
                    else
                        error('Unknown body plotting style: %s', obj.plotStyle.name);
                    end
                    
                    break; %no need to plot more, if we hit the body at a certain time, then it'll only be at that position in time
                end
            end
        end
        
        function createSoIRadii(obj, hAx)
            if(obj.showSoI)     
                r = getSOIRadius(obj.bodyInfo, obj.bodyInfo.getParBodyInfo(obj.bodyInfo.celBodyData));

                xSoI = r*sin(0:0.01:2*pi);
                ySoI = r*cos(0:0.01:2*pi);
                zSoI = zeros(size(xSoI));

                hSoI = plot3(hAx, xSoI, ySoI, zSoI, 'k--','LineWidth',0.5);
                set(hSoI,'Parent',obj.markerPlot);

                hSoI = plot3(hAx, ySoI, zSoI, xSoI, 'k--','LineWidth',0.5);
                set(hSoI,'Parent',obj.markerPlot);

                hSoI = plot3(hAx, zSoI, xSoI, ySoI, 'k--','LineWidth',0.5);
                set(hSoI,'Parent',obj.markerPlot);
            end    
        end
    end
end

