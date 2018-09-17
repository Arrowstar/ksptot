function [onOff] = convertTfToOnOff(tf)
    if(tf)
        onOff = 'on';
    else
        onOff = 'off';
    end
end

