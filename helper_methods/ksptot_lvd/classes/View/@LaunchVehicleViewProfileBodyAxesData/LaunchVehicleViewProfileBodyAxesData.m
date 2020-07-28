classdef LaunchVehicleViewProfileBodyAxesData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileTrajectoryData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        timesArr(1,:) cell = {};
        xPosInterps(1,:) cell = {};
        yPosInterps(1,:) cell = {};
        zPosInterps(1,:) cell = {};
        
        dcm11Interps(1,:) cell = {};
        dcm21Interps(1,:) cell = {};
        dcm31Interps(1,:) cell = {};
        
        dcm12Interps(1,:) cell = {};
        dcm22Interps(1,:) cell = {};
        dcm32Interps(1,:) cell = {};
        
        dcm13Interps(1,:) cell = {};
        dcm23Interps(1,:) cell = {};
        dcm33Interps(1,:) cell = {};
        
        scale(1,1) double = 100;
        markerPlot(1,:) cell = {}
    end
    
    methods
        function obj = LaunchVehicleViewProfileBodyAxesData(scale)
            obj.scale = scale;
        end
        
        function addData(obj, times, rVects, rotMatsBodyToView)
            obj.timesArr(end+1) = {times};
            
            if(length(times) >= 3)
                method = 'spline';
            else
                method = 'linear';
            end
            
            obj.xPosInterps{end+1} = griddedInterpolant(times, rVects(1,:), method, 'linear');
            obj.yPosInterps{end+1} = griddedInterpolant(times, rVects(2,:), method, 'linear');
            obj.zPosInterps{end+1} = griddedInterpolant(times, rVects(3,:), method, 'linear');
            
            obj.dcm11Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(1,1,:),1,length(times)), method, 'linear');
            obj.dcm21Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(2,1,:),1,length(times)), method, 'linear');
            obj.dcm31Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(3,1,:),1,length(times)), method, 'linear');
            
            obj.dcm12Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(1,2,:),1,length(times)), method, 'linear');
            obj.dcm22Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(2,2,:),1,length(times)), method, 'linear');
            obj.dcm32Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(3,2,:),1,length(times)), method, 'linear');
            
            obj.dcm13Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(1,3,:),1,length(times)), method, 'linear');
            obj.dcm23Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(2,3,:),1,length(times)), method, 'linear');
            obj.dcm33Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(3,3,:),1,length(times)), method, 'linear');
            
            obj.markerPlot{end+1} = [];
        end
        
        function plotBodyAxesAtTime(obj, time, hAx)            
            for(i=1:length(obj.timesArr))
                times = obj.timesArr{i};
                
                if(time >= min(floor(times)) && time <= max(ceil(times)))                                        
                    pos = [obj.xPosInterps{i}(time); obj.yPosInterps{i}(time); obj.zPosInterps{i}(time)];
                    
                    dcm = [obj.dcm11Interps{i}(time), obj.dcm12Interps{i}(time), obj.dcm13Interps{i}(time);
                           obj.dcm21Interps{i}(time), obj.dcm22Interps{i}(time), obj.dcm23Interps{i}(time);
                           obj.dcm31Interps{i}(time), obj.dcm32Interps{i}(time), obj.dcm33Interps{i}(time)]';
                    
                    if(not(isempty(obj.markerPlot{i})) && isvalid(obj.markerPlot{i}) && isa(obj.markerPlot{i}, 'matlab.graphics.primitive.Transform'))
%                         q = dcm2quat(dcm);
%                         angle = 2 * acos(q(1));
%                         x = q(2) / sqrt(1-q(1)*q(1));
%                         y = q(3) / sqrt(1-q(1)*q(1));
%                         z = q(4) / sqrt(1-q(1)*q(1));
%                         
%                         M = makehgtform('translate',pos, 'axisrotate',[x,y,z],angle);

                        [r1, r2, r3] = dcm2angle(dcm, 'XYZ');
                        
                        M = makehgtform('translate',pos, 'xrotate',r1, 'yrotate',r2, 'zrotate',r3);
                        set(obj.markerPlot{i},'Matrix',M);
                        obj.markerPlot{i}.Visible = 'on';
                    else
                        hold(hAx,'on');
                        obj.markerPlot{i} = hgtransform('Parent', hAx);
                        
                        xAxis = quiver3(0,0,0,obj.scale,0,0, 'Color','r', 'LineWidth',2);
                        set(xAxis,'Parent',obj.markerPlot{i});
                        
                        yAxis = quiver3(0,0,0,0,obj.scale,0, 'Color','g', 'LineWidth',2);
                        set(yAxis,'Parent',obj.markerPlot{i});
                        
                        zAxis = quiver3(0,0,0,0,0,obj.scale, 'Color','b', 'LineWidth',2);
                        set(zAxis,'Parent',obj.markerPlot{i});
                        
%                         q = dcm2quat(dcm);
%                         angle = 2 * acos(q(1));
%                         x = q(2) / sqrt(1-q(1)*q(1));
%                         y = q(3) / sqrt(1-q(1)*q(1));
%                         z = q(4) / sqrt(1-q(1)*q(1));

%                         M = makehgtform('translate',pos, 'axisrotate',[x,y,z],angle);

                        [r1, r2, r3] = dcm2angle(dcm, 'XYZ');

                        M = makehgtform('translate',pos, 'xrotate',r1, 'yrotate',r2, 'zrotate',r3);
                        set(obj.markerPlot{i},'Matrix',M);
                        obj.markerPlot{i}.Visible = 'on';
                        
                        hold(hAx,'off');
                    end
                else
                    if(not(isempty(obj.markerPlot{i})) && isvalid(obj.markerPlot{i}) && isa(obj.markerPlot{i}, 'matlab.graphics.primitive.Transform'))
                        obj.markerPlot{i}.Visible = 'off';
                    end
                end
            end
        end
    end
end