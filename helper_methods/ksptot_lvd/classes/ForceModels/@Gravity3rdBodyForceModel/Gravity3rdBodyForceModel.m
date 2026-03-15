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
        
        function [forceVect, tankMdots, ecStgDots] = getForce(obj, ut, rVectSC, vVectSC, mass, bodySC, ~, ~, ~, ~, ~, ~, ~, ~, grav3Body, ~, ~, ~, ~, altitude, pressure, density)      
            persistent cache;
            if(isempty(cache))
                cache.ut = NaN;
                cache.rVectSC = [NaN;NaN;NaN];
                cache.bodySC = KSPTOT_BodyInfo.empty(0,1);
                cache.grav3Body = LaunchVehicle3BodyGravState.empty(0,1);
                cache.accelVect = [0;0;0];
                
                cache.term2Ut = NaN;
                cache.term2BodySC = KSPTOT_BodyInfo.empty(0,1);
                cache.term2Grav3Body = LaunchVehicle3BodyGravState.empty(0,1);
                cache.term2Sum = [0;0;0];
            end

            if(ut == cache.ut && all(rVectSC == cache.rVectSC) && bodySC == cache.bodySC && grav3Body == cache.grav3Body)
                forceVect = mass * cache.accelVect;
                tankMdots = [];
                ecStgDots = [];
                return;
            end

            bodyScFrame = bodySC.getBodyCenteredInertialFrame();
            bodyScFrameOriginChain = bodyScFrame.getOriginBody().getOrbitElemsChain();
            
            bodies = grav3Body.bodies;
            bodies = bodies(bodies ~= bodySC);
            bodySCChain = bodySC.getOrbitElemsChain();

            if(ut == cache.term2Ut && bodySC == cache.term2BodySC && grav3Body == cache.term2Grav3Body)
                term2Sum = cache.term2Sum;
            else
                term2Sum = [0;0;0];
                for(i=1:length(bodies))
                    bodyInfoJ = bodies(i);
                    bodyInfoJChain = bodyInfoJ.getOrbitElemsChain();
                    
                    r_1_to_j = getAbsPositBetweenSpacecraftAndBody_fast_mex(ut, [0;0;0], bodyScFrameOriginChain, bodyInfoJChain, NaN(3,1));
                    
                    if(norm(r_1_to_j) > 0)
                        term2Sum = term2Sum + bodyInfoJ.gm * (r_1_to_j/norm(r_1_to_j)^3);
                    end
                end
                cache.term2Ut = ut;
                cache.term2BodySC = bodySC;
                cache.term2Grav3Body = grav3Body;
                cache.term2Sum = term2Sum;
            end
            
            accelVect = [0;0;0]; 
            for(i=1:length(bodies)) %#ok<*NO4LP> 
                bodyInfoJ = bodies(i);
                bodyInfoJChain = bodyInfoJ.getOrbitElemsChain();

                r_sat_to_j = getAbsPositBetweenSpacecraftAndBody_fast_mex(ut, rVectSC, bodySCChain, bodyInfoJChain, NaN(size(rVectSC)));

                if(norm(r_sat_to_j) > 0)
                    accelVect = accelVect + bodyInfoJ.gm * (r_sat_to_j/norm(r_sat_to_j)^3);
                end
            end
            accelVect = accelVect - term2Sum;
            
            cache.ut = ut;
            cache.rVectSC = rVectSC;
            cache.bodySC = bodySC;
            cache.grav3Body = grav3Body;
            cache.accelVect = accelVect;

            forceVect = mass * accelVect;
            tankMdots = [];
            ecStgDots = [];
        end
    end
end