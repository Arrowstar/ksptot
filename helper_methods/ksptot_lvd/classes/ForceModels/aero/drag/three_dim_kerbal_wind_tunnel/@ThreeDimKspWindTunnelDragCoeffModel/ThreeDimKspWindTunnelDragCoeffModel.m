classdef ThreeDimKspWindTunnelDragCoeffModel < AbstractDragCoefficientModel
    %ThreeDimKspWindTunnelDragCoeffModel Summary of this class goes here
    %   Detailed explanation goes here

    properties
        slices(1,:) ThreeDimKWTDragCoefficientModelSlice

        speed(1,:) double
        altitude(:,1) double
        aoa(1,:) double
        data double

        gi
    end

    properties(Constant)
        enum = DragCoefficientModelEnum.ThreeDimWindTunnel
    end

    methods
        function obj = ThreeDimKspWindTunnelDragCoeffModel(dataSlices)
            obj.slices = dataSlices;
            obj.sortSlicesByAoA();
        end

        function CdA = getDragCoeff(obj, ut, rVect, vVect, bodyInfo, mass, altitude, pressure, density, vVectECEFMag, totalAoA, aoa, sideslip)
            arguments
                obj(1,1) ThreeDimKspWindTunnelDragCoeffModel
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

            CdA = obj.gi(altitude, vVectECEFMag, totalAoA);
            CdA = max([CdA, 0]);
        end

        function addSlice(obj, newSlice)
            obj.slices(end+1) = newSlice;
            obj.sortSlicesByAoA();
        end

        function removeSlice(obj, slice)
            obj.slices(obj.slices == slice) = [];
            obj.sortSlicesByAoA();
        end

        function tf = usesTotalAoA(obj)
            tf = true;
        end

        function tf = usesAoaAndSideslip(obj)
            tf = false;
        end

        function createGriddedInterpFromSlices(obj)
            obj.sortSlicesByAoA();

            obj.speed = obj.slices(1).twoDSlice.speed;
            obj.altitude = obj.slices(1).twoDSlice.altitude;
            obj.aoa = [obj.slices.aoa];

            obj.data = [];
            for(i=1:length(obj.slices)) %#ok<*NO4LP> 
                slice = obj.slices(i);
                obj.data(:,:,i) = slice.twoDSlice.data;
            end

            gridVecs = {obj.altitude, obj.speed, obj.aoa};
            obj.gi = griddedInterpolant(gridVecs, obj.data, 'makima', 'nearest');
        end

        function sortSlicesByAoA(obj)
            AoAs = [obj.slices.aoa];
            [~,I] = sort(AoAs);
            obj.slices = obj.slices(I);
        end

        function [sliceGoodTf, messages] = getStatusOfSlices(obj)
            sliceGoodTf = true(1, length(obj.slices));
            messages = cell(1, length(obj.slices));

            AoAs = [obj.slices.aoa];
            
            for(i=1:length(obj.slices))
                slice = obj.slices(i);

                [thisSliceGoodTf, sliceMessages] = slice.getSliceStatus(); 
                sliceGoodTf(i) = sliceGoodTf(i) && thisSliceGoodTf;
                messages{i} = horzcat(messages{i}, sliceMessages);

                if(length(obj.slices) == 1)
                    sliceGoodTf(i) = false;
                    messages{i}(end+1) = 'There must be at least two AoA data sets.';
                end

                if(i >= 2)
                    subAoAs = AoAs;
                    subAoAs(i) = [];
                    if(any(AoAs(i) == subAoAs)) 
                        sliceGoodTf(i) = false;
                        messages{i}(end+1) = 'Duplicate angle of attack data sets are not allowed.';
                    end

                    slice1 = obj.slices(1);
                    twoDModelSlice1 = slice1.twoDSlice;
        
                    altitudeSlice1 = twoDModelSlice1.altitude;
                    speedSlice1 = twoDModelSlice1.speed;

                    twoDModel = slice.twoDSlice;
                    altitudeSliceI = twoDModel.altitude;
                    speedSliceI = twoDModel.speed;

                    if(numel(altitudeSliceI) == numel(altitudeSlice1))
                        bool = altitudeSliceI(:) - altitudeSlice1(:) ~= 0;
                        if(any(bool))
                            sliceGoodTf(i) = false; 
                            messages{i}(end+1) = "The altitude axis points do not match those of the first AoA data set.  All axis points must be identical in all data sets.";
                        end
                    else
                        sliceGoodTf(i) = false; 
                        messages{i}(end+1) = "There are not the same number of altitude axis points of those of the first AoA data set.  All axis points must be identical in all data sets."; 
                    end


                    if(numel(speedSliceI) == numel(speedSlice1))
                        bool = speedSliceI(:) - speedSlice1(:) ~= 0;
                        if(any(bool))
                            sliceGoodTf(i) = false; 
                            messages{i}(end+1) = "The speed axis points do not match those of the first AoA data set.  All axis points must be identical in all data sets."; 
                        end
                    else
                        sliceGoodTf(i) = false; 
                        messages{i}(end+1) = "There are not the same number of speed axis points of those of the first AoA data set.  All axis points must be identical in all data sets."; 
                    end
                end

                if(sliceGoodTf(i) == true)
                    messages{i} = "No warnings or errors found.";
                end
            end
        end

        function [listBoxStr, slices] = getListBoxStrs(obj)
            for(i=1:length(obj.slices))
                listBoxStr(i) = string(obj.slices(i).getListboxStr()); %#ok<AGROW> 
            end

            slices = obj.slices;
        end

        function useTf = openEditDialog(obj, lvdData)
            out = AppDesignerGUIOutput({false});
            lvd_Edit3DKerbalWindTunnelDragPropertiesGUI_App(obj, lvdData, out);
            useTf = out.output{1};
        end
    end

    methods(Static)
        function obj = loadobj(obj)
            if(isempty(obj.slices))
                slice1 = ThreeDimKspWindTunnelDragCoeffModel.produceDataSlice(0, '');
                obj.addSlice(slice1);

                slice2 = ThreeDimKspWindTunnelDragCoeffModel.produceDataSlice(deg2rad(1), '');
                obj.addSlice(slice2);
            end

            try
                obj.createGriddedInterpFromSlices();
            catch ME
                % nothing to do here
            end
        end

        function slice = produceDataSlice(aoa, sliceDataFile)
            slice = ThreeDimKWTDragCoefficientModelSlice(aoa, sliceDataFile);
        end
        
        function dragCoeffModel = createDefault()
            slice1 = ThreeDimKspWindTunnelDragCoeffModel.produceDataSlice(0, '');
            slice2 = ThreeDimKspWindTunnelDragCoeffModel.produceDataSlice(deg2rad(1), '');
            slices = [slice1, slice2];
            
            dragCoeffModel = ThreeDimKspWindTunnelDragCoeffModel(slices);
        end
    end
end