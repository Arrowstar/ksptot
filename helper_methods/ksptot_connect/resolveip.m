function address = resolveip(input)
%resolveip Summary of this function goes here
%   Detailed explanation goes here
    try
        address = java.net.InetAddress.getByName(input);
    catch
        error(sprintf('Unknown host %s.', input));
    end
end

