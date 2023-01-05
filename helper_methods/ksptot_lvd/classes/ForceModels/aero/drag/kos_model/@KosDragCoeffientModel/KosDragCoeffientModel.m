classdef KosDragCoeffientModel < AbstractDragCoefficientModel
    %kOSDragCoefficientModel Summary of this class goes here
    %   Detailed explanation goes here

    properties
        dataFile(1,:) char

        machNum(:,1) double
        aoa(:,1) double
        sideslip(:,1) double
        data double

        giDragCube
        giOtherDrag
    end

    properties(Access=private)
        giRnCorr
    end

    properties(Constant)
        enum = DragCoefficientModelEnum.kOSModel
    end

    methods
        function obj = KosDragCoeffientModel(dataFile)
            obj.dataFile = dataFile;

            obj.dataFile = dataFile;

            if(isfile(dataFile))
                obj.createGriddedInterpFromFile();
            else
                obj.machNum = [0; 1];
                obj.aoa = [0; deg2rad(1)];
                obj.sideslip = [0; deg2rad(1)];

                rows = combvec(obj.machNum', obj.aoa', obj.sideslip')';
                rows(:,4:5) = 0;
                obj.data = rows;
                
                obj.createGriddedInterpFromData();
            end

            %see Profile.ks in the Project-Atmospheric-Drag for details of
            %this correction factor
            %https://github.com/Ren0k/Project-Atmospheric-Drag/blob/main/CCAT/DragProfile/LIB/Profile.ks
            rnCorrData = [0.00, 4.0000;
                            0.0001 ,3.0000;
                            0.01   ,2.0000;
                            0.10   ,1.2000;
                            1.00   ,1.0000;
                            100.0  ,1.0000;
                            200.0  ,0.8200;
                            500.0  ,0.8600;
                            1000.0 ,0.9000;
                            10000  ,0.9500];
            obj.giRnCorr = griddedInterpolant(rnCorrData(:,1), rnCorrData(:,2), 'pchip', 'nearest');
        end

        function createGriddedInterpFromFile(obj)
            obj.data = readmatrix(obj.dataFile);
            obj.data(:,2:3) = deg2rad(obj.data(:,2:3)); %convert aoa and sideslip to radian from deg
            
            obj.data = sortrows(obj.data, [3 2 1]);
            obj.machNum = unique(obj.data(:,1));
            obj.aoa = unique(obj.data(:,2));
            obj.sideslip = unique(obj.data(:,3));

            obj.createGriddedInterpFromData();
        end

        function createGriddedInterpFromData(obj)
            %drag cube Model
            c = obj.data(:,4);
            V = reshape(c, [length(obj.machNum), length(obj.aoa), length(obj.sideslip)]);
            
            gridVecs = {obj.machNum,obj.aoa,obj.sideslip};
            
            obj.giDragCube = griddedInterpolant(gridVecs,V, "linear", "nearest");

            %other drag Model
            c = obj.data(:,5);
            V = reshape(c, [length(obj.machNum), length(obj.aoa), length(obj.sideslip)]);
            
            gridVecs = {obj.machNum,obj.aoa,obj.sideslip};
            
            obj.giOtherDrag = griddedInterpolant(gridVecs,V, "linear", "nearest");
        end

        function clearData(obj)
            obj.machNum = [];
            obj.aoa = [];
            obj.sideslip = [];
            obj.data = [];
            obj.giDragCube = [];
        end

        function CdA = getDragCoeff(obj, ut, rVect, vVect, bodyInfo, mass, altitude, pressure, density, vVectECEFMag, totalAoA, aoa, sideslip)
            arguments
                obj(1,1) KosDragCoeffientModel
                ut(1,1) double 
                rVect(3,1) double 
                vVect(3,1) double 
                bodyInfo(1,1) KSPTOT_BodyInfo
                mass(1,1) double
                altitude(1,1) double
                pressure(1,1) double
                density(1,1) double
                vVectECEFMag(1,1) double
                totalAoA(1,1) double = 0;
                aoa(1,1) double = 0;
                sideslip(1,1) double = 0;
            end

            if(density > 0)
                sideslip = angleNegPiToPi_mex(sideslip);
    
                %see useProfile.ks in the Project-Atmospheric-Drag for details
                %of this algorithm
                %https://github.com/Ren0k/Project-Atmospheric-Drag/blob/main/CCAT/useProfile.ks
                reynoldsNumber = density*vVectECEFMag;
                reynoldsCorrection = obj.giRnCorr(reynoldsNumber);
    
                pressurePa = pressure*1000;
                speedSound = sqrt(1.4 * pressurePa / density); %m/s
                speedMS = vVectECEFMag*1000;                   %m/s
                thisMachNum = speedMS / speedSound;
    
                dragCubeCdA = obj.giDragCube(thisMachNum, aoa, sideslip);
                otherDragCdA = obj.giOtherDrag(thisMachNum, aoa, sideslip);
    
                CdA = ((dragCubeCdA*reynoldsCorrection)+otherDragCdA);
            else
                CdA = 0;
            end
        end

        function tf = usesTotalAoA(obj)
            tf = false;
        end

        function tf = usesAoaAndSideslip(obj)
            tf = true;
        end

        function useTf = openEditDialog(obj, lvdData)
            out = AppDesignerGUIOutput({false});
            lvd_EditKosDragPropertiesGUI_App(obj, lvdData, out);
            useTf = out.output{1};
        end

        function plotDragEnvelope(obj, hAx, machNum)
            arguments
                obj(1,1) KosDragCoeffientModel
                hAx = [];
                machNum(1,1) double = 0;
            end

            if(isempty(obj.machNum) || isempty(obj.aoa) || isempty(obj.sideslip))
                warning('No kOS drag coefficient data loaded: cannot plot.');
                return;
            end

            if(isempty(hAx))
                hAx = axes(figure());
            end

            dragCubeData = obj.data(:,4);

            maxCdA = max(dragCubeData);
            minCdA = min(dragCubeData);
            levels = linspace(minCdA, maxCdA, 50);

            warning("off",'MATLAB:contour:ConstantData');

            allVect = combvec(obj.aoa(:)', obj.sideslip(:)')';
            allVect = [machNum*ones(height(allVect), 1), allVect];
            cd = obj.giDragCube(allVect(:,1), allVect(:,2), allVect(:,3));

            [~,hContour] = contour(hAx, rad2deg(obj.aoa), rad2deg(obj.sideslip), reshape(cd, [length(obj.aoa), length(obj.sideslip)]), levels, 'Fill','on');
            xlabel(hAx, 'Angle of Attack [deg]');
            ylabel(hAx, 'Sideslip Angle [deg]');
            title(hAx, sprintf('Cd*A for Mach Number = %0.3f', machNum));
            grid(hAx, 'on');

            hContour.DataTipTemplate.DataTipRows(1).Label = 'AoA (deg)';
            hContour.DataTipTemplate.DataTipRows(2).Label = 'Sideslip (deg)';
            hContour.DataTipTemplate.DataTipRows(3).Label = 'Cd*A (m^2)';

            hContour.DataTipTemplate.DataTipRows(1).Format = '%0.3f';
            hContour.DataTipTemplate.DataTipRows(2).Format = '%0.3f';
            hContour.DataTipTemplate.DataTipRows(3).Format = '%0.3f';
    
            warning("on",'MATLAB:contour:ConstantData');
            
            hC = colorbar(hAx);
            hC.Label.String = 'Cd*A [m^2]';
        end
    end
end