classdef UserTabulatedLiftModel < AbstractLiftCoefficientModel
    %UserTabulatedLiftModel Tabular Cl*S(Mach, AoA, sideslip) lift model.
    %   CSV rows: mach, AoA_deg, sideslip_deg, ClS_m2 (no header).
    %   Mirrors KosDragCoeffientModel storage/interp; ClS is stored
    %   directly (no separate reference area).

    properties
        dataFile(1,:) char = ''

        machNum(:,1) double = double.empty(0,1)
        aoa(:,1) double = double.empty(0,1)
        sideslip(:,1) double = double.empty(0,1)
        data double = double.empty(0,4)

        giClS
    end

    properties(Constant)
        enum = LiftCoefficientModelEnum.UserTabulated
    end

    methods
        function obj = UserTabulatedLiftModel(dataFile)
            if(nargin < 1)
                dataFile = '';
            end
            obj.dataFile = dataFile;

            if(ischar(dataFile) && ~isempty(dataFile) && isfile(dataFile))
                obj.createGriddedInterpFromFile();
            else
                obj.machNum = [0; 1];
                obj.aoa = [0; deg2rad(1)];
                obj.sideslip = [0; deg2rad(1)];

                rows = combvec(obj.machNum', obj.aoa', obj.sideslip')';
                rows(:,4) = 0;
                obj.data = rows;

                obj.createGriddedInterpFromData();
            end
        end

        function createGriddedInterpFromFile(obj)
            obj.data = readmatrix(obj.dataFile);
            if(size(obj.data,2) ~= 4)
                error('UserTabulatedLiftModel:badTable', ...
                    'Lift table must have 4 columns: mach, AoA_deg, sideslip_deg, ClS_m2.');
            end
            obj.data(:,2:3) = deg2rad(obj.data(:,2:3)); %deg -> rad

            obj.data = sortrows(obj.data, [3 2 1]);
            obj.machNum = unique(obj.data(:,1));
            obj.aoa = unique(obj.data(:,2));
            obj.sideslip = unique(obj.data(:,3));

            obj.createGriddedInterpFromData();
        end

        function createGriddedInterpFromData(obj)
            c = obj.data(:,4);
            V = reshape(c, [length(obj.machNum), length(obj.aoa), length(obj.sideslip)]);

            gridVecs = {obj.machNum, obj.aoa, obj.sideslip};

            obj.giClS = griddedInterpolant(gridVecs, V, "linear", "nearest");
        end

        function clearData(obj)
            obj.machNum = double.empty(0,1);
            obj.aoa = double.empty(0,1);
            obj.sideslip = double.empty(0,1);
            obj.data = double.empty(0,4);
            obj.giClS = [];
        end

        function [ClS, liftUnitVectInertial] = getLiftCoeffAndDir(obj, ut, rVect, vVect, bodyInfo, mass, altitude, pressure, density, vVectECEF, attState)
            arguments
                obj(1,1) UserTabulatedLiftModel
                ut(1,1) double
                rVect(3,1) double
                vVect(3,1) double
                bodyInfo(1,1) KSPTOT_BodyInfo
                mass(1,1) double
                altitude(1,1) double
                pressure(1,1) double
                density(1,1) double
                vVectECEF(3,1) double
                attState(1,1) LaunchVehicleAttitudeState
            end

            if(density <= 0 || isempty(obj.giClS))
                ClS = 0;
            else
                [~,aoa,sideslip,~] = attState.getAeroAngles(ut, rVect, vVect, bodyInfo);
                sideslip = angleNegPiToPi_mex(sideslip);

                vVectECEFMag = norm(vVectECEF);
                pressurePa = pressure*1000;
                speedSound = sqrt(1.4 * pressurePa / density); %m/s
                thisMachNum = (vVectECEFMag*1000) / speedSound;

                ClS = obj.giClS(thisMachNum, aoa, sideslip);
            end

            %lift direction: same construction as CylindricalLiftModel
            bff = bodyInfo.getBodyFixedFrame();
            bci = bodyInfo.getBodyCenteredInertialFrame();

            R_ecef_to_global_inertial = bff.getRotMatToInertialAtTime(ut,[],[]);
            R_bci_to_global_inertial = bci.getRotMatToInertialAtTime(ut,[],[]);
            R_ecef_to_bci = R_bci_to_global_inertial' * R_ecef_to_global_inertial;

            R_bci_to_ecef = R_ecef_to_bci';
            bodyXECEF = R_bci_to_ecef*attState.bodyX;

            v1 = crossARH(vVectECEF, bodyXECEF);
            liftUnitVectECEF = normVector(crossARH(v1, bodyXECEF));
            liftUnitVectInertial = R_ecef_to_bci * liftUnitVectECEF;
        end

        function useTf = openEditDialog(obj, lvdData)
            out = AppDesignerGUIOutput({false});
            lvd_EditUserTabulatedLiftPropertiesGUI_App(obj, lvdData, out);
            useTf = out.output{1};
        end

        function plotLiftEnvelope(obj, hAx, machNum)
            arguments
                obj(1,1) UserTabulatedLiftModel
                hAx = [];
                machNum(1,1) double = 0;
            end

            if(isempty(obj.machNum) || isempty(obj.aoa) || isempty(obj.sideslip))
                warning('No tabulated lift data loaded: cannot plot.');
                return;
            end

            if(isempty(hAx))
                hAx = axes(figure());
            end

            clsData = obj.data(:,4);

            maxClS = max(clsData);
            minClS = min(clsData);
            levels = linspace(minClS, maxClS, 50);

            warning("off",'MATLAB:contour:ConstantData');

            allVect = combvec(obj.aoa(:)', obj.sideslip(:)')';
            allVect = [machNum*ones(height(allVect), 1), allVect];
            cls = obj.giClS(allVect(:,1), allVect(:,2), allVect(:,3));

            [~,hContour] = contour(hAx, rad2deg(obj.aoa), rad2deg(obj.sideslip), reshape(cls, [length(obj.aoa), length(obj.sideslip)]), levels, 'Fill','on');
            xlabel(hAx, 'Angle of Attack [deg]');
            ylabel(hAx, 'Sideslip Angle [deg]');
            title(hAx, sprintf('Cl*S for Mach Number = %0.3f', machNum));
            grid(hAx, 'on');

            hContour.DataTipTemplate.DataTipRows(1).Label = 'AoA (deg)';
            hContour.DataTipTemplate.DataTipRows(2).Label = 'Sideslip (deg)';
            hContour.DataTipTemplate.DataTipRows(3).Label = 'Cl*S (m^2)';

            hContour.DataTipTemplate.DataTipRows(1).Format = '%0.3f';
            hContour.DataTipTemplate.DataTipRows(2).Format = '%0.3f';
            hContour.DataTipTemplate.DataTipRows(3).Format = '%0.3f';

            warning("on",'MATLAB:contour:ConstantData');

            hC = colorbar(hAx);
            hC.Label.String = 'Cl*S [m^2]';
        end
    end
end
