classdef NomadSurrogateOptions < matlab.mixin.SetGet
    %NomadSurrogateOptions Summary of this class goes here
    %   See: https://nomad-4-user-guide.readthedocs.io/en/latest/SgteLib.html

    properties
        stge_model_search(1,1) logical = false;
        type(1,1) NomadSurrogateModelTypeEnum = NomadSurrogateModelTypeEnum.LOWESS;

        degree(1,1) double {mustBeInteger(degree), mustBeGreaterThanOrEqual(degree, 1)} = 5;
        degree_optim(1,1) logical = true;

        ridge(1,1) double {mustBeGreaterThanOrEqual(ridge, 0)} = 0.001;
        ridge_optim(1,1) logical = true;

        kernel_type(1,1) NomadSurrogateKernelTypeEnum = NomadSurrogateKernelTypeEnum.D1;
        kernel_type_optim(1,1) logical = true;

        kernel_shape(1,1) double {mustBeGreaterThanOrEqual(kernel_shape, 0)} = 1;
        kernel_shape_optim(1,1) logical = true;

        distance_type(1,1) NomadSurrogateDistanceTypeEnum = NomadSurrogateDistanceTypeEnum.NORM2;
        distance_optim(1,1) logical = true;

        weight(1,1) NomadSurrogateWeightTypeEnum = NomadSurrogateWeightTypeEnum.SELECT;
        uncertainty(1,1) NomadSurrogateUncertaintyTypeEnum = NomadSurrogateUncertaintyTypeEnum.SMOOTH;
        size_param(1,1) double {mustBeGreaterThanOrEqual(size_param,0)} = 0.001;
        sigma_mult(1,1) double {mustBeGreaterThanOrEqual(sigma_mult,0)} = 10;
        lambda_p(1,1) double {mustBeGreaterThanOrEqual(lambda_p,0)} = 3;
        lambda_pi(1,1) double {mustBeGreaterThanOrEqual(lambda_pi,0)} = 0.1;

        metric(1,1) NomadSurrogateMetricTypeEnum = NomadSurrogateMetricTypeEnum.AOECV;

        budget(1,1) double {mustBeInteger(budget), mustBeGreaterThanOrEqual(budget, 5)} = 100;
    end

    methods
        function obj = NomadSurrogateOptions()

        end

        function modelDefStr = getSurrogateModelDefinitionString(obj)
            if(obj.degree_optim)
                degreeStr = "OPTIM";
            else
                degreeStr = obj.degree;
            end

            if(obj.ridge_optim)
                ridgeStr = "OPTIM";
            else
                ridgeStr = obj.ridge;
            end

            if(obj.kernel_type_optim)
                kernelTypeStr = "OPTIM";
            else
                kernelTypeStr = obj.kernel_type.optionStr;
            end

            if(obj.kernel_shape_optim)
                kernelShapeStr = "OPTIM";
            else
                kernelShapeStr = obj.kernel_shape;
            end

            if(obj.distance_optim)
                distanceTypeStr = "OPTIM";
            else
                distanceTypeStr = obj.distance_type.optionStr;
            end

            modelDefStr = "TYPE " + obj.type.optionStr + " ";

            switch obj.type
                case NomadSurrogateModelTypeEnum.PRS
                    modelDefStr = modelDefStr + "DEGREE " + degreeStr + " " + ...
                                                "RIDGE " + ridgeStr + " " + ...
                                                "BUDGET " + obj.budget;

                case NomadSurrogateModelTypeEnum.PRS_EDGE
                    modelDefStr = modelDefStr + "DEGREE " + degreeStr + " " + ...
                                                "RIDGE " + ridgeStr + " " + ...
                                                "BUDGET " + obj.budget;

                case NomadSurrogateModelTypeEnum.PRS_CAT
                    modelDefStr = modelDefStr + "DEGREE " + degreeStr + " " + ...
                                                "RIDGE " + ridgeStr + " " + ...
                                                "BUDGET " + obj.budget;

                case NomadSurrogateModelTypeEnum.RBF
                    modelDefStr = modelDefStr + "KERNEL_TYPE " + kernelTypeStr + " " + ...
                                                "KERNEL_SHAPE " + kernelShapeStr + " " + ...
                                                "DISTANCE_TYPE " + distanceTypeStr + " " + ...
                                                "RIDGE " + ridgeStr + " " + ...
                                                "BUDGET " + obj.budget;

                case NomadSurrogateModelTypeEnum.KS
                    modelDefStr = modelDefStr + "KERNEL_TYPE " + kernelTypeStr + " " + ...
                                                "KERNEL_SHAPE " + kernelShapeStr + " " + ...
                                                "DISTANCE_TYPE " + distanceTypeStr + " " + ...
                                                "BUDGET " + obj.budget;

                case NomadSurrogateModelTypeEnum.KRIGING
                    modelDefStr = modelDefStr + "DISTANCE_TYPE " + distanceTypeStr + " " + ...
                                                "RIDGE " + ridgeStr + " " + ...
                                                "BUDGET " + obj.budget;

                case NomadSurrogateModelTypeEnum.LOWESS
                    modelDefStr = modelDefStr + "DEGREE " + degreeStr + " " + ...
                                                "RIDGE " + ridgeStr + " " + ...
                                                "KERNEL_TYPE " + kernelTypeStr + " " + ...
                                                "KERNEL_SHAPE " + kernelShapeStr + " " + ...
                                                "DISTANCE_TYPE " + distanceTypeStr + " " + ...
                                                "BUDGET " + obj.budget;

                case NomadSurrogateModelTypeEnum.CN
                    modelDefStr = modelDefStr + "DISTANCE_TYPE " + distanceTypeStr + " " + ...
                                                "BUDGET " + obj.budget;

                case NomadSurrogateModelTypeEnum.ENSEMBLE
                    modelDefStr = modelDefStr + "WEIGHT " + obj.weight.optionStr + " " + ...
                                                "METRIC " + obj.metric.optionStr + " " + ...
                                                "DISTANCE_TYPE " + distanceTypeStr + " " + ...
                                                "BUDGET " + obj.budget;

                case NomadSurrogateModelTypeEnum.ENSEMBLE_STAT
                    modelDefStr = modelDefStr + "WEIGHT " + obj.weight.optionStr + " " + ...
                                                "METRIC " + obj.metric.optionStr + " " + ...
                                                "DISTANCE_TYPE " + distanceTypeStr + " " + ...
                                                "UNCERTAINTY " + obj.uncertainty.optionStr + " " + ...
                                                "SIZE_PARAM " + obj.size_param + " " + ...
                                                "SIGMA_MULT " + obj.sigma_mult + " " + ...
                                                "LAMBDA_P " + obj.lambda_p + " " + ...
                                                "LAMBDA_PI" + obj.lambda_pi + " " + ...
                                                "BUDGET " + obj.budget;
                otherwise 
                    error('Unknown surrogate model type: %s', obj.type.name);
            end
        end
    end
end