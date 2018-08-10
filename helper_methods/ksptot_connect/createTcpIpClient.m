function [tcpipClient] = createTcpIpClient(varargin)
%createTcpIpClient Summary of this function goes here
%   Detailed explanation goes here
    global rHost;

    if(isempty(varargin)) 
        port = 8282;
        role = 'Client';
        if(isempty(rHost))
            rHost = 'localhost';
        end
    else
        port = varargin{1};
        role = varargin{2};
        try
            rHost = varargin{3};
        catch
            if(isempty(rHost))
                rHost = 'localhost';
            end
        end
    end
    
    tcpipClient = tcpip(rHost,port,'NetworkRole',role);

    tcpipClient.ByteOrder = 'bigEndian';
    set(tcpipClient, 'InputBufferSize',120480);
    set(tcpipClient, 'OutputBufferSize',120480);
    set(tcpipClient, 'Timeout',1);
    set(tcpipClient, 'ReadAsyncMode', 'continuous');
    set(tcpipClient, 'BytesAvailableFcnMode', 'byte');
    set(tcpipClient, 'BytesAvailableFcnCount', 120240);
end