function options = createDefaultKsptotOptions()
%createDefaultKsptotOptions Summary of this function goes here
%   Detailed explanation goes here
    options = cell(1,4);
    
    %ksptot options
    options(1,:) = {'ksptot','','bodiesIniFile',''};
    options(2,:) = {'ksptot','','timeSystem','Earth'};
    options(3,:) = {'ksptot','','rtsHostName','localhost'};
    options(4,:) = {'ksptot','','gravParamType','kspStockLike'};
    
    options(5,:) = {'ksptot','','plotmaxdeltav',10};
    options(6,:) = {'ksptot','','porkchopptsaxes',250};
    options(7,:) = {'ksptot','','porkchopnumsynperiods',1};
    options(8,:) = {'ksptot','','departplotnumoptiters',50};
    options(9,:) = {'ksptot','','quant2opt','departPArrivalDVRadioBtn'};
    
    options(10,:) = {'ksptot','','lvdrecentmsncasefiles',''};
end

