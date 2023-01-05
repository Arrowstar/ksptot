classdef LiftCoefficientCurves
    %LiftCoefficientCurves Summary of this class goes here
    %   Detailed explanation goes here

    properties
        %default
        defaultGiLift
        defaultMachCurve

        %body lift curves
        bodyLiftGiLift
        bodyLiftMachCurve
    end

    methods
        function obj = LiftCoefficientCurves()
            %these curves come from KSP's physics.cfg file

            %default curves
            %lift
            liftCurve = [0	        0
                         0.258819	0.5114774
                         0.5	    0.9026583
                         0.7071068	0.5926583
                         1	        0];
            obj.defaultGiLift = griddedInterpolant(liftCurve(:,1),liftCurve(:,2), 'pchip', 'nearest');

            %liftMach
            machLiftCurve = [0	    1
                             0.3	0.5
                             1	    0.125
                             5	    0.0625
                             25	    0.05];
            obj.defaultMachCurve = griddedInterpolant(machLiftCurve(:,1),machLiftCurve(:,2), 'pchip', 'nearest');

            %body lift curves
            %lift
            liftCurve = [0	        0
                         0.309017	0.5877852
                         0.5877852	0.9510565
                         0.7071068	1
                         0.8910065	0.809017
                         1	        0];
            obj.bodyLiftGiLift = griddedInterpolant(liftCurve(:,1),liftCurve(:,2), 'pchip', 'nearest');

            %liftMach
            machLiftCurve = [0.3	0.167
                            0.8	    0.167
                            1	    0.125
                            5	    0.0625
                            25	    0.05];
            obj.bodyLiftMachCurve = griddedInterpolant(machLiftCurve(:,1),machLiftCurve(:,2), 'pchip', 'nearest');
        end
    end
end