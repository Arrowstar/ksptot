classdef (Abstract) KsptotTestCase < matlab.unittest.TestCase
    %KsptotTestCase Shared base class for all KSPTOT unit tests.
    %
    % Handles path setup and provides the stock celestial body data plus a
    % few frequently used bodies and frames.

    properties
        celBodyData
        kerbin      % atmospheric home body, gm = 3531.6 km^3/s^2
        mun         % airless moon of Kerbin
        sun         % system barycenter body
        kerbinFrame % Kerbin-centered inertial frame
    end

    methods(TestClassSetup)
        function setUpKsptotEnvironment(testCase)
            ksptotAddProjectPaths();

            testCase.celBodyData = ksptotTestBodyData();
            testCase.kerbin      = testCase.celBodyData.kerbin;
            testCase.mun         = testCase.celBodyData.mun;
            testCase.sun         = testCase.celBodyData.sun;
            testCase.kerbinFrame = testCase.kerbin.getBodyCenteredInertialFrame();
        end
    end

    methods
        function verifyVectorEqual(testCase, actual, expected, absTol, msg)
            %verifyVectorEqual Compares two 3-vectors component-wise.
            if(nargin < 5)
                msg = '';
            end

            testCase.verifyEqual(size(actual(:)), size(expected(:)), ...
                sprintf('%s (vector sizes differ)', msg));
            testCase.verifyLessThanOrEqual(norm(actual(:) - expected(:)), absTol, ...
                sprintf('%s (|actual - expected| = %g, tol = %g)', ...
                        msg, norm(actual(:) - expected(:)), absTol));
        end

        function verifyAngleEqual(testCase, actual, expected, absTol, msg)
            %verifyAngleEqual Compares two angles modulo 2*pi.
            if(nargin < 5)
                msg = '';
            end

            delta = abs(angleNegPiToPi(actual - expected));
            testCase.verifyLessThanOrEqual(delta, absTol, ...
                sprintf('%s (angular difference = %g rad, tol = %g rad)', ...
                        msg, delta, absTol));
        end

        function bodyInfo = copyBodyInfo(testCase, bodyInfoIn)
            %copyBodyInfo Shallow-copies a KSPTOT_BodyInfo handle so tests
            %can mutate properties without affecting the shared body data.
            %
            %KSPTOT_BodyInfo derives from matlab.mixin.SetGet (a handle
            %class) so the built-in copy() is undefined; property-wise
            %shallow copy is sufficient for the force model tests, which
            %only read scalar body properties.

            %Derived memo properties are deliberately NOT copied. They are
            %snapshots of other properties, so carrying one over to a fresh
            %object that a test is about to mutate reintroduces exactly the
            %staleness the copy was made to avoid. Concretely:
            %fixedFrameFromInertialFrameCache snapshots {rotperiod, rotini},
            %and every test that uses the "non-rotating body" trick
            %(rotperiod=Inf, rotini=0) sets those two properties immediately
            %after this copy. Copying a warm memo in made the trick a no-op
            %whenever some earlier test in the same session had already
            %warmed it -- so those fixtures silently passed or failed
            %depending on test execution order. Skipping caches keeps the
            %copy order-independent; matching by name also covers memos added
            %later.
            bodyInfo = feval(class(bodyInfoIn));

            props = properties(bodyInfoIn);
            isDerivedMemo = endsWith(props, 'Cache') | startsWith(props, 'lastComputed');
            props = props(~isDerivedMemo);

            for(i=1:length(props)) %#ok<*NO4LP>
                try
                    bodyInfo.(props{i}) = bodyInfoIn.(props{i});
                catch
                    % read-only and private properties keep their defaults
                end
            end
        end
    end
end
