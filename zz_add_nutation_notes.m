% zz_add_nutation_notes.m -- append pole-nutation caveats to Rotational info
% blocks of bodies whose IAU model has large NUT_PREC series or fast pole rates.
% Amplitudes below are the dominant BODY<id>_NUT_PREC_RA/DEC terms in pck00011.tpc.
notes = {
 'Mars',    499, 'BODY499_NUT_PREC pole series amplitudes ~0.42 deg in RA and ~1.59 deg in Dec: pole wanders ~2 deg, so these frozen axes are exact only at J2000.0.'
 'Neptune', 899, 'BODY899_NUT_PREC pole series amplitudes ~0.70 deg in RA and ~0.51 deg in Dec: pole wanders ~1.2 deg, so these frozen axes are exact only at J2000.0.'
 'Phobos',  401, 'BODY401_NUT_PREC pole series amplitudes ~1.78 deg in RA and ~1.08 deg in Dec: pole wanders ~2.9 deg, so these frozen axes are exact only at J2000.0.'
 'Deimos',  402, 'BODY402_NUT_PREC pole series amplitudes ~3.09 deg in RA and ~1.84 deg in Dec: pole wanders ~5.4 deg, so these frozen axes are exact only at J2000.0.'
 'Europa',  502, 'BODY502_NUT_PREC pole series amplitudes ~1.09 deg in RA and ~0.47 deg in Dec: pole wanders ~1.7 deg, so these frozen axes are exact only at J2000.0.'
 'Ganymede',503, 'BODY503_NUT_PREC pole series amplitudes ~0.43 deg in RA and ~0.19 deg in Dec: pole wanders ~0.8 deg, so these frozen axes are exact only at J2000.0.'
 'Callisto',504, 'BODY504_NUT_PREC pole series amplitudes ~0.59 deg in RA and ~0.25 deg in Dec: pole wanders ~1.0 deg, so these frozen axes are exact only at J2000.0.'
 'Mimas',   601, 'BODY601_NUT_PREC pole series amplitudes ~13.56 deg in RA and ~1.53 deg in Dec: pole wanders ~15 deg, so these frozen axes are exact only at J2000.0.'
 'Tethys',  603, 'BODY603_NUT_PREC pole series amplitudes ~9.66 deg in RA and ~1.09 deg in Dec: pole wanders ~10.8 deg, so these frozen axes are exact only at J2000.0.'
 'Rhea',    605, 'BODY605_NUT_PREC pole series amplitudes ~3.10 deg in RA and ~0.35 deg in Dec: pole wanders ~3.5 deg, so these frozen axes are exact only at J2000.0.'
 'Iapetus', 608, 'BODY608 pole rates (-3.949, -1.143) deg/century move the pole ~0.5 deg/decade: frozen axes are exact only at J2000.0.'
 };
F=fopen('bodies_other\bodiesSolarSystem.ini'); L=textscan(F,'%s','Delimiter','\n'); fclose(F); L=L{1};
anchor = 'precession), while the x-axis rotates at the sidereal rate.';
for k=1:size(notes,1)
  nm=notes{k,1};
  iPx = find(~cellfun(@isempty, strfind(L, sprintf('cspice_pxform(''IAU_%s''', upper(nm)))), 1);
  assert(~isempty(iPx), nm);
  % the anchor line follows within a few lines of the pxform line
  rel = find(~cellfun(@isempty, strfind(L(iPx:min(iPx+4,numel(L))), anchor)), 1);
  assert(~isempty(rel) && numel(rel)==1, nm);
  j = iPx + rel - 1;
  L = [L(1:j); {[';   Pole-nutation caveat: ' notes{k,3}]}; L(j+1:end)];
  fprintf('%s: note added\n', nm);
end
F=fopen('bodies_other\bodiesSolarSystem.ini','w'); fprintf(F,'%s\n',L{:}); fclose(F);
disp('done');
