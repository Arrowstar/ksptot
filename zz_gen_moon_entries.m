% zz_gen_moon_entries.m -- generate new moon sections for bodiesSolarSystem.ini
% NOTE: the rotini/bodyxaxis/bodyzaxis this script writes are construction
% placeholders only. Final values in the ini come from NAIF SPICE/MSOPCK
% (pck00011.tpc) via zz_fix_spin_axes_from_spice.m + zz_set_pm_rot.m.
% Do NOT re-run this script against the finished ini without re-running those.
% Sources: NAIF gm_de431.tpc, JPL Horizons osculating elements @ J2000,
% celestiamotherlode / CelestiaProject textures.
R = 8.314462618; M_earth = 5.9722e24;

% [name id gm radius a ecc inc raan arg mean PR(s) parent name parentID]
moons = { ...
 'Phobos',401,7.087546066894452E-04,11.17,9378.610328444505,1.469841851969655E-02,26.05670195883539,84.81514244056581,342.7848642391356,189.8224342278868,27575.39897706098,'Mars',499;
 'Deimos',402,9.615569648120313E-05,6.30,23458.18251161354,3.299624878237082E-04,27.56936980386812,83.66926662588133,211.8947925261645,5.093950813525924,109082.6328420468,'Mars',499;
 'Io',501,5.959916033410404E+03,1821.49,422036.4314844596,4.715688921345897E-03,2.212617763556377,336.8524452085695,66.16488500283468,335.153206478952,153048.5934426014,'Jupiter',599;
 'Europa',502,3.202738774922892E+03,1560.8,671248.4976902213,9.812823575576082E-03,1.790971209716447,332.6287323572119,254.6471423731226,345.4110367698480,306997.0096898566,'Jupiter',599;
 'Ganymede',503,9.887834453334144E+03,2631.2,1070497.481019323,1.457215292672099E-03,2.214148041848081,343.1728455275238,319.8078127226449,277.0487684461206,618267.1494885626,'Jupiter',599;
 'Callisto',504,7.179289361397270E+03,2410.3,1882772.953875105,7.439434600948234E-03,2.016916220859312,337.9426103461244,16.12689497888475,85.11888858079212,1442112.913946019,'Jupiter',599;
 'Mimas',601,2.503522884661795E+00,198.8,186036.8223903924,2.175634846415301E-02,27.00265761372071,172.0569449519339,108.7253838060412,37.39805775106126,81861.53737808102,'Saturn',699;
 'Enceladus',602,7.211292085479989E+00,252.3,238419.8688441309,6.351597350212341E-03,28.05202310549093,169.5065956328603,135.4830251984964,6.953398474767734,118766.8306614697,'Saturn',699;
 'Tethys',603,4.121117207701302E+01,536.3,294980.2530852608,9.698778768676897E-04,27.22072909012297,167.9977256763769,158.0570744864902,350.3828192477454,163444.6544872375,'Saturn',699;
 'Dione',604,7.311635322923193E+01,562.5,377652.1784818554,2.928360145096942E-03,28.04139510566285,169.4701967860710,164.9353995421455,332.0565629313631,236765.8785397468,'Saturn',699;
 'Rhea',605,1.539422045545342E+02,764.5,527225.2527315543,8.002149724314739E-04,28.24141737577452,168.9842022220848,165.7818213737295,206.9021112955066,390548.4924366264,'Saturn',699;
 'Titan',606,8.978138845307376E+03,2575.5,1221934.800913171,2.860066256432539E-02,27.71833887311165,169.2391602866279,164.4091285733822,163.4361974944248,1377850.824651786,'Saturn',699;
 'Iapetus',608,1.205134781724041E+02,734.5,3562566.556811612,2.786249162022612E-02,17.23820439459392,139.6917551276544,229.6583954051450,208.0175928163262,6860019.206180421,'Saturn',699;
};

% textures
tex = containers.Map;
tex('Phobos')='images/body_textures/surface/phobosSurface.jpg';
tex('Deimos')='images/body_textures/surface/deimosSurface.jpg';
tex('Io')='images/body_textures/surface/ioSurface.jpg';
tex('Europa')='images/body_textures/surface/europaSurface.jpg';
tex('Ganymede')='images/body_textures/surface/ganymedeSurface.jpg';
tex('Callisto')='images/body_textures/surface/callistoSurface.jpg';
tex('Mimas')='images/body_textures/surface/mimasSurface.jpg';
tex('Enceladus')='images/body_textures/surface/enceladusSurface.jpg';
tex('Tethys')='images/body_textures/surface/tethysSurface.jpg';
tex('Dione')='images/body_textures/surface/dioneSurface.jpg';
tex('Rhea')='images/body_textures/surface/rheaSurface.jpg';
tex('Titan')='images/body_textures/surface/titanSurface.jpg';
tex('Iapetus')='images/body_textures/surface/iapetusSurface.jpg';

colors = containers.Map;
colors('Phobos')='copper'; colors('Deimos')='copper';
colors('Io')='hot'; colors('Europa')='winter'; colors('Ganymede')='winter';
colors('Callisto')='winter'; colors('Mimas')='winter'; colors('Enceladus')='winter';
colors('Tethys')='winter'; colors('Dione')='winter'; colors('Rhea')='winter';
colors('Titan')='summer'; colors('Iapetus')='winter';

% ============ Titan atmosphere model ============
% Anchors: P[kPa], T[K] from Huygens HASI (Fulchignoni et al. 2005, Nature
% 438:991) and Cassini RADAR/CIRS + Lindal et al. 1983 (Voyager 1 RO):
% surface 94 K @ 146.7 kPa; tropopause 70 K near 44 km; stratopause ~186 K
% near 250-300 km. M = 0.95*N2 + 0.05*CH4 mix from GCMS (Niemann 2010).
Panc = [146.7 100 60 30 15 10 5 2 1 0.5 0.2 0.1 0.05 0.02 0.01 0.005 0.002 0.001 0.0005 0.0002 1e-4];
Tanc = [94.0 90.0 80.0 74.0 70.5 70.0 72.0 80.0 90.0 100.0 125.0 145.0 160.0 172.0 178.0 186.0 180.0 173.0 160.0 140.0 120.0];
M = 0.95*0.028014 + 0.05*0.016043;  % kg/mol
g1 = 8.978138845307376E+03 / 2575.5^2 * 1000; % m/s^2
P = Panc*1e3; T = Tanc;                 % Pa, K; z increases as P decreases
r0 = 2575.5e3;
lnP = log(P);
qp = min(max(log(Panc), log(Panc(end))), log(Panc(1)));
Tlog = interp1(log(Panc(end:-1:1)), Tanc(end:-1:1), qp, 'linear');
H = R*Tlog/(M*g1);                    % scale height (m)
z = cumtrapz(-lnP, H);                % m, z increases as P decreases
z = z - z(1); z = z/1e3;             % km above surface
atmoHgt_t = z(end);
zlim_t = floor(atmoHgt_t/2)*2;
zg = 0:2:zlim_t;                      % 2 km grid like the planets
Pg = interp1(z, P/1e3, zg, 'linear'); % kPa
Tg = interp1(z, T, zg, 'linear');
Pg(end) = P(end)/1e3; Tg(end) = T(end);
fprintf('Titan atmoHgt = %.3f km, top P = %.2e kPa\n', zlim_t, Pg(end));
% print Titan tables (Panc/Tanc order: ascending z)
for i=1:numel(zg)
  fprintf('TITAN %.1f %.11g %.11g\n', zg(i), Pg(i), Tg(i));
end

% body axis vectors: z = orbit normal, x = node direction
function [x,z] = axes_from_orbit(i_deg, om_deg)
  i=deg2rad(i_deg); om=deg2rad(om_deg);
  z=[sin(i)*sin(om), -sin(i)*cos(om), cos(i)];
  x=[cos(om), sin(om), 0];
  z=z/norm(z); x=x/norm(x);
end

for r=1:height(moons)
  nm=moons{r,1}; id=moons{r,2};
  i_deg=moons{r,7}; om_deg=moons{r,8};
  [x,z]=axes_from_orbit(i_deg,om_deg);
  fprintf('AXES %s : %.9f %.9f %.9f ; %.9f %.9f %.9f\n', nm, x, z);
end

% ============ write moon_blocks.ini ============
fid = fopen('moon_blocks.ini','w');
tid = containers.Map; tid('Phobos')=1; tid('Deimos')=1; tid('Io')=1; tid('Europa')=1; tid('Ganymede')=1; tid('Callisto')=1; tid('Mimas')=1; tid('Enceladus')=1; tid('Tethys')=1; tid('Dione')=1; tid('Rhea')=1; tid('Titan')=0; tid('Iapetus')=1;
note = containers.Map;
note('Phobos')=';   Note: two tiny Mars moonlets; no atmosphere (exosphere too tenuous to model).';
note('Deimos')=';   Note: two tiny Mars moonlets; no atmosphere (exosphere too tenuous to model).';
note('Io')=';   Note: SO2 sublimation atmosphere + Pele plumes, ~1 nbar surface; set to zero (too thin for drag).';
note('Europa')=';   Note: trace O2 exosphere (sputtered), ~1e-11 Pa; set to zero.';
note('Ganymede')=';   Note: atomic O2 exosphere, trace; set to zero.';
note('Callisto')=';   Note: tenuous CO2 exosphere (Galileo), ~1e-9 hPa; set to zero.';
note('Mimas')=';   Note: no atmosphere (Huygens/Voyager/Cassini show surface-only).';
note('Enceladus')=';   Note: transient H2O plume + tenuous exosphere; set to zero for trajectory model.';
note('Tethys')=';   Note: no significant atmosphere.';
note('Dione')=';   Note: trace O2 exosphere (Cassini INMS, ~1e-4 hPa); set to zero.';
note('Rhea')=';   Note: trace O2 + CO2 exosphere (~1e-4-1e-3 hPa, Cassini INMS 2010); set to zero.';
note('Iapetus')=';   Note: no atmosphere.';
for r=1:height(moons)
  nm=moons{r,1}; id=moons{r,2}; gm_=moons{r,3}; rad=moons{r,4};
  a=moons{r,5}; e=moons{r,6}; i_=moons{r,7}; raan=moons{r,8}; arg=moons{r,9}; mean=moons{r,10}; PR=moons{r,11};
  pname=moons{r,12}; pid=moons{r,13};
  [x,z]=axes_from_orbit(i_,raan);
  fprintf(fid,'; =================================================================\n');
  fprintf(fid,'; [%s]\n',nm);
  fprintf(fid,'; Orbit (sma/ecc/inc/raan/arg/mean at J2000) w.r.t. %s center:\n',pname);
  fprintf(fid,';   JPL Horizons target %d, center %d, osculating elements @ JDTDB 2451545.0,\n',id,pid);
  fprintf(fid,';   geometric osculating, ecliptic of J2000 (https://ssd.jpl.nasa.gov/api/horizons.api).\n');
  fprintf(fid,'; GM: DE431 "ASTRO-VALUES" / satellite file (NAIF gm_de431.tpc,\n');
  fprintf(fid,';   BODY%d_GM). Radius: mean radius from the Horizons satellite physical-properties\n',id);
  fprintf(fid,';   header. Rotperiod = synchronous orbital (sidereal) period from Horizons.\n');
  fprintf(fid,'; Rotational info: synchronous rotator, so spin pole = orbit normal;\n');
  fprintf(fid,';   bodyzaxis = unit orbit normal, bodyxaxis = ascending-node direction,\n');
  fprintf(fid,';   rotini = 0 deg at J2000 (prime meridian reference arbitrary but fixed).\n');
  tt = tex(nm);
  fprintf(fid,'; Texture: CelestiaProject/CelestiaContent textures/hires/%s,\n',   tt(30:end));
  fprintf(fid,';   NASA/JPL-Caltech/Cassini/Voyager/Galileo-derived mosaic, CC-BY license,\n');
  fprintf(fid,';   https://github.com/CelestiaProject/CelestiaContent\n');
  fprintf(fid,';   (see .license sidecar files in that repo for full credits).\n');
  if tid(nm), fprintf(fid,'%s\n', note(nm)); end
  fprintf(fid,'[%s]\n',nm);
  fprintf(fid,'epoch = 0.000000000\n');
  fprintf(fid,'sma = %.9E\n',a);
  fprintf(fid,'ecc = %.15E\n',e);
  fprintf(fid,'inc = %.15E\n',i_);
  fprintf(fid,'raan = %.15E\n',raan);
  fprintf(fid,'arg = %.15E\n',arg);
  fprintf(fid,'mean = %.15E\n',mean);
  fprintf(fid,'gm = %.15E\n',gm_);
  fprintf(fid,'radius = %.4f\n',rad);
  if tid(nm)
    fprintf(fid,'atmoHgt = 0.000000000\natmoPressAlts = 0.00000000000\natmoPressPresses = 0.00000000000\natmoTempAlts = 0.00000000000\natmoTempTemps = 0.00000000000\natmoTempSunMultAlts = 0.00000000000\natmoTempSunMults = 0.00000000000\nlatTempBiasLats = 0.00000000000\nlatTempBiases = 0.00000000000\nlatTempSunMultLats = 0.00000000000\nlatTempSunMults = 0.00000000000\natmoMolarMass = 0.0\n');
  else
    fprintf(fid,'; Atmosphere source: Huygens HASI in-situ descent profile (Fulchignoni et al. 2005,\n');
    fprintf(fid,';   Nature 438:991-995) P-T anchors + Cassini radio occultation (Lindal et al. 1983,\n');
    fprintf(fid,';   Icarus 53:348; Schinder et al. 2011 JGRE 116:E10003) + GCMS N2/CH4 mix\n');
    fprintf(fid,';   (Niemann et al. 2010). Solar-mean diurnal/seasonal climatology; surface\n');
    fprintf(fid,';   94 K, 146.7 kPa, M = 0.95*N2 + 0.05*CH4 = 0.02663 kg/mol. Tropopause\n');
    fprintf(fid,';   70 K near 44 km; stratopause ~186 K near 260 km. Integrate P(z) by hydrostatic\n');
    fprintf(fid,';   equilibrium dlnP = -dz/H, H = R*T/(M*g), T(P) piecewise-linear between the\n');
    fprintf(fid,';   tabulated anchors above, resampled to a 2 km grid (matches the planet tables).\n');
    fprintf(fid,'atmoHgt = %.1f\n', zlim_t);
    fprintf(fid,'atmoPressAlts = '); fprintf(fid,'%.11g,', zg(1:end-1)); fprintf(fid,'%.11g\n', zg(end));
    fprintf(fid,'atmoPressPresses = '); fprintf(fid,'%.11g,', Pg(1:end-1)); fprintf(fid,'%.11g\n', Pg(end));
    fprintf(fid,'atmoTempAlts = '); fprintf(fid,'%.11g,', zg(1:end-1)); fprintf(fid,'%.11g\n', zg(end));
    fprintf(fid,'atmoTempTemps = '); fprintf(fid,'%.11g,', Tg(1:end-1)); fprintf(fid,'%.11g\n', Tg(end));
    fprintf(fid,'atmoTempSunMultAlts = 0.00000000000\natmoTempSunMults = 0.00000000000\nlatTempBiasLats = 0.00000000000\nlatTempBiases = 0.00000000000\nlatTempSunMultLats = 0.00000000000\nlatTempSunMults = 0.00000000000\n');
    fprintf(fid,'atmoMolarMass = %.8f\n', M);
  end
  fprintf(fid,'rotperiod = %.8f\n', PR);
  fprintf(fid,'rotini = 0.000000000\n');
  fprintf(fid,'bodycolor = %s\n', colors(nm));
  fprintf(fid,'canBeCentral = 0\n');
  fprintf(fid,'canBeArriveDepart = 0\n');
  fprintf(fid,'parent = %s\n', pname);
  fprintf(fid,'parentID = %d\n', pid);
  fprintf(fid,'name = %s\n', nm);
  fprintf(fid,'id = %d\n', id);
  fprintf(fid,'surfTextureFile = %s\n', tex(nm));
  fprintf(fid,'bodyxaxis = %.9f, %.9f, %.9f\n', x);
  fprintf(fid,'bodyzaxis = %.9f, %.9f, %.9f\n\n', z);
end
fclose(fid);
disp('moon_blocks.ini written');
