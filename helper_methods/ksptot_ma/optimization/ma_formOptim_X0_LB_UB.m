function [x0, lb, ub] = ma_formOptim_X0_LB_UB(variables)
%ma_formOptim_X0_LB_UB Summary of this function goes here
%   Detailed explanation goes here

    lb = [];
    ub = [];
    x0 = [];
    for(varC = variables) %#ok<*NO4LP>
        var = varC{1};
        lb = [lb,var.lb]; %#ok<*AGROW>
        ub = [ub,var.ub];
        x0 = [x0,var.x0];
    end
end

