function [statusBoxMsg] = setINIStatusBoxMsg()
%setINIStatusBoxMsg Summary of this function goes here
%   Detailed explanation goes here

    statusBoxMsg = {['KSP Trajectory Optimization Tool v', getKSPTOTVersionNumStr()], 'Written By Arrowstar (C) 2015', statusBoxHR()};
end

