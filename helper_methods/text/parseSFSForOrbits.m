function [orbits] = parseSFSForOrbits(filePath)
%parseSFSForOrbits Summary of this function goes here
%   Detailed explanation goes here

    text = fileread(filePath);
    text = text(strfind(text,'FLIGHTSTATE') : strfind(text, 'ROSTER') ); % trim to just the FLIGHTSTATE portion
    genNum = '[\d\.E\-]*';
    regex = {};
    regex{end+1} = ['[^\w]VESSEL.*?name \= [ ^\S]*'];
    regex{end+1} = ['sit \= [ \w]*'];
    regex{end+1} = ['SMA \= ', genNum];
    regex{end+1} = ['ECC \= ', genNum];
    regex{end+1} = ['INC \= ', genNum];
    regex{end+1} = ['LAN \= ', genNum];
    regex{end+1} = ['LPE \= ', genNum];
    regex{end+1} = ['MNA \= ', genNum];
    regex{end+1} = ['EPH \= ', genNum];
    regex{end+1} = ['REF \= ', genNum];
    out = regexp(text, regex, 'match');

    orbits = {};

    for(i=1 : size(out{1},2))
        try
            nameStr = regexp(out{1}{i}, 'name \= [ ^\S]*', 'match');
            sitStr = regexp(out{2}{i}, 'sit \= [ ^\S]*', 'match');
            orbits{i,1} = strrep(nameStr, 'name = ', '');
            orbits{i,1} = orbits{i,1}{1};
            orbits{i,2} = strrep(sitStr, 'sit = ', '');
            orbits{i,2} = orbits{i,2}{1};
            orbits{i,3} = cell2mat(textscan(out{3}{i}, '%*s = %f'))/1000;
            orbits{i,4} = cell2mat(textscan(out{4}{i}, '%*s = %f'));
            orbits{i,5} = cell2mat(textscan(out{5}{i}, '%*s = %f'));
            orbits{i,6} = cell2mat(textscan(out{6}{i}, '%*s = %f'));
            orbits{i,7} = cell2mat(textscan(out{7}{i}, '%*s = %f'));
            orbits{i,8} = cell2mat(textscan(out{8}{i}, '%*s = %f'))*180/pi;
            orbits{i,9} = cell2mat(textscan(out{9}{i}, '%*s = %f'));
            orbits{i,10} = cell2mat(textscan(out{10}{i}, '%*s = %f'));
        catch ME
            orbits{i,:} = [];
            continue;
        end
    end
end

