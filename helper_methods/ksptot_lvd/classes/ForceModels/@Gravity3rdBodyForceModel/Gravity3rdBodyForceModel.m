classdef Gravity3rdBodyForceModel < AbstractForceModel
    %Gravity3rdBodyForceModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        cartElemSCObj CartesianElementSet = CartesianElementSet.getDefaultElements();
        cartElemSCBodyObj CartesianElementSet = CartesianElementSet.getDefaultElements();
    end
    
    methods
        function obj = Gravity3rdBodyForceModel()
            
        end
        
        function [forceVect, tankMdots, ecStgDots] = getForce(obj, ut, rVectSC, vVectSC, mass, bodySC, ~, ~, ~, ~, ~, ~, ~, ~, grav3Body, ~, ~, ~, ~)
            persistent cachedGrav3BodyId cachedGrav3ScChain cachedGrav3OriChain cachedGrav3BodyChains cachedGrav3NumBodies

            bodies = grav3Body.bodies;
            bodies = bodies(bodies ~= bodySC);

            % Cache orbit element chains — they describe the fixed celestial body hierarchy and
            % never change during a session. Invalidate when the central body or body count changes.
            if(isempty(cachedGrav3BodyId) || cachedGrav3BodyId ~= bodySC.id || numel(bodies) ~= cachedGrav3NumBodies)
                cachedGrav3BodyId    = bodySC.id;
                cachedGrav3NumBodies = numel(bodies);
                bodyScFrame          = bodySC.getBodyCenteredInertialFrame();
                cachedGrav3ScChain   = bodySC.getOrbitElemsChain();
                cachedGrav3OriChain  = bodyScFrame.getOriginBody().getOrbitElemsChain();
                cachedGrav3BodyChains = cell(1, numel(bodies));
                for(k=1:numel(bodies)) %#ok<*NO4LP>
                    cachedGrav3BodyChains{k} = bodies(k).getOrbitElemsChain();
                end
            end

            forceVect = [0;0;0];
            for(i=1:length(bodies)) %#ok<*NO4LP>
                bodyInfoJ = bodies(i);
                bodyInfoJChain = cachedGrav3BodyChains{i};

                % [r_sat_to_j,~] = getAbsPositBetweenSpacecraftAndBody(ut, rVectSC, bodySC, bodyInfoJ, bodyInfoJ.celBodyData);
                r_sat_to_j =          getAbsPositBetweenSpacecraftAndBody_fast_mex(ut, rVectSC, cachedGrav3ScChain, bodyInfoJChain, NaN(size(rVectSC)));

                % [r_1_to_j,~] = getAbsPositBetweenSpacecraftAndBody(ut, [0;0;0], bodyScFrame.getOriginBody(), bodyInfoJ, bodyInfoJ.celBodyData);
                r_1_to_j =          getAbsPositBetweenSpacecraftAndBody_fast_mex(ut, [0;0;0], cachedGrav3OriChain, bodyInfoJChain, NaN(3,1));

                if(norm(r_sat_to_j) > 0)
                    term1 = r_sat_to_j/norm(r_sat_to_j)^3;  %km/km^3 = km^-2
                else
                    term1 = 0;
                end

                if(norm(r_1_to_j) > 0)
                    term2 = r_1_to_j/norm(r_1_to_j)^3;      %km/km^3 = km^-2
                else
                    term2 = 0;
                end

                accel = bodyInfoJ.gm * (term1 - term2); %km^3/s^2 * km^-2 = km/s^2
                forceVect = forceVect + mass * accel; %mT * km/s^2 = km*mT/s^2
            end
            
            tankMdots = [];
            ecStgDots = [];
        end
    end
end