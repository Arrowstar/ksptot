classdef GenericQuatInterpSteeringModel < AbstractSteeringModel
    %GenericQuatInterpSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties              
        t0(1,1) double = 0;
        tDur(1,1) double = 0;
        
        alpha0(1,1) double = 0;
        beta0(1,1) double = 0;
        gamma0(1,1) double = 0;
        
        alpha1(1,1) double = 0;
        beta1(1,1) double = 0;
        gamma1(1,1) double = 0;
        
        initQuat(1,4) double = [1,0,0,0];
        finalQuat(1,4) double = [1,0,0,0];
        
        angleContinuity(1,1) double = false;
        
        refFrame AbstractReferenceFrame
        controlFrame AbstractControlFrame
    end
    
    methods       
        function dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect, bodyInfo)
            if(obj.tDur > 0)
                if(ut < obj.t0)
                    f = 0;
                elseif(ut > (obj.t0 + obj.tDur))
                    f = 1;
                else
                    f = ((ut - obj.t0)/(obj.tDur));
                    
                    if(f > 1)
                        f = 1;
                    elseif(f < 0)
                        f = 0;
                    end
                end

                q = quatinterp(obj.initQuat, obj.finalQuat, f);
            else
                q = obj.initQuat;
            end
            
%             elemSet = CartesianElementSet(ut, rVect(:), vVect(:), bodyInfo.getBodyCenteredInertialFrame());
%             if(not(isempty(obj.refFrame.getOriginBody())))
%                 elemSet = elemSet.convertToFrame(obj.refFrame);
%             end
            
            [alphaAng, betaAng, gammaAng] = quat2angle(q, 'ZYX');
            
            dcm = obj.controlFrame.computeDcmToInertialFrame(ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, obj.refFrame);
            dcm = real(dcm);
        end
        
        function t0 = getT0(obj)
            t0 = obj.t0;
        end
        
        function setT0(obj, newT0)
            obj.t0 = newT0;
        end
        
        function angleCont = getContinuityTerms(obj)
            angleCont = obj.angleContinuity;
        end
        
        function setContinuityTerms(obj, angleContinuity)
            obj.angleContinuity = angleContinuity;
        end
        
        function tDur = getDuration(obj)
            tDur = obj.tDur;
        end
        
        function setDuration(obj, tDur)
            obj.tDur = tDur;
        end
        
        function [gamma0, beta0, alpha0] = getInitAngles(obj)
            gamma0 = obj.gamma0;
            beta0 = obj.beta0;
            alpha0 = obj.alpha0;
        end
        
        function [gamma1, beta1, alpha1] = getFinalAngles(obj)
            gamma1 = obj.gamma1;
            beta1 = obj.beta1;
            alpha1 = obj.alpha1;
        end
        
        function setInitAngles(obj, gamma0, beta0, alpha0)
            obj.gamma0 = gamma0;
            obj.beta0 = beta0;
            obj.alpha0 = alpha0;
        end
        
        function setFinalAngles(obj, gamma1, beta1, alpha1)
            obj.gamma1 = gamma1;
            obj.beta1 = beta1;
            obj.alpha1 = alpha1;
        end
        
        function setConstsFromDcmAndContinuitySettings(obj, dcm, ut, rVect, vVect, bodyInfo)               
            if(obj.angleContinuity)
                elemSet = CartesianElementSet(ut, rVect(:), vVect(:), bodyInfo.getBodyCenteredInertialFrame());

%                 if(not(isempty(obj.refFrame.getOriginBody())))
%                     elemSet = elemSet.convertToFrame(obj.refFrame);
%                 end
                
                [gammaAngle, betaAngle, alphaAngle] = obj.controlFrame.getAnglesFromInertialBodyAxes(LaunchVehicleAttitudeState(dcm), elemSet.time, elemSet.rVect(:), elemSet.vVect(:), elemSet.frame.getOriginBody(), obj.refFrame);

                obj.alpha0 = alphaAngle;
                obj.beta0 = betaAngle;
                obj.gamma0 = gammaAngle;
            end
            
            obj.setQuatsByAngles(); %need this here because I need to initialize the quaternions correctly from the angles at action init
        end
        
        function setInitialAttitudeFromState(obj, stateLogEntry, tOffsetDelta)
            %nothing
        end
        
        function [angle1Name, angle2Name, angle3Name] = getAngleNames(obj)
%             angle1Name = 'Gamma';
%             angle2Name = 'Beta';
%             angle3Name = 'Alpha';

            angleNames = obj.controlFrame.getControlFrameEnum().angleNames;
            angle1Name = angleNames{1};
            angle2Name = angleNames{2};
            angle3Name = angleNames{3};
        end
        
        function newSteeringModel = deepCopy(obj)
            newSteeringModel = GenericQuatInterpSteeringModel(obj.t0, obj.tDur, obj.alpha0, obj.beta0, obj.gamma0, obj.alpha1, obj.beta1, obj.gamma1);

            newSteeringModel.angleContinuity = obj.angleContinuity;

            newSteeringModel.refFrame = obj.refFrame;
            newSteeringModel.controlFrame = obj.controlFrame;
        end
        
        function optVar = getNewOptVar(obj)
            optVar = SetGenericQuatInterpSteeringModelActionOptimVar(obj);
        end
        
        function optVar = getExistingOptVar(obj)
            optVar = obj.optVar;
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
            enum = SteerModelTypeEnum.QuaterionInterp;
        end
    end
    
    methods(Access=private)
        function obj = GenericQuatInterpSteeringModel(t0, tDur, alpha0, beta0, gamma0, alpha1, beta1, gamma1)
            obj.t0 = t0;
            obj.tDur = tDur;
            
            obj.alpha0 = alpha0;
            obj.beta0 = beta0;
            obj.gamma0 = gamma0;
            
            obj.alpha1 = alpha1;
            obj.beta1 = beta1;
            obj.gamma1 = gamma1;
            
            obj.setQuatsByAngles();
        end   
        
        function setQuatsByAngles(obj)
            obj.initQuat = angle2quat(obj.alpha0, obj.beta0, obj.gamma0, 'ZYX');
            obj.finalQuat = angle2quat(obj.alpha1, obj.beta1, obj.gamma1, 'ZYX');
        end
    end
    
    methods(Static)
        function model = getDefaultSteeringModel() 
            t0 = 0;
            tDur = 1;

            alpha0 = 0;
            beta0 = 0;
            gamma0 = 0;
            
            alpha1 = 0;
            beta1 = 0;
            gamma1 = 0;
            
            model = GenericQuatInterpSteeringModel(t0, tDur, alpha0, beta0, gamma0, alpha1, beta1, gamma1);
        end
        
        function typeStr = getTypeNameStr()
            typeStr = SteeringModelEnum.GenericQuatInterp.nameStr;
        end
    end
end