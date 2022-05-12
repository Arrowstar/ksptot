classdef LaunchVehicleAttitudeState < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dcm(3,3) double = eye(3)
    end

    properties(Dependent)
        bodyX
        bodyY
        bodyZ
    end
    
    methods
        function obj = LaunchVehicleAttitudeState(dcm)
            if(nargin >= 1)
                obj.dcm = dcm;
            end
        end

        function value = get.bodyX(obj)
            value = obj.dcm(:,1);
        end

        function value = get.bodyY(obj)
            value = obj.dcm(:,2);
        end

        function value = get.bodyZ(obj)
            value = obj.dcm(:,3);
        end

        function [gammaAngle, betaAngle, alphaAngle] = getEulerAnglesInBaseFrame(obj, ut, rVect, vVect, bodyInfo, inFrame)
            arguments
                obj(1,1) LaunchVehicleAttitudeState
                ut(1,1) double
                rVect(3,1) double
                vVect(3,1) double
                bodyInfo(1,1) KSPTOT_BodyInfo
                inFrame(1,1) AbstractReferenceFrame
            end

            frame = bodyInfo.getBodyCenteredInertialFrame();
            ce = CartesianElementSet(ut, rVect, vVect, frame);

%             [~, ~, ~, base_frame_2_inertial] = inFrame.getOffsetsWrtInertialOrigin(ut, ce);
            base_frame_2_inertial = inFrame.getRotMatToInertialAtTime(ut, ce, []);
        
            angles = real(rotm2eulARH(base_frame_2_inertial' * obj.dcm, 'zyx'));
        
            gammaAngle = angles(3);
            betaAngle = angles(2);
            alphaAngle = angles(1);
        end
        
        function [rollAngle, pitchAngle, yawAngle] = getEulerAngles(obj, ut, rVect, vVect, bodyInfo)  
            arguments
                obj(1,1) LaunchVehicleAttitudeState
                ut(1,1) double
                rVect(3,1) double
                vVect(3,1) double
                bodyInfo(1,1) KSPTOT_BodyInfo
            end

            inFrame = bodyInfo.getBodyFixedFrame();
            [rollAngle, pitchAngle, yawAngle] = obj.getEulerAnglesInFrame(ut, rVect, vVect, bodyInfo, inFrame);
        end
        
        function [rollAngle, pitchAngle, yawAngle] = getEulerAnglesInFrame(obj, ut, rVect, vVect, bodyInfo, inFrame)  
            arguments
                obj(1,1) LaunchVehicleAttitudeState
                ut(1,1) double
                rVect(3,1) double
                vVect(3,1) double
                bodyInfo(1,1) KSPTOT_BodyInfo
                inFrame(1,1) AbstractReferenceFrame
            end

            frame = bodyInfo.getBodyCenteredInertialFrame();
            ce = CartesianElementSet(ut, rVect, vVect, frame);
            ce = ce.convertToFrame(inFrame, true);
            rVectFrame = ce.rVect;

            [~, ~, ~, R_1_to_inert] = frame.getOffsetsWrtInertialOrigin(ut,[]);
            [~, ~, ~, R_2_to_inert] = inFrame.getOffsetsWrtInertialOrigin(ut,[]);
            R_1_to_2 = R_2_to_inert' * R_1_to_inert;

            bodyXFrame = R_1_to_2 * obj.bodyX;
            bodyYFrame = R_1_to_2 * obj.bodyY;
            bodyZFrame = R_1_to_2 * obj.bodyZ;

            [rollAngle, pitchAngle, yawAngle] = computeEulerAnglesFromFrameBodyAxes(rVectFrame, bodyXFrame, bodyYFrame, bodyZFrame);
            rollAngle = AngleZero2Pi(rollAngle);
            yawAngle = AngleZero2Pi(yawAngle);
        end

        function [bankAng,angOfAttack,angOfSideslip,totalAoA] = getAeroAngles(obj, ut, rVect, vVect, bodyInfo)    
            arguments
                obj(1,1) LaunchVehicleAttitudeState
                ut(1,1) double
                rVect(3,1) double
                vVect(3,1) double
                bodyInfo(1,1) KSPTOT_BodyInfo
            end
            inFrame = bodyInfo.getBodyFixedFrame();
            [bankAng,angOfAttack,angOfSideslip,totalAoA] = obj.getAeroAnglesInFrame(ut, rVect, vVect, bodyInfo, inFrame);
        end

        function [bankAng,angOfAttack,angOfSideslip,totalAoA] = getAeroAnglesInFrame(obj, ut, rVect, vVect, bodyInfo, inFrame)            
            arguments
                obj(1,1) LaunchVehicleAttitudeState
                ut(1,1) double
                rVect(3,1) double
                vVect(3,1) double
                bodyInfo(1,1) KSPTOT_BodyInfo
                inFrame(1,1) AbstractReferenceFrame
            end

            frame = bodyInfo.getBodyCenteredInertialFrame();
            ce = CartesianElementSet(ut, rVect, vVect, frame);
            ce = ce.convertToFrame(inFrame, true);
            rVectFrame = ce.rVect;
            vVectFrame = ce.vVect;

%             [~, ~, ~, R_1_to_inert] = frame.getOffsetsWrtInertialOrigin(ut,[]);
%             [~, ~, ~, R_2_to_inert] = inFrame.getOffsetsWrtInertialOrigin(ut,[]);

            R_1_to_inert = frame.getRotMatToInertialAtTime(ut,[],[]);
            R_2_to_inert = inFrame.getRotMatToInertialAtTime(ut,[],[]);

            R_1_to_2 = R_2_to_inert' * R_1_to_inert;

            bodyXFrame = R_1_to_2 * obj.bodyX;
            bodyYFrame = R_1_to_2 * obj.bodyY;
            bodyZFrame = R_1_to_2 * obj.bodyZ;

            [bankAng,angOfAttack,angOfSideslip,totalAoA] = computeAeroAnglesFromFrameBodyAxes(rVectFrame, vVectFrame, bodyXFrame, bodyYFrame, bodyZFrame);
            bankAng = AngleZero2Pi(bankAng);
            angOfSideslip = AngleZero2Pi(angOfSideslip);
        end
        
        function [inertBankAng,inertAngOfAttack,insertAngOfSideslip] = getInertialAeroAngles(obj, ut, rVect, vVect, bodyInfo)       
            arguments
                obj(1,1) LaunchVehicleAttitudeState
                ut(1,1) double
                rVect(3,1) double
                vVect(3,1) double
                bodyInfo(1,1) KSPTOT_BodyInfo
            end
            inFrame = bodyInfo.getBodyCenteredInertialFrame();
            [inertBankAng,inertAngOfAttack,insertAngOfSideslip,~] = obj.getAeroAnglesInFrame(ut, rVect, vVect, bodyInfo, inFrame);
        end
        
        function newAttState = deepCopy(obj)
            newAttState = LaunchVehicleAttitudeState();
            newAttState.dcm = obj.dcm;
        end
    end
end