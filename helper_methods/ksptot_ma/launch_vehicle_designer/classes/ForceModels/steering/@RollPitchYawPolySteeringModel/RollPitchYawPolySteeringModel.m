classdef RollPitchYawPolySteeringModel < AbstractSteeringModel
    %RollPitchYawSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rollModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        pitchModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        yawModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
    end
    
    methods       
        function dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect)
            rollAng = obj.rollModel.getValueAtTime(ut);
            pitchAng = obj.pitchModel.getValueAtTime(ut);
            yawAng = obj.yawModel.getValueAtTime(ut);
            
            [~, ~, ~, dcm] = computeBodyAxesFromEuler(rVect, vVect, rollAng, pitchAng, yawAng);
        end
    end
    
    methods(Access=private)
        function obj = RollPitchYawPolySteeringModel(rollModel, pitchModel, yawModel)
            obj.rollModel = rollModel;
            obj.pitchModel = pitchModel;
            obj.yawModel = yawModel;
        end        
    end
    
    methods(Static)
        function model = getDefaultSteeringModel()
            rollModel = PolynominalModel(0,0,0,0);
            pitchModel = PolynominalModel(0,deg2rad(-90),deg2rad(0.99),0);
            yawModel = PolynominalModel(0,0,0,0);
            
            model = RollPitchYawPolySteeringModel(rollModel, pitchModel, yawModel);
        end
    end
end