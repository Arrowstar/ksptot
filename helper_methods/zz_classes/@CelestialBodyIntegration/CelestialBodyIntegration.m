classdef CelestialBodyIntegration
    %CelestialBodyIntegration Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        celBodyData CelestialBodyData
    end
    
    methods
        function obj = CelestialBodyIntegration(celBodyData)
            obj.celBodyData = celBodyData;
        end
        
        function integrateCelestialBodies(obj, minUT, maxUT)         
%             allBodies = obj.celBodyData.getAllBodyInfo();
            [~, allBodiesCell] = ma_getSortedBodyNames(obj.celBodyData);
            
            for(i=1:length(allBodiesCell))
                allBodies(i) = allBodiesCell{i}; %#ok<AGROW>
            end
            
            bool = [allBodies.propTypeEnum] == BodyPropagationTypeEnum.Numerical;
            if(any(bool))
                hFig = uifigure('Position',[0,0,400,125], 'WindowStyle','modal', 'Icon','logoSquare_48px_transparentBg.png');
                centerUIFigure(hFig);
                hWaitbar = uiprogressdlg(hFig, 'Title','Integrating Trajectories', ...
                                        'Message', 'Creating trajectory databases for numerically integrated celestial bodies.  Please wait.', ...
                                        'Indeterminate','on');
                drawnow;
                
                numericBodies = allBodies(bool);
                numericInds = 1:sum(bool);
                
                analyticBodies = allBodies(not(bool));
                analyticInds = 1:sum(not(bool));
                
                epochs = [numericBodies.epoch];
                if(numel(unique(epochs)) == 1)
                    t0 = unique(epochs);
                    
                    [y0, numericMasses] = CelestialBodyIntegration.getInitialStates(numericBodies);                   
                    if(t0 > minUT)
                        [T,Y,~] = obj.callIntegrator(numericBodies, numericMasses, numericInds, analyticBodies, analyticInds, t0, minUT, y0, hWaitbar);
                        
                        t0 = T(end);
                        y0 = Y(end,:);
                    end    
                    
                    [T,~,YY] = obj.callIntegrator(numericBodies, numericMasses, numericInds, analyticBodies, analyticInds, t0, maxUT, y0, hWaitbar);
                    
                    hWaitbar.Message = 'Performing frame rotations on computed states.  Please wait.';
                    hWaitbar.Value = 0;
                    hWaitbar.Indeterminate = 'off';
                                        
                    for(i=1:size(YY,3))
                        bodyInfo = numericBodies(i);
                        states = YY(:,:,i);
                        
                        times = T;  
                        rVects = states(:,1:3)';
                        vVects = states(:,4:6)';
                        cartElem = CartesianElementSet(times, rVects, vVects, obj.celBodyData.globalBaseFrame, true);
                        
                        if(not(isempty(bodyInfo.getParBodyInfo(obj.celBodyData))))
                            parentBody = bodyInfo.getParBodyInfo(obj.celBodyData);
                            convertFrame = parentBody.getBodyCenteredInertialFrame();

                        else
                            convertFrame = obj.celBodyData.globalBaseFrame;
                        end
                        
                        cartElem = convertToFrame(cartElem, convertFrame);
                        
                        times = [cartElem.time]';
                        rVects = [cartElem.rVect];
                        vVects = [cartElem.vVect]; 
                        states = vertcat(rVects, vVects)';
                        bodyInfo.setStateCacheData(times, states, convertFrame);
                        
                        hWaitbar.Value = i/size(YY,3);
                    end
                else
                    error('All bodies must be defined with the same orbit epoch.');
                end
                
                if(isvalid(hFig))
                    close(hFig);
                end
            end
        end
    end
    
    methods(Access=private)
        function [T,Y,YY] = callIntegrator(obj, numericBodies, numericMasses, numericInds, analyticBodies, analyticInds, t0, tf, y0, hWaitbar)
            numPts = length(numericBodies);
            
            ptCombsNum = getPtsCombs(numericInds, numericInds, true);
            ptCombsAnalytic = getPtsCombs(numericInds, analyticInds, false);

            massesAnalytic = [analyticBodies.gm];
            
            odefcn = @(t,y) odefun(t,y, numericMasses, numPts, ptCombsNum, massesAnalytic, ptCombsAnalytic, analyticBodies, obj.celBodyData);
            options = odeset('AbsTol',1E-10, 'RelTol',1E-6, ...
                             'OutputFcn',@(t,y,flag) outputFcn(t,y,flag, t0, tf, hWaitbar)); %'Events',@(t,y) myEventsFcn(t,y, numPts, masses, density, ptCombs), 
                                                                             %'OutputFcn',@(t,y,flag) myOutputFcn(t,y,flag), ...

            tspan = [t0 tf];
            [T,Y] = ode113(odefcn, tspan, y0, options);
            
            YY = reshape(Y, size(Y,1), size(Y,2)/numPts, numPts);
        end
    end
    
    methods(Static, Access=private)
        function [y0, masses] = getInitialStates(bodies)            
            rVects = NaN(3, length(bodies));
            vVects = rVects;
            masses = NaN(1, length(bodies));
            for(i=1:length(bodies))
                bodyInfo = bodies(i);

                [rVectB, vVectB] = getPositOfBodyWRTSun(bodyInfo.epoch, bodyInfo, bodyInfo.celBodyData);
                rVects(:,i) = rVectB(:);
                vVects(:,i) = vVectB(:);
                masses(i) = bodyInfo.gm;
            end

            states = [rVects;vVects];
            y0 = states(:);
        end
    end
end

function ydot = odefun(t,y, masses, numPtsNumeric, ptCombsNumeric, massesAnalytic, ptCombsAnalytic, analyticBodies, celBodyData)
    %Gravity from numerically propagated bodies
    states = reshape(y, 6, numPtsNumeric);
    rVects = states(1:3,:);
    vVects = states(4:6,:);
    
    ydot = NaN(size(states));
    ydot(1:3,:) = vVects;
    
    rDiffs = rVects(:, ptCombsNumeric(2,:)) - rVects(:, ptCombsNumeric(1,:));
    rDiffMags = sqrt(sum((rDiffs.^2), 1));
    
    massProducts = masses(ptCombsNumeric(2,:));
    
    fVectMag = (massProducts ./ (rDiffMags.^3));
    accelVects = bsxfun(@times, fVectMag, rDiffs);
    
    accelVects = reshape(accelVects, [3, size(accelVects,2)/numPtsNumeric, numPtsNumeric]);
    accelVectsTotalNumeric = sum(accelVects,2);
    accelVectsTotalNumeric = reshape(accelVectsTotalNumeric,[3,numPtsNumeric]);

    %Gravity from analytic propagated bodies
    if(not(isempty(massesAnalytic)))
        rVectAnalytic = NaN(3,numel(analyticBodies));
        for(i=1:length(analyticBodies))
            rVectAnalytic(:,i) = getPositOfBodyWRTSun(t, analyticBodies(i), celBodyData);
        end

        rDiffs = -1*(rVects(:, ptCombsAnalytic(2,:)) - rVectAnalytic(:, ptCombsAnalytic(1,:)));
        rDiffMags = sqrt(sum((rDiffs.^2), 1));

        massProducts = massesAnalytic(ptCombsAnalytic(1,:));

        fVectMag = (massProducts ./ (rDiffMags.^3));
        accelVects = bsxfun(@times, fVectMag, rDiffs);

        accelVectsTotalAnalytic = NaN([3, numPtsNumeric]);
        for(i=1:numPtsNumeric)
            accelVectsTotalAnalytic(:,i) = sum(accelVects(:, ptCombsAnalytic(2,:) == i), 2);
        end
    else
        accelVectsTotalAnalytic = zeros(size(accelVectsTotalNumeric));
    end
    
    %Sum up inputs
    accelVectsTotal = accelVectsTotalNumeric + accelVectsTotalAnalytic;
    ydot(4:6,:) = accelVectsTotal; %a = F/m 
    ydot = ydot(:);
end

%% Output function (for fun)
function status = outputFcn(t,~,flag, t0, tf, hWaitbar)
%     if(isempty(flag))
%         tPercent = (t-t0)/(tf-t0);
%         hWaitbar.Value = tPercent;
%     end
    status = 0;
end

%% Utility function(s)
function ptCombs = getPtsCombs(ptInds1, ptInd2, removeDups)
    ptCombs = combvec(ptInds1,ptInd2);
    
    if(removeDups)
        ptCombs(:, ptCombs(1,:) == ptCombs(2,:)) = []; %eliminate duplicates
    end
    
    A = ptCombs(1,:);
    B = ptCombs(2,:);
    ptCombs = [B;A];
end