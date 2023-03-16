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
    
    if(strcmpi(role,'client'))
        tcpipClient = tcpclient(rHost,port);
    elseif(strcmpi(role,'server'))
        tcpipClient = tcpserver(rHost,port);
    else
        error('Unknown tcpip network role: %s', role);
    end

%     tcpipClient = tcpip(rHost,port,'NetworkRole',role);

    try
        tcpipClient.ByteOrder = 'bigEndian';
    catch 
        tcpipClient.ByteOrder = 'big-endian';
    end
    set(tcpipClient, 'InputBufferSize',120480);
    set(tcpipClient, 'OutputBufferSize',120480);
    set(tcpipClient, 'Timeout',10);
    set(tcpipClient, 'ReadAsyncMode', 'continuous');

    try
        set(tcpipClient, 'BytesAvailableFcnMode', 'byte');
        set(tcpipClient, 'BytesAvailableFcnCount', 120240);
    catch
        configureCallback(tcpipClient, 'byte', 120240, @() 1);
    end
end