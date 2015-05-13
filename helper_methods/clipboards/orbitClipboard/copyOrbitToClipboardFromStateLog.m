function copyOrbitToClipboardFromStateLog(~,~,hStateReadoutText)
%copyOrbitToClipboardFromStateLog Summary of this function goes here
%   Detailed explanation goes here
%     clipboardData = [utSec, sma, ecc, inc, raan, arg, tru];
    global GLOBAL_OrbitClipboard;
    clipboardData = get(hStateReadoutText,'UserData');

    GLOBAL_OrbitClipboard(1) = clipboardData(1);
    GLOBAL_OrbitClipboard(2) = clipboardData(2);
    GLOBAL_OrbitClipboard(3) = clipboardData(3);
    GLOBAL_OrbitClipboard(4) = clipboardData(4);
    GLOBAL_OrbitClipboard(5) = clipboardData(5);
    GLOBAL_OrbitClipboard(6) = clipboardData(6);
    GLOBAL_OrbitClipboard(7) = clipboardData(7);
end

