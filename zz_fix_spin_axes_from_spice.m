% zz_fix_spin_axes_from_spice.m -- set bodyxaxis/bodyzaxis from SPICE pxform at J2000
addpath('C:\spice\mice\lib','C:\spice\mice\src\mice');
cspice_furnsh('C:\spice\mice\data\naif0012.tls');
cspice_furnsh('C:\spice\mice\data\pck00011.tpc');
moons = {{'Phobos',401},{'Deimos',402},{'Io',501},{'Europa',502},{'Ganymede',503},{'Callisto',504}, ...
         {'Mimas',601},{'Enceladus',602},{'Tethys',603},{'Dione',604},{'Rhea',605},{'Titan',606},{'Iapetus',608}};
planets = {{'Mercury',199},{'Venus',299},{'Moon',301},{'Mars',499},{'Jupiter',599},{'Saturn',699},{'Uranus',799},{'Neptune',899},{'Pluto',999}};
names = [planets, moons];
F=fopen('bodies_other\bodiesSolarSystem.ini'); L=textscan(F,'%s','Delimiter','\n'); fclose(F); L=L{1};
et=0;
for k=1:numel(names)
  nm=names{k}{1}; id=names{k}{2};
  M=cspice_pxform(sprintf('IAU_%s',upper(nm)),'ECLIPJ2000',et);
  x=M(:,1); z=M(:,3);
  iSec = find(strcmp(L, sprintf('[%s]', nm)), 1);
  iS = find(strncmp(L(iSec:end), 'surfTextureFile', 15), 1) + iSec - 1;
  iX  = find(strncmp(L(iS:end), 'bodyxaxis =', 11), 1) + iS - 1;
  iZ  = find(strncmp(L(iS:end), 'bodyzaxis =', 11), 1) + iS - 1;
  iR  = find(strncmp(L(iSec:iS), 'rotini =', 8), 1) + iSec - 1;
  iT  = find(strncmp(L(iSec:iS), 'rotperiod =', 11), 1) + iSec - 1;
  pm = cspice_gdpool(sprintf('BODY%d_PM', id), 1, 3);
  iSec = max(iSec,find(strcmp(L, '['),1));
  r_ok=2;
  L{iX} = sprintf('bodyxaxis = %.9f, %.9f, %.9f', x);
  L{iZ} = sprintf('bodyzaxis = %.9f, %.9f, %.9f', z);
  % replace the 4-line "; Rotational info ..." block: locate its BODY%d_POLE marker
  iB = find(strncmp(L, sprintf(';   BODY%d_POLE_RA/DEC/PM',id), 23), 1);
  if ~isempty(iB)
    i0 = iB-2;
    assert(startsWith(L{i0},'; Rotational info'), nm);
    assert(contains(L{iB+1}, 'J2000 frame used by this file'), nm);
    newBlk = { sprintf('; Rotational info (SPICE/NAIF MSOPCK model; pck00011.tpc; Archinal et al. 2018,');
               sprintf(';   Celest. Mech. Dyn. Astr. 130:22): IAU_%s body-fixed frame at J2000.0,', upper(nm));
               sprintf(';   with bodyxaxis/bodyzaxis = the body x/z unit vectors expressed in the Sun-Earth');
               sprintf(';   ecliptic J2000 frame, computed with cspice_pxform(''IAU_%s'',''ECLIPJ2000'',et).', upper(nm));
               sprintf(';   rotini = the W (prime meridian angle) of the model at J2000.0; rotperiod = the sidereal');
               sprintf(';   rotation period. At later epochs only the z-axis is slowly time-varying (pole');
               sprintf(';   precession), while the x-axis rotates at the sidereal rate.') };
    L = [L(1:i0-1); newBlk; L(iB+2:end)];
  end
  fprintf('%s: z=(%.9f, %.9f, %.9f)\n', nm, z);
end
F=fopen('bodies_other\bodiesSolarSystem.ini','w'); fprintf(F,'%s\n',L{:}); fclose(F);
disp('done');




