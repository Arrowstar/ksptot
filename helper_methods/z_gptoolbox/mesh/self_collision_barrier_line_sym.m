function [sf,out2,out3] = self_collision_barrier_line_sym(in1,tol1)
%SELF_COLLISION_BARRIER_LINE_SYM
%    [SF,OUT2,OUT3] = SELF_COLLISION_BARRIER_LINE_SYM(IN1,TOL1)

%    This function was generated by the Symbolic Math Toolbox version 8.6.
%    24-Apr-2021 15:46:44

X1 = in1(:,1);
X2 = in1(:,2);
X3 = in1(:,3);
X4 = in1(:,4);
X5 = in1(:,5);
X6 = in1(:,6);
t2 = X2.*2.0;
t3 = X3.*2.0;
t4 = X5.*2.0;
t5 = X6.*2.0;
t6 = -X1;
t7 = -X2;
t9 = -X3;
t11 = -X4;
t12 = -X5;
t14 = -X6;
t16 = 1.0./tol1;
t8 = -t2;
t10 = -t3;
t13 = -t4;
t15 = -t5;
t17 = X1+t7;
t18 = X2+t9;
t19 = X4+t12;
t20 = X5+t14;
t21 = X1+X3+t8;
t22 = X4+X6+t13;
t23 = t2+t10;
t24 = t4+t15;
t25 = t18.^2;
t26 = t20.^2;
t29 = t17.*t18;
t30 = t19.*t20;
t27 = t23.^2;
t28 = t24.^2;
t31 = t25+t26;
t39 = t29+t30;
t32 = 1.0./t31;
t33 = t32.^2;
t34 = t32.^3;
t35 = t17.*t32;
t36 = t18.*t32;
t37 = t19.*t32;
t38 = t20.*t32;
t44 = t21.*t32;
t45 = t22.*t32;
t52 = t23.*t32;
t53 = t24.*t32;
t54 = t25.*t32;
t55 = t26.*t32;
t62 = t29.*t32;
t65 = t30.*t32;
t107 = t32.*t39;
t40 = t35.*2.0;
t41 = t36.*2.0;
t42 = t37.*2.0;
t43 = t38.*2.0;
t46 = -t35;
t48 = -t37;
t50 = t44.*2.0;
t51 = t45.*2.0;
t56 = -t44;
t58 = -t45;
t60 = t54-1.0;
t61 = t55-1.0;
t63 = t20.*t35;
t64 = t19.*t36;
t68 = t21.*t36;
t69 = t21.*t38;
t70 = t22.*t36;
t71 = t22.*t38;
t74 = t23.*t25.*t33;
t75 = t24.*t26.*t33;
t76 = t25.*t26.*t33.*2.0;
t79 = t23.*t29.*t33;
t80 = t24.*t29.*t33;
t81 = t17.*t20.*t23.*t33;
t82 = t18.*t19.*t23.*t33;
t83 = t18.*t20.*t23.*t33;
t84 = t17.*t20.*t24.*t33;
t85 = t18.*t19.*t24.*t33;
t86 = t23.*t30.*t33;
t87 = t18.*t20.*t24.*t33;
t88 = t24.*t30.*t33;
t93 = t18.*t21.*t23.*t33;
t94 = t18.*t21.*t24.*t33;
t95 = t20.*t21.*t23.*t33;
t96 = t18.*t22.*t23.*t33;
t97 = t20.*t21.*t24.*t33;
t98 = t18.*t22.*t24.*t33;
t99 = t20.*t22.*t23.*t33;
t100 = t20.*t22.*t24.*t33;
t108 = t36.*t39;
t109 = t38.*t39;
t110 = t18.*t33.*t39.*2.0;
t111 = t20.*t33.*t39.*2.0;
t112 = t23.*t33.*t39;
t113 = t24.*t33.*t39;
t128 = t18.*t27.*t34.*t39.*2.0;
t129 = t18.*t28.*t34.*t39.*2.0;
t130 = t20.*t27.*t34.*t39.*2.0;
t131 = t20.*t28.*t34.*t39.*2.0;
t142 = t18.*t23.*t24.*t34.*t39.*2.0;
t143 = t20.*t23.*t24.*t34.*t39.*2.0;
t47 = -t40;
t49 = -t42;
t57 = -t50;
t59 = -t51;
t66 = t60.^2;
t67 = t61.^2;
t77 = -t74;
t78 = -t75;
t89 = t79.*2.0;
t90 = t81.*2.0;
t91 = t85.*2.0;
t92 = t88.*2.0;
t101 = -t83;
t102 = -t87;
t103 = t93.*2.0;
t104 = t95.*2.0;
t105 = t98.*2.0;
t106 = t100.*2.0;
t114 = t112.*2.0;
t115 = t113.*2.0;
t116 = X2+t6+t108;
t117 = X5+t11+t109;
t118 = t18.*t112;
t119 = t18.*t113;
t120 = t20.*t112;
t121 = t20.*t113;
t132 = -t128;
t133 = -t129;
t134 = -t130;
t135 = -t131;
t136 = t20.*t41.*t60;
t137 = t20.*t41.*t61;
t146 = -t142;
t147 = -t143;
t72 = t66.*2.0;
t73 = t67.*2.0;
t122 = t116.^2;
t123 = t117.^2;
t124 = -t118;
t125 = -t119;
t126 = -t120;
t127 = -t121;
t138 = t41+t77;
t139 = t43+t78;
t140 = t52+t77;
t141 = t53+t78;
t144 = t36+t102;
t145 = t38+t101;
t150 = t41.*t116;
t151 = t43.*t116;
t152 = t41.*t117;
t153 = t43.*t117;
t156 = t60.*t116.*2.0;
t157 = t61.*t117.*2.0;
t160 = t24.*t25.*t33.*t116.*2.0;
t161 = t23.*t26.*t33.*t117.*2.0;
t172 = t83.*t116.*2.0;
t173 = t87.*t116.*2.0;
t174 = t83.*t117.*2.0;
t175 = t87.*t117.*2.0;
t197 = t136+t137;
t226 = t91+t110+t133;
t227 = t90+t111+t134;
t240 = t41+t105+t110+t133;
t241 = t43+t104+t111+t134;
t252 = t38+t81+t95+t111+t134;
t253 = t36+t85+t98+t110+t133;
t254 = t48+t80+t82+t113+t146;
t255 = t46+t84+t86+t112+t147;
t256 = t48+t82+t94+t113+t146;
t257 = t46+t84+t99+t112+t147;
t258 = t56+t86+t97+t112+t147;
t259 = t58+t80+t96+t113+t146;
t260 = t58+t94+t96+t113+t146;
t261 = t56+t97+t99+t112+t147;
t278 = t47+t89+t110+t114+t132;
t279 = t49+t92+t111+t115+t135;
t284 = t41+t57+t103+t110+t114+t132;
t285 = t43+t59+t106+t111+t115+t135;
t308 = t36+t46+t56+t79+t93+t110+t114+t132;
t309 = t38+t48+t58+t88+t100+t111+t115+t135;
t148 = t72+t76;
t149 = t73+t76;
t154 = t20.*t150;
t155 = t20.*t152;
t158 = t63+t126;
t159 = t64+t125;
t162 = t69+t126;
t163 = t70+t125;
t164 = -t160;
t165 = -t161;
t176 = -t172;
t177 = -t173;
t178 = -t174;
t179 = -t175;
t182 = t122+t123;
t188 = t116.*t138.*2.0;
t189 = t117.*t139.*2.0;
t190 = t116.*t140.*2.0;
t191 = t117.*t141.*2.0;
t202 = t116.*t144.*2.0;
t203 = t116.*t145.*2.0;
t204 = t117.*t144.*2.0;
t205 = t117.*t145.*2.0;
t210 = t62+t107+t124;
t211 = t65+t107+t127;
t212 = t68+t107+t124+1.0;
t213 = t71+t107+t127+1.0;
t248 = t116.*t226.*2.0;
t249 = t117.*t227.*2.0;
t280 = t116.*t240.*2.0;
t281 = t117.*t241.*2.0;
t286 = t116.*t253.*2.0;
t287 = t117.*t252.*2.0;
t292 = t116.*t254.*2.0;
t293 = t117.*t255.*2.0;
t294 = t116.*t256.*2.0;
t295 = t117.*t257.*2.0;
t296 = t116.*t259.*2.0;
t297 = t117.*t258.*2.0;
t298 = t116.*t260.*2.0;
t299 = t117.*t261.*2.0;
t300 = t116.*t278.*2.0;
t301 = t117.*t279.*2.0;
t304 = t116.*t284.*2.0;
t305 = t117.*t285.*2.0;
t320 = t116.*t308.*2.0;
t321 = t117.*t309.*2.0;
t166 = t158.^2;
t167 = t159.^2;
t168 = t162.^2;
t169 = t163.^2;
t183 = 1.0./t182;
t185 = sqrt(t182);
t192 = t60.*t159.*2.0;
t193 = t61.*t158.*2.0;
t194 = t20.*t41.*t158;
t195 = t20.*t41.*t159;
t198 = t60.*t163.*2.0;
t199 = t61.*t162.*2.0;
t200 = t20.*t41.*t162;
t201 = t20.*t41.*t163;
t214 = t210.^2;
t215 = t211.^2;
t216 = t212.^2;
t217 = t213.^2;
t222 = t116.*t159.*2.0;
t223 = t117.*t158.*2.0;
t224 = t116.*t163.*2.0;
t225 = t117.*t162.*2.0;
t228 = t60.*t210.*2.0;
t229 = t61.*t211.*2.0;
t230 = t20.*t41.*t210;
t231 = t20.*t41.*t211;
t232 = t20.*t41.*t212;
t233 = t20.*t41.*t213;
t234 = t60.*t212.*2.0;
t235 = t61.*t213.*2.0;
t236 = t155+t156;
t237 = t154+t157;
t242 = t158.*t162.*2.0;
t243 = t159.*t163.*2.0;
t244 = t116.*t210.*2.0;
t245 = t117.*t211.*2.0;
t246 = t116.*t212.*2.0;
t247 = t117.*t213.*2.0;
t250 = -t248;
t251 = -t249;
t262 = t159.*t210.*2.0;
t263 = t158.*t211.*2.0;
t266 = t163.*t210.*2.0;
t267 = t162.*t211.*2.0;
t268 = t159.*t212.*2.0;
t271 = t158.*t213.*2.0;
t272 = t163.*t212.*2.0;
t273 = t162.*t213.*2.0;
t282 = -t280;
t283 = -t281;
t288 = -t286;
t289 = -t287;
t290 = t210.*t212.*2.0;
t291 = t211.*t213.*2.0;
t302 = -t300;
t303 = -t301;
t306 = -t304;
t307 = -t305;
t322 = -t320;
t323 = -t321;
t170 = t166.*2.0;
t171 = t167.*2.0;
t180 = t168.*2.0;
t181 = t169.*2.0;
t184 = t183.^2;
t186 = 1.0./t185;
t196 = -t185;
t207 = t16.*t185;
t209 = (t185-tol1).^2;
t218 = t214.*2.0;
t219 = t215.*2.0;
t220 = t216.*2.0;
t221 = t217.*2.0;
t238 = t236.^2;
t239 = t237.^2;
t264 = -t262;
t265 = -t263;
t269 = -t266;
t270 = -t267;
t274 = -t268;
t275 = -t271;
t276 = -t272;
t277 = -t273;
t310 = t223+t244;
t311 = t222+t245;
t314 = t225+t246;
t315 = t224+t247;
t325 = t165+t193+t203+t230;
t326 = t164+t192+t204+t231;
t327 = t165+t199+t203+t232;
t328 = t164+t198+t204+t233;
t329 = t188+t194+t205+t228;
t330 = t189+t195+t202+t229;
t331 = t188+t200+t205+t234;
t332 = t189+t201+t202+t235;
t333 = t151+t165+t176+t193+t230;
t334 = t152+t164+t179+t192+t231;
t335 = t151+t165+t176+t199+t232;
t336 = t152+t164+t179+t198+t233;
t337 = t153+t178+t190+t194+t228;
t338 = t150+t177+t191+t195+t229;
t339 = t153+t178+t190+t200+t234;
t340 = t150+t177+t191+t201+t235;
t439 = t242+t289+t290+t322;
t440 = t243+t288+t291+t323;
t187 = t186.^3;
t206 = t196+tol1;
t208 = log(t207);
sf = -t208.*t209;
if nargout > 1
    out2 = [t183.*t209.*t236.*(-1.0./2.0)-t186.*t208.*t236.*(t185-tol1);t183.*t209.*t314.*(-1.0./2.0)-t186.*t208.*t314.*(t185-tol1);(t183.*t209.*t310)./2.0+t186.*t208.*t310.*(t185-tol1);t183.*t209.*t237.*(-1.0./2.0)-t186.*t208.*t237.*(t185-tol1);t183.*t209.*t315.*(-1.0./2.0)-t186.*t208.*t315.*(t185-tol1);(t183.*t209.*t311)./2.0+t186.*t208.*t311.*(t185-tol1)];
end
if nargout > 2
    t312 = t310.^2;
    t313 = t311.^2;
    t316 = t314.^2;
    t317 = t315.^2;
    t318 = (t183.*t197.*t209)./2.0;
    t343 = (t184.*t209.*t236.*t237)./2.0;
    t347 = t170+t218+t251+t302;
    t348 = t171+t219+t250+t303;
    t361 = (t184.*t209.*t236.*t310)./2.0;
    t362 = (t184.*t209.*t237.*t310)./2.0;
    t363 = (t184.*t209.*t236.*t311)./2.0;
    t364 = (t184.*t209.*t237.*t311)./2.0;
    t377 = (t184.*t209.*t236.*t314)./2.0;
    t378 = (t184.*t209.*t237.*t314)./2.0;
    t379 = (t184.*t209.*t236.*t315)./2.0;
    t380 = (t184.*t209.*t237.*t315)./2.0;
    t385 = t180+t220+t283+t306;
    t386 = t181+t221+t282+t307;
    t401 = (t184.*t209.*t310.*t311)./2.0;
    t416 = (t184.*t209.*t310.*t314)./2.0;
    t417 = (t184.*t209.*t311.*t314)./2.0;
    t418 = (t184.*t209.*t310.*t315)./2.0;
    t419 = (t184.*t209.*t311.*t315)./2.0;
    t425 = (t184.*t209.*t314.*t315)./2.0;
    t427 = t264+t265+t292+t293;
    t428 = t270+t274+t294+t297;
    t429 = t269+t275+t295+t296;
    t430 = t276+t277+t298+t299;
    t441 = t183.*t209.*(t262+t263-t292-t293).*(-1.0./2.0);
    t442 = t183.*t209.*(t267+t268-t294-t297).*(-1.0./2.0);
    t443 = t183.*t209.*(t266+t271-t295-t296).*(-1.0./2.0);
    t444 = (t183.*t209.*(t267+t268-t294-t297))./2.0;
    t445 = (t183.*t209.*(t266+t271-t295-t296))./2.0;
    t446 = t183.*t209.*(t272+t273-t298-t299).*(-1.0./2.0);
    t447 = (t183.*t209.*t439)./2.0;
    t448 = (t183.*t209.*t440)./2.0;
    t319 = -t318;
    t324 = -t186.*t197.*t208.*(t185-tol1);
    t341 = -t187.*t236.*t237.*(t185-tol1);
    t342 = (t183.*t208.*t236.*t237)./2.0;
    t345 = t187.*t208.*t236.*t237.*(t185-tol1).*(-1.0./2.0);
    t346 = (t187.*t208.*t236.*t237.*(t185-tol1))./2.0;
    t349 = -t187.*t236.*t310.*(t185-tol1);
    t350 = -t187.*t237.*t310.*(t185-tol1);
    t351 = -t187.*t236.*t311.*(t185-tol1);
    t352 = -t187.*t237.*t311.*(t185-tol1);
    t353 = (t183.*t208.*t236.*t310)./2.0;
    t354 = (t183.*t208.*t237.*t310)./2.0;
    t355 = (t183.*t208.*t236.*t311)./2.0;
    t356 = (t183.*t208.*t237.*t311)./2.0;
    t357 = t187.*t236.*t310.*(t185-tol1);
    t358 = t187.*t237.*t310.*(t185-tol1);
    t359 = t187.*t236.*t311.*(t185-tol1);
    t360 = t187.*t237.*t311.*(t185-tol1);
    t365 = -t187.*t236.*t314.*(t185-tol1);
    t366 = -t187.*t237.*t314.*(t185-tol1);
    t367 = -t187.*t236.*t315.*(t185-tol1);
    t368 = -t187.*t237.*t315.*(t185-tol1);
    t369 = -t361;
    t370 = -t362;
    t371 = -t363;
    t372 = -t364;
    t373 = (t183.*t208.*t236.*t314)./2.0;
    t374 = (t183.*t208.*t237.*t314)./2.0;
    t375 = (t183.*t208.*t236.*t315)./2.0;
    t376 = (t183.*t208.*t237.*t315)./2.0;
    t391 = t187.*t208.*t236.*t314.*(t185-tol1).*(-1.0./2.0);
    t392 = t187.*t208.*t237.*t314.*(t185-tol1).*(-1.0./2.0);
    t393 = t187.*t208.*t236.*t315.*(t185-tol1).*(-1.0./2.0);
    t394 = t187.*t208.*t237.*t315.*(t185-tol1).*(-1.0./2.0);
    t395 = (t187.*t208.*t236.*t314.*(t185-tol1))./2.0;
    t396 = (t187.*t208.*t237.*t314.*(t185-tol1))./2.0;
    t397 = (t187.*t208.*t236.*t315.*(t185-tol1))./2.0;
    t398 = (t187.*t208.*t237.*t315.*(t185-tol1))./2.0;
    t399 = -t187.*t310.*t311.*(t185-tol1);
    t400 = (t183.*t208.*t310.*t311)./2.0;
    t403 = -t187.*t310.*t314.*(t185-tol1);
    t404 = -t187.*t311.*t314.*(t185-tol1);
    t405 = -t187.*t310.*t315.*(t185-tol1);
    t406 = -t187.*t311.*t315.*(t185-tol1);
    t407 = t187.*t310.*t314.*(t185-tol1);
    t408 = t187.*t311.*t314.*(t185-tol1);
    t409 = t187.*t310.*t315.*(t185-tol1);
    t410 = t187.*t311.*t315.*(t185-tol1);
    t411 = (t183.*t208.*t310.*t314)./2.0;
    t412 = (t183.*t208.*t311.*t314)./2.0;
    t413 = (t183.*t208.*t310.*t315)./2.0;
    t414 = (t183.*t208.*t311.*t315)./2.0;
    t415 = -t187.*t314.*t315.*(t185-tol1);
    t420 = -t416;
    t421 = -t417;
    t422 = -t418;
    t423 = -t419;
    t424 = (t183.*t208.*t314.*t315)./2.0;
    t431 = t187.*t208.*t310.*t311.*(t185-tol1).*(-1.0./2.0);
    t432 = (t187.*t208.*t310.*t311.*(t185-tol1))./2.0;
    t437 = t187.*t208.*t314.*t315.*(t185-tol1).*(-1.0./2.0);
    t438 = (t187.*t208.*t314.*t315.*(t185-tol1))./2.0;
    t449 = t186.*t208.*(t185-tol1).*(t262+t263-t292-t293);
    t451 = t186.*t208.*(t185-tol1).*(t267+t268-t294-t297);
    t452 = t186.*t208.*(t185-tol1).*(t266+t271-t295-t296);
    t453 = t186.*t208.*(t185-tol1).*(t272+t273-t298-t299);
    t455 = -t186.*t208.*t439.*(t185-tol1);
    t456 = -t186.*t208.*t440.*(t185-tol1);
    t457 = t186.*t208.*t439.*(t185-tol1);
    t458 = t186.*t208.*t440.*(t185-tol1);
    t344 = -t342;
    t381 = -t373;
    t382 = -t374;
    t383 = -t375;
    t384 = -t376;
    t387 = t208.*t357.*(-1.0./2.0);
    t388 = t208.*t358.*(-1.0./2.0);
    t389 = t208.*t359.*(-1.0./2.0);
    t390 = t208.*t360.*(-1.0./2.0);
    t402 = -t400;
    t426 = -t424;
    t433 = t208.*t407.*(-1.0./2.0);
    t434 = t208.*t408.*(-1.0./2.0);
    t435 = t208.*t409.*(-1.0./2.0);
    t436 = t208.*t410.*(-1.0./2.0);
    t450 = -t449;
    t454 = -t453;
    t459 = t319+t324+t341+t343+t344+t346;
    t460 = t399+t401+t402+t432+t441+t450;
    t461 = t408+t412+t421+t434+t444+t451;
    t462 = t409+t413+t422+t435+t445+t452;
    t463 = t415+t425+t426+t438+t446+t454;
    t464 = t407+t411+t420+t433+t447+t457;
    t465 = t410+t414+t423+t436+t448+t458;
    out3 = [t148.*t183.*t209.*(-1.0./2.0)-(t183.*t208.*t238)./2.0+(t184.*t209.*t238)./2.0-t187.*t238.*(t185-tol1)-t148.*t186.*t208.*(t185-tol1)+(t187.*t208.*t238.*(t185-tol1))./2.0;t365+t377+t381+t395-(t183.*t209.*t339)./2.0-t186.*t208.*t339.*(t185-tol1);t353+t357+t369+t387+(t183.*t209.*t337)./2.0+t186.*t208.*t337.*(t185-tol1);t459;t367+t379+t383+t397-(t183.*t209.*t336)./2.0-t186.*t208.*t336.*(t185-tol1);t355+t359+t371+t389+(t183.*t209.*t334)./2.0+t186.*t208.*t334.*(t185-tol1);t365+t377+t381+t395-(t183.*t209.*t331)./2.0-t186.*t208.*t331.*(t185-tol1);t183.*t208.*t316.*(-1.0./2.0)+(t184.*t209.*t316)./2.0-(t183.*t209.*t385)./2.0-t187.*t316.*(t185-tol1)+(t187.*t208.*t316.*(t185-tol1))./2.0-t186.*t208.*t385.*(t185-tol1);t464;t366+t378+t382+t396-(t183.*t209.*t327)./2.0-t186.*t208.*t327.*(t185-tol1);t463;t461;t353+t357+t369+t387+(t183.*t209.*t329)./2.0+t186.*t208.*t329.*(t185-tol1);t464;t183.*t208.*t312.*(-1.0./2.0)+(t184.*t209.*t312)./2.0-(t183.*t209.*t347)./2.0-t187.*t312.*(t185-tol1)+(t187.*t208.*t312.*(t185-tol1))./2.0-t186.*t208.*t347.*(t185-tol1);t354+t358+t370+t388+(t183.*t209.*t325)./2.0+t186.*t208.*t325.*(t185-tol1);t462;t460;t459;t366+t378+t382+t396-(t183.*t209.*t335)./2.0-t186.*t208.*t335.*(t185-tol1);t354+t358+t370+t388+(t183.*t209.*t333)./2.0+t186.*t208.*t333.*(t185-tol1);t149.*t183.*t209.*(-1.0./2.0)-(t183.*t208.*t239)./2.0+(t184.*t209.*t239)./2.0-t187.*t239.*(t185-tol1)-t149.*t186.*t208.*(t185-tol1)+(t187.*t208.*t239.*(t185-tol1))./2.0;t368+t380+t384+t398-(t183.*t209.*t340)./2.0-t186.*t208.*t340.*(t185-tol1);t356+t360+t372+t390+(t183.*t209.*t338)./2.0+t186.*t208.*t338.*(t185-tol1);t367+t379+t383+t397-(t183.*t209.*t328)./2.0-t186.*t208.*t328.*(t185-tol1);t463;t462;t368+t380+t384+t398-(t183.*t209.*t332)./2.0-t186.*t208.*t332.*(t185-tol1);t183.*t208.*t317.*(-1.0./2.0)+(t184.*t209.*t317)./2.0-(t183.*t209.*t386)./2.0-t187.*t317.*(t185-tol1)+(t187.*t208.*t317.*(t185-tol1))./2.0-t186.*t208.*t386.*(t185-tol1);t465;t355+t359+t371+t389+(t183.*t209.*t326)./2.0+t186.*t208.*t326.*(t185-tol1);t461;t460;t356+t360+t372+t390+(t183.*t209.*t330)./2.0+t186.*t208.*t330.*(t185-tol1);t465;t183.*t208.*t313.*(-1.0./2.0)+(t184.*t209.*t313)./2.0-(t183.*t209.*t348)./2.0-t187.*t313.*(t185-tol1)+(t187.*t208.*t313.*(t185-tol1))./2.0-t186.*t208.*t348.*(t185-tol1)];
end
