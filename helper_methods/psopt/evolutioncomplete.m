function state = evolutioncomplete(options,state,flag)
% Plays a notification when genetic algorithm finishes. Requires a
% Starcraft installation, in its default directory, typically:
% C:\Program Files\Starcraft
%
% Works with Windows, not tested on other platforms.

if ispc && strcmp(flag,'done') && ~strcmp(options.Display,'off')
    sounddir = [getenv('ProgramFiles') '\Starcraft\Sound\Zerg\Advisor'] ;
    if isdir(sounddir) && exist([sounddir '\ZAdUpd02.wav'],'file')
        [y, Fs, nbits] = audioread([sounddir '\ZAdUpd02.wav']) ;
        obj = audioplayer(y, Fs, nbits);
        playblocking(obj)
    end
end