function [statusBoxMsg] = setINIStatusBoxMsg()
%setINIStatusBoxMsg Summary of this function goes here
%   Detailed explanation goes here

    statusBoxMsg = {['KSP Trajectory Optimization Tool v', getKSPTOTVersionNumStr(), sprintf(' (R%s)', version('-release'))], 'Written By Arrowstar (C) 2023', statusBoxHR()};
end

