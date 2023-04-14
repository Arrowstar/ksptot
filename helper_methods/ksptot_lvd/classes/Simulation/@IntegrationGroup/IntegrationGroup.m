classdef IntegrationGroup < matlab.mixin.SetGet
    %IntegrationGroup Summary of this class goes here
    %   Detailed explanation goes here

    properties
        integrationGroupNum(1,1) double = 1;
    end

    methods
        function obj = IntegrationGroup(integrationGroupNum)
            obj.integrationGroupNum = integrationGroupNum;
        end
    end
end