function lossConvert = getDefaultLossConvert(handles)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    names = maData.spacecraft.propellant.names;

    name = 'New Loss/Conversion';
    resLostIds = 1:length(names);
    resLostRates = zeros(1,length(names));
    resConvertIds = 1:length(names);
    resConvertRates = zeros(1,length(names));
    
    lossConvert = struct('name',name, 'resLost',resLostIds, 'resLostRates',resLostRates, 'resConvert',resConvertIds, 'resConvertPercent', resConvertRates);
end