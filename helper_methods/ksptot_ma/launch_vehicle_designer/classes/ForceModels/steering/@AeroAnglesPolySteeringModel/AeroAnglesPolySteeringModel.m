classdef AeroAnglesPolySteeringModel < AbstractSteeringModel
    %RollPitchYawSteeringModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bankModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        aoAModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
        slipModel(1,1) PolynominalModel = PolynominalModel(0,0,0,0);
    end
    
    methods       
        function dcm = getBody2InertialDcmAtTime(obj, ut, rVect, vVect)
            bankAng = obj.bankModel.getValueAtTime(ut);
            angOfAttack = obj.aoAModel.getValueAtTime(ut);
            angOfSideslip = obj.slipModel.getValueAtTime(ut);
            
            [~, ~, ~, dcm] = computeBodyAxesFromAeroAngles(rVect, vVect, angOfAttack, angOfSideslip, bankAng);
        end
        
        function setT0(obj, newT0)
            obj.bankModel.t0 = newT0;
            obj.aoAModel.t0 = newT0;
            obj.slipModel.t0 = newT0;
        end
        
        function setConstTerms(obj, bankConst, aoaConst, slipConst)
            obj.bankModel.constTerm = bankConst;
            obj.aoAModel.constTerm = aoaConst;
            obj.slipModel.constTerm = slipConst;
        end
    end
    
    methods(Access=private)
        function obj = AeroAnglesPolySteeringModel(bankModel, aoAModel, slipModel)
            obj.bankModel = bankModel;
            obj.aoAModel = aoAModel;
            obj.slipModel = slipModel;
        end        
    end
    
    methods(Static)
        function model = getDefaultSteeringModel()
            bankModel = PolynominalModel(0,0,0,0);
            aoAModel = PolynominalModel(0,0,0,0);
            slipModel = PolynominalModel(0,0,0,0);
            
            model = AeroAnglesPolySteeringModel(bankModel, aoAModel, slipModel);
        end
    end
end