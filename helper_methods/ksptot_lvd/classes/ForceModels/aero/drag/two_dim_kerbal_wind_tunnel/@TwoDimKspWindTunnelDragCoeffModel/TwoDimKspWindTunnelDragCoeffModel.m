classdef TwoDimKspWindTunnelDragCoeffModel < AbstractDragCoefficientModel
    %TwoDimKspWindTunnelDragCoeffModel Summary of this class goes here
    %   Detailed explanation goes here

    properties
        dataFile(1,:) char

        speed(1,:) double
        altitude(:,1) double
        data double

        gi
    end

    properties(Constant)
        enum = DragCoefficientModelEnum.TwoDimWindTunnel
    end

    methods
        function obj = TwoDimKspWindTunnelDragCoeffModel(dataFile)
            obj.dataFile = dataFile;

            if(isfile(dataFile))
                obj.createGriddedInterpFromFile();
            else
                obj.speed = [0 1];
                obj.altitude = [0; 1];
                obj.data = [1 1; 1 1];
                obj.createGriddedInterpolateFromData();
            end
        end

        function createGriddedInterpFromFile(obj)
            if(isfile(obj.dataFile))
                M = readmatrix(obj.dataFile);
                obj.speed = M(1,2:end)/1000; %convert from m/s to km/s
                obj.altitude = M(2:end, 1)/1000; %convert from m to km
                obj.data = M(2:end, 2:end);
    
                if(any(isnan(obj.data(:,1))))
                    obj.data(:,1) = obj.data(:,2);
                end
    
                [obj.altitude,I] = sort(obj.altitude);
                obj.data = obj.data(I,:);

                obj.createGriddedInterpolateFromData();

            else
                warning('The Kerbal Wind Tunnel flight envelope data file (%s) does not exist.', obj.dataFile);
            end
        end

        function createGriddedInterpolateFromData(obj)
            gridVecs = {obj.altitude, obj.speed};
            obj.gi = griddedInterpolant(gridVecs, obj.data, 'makima', 'nearest');
        end

        function clearData(obj)
            obj.speed = [];
            obj.altitude = [];
            obj.data = [];
            obj.gi = [];
        end

        function CdA = getDragCoeff(obj, ut, rVect, vVect, bodyInfo, mass, altitude, vVectECEFMag, aoa)
            arguments
                obj(1,1) TwoDimKspWindTunnelDragCoeffModel
                ut(1,1) double 
                rVect(3,1) double 
                vVect(3,1) double 
                bodyInfo(1,1) KSPTOT_BodyInfo
                mass(1,1) double
                altitude(1,1) double
                vVectECEFMag(1,1) double
                aoa(1,1) double = 0;  %this is not implemented yet
            end

            CdA = obj.gi(altitude, vVectECEFMag);
            CdA = max([CdA, 0]);
        end

        function tf = usesAoA(obj)
            tf = false;
        end

        function plotDragEnvelope(obj, hAx)
            arguments
                obj(1,1) TwoDimKspWindTunnelDragCoeffModel
                hAx = [];
            end

            if(isempty(obj.speed) || isempty(obj.altitude) || isempty(obj.data))
                warning('No Kerbal Wind Tunnel flight envelope data loaded: cannot plot.');
                return
            end

            if(isempty(hAx))
                hAx = axes(figure());
            end

            maxCdA = max(obj.data,[],'all');
            minCdA = min(obj.data,[],'all');
            levels = linspace(minCdA, maxCdA, 50);

            warning("off",'MATLAB:contour:ConstantData');

            contour(hAx, obj.speed, obj.altitude, obj.data, levels, 'Fill','on');
            xlabel(hAx, 'Speed [km/s]');
            ylabel(hAx, 'Altitude [km]');
            title(hAx, '');
            grid(hAx, 'on');

            warning("on",'MATLAB:contour:ConstantData');
            
            hC = colorbar(hAx);
            hC.Label.String = 'Cd*A [m^2]';
        end

        function useTf = openEditDialog(obj, lvdData)
            out = AppDesignerGUIOutput({false});
            lvd_Edit2DKerbalWindTunnelDragPropertiesGUI_App(obj, lvdData, out);
            useTf = out.output{1};
        end
    end

    methods(Static)
        function obj = loadobj(obj)
            try
                obj.createGriddedInterpolateFromData();
            catch ME
                % nothing to do here
            end
        end
    end
end