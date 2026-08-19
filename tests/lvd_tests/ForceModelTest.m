classdef ForceModelTest < KsptotTestCase
    %ForceModelTest LVD force models and their aggregation.
    %
    % Forces in LVD are in mT*km/s^2, so dividing by the vehicle mass in mT
    % gives an acceleration in km/s^2.  Each model is checked against the
    % closed-form physics it implements rather than against a stored value.

    properties(TestParameter)
        orbitCase = ksptotTestOrbitCatalog();
        vehicleMass = struct('light', 0.5, 'nominal', 12.5, 'heavy', 400);
    end

    methods(Test)

        %% Point-mass gravity

        function gravityMatchesPointMassLaw(testCase, orbitCase)
            %F = -gm*m/r^3 * rVect.

            bodyInfo = testCase.kerbin;
            mass     = 10;
            rVect    = orbitCase.rVect;

            forceVect = testCase.callForce(GravityForceModel(), rVect, orbitCase.vVect, mass, bodyInfo);

            expected = -(bodyInfo.gm * mass / norm(rVect)^3) * rVect;

            testCase.verifyVectorEqual(forceVect, expected, 1e-9 * norm(expected), ...
                sprintf('%s: gravity does not match the point-mass law', orbitCase.desc));
        end

        function gravityScalesLinearlyWithMass(testCase, vehicleMass)
            %Doubling the mass must double the force.

            bodyInfo = testCase.kerbin;
            rVect    = [800; 250; -140];
            vVect    = [0.1; 2.0; 0.3];

            force1 = testCase.callForce(GravityForceModel(), rVect, vVect, vehicleMass, bodyInfo);
            force2 = testCase.callForce(GravityForceModel(), rVect, vVect, 2 * vehicleMass, bodyInfo);

            testCase.verifyVectorEqual(force2, 2 * force1, 1e-9 * norm(force1), sprintf( ...
                'Gravity is not linear in mass at %g mT', vehicleMass));
        end

        function gravityObeysInverseSquare(testCase)
            %Doubling the radius must quarter the force magnitude.

            bodyInfo  = testCase.kerbin;
            direction = normVector([1; 2; 3]);
            mass      = 7;

            radiusNear = 900;
            forceNear = testCase.callForce(GravityForceModel(), ...
                radiusNear * direction, [0; 1; 0], mass, bodyInfo);
            forceFar = testCase.callForce(GravityForceModel(), ...
                2 * radiusNear * direction, [0; 1; 0], mass, bodyInfo);

            testCase.verifyEqual(norm(forceNear) / norm(forceFar), 4, 'RelTol', 1e-10, ...
                'Gravity does not fall off as the inverse square of radius');
        end

        function gravityPointsAtTheBodyCentre(testCase, orbitCase)
            %The force must be exactly antiparallel to the position vector.

            bodyInfo = testCase.kerbin;

            forceVect = testCase.callForce(GravityForceModel(), ...
                orbitCase.rVect, orbitCase.vVect, 3, bodyInfo);

            cosAngle = dot(normVector(forceVect), normVector(orbitCase.rVect));

            testCase.verifyEqual(cosAngle, -1, 'AbsTol', 1e-12, sprintf( ...
                '%s: gravity is not directed at the body centre', orbitCase.desc));
        end

        function gravityProducesNoMassOrChargeFlow(testCase)
            %Gravity must not report propellant or electric charge rates.

            [~, tankMdots, ecStgDots] = testCase.callForce(GravityForceModel(), ...
                [900; 0; 0], [0; 2; 0], 5, testCase.kerbin);

            testCase.verifyEmpty(tankMdots, 'Gravity reported a tank mass flow rate');
            testCase.verifyEmpty(ecStgDots, 'Gravity reported an electric charge rate');
        end

        function zeroDegreeHarmonicsMatchPointMassGravity(testCase)
            %With nonspherical gravity enabled but degree 0, nothing changes.

            bodyInfo = testCase.copyBodyInfo(testCase.kerbin);
            rVect    = [850; 300; 175];
            vVect    = [0.2; 1.9; 0.4];
            mass     = 9;

            bodyInfo.usenonsphericalgrav    = false;
            pointMassForce = testCase.callForce(GravityForceModel(), rVect, vVect, mass, bodyInfo);

            bodyInfo.usenonsphericalgrav    = true;
            bodyInfo.nonsphericalgravmaxdeg = 0;
            harmonicForce = testCase.callForce(GravityForceModel(), rVect, vVect, mass, bodyInfo);

            testCase.verifyVectorEqual(harmonicForce, pointMassForce, 1e-9 * norm(pointMassForce), ...
                'Degree-0 nonspherical gravity does not reduce to the point-mass law');
        end

        %% Normal (surface reaction) force

        function normalForceIsZeroAboveTheSurface(testCase)
            %Nothing to push against once the vehicle has left the ground.

            bodyInfo = testCase.kerbin;
            rVect    = (bodyInfo.radius + 5) * normVector([1; 0.3; 0.2]);

            forceVect = testCase.callForce(NormalForceModel(), rVect, [0; 2; 0], 8, bodyInfo);

            testCase.verifyVectorEqual(forceVect, [0; 0; 0], 0, ...
                'The normal force is non-zero 5 km above the surface');
        end

        function normalForceCancelsGravityAtTheSurface(testCase)
            %At or below the surface the model must supply -gravity plus the
            %centripetal term needed to co-rotate with the body.

            bodyInfo = testCase.kerbin;
            mass     = 8;
            rVect    = bodyInfo.radius * normVector([1; 0.3; 0.2]);

            forceVect = testCase.callForce(NormalForceModel(), rVect, [0; 2; 0], mass, bodyInfo);

            spinRate     = 2 * pi / bodyInfo.rotperiod;
            spinVect     = [0; 0; spinRate];
            centripAccel = cross(spinVect, cross(spinVect, rVect));
            gravAccel    = -(bodyInfo.gm / norm(rVect)^3) * rVect;

            expected = mass * (-gravAccel + centripAccel);

            testCase.verifyVectorEqual(forceVect, expected, 1e-9 * norm(expected), ...
                'The normal force does not match -gravity plus the centripetal term');
        end

        function normalForceBalancesGravityOnANonRotatingBody(testCase)
            %With no spin the normal force must exactly oppose gravity.

            bodyInfo = testCase.copyBodyInfo(testCase.kerbin);
            bodyInfo.rotperiod = Inf;

            mass  = 6;
            rVect = bodyInfo.radius * normVector([0.4; -1; 0.1]);

            normalForce  = testCase.callForce(NormalForceModel(),  rVect, [0; 0; 0], mass, bodyInfo);
            gravityForce = testCase.callForce(GravityForceModel(), rVect, [0; 0; 0], mass, bodyInfo);

            testCase.verifyVectorEqual(normalForce + gravityForce, [0; 0; 0], ...
                1e-9 * norm(gravityForce), ...
                'Normal force and gravity do not cancel on a non-rotating body');
        end

        %% Third-body gravity

        function thirdBodyGravityIsZeroWithNoBodies(testCase)
            %An empty body list must produce no force.

            grav3Body = LaunchVehicle3BodyGravState();
            grav3Body.bodies      = KSPTOT_BodyInfo.empty(1, 0);
            grav3Body.celBodyData = testCase.celBodyData;

            forceVect = testCase.callThirdBody(grav3Body, [900; 0; 0], 10, testCase.kerbin);

            testCase.verifyVectorEqual(forceVect, [0; 0; 0], 0, ...
                'Third-body gravity is non-zero with no perturbing bodies');
        end

        function thirdBodyGravityIgnoresTheCentralBody(testCase)
            %The central body must be filtered out of its own perturbations.

            grav3Body = LaunchVehicle3BodyGravState();
            grav3Body.bodies      = testCase.kerbin;
            grav3Body.celBodyData = testCase.celBodyData;

            forceVect = testCase.callThirdBody(grav3Body, [900; 0; 0], 10, testCase.kerbin);

            testCase.verifyVectorEqual(forceVect, [0; 0; 0], 0, ...
                'The central body perturbed itself');
        end

        function thirdBodyGravityScalesLinearlyWithMass(testCase)
            %Third-body acceleration is mass independent, so force is linear.

            grav3Body = LaunchVehicle3BodyGravState();
            grav3Body.bodies      = testCase.mun;
            grav3Body.celBodyData = testCase.celBodyData;

            rVect = [900; 120; 60];

            force1 = testCase.callThirdBody(grav3Body, rVect, 10, testCase.kerbin);
            force2 = testCase.callThirdBody(grav3Body, rVect, 40, testCase.kerbin);

            testCase.assertGreaterThan(norm(force1), 0, ...
                'The Mun exerted no third-body force at all');

            testCase.verifyVectorEqual(force2, 4 * force1, 1e-9 * norm(force1), ...
                'Third-body gravity is not linear in vehicle mass');
        end

        function thirdBodyGravityRespondsToADifferentBodySet(testCase)
            %Swapping the perturbing body must change the force.
            %
            % Gravity3rdBodyForceModel caches the celestial-body orbit
            % element chains in a persistent variable, invalidating only
            % when the central body id or the *number* of bodies changes.
            % Swapping one body for another keeps both of those the same.

            rVect = [900; 120; 60];
            mass  = 10;

            munState = LaunchVehicle3BodyGravState();
            munState.bodies      = testCase.mun;
            munState.celBodyData = testCase.celBodyData;

            sunState = LaunchVehicle3BodyGravState();
            sunState.bodies      = testCase.sun;
            sunState.celBodyData = testCase.celBodyData;

            % Evaluate each first from a cold cache, so we know the correct
            % answers, then interleave them to expose any stale caching.
            clear Gravity3rdBodyForceModel;
            munForceCold = testCase.callThirdBody(munState, rVect, mass, testCase.kerbin);

            clear Gravity3rdBodyForceModel;
            sunForceCold = testCase.callThirdBody(sunState, rVect, mass, testCase.kerbin);

            testCase.assertGreaterThan(norm(munForceCold - sunForceCold), 1e-12, ...
                'The Mun and the Sun happen to exert the same force; pick another pair');

            % Now the interleaved order: Mun primes the cache, Sun follows.
            clear Gravity3rdBodyForceModel;
            testCase.callThirdBody(munState, rVect, mass, testCase.kerbin);
            sunForceWarm = testCase.callThirdBody(sunState, rVect, mass, testCase.kerbin);

            testCase.verifyVectorEqual(sunForceWarm, sunForceCold, 1e-9 * norm(sunForceCold), ...
                ['The third-body force from the Sun depended on whether the Mun ', ...
                 'had been evaluated first, so the cached body chains are stale.']);
        end

        %% Total force aggregation

        function totalForceEqualsTheSumOfItsParts(testCase)
            %The aggregate must equal the sum of the individual models.

            bodyInfo = testCase.kerbin;
            rVect    = [900; 120; 60];
            vVect    = [0.1; 1.8; 0.2];
            mass     = 10;

            grav3Body = LaunchVehicle3BodyGravState();
            grav3Body.bodies      = testCase.mun;
            grav3Body.celBodyData = testCase.celBodyData;

            fmEnums = [ForceModelsEnum.Gravity, ForceModelsEnum.Gravity3rdBody];

            totalForce = testCase.callTotalForce(fmEnums, rVect, vVect, mass, bodyInfo, grav3Body);

            gravityForce  = testCase.callForce(GravityForceModel(), rVect, vVect, mass, bodyInfo);
            thirdBodyForce = testCase.callThirdBody(grav3Body, rVect, mass, bodyInfo);

            expected = gravityForce + thirdBodyForce;

            testCase.verifyVectorEqual(totalForce, expected, 1e-9 * norm(expected), ...
                'The total force is not the sum of the gravity and third-body models');
        end

        function totalForceIsZeroForAMasslessVehicle(testCase)
            %getForce short-circuits at zero mass.

            grav3Body = LaunchVehicle3BodyGravState();
            grav3Body.bodies      = testCase.mun;
            grav3Body.celBodyData = testCase.celBodyData;

            totalForce = testCase.callTotalForce(ForceModelsEnum.Gravity, ...
                [900; 120; 60], [0.1; 1.8; 0.2], 0, testCase.kerbin, grav3Body);

            testCase.verifyVectorEqual(totalForce, [0; 0; 0], 0, ...
                'A zero-mass vehicle experienced a non-zero force');
        end

        function attitudeIsBuiltWhenAForceModelNeedsIt(testCase)
            %A force model flagged usesAttitudeState must get an attitude.

            steeringModel = MockSteeringModel();

            clear TotalForceModel;
            testCase.callTotalForce([ForceModelsEnum.Gravity, ForceModelsEnum.Drag], ...
                testCase.aboveAtmospherePosition(), [0.1; 1.8; 0.2], 10, ...
                testCase.kerbin, testCase.emptyThirdBodyState(), steeringModel);

            testCase.verifyGreaterThan(steeringModel.callCount, 0, ...
                'Drag is flagged usesAttitudeState but no attitude DCM was requested');
        end

        function attitudeIsNotBuiltWhenNoForceModelNeedsIt(testCase)
            %Conversely, a purely gravitational set must skip the attitude.

            steeringModel = MockSteeringModel();

            clear TotalForceModel;
            testCase.callTotalForce([ForceModelsEnum.Gravity, ForceModelsEnum.Normal], ...
                testCase.aboveAtmospherePosition(), [0.1; 1.8; 0.2], 10, ...
                testCase.kerbin, testCase.emptyThirdBodyState(), steeringModel);

            testCase.verifyEqual(steeringModel.callCount, 0, ...
                'An attitude DCM was computed for a force model set that does not need one');
        end

        function attitudeDecisionTracksTheForceModelSetNotItsLength(testCase)
            %Two different sets of the same length must be judged separately.
            %
            % TotalForceModel.getForce caches whether an attitude state is
            % needed in a persistent variable, and invalidates that cache
            % only when length(fmEnums) changes:
            %
            %     if(isempty(cachedFmLen) || cachedFmLen ~= fmLen)
            %         cachedNeedsAtt = any([fmEnums.usesAttitudeState]);
            %
            % [Gravity, Normal] and [Gravity, Drag] are both length 2 but
            % disagree on usesAttitudeState, so whichever runs first decides
            % for the other.  Drag then receives an empty attitude state.

            steeringModel = MockSteeringModel();
            rVect = testCase.aboveAtmospherePosition();
            vVect = [0.1; 1.8; 0.2];

            % Prime the cache with a set that does NOT need an attitude.
            clear TotalForceModel;
            testCase.callTotalForce([ForceModelsEnum.Gravity, ForceModelsEnum.Normal], ...
                rVect, vVect, 10, testCase.kerbin, testCase.emptyThirdBodyState(), steeringModel);

            testCase.assertEqual(steeringModel.callCount, 0, ...
                'Setup: [Gravity, Normal] should not have requested an attitude');

            % Same length, but this one does need an attitude.
            testCase.callTotalForce([ForceModelsEnum.Gravity, ForceModelsEnum.Drag], ...
                rVect, vVect, 10, testCase.kerbin, testCase.emptyThirdBodyState(), steeringModel);

            testCase.verifyGreaterThan(steeringModel.callCount, 0, ...
                ['[Gravity, Drag] needs an attitude state but none was built, because ', ...
                 'the persistent cache had already decided "no attitude" for the ', ...
                 'same-length set [Gravity, Normal].  Inside the atmosphere the drag ', ...
                 'model would then be handed an empty attitude state.']);
        end

        function dragInsideAtmosphereSurvivesAPrecedingNonAttitudeSet(testCase)
            %End-to-end consequence of the length-keyed attitude cache.

            steeringModel = MockSteeringModel();
            bodyInfo = testCase.kerbin;

            insideAtmo = (bodyInfo.radius + bodyInfo.atmohgt / 2) * normVector([1; 0.2; 0.1]);
            vVect      = [0.05; 1.5; 0.1];

            clear TotalForceModel;
            testCase.callTotalForce([ForceModelsEnum.Gravity, ForceModelsEnum.Normal], ...
                insideAtmo, vVect, 10, bodyInfo, testCase.emptyThirdBodyState(), steeringModel);

            caughtError = '';
            try
                testCase.callTotalForce([ForceModelsEnum.Gravity, ForceModelsEnum.Drag], ...
                    insideAtmo, vVect, 10, bodyInfo, testCase.emptyThirdBodyState(), ...
                    steeringModel, testCase.buildAeroState());
            catch ME
                caughtError = ME.message;
            end

            testCase.verifyEmpty(caughtError, sprintf( ...
                ['Evaluating drag inside the atmosphere threw after a same-length ', ...
                 'force model set had primed the attitude cache: "%s"'], caughtError));
        end

        function forceModelEnumFlagsAreSelfConsistent(testCase)
            %Every enum member must carry a usable model object.

            [allModels, ~] = enumeration('ForceModelsEnum');

            for(i = 1:numel(allModels)) %#ok<*NO4LP>
                testCase.verifyTrue(isa(allModels(i).model, 'AbstractForceModel'), sprintf( ...
                    '%s does not hold an AbstractForceModel', allModels(i).name));

                testCase.verifyNotEmpty(allModels(i).name, ...
                    'A force model enum member has no display name');
            end

            % Gravity must never be disablable: it is the one force that
            % every propagator assumes is present.
            testCase.verifyFalse(ForceModelsEnum.Gravity.canBeDisabled, ...
                'Gravity is marked as disablable');
        end

        function secondOrderForceModelsDoNotDependOnVelocity(testCase)
            %Models allowed for the second-order propagator must be
            %functions of position only.
            %
            % SecondOrderGravOnlyPropagator.odefun passes vVect = [0;0;0]
            % because a second-order integrator has no velocity to give, so
            % any model flagged allowedForSecondOrder that actually reads
            % velocity would be silently wrong.

            [allModels, ~] = enumeration('ForceModelsEnum');
            secondOrderModels = allModels([allModels.allowedForSecondOrder]);

            bodyInfo = testCase.kerbin;
            rVect    = [900; 120; 60];
            mass     = 10;

            grav3Body = LaunchVehicle3BodyGravState();
            grav3Body.bodies      = testCase.mun;
            grav3Body.celBodyData = testCase.celBodyData;

            for(i = 1:numel(secondOrderModels))
                model = secondOrderModels(i).model;

                forceA = testCase.callForce(model, rVect, [0; 0; 0], mass, bodyInfo, grav3Body);
                forceB = testCase.callForce(model, rVect, [1; -2; 3], mass, bodyInfo, grav3Body);

                testCase.verifyVectorEqual(forceB, forceA, 1e-12 * max(norm(forceA), 1), sprintf( ...
                    ['%s is flagged allowedForSecondOrder but its force changed when ', ...
                     'the velocity changed; the second-order propagator always passes ', ...
                     'a zero velocity.'], secondOrderModels(i).name));
            end
        end
    end

    methods(Access=private)

        function [forceVect, tankMdots, ecStgDots] = callForce(testCase, model, rVect, vVect, mass, bodyInfo, grav3Body)
            %callForce Invokes a single force model with inert arguments.

            if(nargin < 7)
                grav3Body = testCase.emptyThirdBodyState();
            end

            [forceVect, tankMdots, ecStgDots] = model.getForce( ...
                0, rVect, vVect, mass, bodyInfo, ...
                [], [], [], [], [], [], [], [], grav3Body, [], [], ...
                LaunchVehicleAttitudeState(), []);
        end

        function forceVect = callThirdBody(testCase, grav3Body, rVect, mass, bodyInfo) %#ok<INUSD>
            %callThirdBody Invokes the third-body model.

            forceVect = Gravity3rdBodyForceModel().getForce( ...
                0, rVect, [0; 0; 0], mass, bodyInfo, ...
                [], [], [], [], [], [], [], [], grav3Body, [], [], [], []);
        end

        function forceVect = callTotalForce(testCase, fmEnums, rVect, vVect, mass, bodyInfo, grav3Body, steeringModel, aero) %#ok<INUSD>
            %callTotalForce Invokes the aggregate model.

            if(nargin < 8)
                steeringModel = MockSteeringModel();
            end

            if(nargin < 9)
                aero = [];
            end

            forceVect = TotalForceModel.getForce(fmEnums, 0, rVect, vVect, mass, bodyInfo, ...
                aero, [], steeringModel, [], [], [], [], [], grav3Body, [], [], []);
        end

        function grav3Body = emptyThirdBodyState(testCase)
            %emptyThirdBodyState A third-body state with no perturbing bodies.

            grav3Body = LaunchVehicle3BodyGravState();
            grav3Body.bodies      = KSPTOT_BodyInfo.empty(1, 0);
            grav3Body.celBodyData = testCase.celBodyData;
        end

        function rVect = aboveAtmospherePosition(testCase)
            %aboveAtmospherePosition Somewhere the drag model short-circuits.

            bodyInfo = testCase.kerbin;
            rVect = (bodyInfo.radius + bodyInfo.atmohgt + 100) * normVector([1; 0.3; 0.2]);
        end

        function aero = buildAeroState(testCase) %#ok<MANU>
            %buildAeroState A minimal aerodynamic state for drag evaluation.

            aero = LaunchVehicleAeroState();
        end
    end
end
