classdef KwtDragSliceTest < KsptotTestCase
    %KwtDragSliceTest Kerbal Wind Tunnel 3-D drag slice validation.
    %
    % ThreeDimKWTDragCoefficientModelSlice.isAxisMonotonicallyIncreasing used
    % to return true on every path (both branches assigned tf = true), so the
    % "axis must be strictly increasing" status message could never fire and
    % a mis-ordered or duplicated altitude/speed axis was accepted silently.

    methods(Test)
        function monotonicAxisCheckRejectsNonIncreasingAxes(testCase)
            f = @ThreeDimKWTDragCoefficientModelSlice.isAxisMonotonicallyIncreasing;

            testCase.verifyTrue(f([0 1 2]),        'A strictly increasing row must pass.');
            testCase.verifyTrue(f([0; 1; 2]),      'A strictly increasing column must pass.');
            testCase.verifyTrue(f([-5 -1 0 1e-9]), 'Small positive steps still count as increasing.');

            testCase.verifyFalse(f([0 1 1]),  'A repeated value is not strictly increasing.');
            testCase.verifyFalse(f([0 2 1]),  'A decrease anywhere must fail.');
            testCase.verifyFalse(f([2 1 0]),  'A decreasing axis must fail.');
            testCase.verifyFalse(f(5),        'A single point has no increasing direction.');
            testCase.verifyFalse(f([]),       'An empty axis must fail.');
        end

        function sliceStatusReportsBadAxes(testCase)
            slice = ThreeDimKWTDragCoefficientModelSlice(0, '');

            slice.twoDSlice.altitude = [0; 1; 2];
            slice.twoDSlice.speed = [0 1 2];
            [ok, messages] = slice.getSliceStatus();
            testCase.verifyTrue(ok, 'Well-ordered axes must pass validation.');
            testCase.verifyEmpty(messages);

            slice.twoDSlice.altitude = [0; 1; 1];
            [ok, messages] = slice.getSliceStatus();
            testCase.verifyFalse(ok, 'A duplicated altitude value must fail validation.');
            testCase.verifyTrue(any(contains(messages, 'Altitude axis must be strictly increasing')), ...
                'The altitude ordering message must be produced.');
            testCase.verifyFalse(any(contains(messages, 'Speed axis')), ...
                'A good speed axis must not be flagged.');

            slice.twoDSlice.altitude = [0; 1; 2];
            slice.twoDSlice.speed = [0 2 1];
            [ok, messages] = slice.getSliceStatus();
            testCase.verifyFalse(ok, 'A non-monotonic speed axis must fail validation.');
            testCase.verifyTrue(any(contains(messages, 'Speed axis must be strictly increasing')), ...
                'The speed ordering message must be produced.');
        end
    end
end
