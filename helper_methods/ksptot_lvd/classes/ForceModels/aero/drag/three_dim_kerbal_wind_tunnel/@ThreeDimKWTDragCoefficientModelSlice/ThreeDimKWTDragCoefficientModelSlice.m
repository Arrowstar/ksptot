classdef ThreeDimKWTDragCoefficientModelSlice < matlab.mixin.SetGet
    %ThreeDimKWTDragCoefficientModelSlice Summary of this class goes here
    %   Detailed explanation goes here

    properties
        aoa(1,1) double = 0; %total angle of attack in rad
        twoDSlice(1,1) TwoDimKspWindTunnelDragCoeffModel = TwoDimKspWindTunnelDragCoeffModel('');
    end

    methods
        function obj = ThreeDimKWTDragCoefficientModelSlice(aoa, sliceDataFile)
            obj.aoa = aoa;
            obj.twoDSlice = TwoDimKspWindTunnelDragCoeffModel(sliceDataFile);
            obj.twoDSlice.createGriddedInterpFromFile();
        end

        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('Kerbal Wind Tunnel Data Slice (Total AoA = %0.3f deg)', rad2deg(obj.aoa));
        end

        function data = getSliceDataTableData(obj)
            twoDModel = obj.twoDSlice;

            altitude = twoDModel.altitude;
            speed = twoDModel.speed;

            data = [min(altitude), max(altitude), min(diff(altitude)), numel(altitude);
                    min(speed),    max(speed),    min(diff(speed)),    numel(speed)];
        end

        function [statusGoodTf, messages] = getSliceStatus(obj)
            twoDModel = obj.twoDSlice;

            altitude = twoDModel.altitude;
            speed = twoDModel.speed;

            statusGoodTf = true;
            messages = string.empty(1,0);

            if(numel(altitude) < 2)
                messages(end+1) = "Altitude axis must have at least two points.";
                statusGoodTf = false;
            else
                if(~obj.isAxisMonotonicallyIncreasing(altitude))
                    messages(end+1) = "Altitude axis must be strictly increasing.";
                    statusGoodTf = false;
                end
            end

            if(numel(speed) < 2)
                messages(end+1) = "Speed axis must have at least two points.";
                statusGoodTf = false;
            else
                if(~obj.isAxisMonotonicallyIncreasing(speed))
                    messages(end+1) = "Speed axis must be strictly increasing.";
                    statusGoodTf = false;
                end
            end
        end
    end

    methods(Static, Access=private)
        function tf = isAxisMonotonicallyIncreasing(axis)
            tf = true;
            
            axisDiff = diff(axis);
            if(any(axisDiff <= 0))
                tf = true;
            end
        end
    end
end