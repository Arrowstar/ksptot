classdef GenericTabularQuatInterpSteeringModel < AbstractSteeringModel
    %GenericTabularQuatInterpSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties         
        %initial state
        t0(1,1) double = 0;  
        gamma0(1,1) double = 0;
        beta0(1,1) double = 0;
        alpha0(1,1) double = 0;
        
        %other states
        tDurs(:,1) double {mustBeGreaterThan(tDurs,0)} = 1;
        gammaAngs(:,1) double = 0;
        betaAngs(:,1) double = 0;
        alphaAngs(:,1) double = 0;

        %quaterions
        initQuat(1,4) double = [1,0,0,0];
        quats(:,4) double = [1,0,0,0];

        %compute angle continuity from previous event
        angleContinuity(1,1) double = false;
        
        %frames
        refFrame AbstractReferenceFrame
        controlFrame AbstractControlFrame
    end
    
    methods       
        function dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect, bodyInfo)
            times = [obj.t0, obj.t0 + cumsum(obj.tDurs(:)')];
            obj.setQuatsByAngles();

            if(ut <= times(1))
                f = 0;
                q1 = obj.initQuat;
                q2 = obj.initQuat;

            elseif(ut >= times(end))
                f = 1;
                q1 = obj.quats(end,:);
                q2 = obj.quats(end,:);

            else
                ind = sum(ut >= times);
                t1 = times(ind);
                t2 = times(ind+1);
                f = ((ut - t1)/(t2-t1));

                q1 = obj.quats(ind,:);
                q2 = obj.quats(ind+1,:);
            end

            q = quatinterp(q1, q2, f);
            
            [alphaAng, betaAng, gammaAng] = quat2angle(q, 'ZYX');
            
            dcm = obj.controlFrame.computeDcmToInertialFrame(ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, obj.refFrame);
            dcm = real(dcm);
        end
               
        function angleCont = getContinuityTerms(obj)
            angleCont = obj.angleContinuity;
        end
        
        function setContinuityTerms(obj, angleContinuity)
            obj.angleContinuity = angleContinuity;
        end

        function t0 = getT0(obj)
            t0 = obj.t0;
        end
        
        function setT0(obj, newT0)
            obj.t0 = newT0;
        end
                
        function [gamma0, beta0, alpha0] = getInitAngles(obj)
            gamma0 = obj.gamma0;
            beta0 = obj.beta0;
            alpha0 = obj.alpha0;
        end

        function setInitAngles(obj, gamma0, beta0, alpha0)
            obj.gamma0 = gamma0;
            obj.beta0 = beta0;
            obj.alpha0 = alpha0;
        end

        function tDurs = getDurations(obj)
            tDurs = obj.tDurs;
        end

        function setDurations(obj, tDurs)
            obj.tDurs = tDurs;
        end
        
        function [gammaAngs, betaAngs, alphaAngs] = getSubsequentAngles(obj)
            gammaAngs = obj.gammaAngs;
            betaAngs = obj.betaAngs;
            alphaAngs = obj.alphaAngs;
        end
               
        function setSubsequentAngles(obj, gammaAngs, betaAngs, alphaAngs)
            obj.gammaAngs = gammaAngs;
            obj.betaAngs = betaAngs;
            obj.alphaAngs = alphaAngs;
        end
       
        function setConstsFromDcmAndContinuitySettings(obj, dcm, ut, rVect, vVect, bodyInfo)               
            if(obj.angleContinuity)
                elemSet = CartesianElementSet(ut, rVect(:), vVect(:), bodyInfo.getBodyCenteredInertialFrame());
                
                [gammaAngle, betaAngle, alphaAngle] = obj.controlFrame.getAnglesFromInertialBodyAxes(LaunchVehicleAttitudeState(dcm), elemSet.time, elemSet.rVect(:), elemSet.vVect(:), elemSet.frame.getOriginBody(), obj.refFrame);

                obj.alpha0 = alphaAngle;
                obj.beta0 = betaAngle;
                obj.gamma0 = gammaAngle;
            end
            
            obj.setQuatsByAngles();
        end
        
        function setInitialAttitudeFromState(obj, stateLogEntry, tOffsetDelta)
            %nothing
        end
        
        function [angle1Name, angle2Name, angle3Name] = getAngleNames(obj)
            angleNames = obj.controlFrame.getControlFrameEnum().angleNames;
            angle1Name = angleNames{1};
            angle2Name = angleNames{2};
            angle3Name = angleNames{3};
        end
        
        function newSteeringModel = deepCopy(obj)
            newSteeringModel = GenericTabularQuatInterpSteeringModel(obj.t0, obj.alpha0, obj.beta0, obj.gamma0, obj.tDurs, obj.alphaAngs, obj.betaAngs, obj.gammaAngs);

            newSteeringModel.angleContinuity = obj.angleContinuity;

            newSteeringModel.refFrame = obj.refFrame;
            newSteeringModel.controlFrame = obj.controlFrame;
        end
        
        function optVar = getNewOptVar(obj)
            optVar = SetGenericTabularQuatInterpSteeringModelActionOptimVar(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
            if(isempty(optVar))
                return;
            end

            % The table editor indexes the variable vectors by table row.
            % Models whose durations were assigned directly (or loaded from
            % older files) can have more rows than their variable, which
            % used to crash makeTableDataFromModel with "Index exceeds the
            % number of array elements". Grow (or shrink) the vectors to the
            % table size, preserving existing entries (same contract as
            % ThrottleInterpolatedModel.getExistingOptVar).
            numRows = numel(obj.tDurs);
            if(numel(optVar.varTDur) ~= numRows || ...
               numel(optVar.varGammaAngles) ~= numRows || ...
               numel(optVar.varBetaAngles) ~= numRows || ...
               numel(optVar.varAlphaAngles) ~= numRows || ...
               numel(optVar.lbTDur) ~= numRows || ...
               numel(optVar.lbGammaAngles) ~= numRows || ...
               numel(optVar.lbBetaAngles) ~= numRows || ...
               numel(optVar.lbAlphaAngles) ~= numRows || ...
               numel(optVar.ubTDur) ~= numRows || ...
               numel(optVar.ubGammaAngles) ~= numRows || ...
               numel(optVar.ubBetaAngles) ~= numRows || ...
               numel(optVar.ubAlphaAngles) ~= numRows)
                optVar.varTDur = GenericTabularQuatInterpSteeringModel.resizeVectorToNumRows(optVar.varTDur, numRows, false);
                optVar.varGammaAngles = GenericTabularQuatInterpSteeringModel.resizeVectorToNumRows(optVar.varGammaAngles, numRows, false);
                optVar.varBetaAngles = GenericTabularQuatInterpSteeringModel.resizeVectorToNumRows(optVar.varBetaAngles, numRows, false);
                optVar.varAlphaAngles = GenericTabularQuatInterpSteeringModel.resizeVectorToNumRows(optVar.varAlphaAngles, numRows, false);
                optVar.lbTDur = GenericTabularQuatInterpSteeringModel.resizeVectorToNumRows(optVar.lbTDur, numRows, 0);
                optVar.lbGammaAngles = GenericTabularQuatInterpSteeringModel.resizeVectorToNumRows(optVar.lbGammaAngles, numRows, -360);
                optVar.lbBetaAngles = GenericTabularQuatInterpSteeringModel.resizeVectorToNumRows(optVar.lbBetaAngles, numRows, -90);
                optVar.lbAlphaAngles = GenericTabularQuatInterpSteeringModel.resizeVectorToNumRows(optVar.lbAlphaAngles, numRows, -360);
                optVar.ubTDur = GenericTabularQuatInterpSteeringModel.resizeVectorToNumRows(optVar.ubTDur, numRows, 1);
                optVar.ubGammaAngles = GenericTabularQuatInterpSteeringModel.resizeVectorToNumRows(optVar.ubGammaAngles, numRows, 360);
                optVar.ubBetaAngles = GenericTabularQuatInterpSteeringModel.resizeVectorToNumRows(optVar.ubBetaAngles, numRows, 90);
                optVar.ubAlphaAngles = GenericTabularQuatInterpSteeringModel.resizeVectorToNumRows(optVar.ubAlphaAngles, numRows, 360);
            end
        end
        
        function tf = usesRefFrame(~)
            tf = true;
        end
        
        function refFrame = getRefFrame(obj)
            refFrame = obj.refFrame;
        end
        
        function setRefFrame(obj, refFrame)
            obj.refFrame = refFrame;
        end
        
        function tf = usesControlFrame(~)
            tf = true;
        end
        
        function cFrame = getControlFrame(obj)
            cFrame = obj.controlFrame;
        end
        
        function setControlFrame(obj, cFrame)
            obj.controlFrame = cFrame;
        end
        
        function tf = requiresReInitAfterSoIChange(obj)
            tf = false;
        end
        
        function enum = getSteeringModelTypeEnum(~)
            enum = SteerModelTypeEnum.TabularQuaterionInterp;
        end

        function [addActionTf, steeringModel] = openEditSteeringModelUI(obj, lv, useContinuity)
            output = AppDesignerGUIOutput({false, obj});
            lvd_EditActionSetTabularQuatInterpSteeringModelGUI_App(obj, lv, useContinuity, output);
            addActionTf = output.output{1};
            steeringModel = output.output{2};
        end
    end
    
    methods(Access=private)
        function obj = GenericTabularQuatInterpSteeringModel(t0, alpha0, beta0, gamma0, tDurs, alphaAngs, betaAngs, gammaAngs)
            %initial attitude
            obj.t0 = t0;           
            obj.alpha0 = alpha0;
            obj.beta0 = beta0;
            obj.gamma0 = gamma0;

            %Subsequent attitudes
            obj.tDurs = tDurs;
            obj.alphaAngs = alphaAngs;
            obj.betaAngs = betaAngs;
            obj.gammaAngs = gammaAngs;
            
            %set the relevant quaterions
            obj.setQuatsByAngles();
        end   
        
        function setQuatsByAngles(obj)
            obj.initQuat = angle2quat(obj.alpha0, obj.beta0, obj.gamma0, 'ZYX');
            obj.quats = [obj.initQuat; angle2quat(obj.alphaAngs, obj.betaAngs, obj.gammaAngs, 'ZYX')];
        end
    end
    
    methods(Static)
        function model = getDefaultSteeringModel() 
            t0 = 0;
            alpha0 = 0;
            beta0 = 0;
            gamma0 = 0;

            tDurs = 1;
            alphaAngs = 0;
            betaAngs = 0;
            gammaAngs = 0;
            
            model = GenericTabularQuatInterpSteeringModel(t0, alpha0, beta0, gamma0, tDurs, alphaAngs, betaAngs, gammaAngs);
        end
        
        function typeStr = getTypeNameStr()
            typeStr = SteeringModelEnum.GenericTabularQuatInterp.nameStr;
        end

        function resized = resizeVectorToNumRows(vec, numRows, padValue)
            %resizeVectorToNumRows Grow or shrink a per-row variable vector,
            % preserving overlapping entries and padding with padValue.
            % (Same contract as ThrottleInterpolatedModel.resizeVectorToNumRows.)
            vec = vec(:);
            numExisting = numel(vec);
            if(numExisting == numRows)
                resized = vec;
            elseif(numExisting > numRows)
                resized = vec(1:numRows, :);
            else
                if(islogical(padValue) || islogical(vec))
                    resized = false(numRows, 1);
                elseif(isa(vec, 'double'))
                    resized = zeros(numRows, 1);
                else
                    resized = repmat(vec(1), numRows, 1);
                end
                resized(1:numExisting, :) = vec;
                if(numRows > numExisting)
                    resized(numExisting+1:end, :) = padValue;
                end
            end
            if(islogical(vec) || islogical(padValue))
                resized = logical(resized);
            end
        end
    end
end