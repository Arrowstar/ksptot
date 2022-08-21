function [appOptionsFromINI] = addMissingAppOptionsRows(appOptionsFromINI)
%addMissingAppOptionsRows Summary of this function goes here
%   Detailed explanation goes here
    defaultOpts = createDefaultKsptotOptions();
    defaultOptsLower(:,1) = lower(defaultOpts(:,1));
    defaultOptsLower(:,3) = lower(defaultOpts(:,3));

    Lia = ismember(defaultOptsLower(:,[1,3]), appOptionsFromINI(:,[1,3]));
    Lia2 = Lia(:,1) & Lia(:,2);

    bool = Lia2 == 0;

    appOptionsFromINI = vertcat(appOptionsFromINI,defaultOpts(bool,:));
end

