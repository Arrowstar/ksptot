% zz_set_pm_rot.m -- refresh rotini/rotperiod in the ini from NAIF pm-kernel values
addpath('C:\spice\mice\lib','C:\spice\mice\src\mice');
cspice_furnsh('C:\spice\mice\data\naif0012.tls');
cspice_furnsh('C:\spice\mice\data\pck00011.tpc');
moons = {{'Phobos',401},{'Deimos',402},{'Io',501},{'Europa',502},{'Ganymede',503},{'Callisto',504}, ...
         {'Mimas',601},{'Enceladus',602},{'Tethys',603},{'Dione',604},{'Rhea',605},{'Titan',606},{'Iapetus',608}};
planets = {{'Mercury',199},{'Venus',299},{'Moon',301},{'Mars',499},{'Jupiter',599},{'Saturn',699},{'Uranus',799},{'Neptune',899},{'Pluto',999}};
names = [planets, moons];
F=fopen('bodies_other\bodiesSolarSystem.ini'); L=textscan(F,'%s','Delimiter','\n'); fclose(F); L=L{1};
for k=1:numel(names)
  nm=names{k}{1}; id=names{k}{2};
  iSec = find(strcmp(L, sprintf('[%s]', nm)), 1);
  iS = find(strncmp(L(iSec:end), 'surfTextureFile', 15), 1) + iSec - 1;
  iR  = find(strncmp(L(iSec:iS), 'rotini =', 8), 1) + iSec - 1;
  iT  = find(strncmp(L(iSec:iS), 'rotperiod =', 11), 1) + iSec - 1;
  pm = cspice_gdpool(sprintf('BODY%d_PM', id), 1, 3);
  L{iR} = sprintf('rotini = %.10g', pm(1));
  L{iT} = sprintf('rotperiod = %.10g', sign(pm(2))*360/abs(pm(2))*86400);
  fprintf('%s: rotini %.10g  rotperiod %.10g\n', nm, pm(1), sign(pm(2))*360/abs(pm(2))*86400);
end
F=fopen('bodies_other\bodiesSolarSystem.ini','w'); fprintf(F,'%s\n',L{:}); fclose(F);
disp('done');
