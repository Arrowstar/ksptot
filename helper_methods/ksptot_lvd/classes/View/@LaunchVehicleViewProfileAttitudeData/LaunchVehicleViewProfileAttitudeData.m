classdef LaunchVehicleViewProfileAttitudeData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileAttitudeData Summary of this class goes here
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
        
%         scale(1,1) double = 100;
%         markerPlot(1,:) cell = {}
    end
    
    methods    
        function obj = LaunchVehicleViewProfileAttitudeData()
            
        end
        
        function addData(obj, times, rotMatsBodyToView)            
            obj.timesArr(end+1) = {times};
            
            if(length(times) >= 3)
                method = 'pchip';
            else
                method = 'linear';
            end
            
            obj.dcm11Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(1,1,:),1,length(times)), method, 'linear');
            obj.dcm21Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(2,1,:),1,length(times)), method, 'linear');
            obj.dcm31Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(3,1,:),1,length(times)), method, 'linear');
            
            obj.dcm12Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(1,2,:),1,length(times)), method, 'linear');
            obj.dcm22Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(2,2,:),1,length(times)), method, 'linear');
            obj.dcm32Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(3,2,:),1,length(times)), method, 'linear');
            
            obj.dcm13Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(1,3,:),1,length(times)), method, 'linear');
            obj.dcm23Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(2,3,:),1,length(times)), method, 'linear');
            obj.dcm33Interps{end+1} = griddedInterpolant(times, reshape(rotMatsBodyToView(3,3,:),1,length(times)), method, 'linear');
        end
    end
    
    methods
        function dcm = getDCMatTime(obj, time)
            dcm = NaN(0,0,0);
            for(i=1:length(obj.timesArr))
                times = obj.timesArr{i};
                
                if(time >= min(floor(times)) && time <= max(ceil(times)))                                                           
                    dcm(:,:,size(dcm,3)+1) = [obj.dcm11Interps{i}(time), obj.dcm12Interps{i}(time), obj.dcm13Interps{i}(time);
                                              obj.dcm21Interps{i}(time), obj.dcm22Interps{i}(time), obj.dcm23Interps{i}(time);
                                              obj.dcm31Interps{i}(time), obj.dcm32Interps{i}(time), obj.dcm33Interps{i}(time)]; %#ok<AGROW>
                end
            end
        end
    end
end