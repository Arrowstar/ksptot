#!/usr/bin/env bash
# build_linux_mex.sh
#
# Rebuilds the three MEX files used by KSP TOT's Kepler element conversion on
# Linux (.mexa64), from fixed source files embedded below.
#
# The fixed sources are embedded (not read from the repo) because:
#   1. The scalar sources (getKeplerFromState_Alg.m, getStatefromKepler_Alg.m)
#      are NOT present in the repo working tree (they live only in git history).
#   2. The fixes are currently uncommitted in the Windows checkout; a fresh
#      Linux checkout would contain the old, buggy sources.
#
# Deployed outputs:
#   <repo>/helper_methods/_compiled/Linux/getKeplerFromState_Alg.mexa64
#   <repo>/helper_methods/_compiled/Linux/getStatefromKepler_Alg.mexa64
#   <repo>/helper_methods/astrodynamics/vectorized_elem_conv/vect_getKeplerFromState_Alg_mex.mexa64
#
# Usage:
#   ./build_linux_mex.sh [REPO_ROOT]
#
# REPO_ROOT defaults to the current directory; it must contain helper_methods/.
# MATLAB is located via $MATLAB_ROOT (path to MATLAB installation) or `which
# matlab`. MATLAB Coder is required.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-$SCRIPT_DIR}"

if [[ ! -d "$REPO_ROOT/helper_methods" ]]; then
    echo "ERROR: '$REPO_ROOT/helper_methods' not found. Pass the KSP TOT repo root as the first argument." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Locate MATLAB
# ---------------------------------------------------------------------------
if [[ -n "${MATLAB_ROOT:-}" ]]; then
    MATLAB_BIN="$MATLAB_ROOT/bin/matlab"
elif command -v matlab >/dev/null 2>&1; then
    MATLAB_BIN="matlab"
else
    echo "ERROR: MATLAB not found. Set MATLAB_ROOT to the MATLAB installation directory." >&2
    exit 1
fi

echo "Using MATLAB: $MATLAB_BIN"
echo "Repo root:    $REPO_ROOT"

# ---------------------------------------------------------------------------
# Build directory
# ---------------------------------------------------------------------------
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT
SRC_DIR="$BUILD_DIR/src"
MEX_DIR="$BUILD_DIR/mexout"
mkdir -p "$SRC_DIR" "$MEX_DIR"

# ---------------------------------------------------------------------------
# Fixed source files (embedded)
# ---------------------------------------------------------------------------
cat > "$SRC_DIR/getKeplerFromState_Alg.m" <<'EOF'
function [sma, ecc, inc, raan, arg, tru] = getKeplerFromState_Alg(rVect,vVect,gmu)
%getKeplerFromState_Alg Summary of this function goes here
%   Detailed explanation goes here
    k_hat = [0; 0; 1];

    hVect=crossARH(rVect,vVect);
    h=norm(hVect);

    r=norm(rVect);
    v=norm(vVect);

    nVect = crossARH(k_hat, hVect);
    eVect = ((v^2 - gmu/r)*rVect - dotARH(rVect,vVect)*vVect)/gmu;
    ecc = norm(eVect);

    Energy=v^2/2 - gmu/r;

    if(ecc ~= 1.0)
        sma=-gmu/(2*Energy);
    else
        sma = Inf;
    end

    cosInc = hVect(3) / h;
    inc = real(acos(complex(cosInc)));

    cosRAAN = nVect(1)/norm(nVect);
    raan = real(acos(complex(cosRAAN)));
    if(nVect(2) < 0)
        raan = 2*pi - raan;
    end

    cosArg = dotARH(nVect, eVect)/(norm(nVect) * norm(eVect));
    arg = real(acos(complex(cosArg)));
    if(eVect(3) < 0)
        arg = 2*pi - arg;
    end

    cosTru = dotARH(eVect, rVect) / (norm(eVect) * norm(rVect));
    tru = real(acos(complex(cosTru)));
    if(dotARH(rVect,vVect)<0)
        tru = -tru;
    end

    %%%%%%%%%%
    % Special Case: Elliptical Equitorial
    %%%%%%%%%%
    if(ecc >= 1E-10 && (inc < 1E-4 || abs(inc-pi) < 1E-4))
        longPeri = real(acos(complex(eVect(1)/norm(eVect))));
        if(eVect(2) < 0)
            longPeri = 2*pi - longPeri;
        end
        raan = 0;
        arg = longPeri;

        if(abs(inc-pi) < 1E-4)
            arg = mod(2*pi - arg, 2*pi);
        end
    end

    %%%%%%%%%%
    % Special Case: Circular Inclined
    %%%%%%%%%%
    if(ecc < 1E-10 && inc >= 1E-4 && abs(inc-pi) >= 1E-4)
        u = real(acos(complex(dotARH(nVect,rVect)/(norm(nVect)*norm(rVect)))));
        if(rVect(3) < 0)
            u = 2*pi - u;
        end
        tru = u;

        arg = 0;
    end

    %%%%%%%%%%
    % Special Case: Circular Equitorial
    %%%%%%%%%%
    if(ecc < 1E-10 && (inc < 1E-4 || abs(inc-pi) < 1E-4))
        l = real(acos(complex(rVect(1)/norm(rVect))));
        if(rVect(2)<0)
            l = 2*pi-l;
        end
        tru = l;

        if(abs(inc-pi) < 1E-4)
            tru = mod(2*pi - tru, 2*pi);
        end

        raan = 0;
        arg = 0;
    end
end
EOF

cat > "$SRC_DIR/getStatefromKepler_Alg.m" <<'EOF'
function [rVect, vVect] = getStatefromKepler_Alg(sma, ecc, inc, raan, arg, tru, gmu)
% getStatefromKepler_Alg() takes a set of Keplerian orbital elements and turns
% them into a set of state vectors (position and velocity vectors).
%
% This is a scalar implementation with retrograde equatorial bug fix.

    %%%%%%%%%%
    % Special Case: Circular Equatorial
    %%%%%%%%%%
    if(ecc < 1E-10 && (inc < 1E-4 || abs(inc-pi) < 1E-4))
        if(abs(inc-pi) < 1E-4)
            l = tru + arg - raan;
            inc = pi;
        else
            l = raan + arg + tru;
            inc = 0;
        end
        tru = l;
        raan = 0;
        arg = 0;
    end

    %%%%%%%%%%
    % Special Case: Circular Inclined
    %%%%%%%%%%
    if(ecc < 1E-10 && inc >= 1E-4 && abs(inc-pi) >= 1E-4)
        u = arg + tru;
        tru = u;
        arg = 0;
    end

    %%%%%%%%%%
    % Special Case: Elliptical Equatorial
    %%%%%%%%%%
    if(ecc >= 1E-10 && (inc < 1E-4 || abs(inc-pi) < 1E-4))
        if(abs(inc-pi) < 1E-4)
            arg = arg - raan;
            inc = pi;
        else
            arg = raan + arg;
            inc = 0;
        end
        raan = 0;
    end

    % General conversion logic
    p = sma * (1 - ecc^2);
    rPQW = [p * cos(tru) / (1 + ecc * cos(tru));
            p * sin(tru) / (1 + ecc * cos(tru));
            0];

    vPQW = [-sqrt(gmu / p) * sin(tru);
            sqrt(gmu / p) * (ecc + cos(tru));
            0];

    % Rotation Matrix: Rz(-raan) * Rx(-inc) * Rz(-arg)
    sinR = sin(raan);
    cosR = cos(raan);
    sinI = sin(inc);
    cosI = cos(inc);
    sinA = sin(arg);
    cosA = cos(arg);

    TransMatrix = [cosR*cosA-sinR*sinA*cosI, -cosR*sinA-sinR*cosA*cosI,  sinR*sinI;
                   sinR*cosA+cosR*sinA*cosI, -sinR*sinA+cosR*cosA*cosI, -cosR*sinI;
                   sinA*sinI,                 cosA*sinI,                 cosI];

    rVect = TransMatrix * rPQW;
    vVect = TransMatrix * vPQW;
end
EOF

cat > "$SRC_DIR/vect_getKeplerFromState_Alg.m" <<'EOF'
function [sma, ecc, inc, raan, arg, tru] = vect_getKeplerFromState_Alg(rVect,vVect,gmu)
%vect_getKeplerFromState_Alg Summary of this function goes here
%   Detailed explanation goes here
    numRV = size(rVect,2);

    k_hat = [0; 0; 1];
    k_hat = repmat(k_hat,1,numRV);

    hVect=cross(rVect,vVect);
    h=sqrt(sum(abs(hVect).^2,1));

    r=sqrt(sum(abs(rVect).^2,1));
    v=sqrt(sum(abs(vVect).^2,1));

    nVect = cross(k_hat, hVect);
    eVect1 = reshape(pagemtimes(reshape(rVect,3,1,numRV),reshape((v.^2 - gmu./r),1,1,numRV)),3,numRV);
    eVect2 = reshape(pagemtimes(reshape(vVect,3,1,numRV),reshape(dot(rVect,vVect),1,1,numRV)),3,numRV);

    eVectNoDiv = (eVect1 - eVect2);
    eVect = bsxfun(@times, eVectNoDiv, 1./gmu);
    ecc = sqrt(sum(abs(eVect).^2,1));

    Energy=v.^2/2 - gmu./r;

    if(any(ecc ~= 1.0))
        sma=-gmu./(2.*Energy);
    else
        sma = Inf;
    end

    cosInc = hVect(3,:) ./ h;
    inc = real(acos(complex(cosInc)));

    cosRAAN = nVect(1,:)./sqrt(sum(abs(nVect).^2,1));
    raan = real(acos(complex(cosRAAN)));
    if(any(nVect(2,:) < 0))
        raan(nVect(2,:) < 0) = 2*pi - raan(nVect(2,:) < 0);
    end

    cosArg = dot(nVect, eVect)./(sqrt(sum(abs(nVect).^2,1)) .* sqrt(sum(abs(eVect).^2,1)));
    arg = real(acos(complex(cosArg)));
    if(any(eVect(3,:) < 0))
        arg(eVect(3,:) < 0) = 2*pi - arg(eVect(3,:) < 0);
    end

    cosTru = dot(eVect, rVect) ./ (sqrt(sum(abs(eVect).^2,1)) .* sqrt(sum(abs(rVect).^2,1)));
    tru = real(acos(complex(cosTru)));
    if(any(dot(rVect,vVect)<0))
        tru(dot(rVect,vVect)<0) = -tru(dot(rVect,vVect)<0);
    end
    
    %%%%%%%%%%
    % Special Case: Elliptical Equitorial
    %%%%%%%%%%
    bool2 = (ecc >= 1E-10) & ((inc < 1E-4) | (abs(inc-pi) < 1E-4));
    if(any(bool2))
        longPeri = real(acos(complex(eVect(1,:)./sqrt(sum(abs(eVect).^2,1)))));
        if(any(eVect(2,:) < 0))
            longPeri(eVect(2,:) < 0) = 2*pi - longPeri(eVect(2,:) < 0);
        end  
        raan(bool2) = 0;
        arg(bool2) = longPeri(bool2);
        
        retBool = bool2 & (abs(inc-pi) < 1E-4);
        if(any(retBool))
            arg(retBool) = mod(2*pi - arg(retBool), 2*pi);
        end
    end

    %%%%%%%%%%
    % Special Case: Circular Inclined
    %%%%%%%%%%
    bool2 = (ecc < 1E-10) & (inc >= 1E-4) & (abs(inc-pi) >= 1E-4);
    if(any(bool2))
        u = real(acos(complex(dot(nVect,rVect)./(sqrt(sum(abs(nVect).^2,1)).*sqrt(sum(abs(rVect).^2,1)) ))));
        if(any(rVect(3,:) < 0))
            u(rVect(3,:) < 0) = 2*pi - u(rVect(3,:) < 0);
        end
        tru(bool2) = u(bool2);
        arg(bool2) = 0;
    end

    %%%%%%%%%%
    % Special Case: Circular Equitorial
    %%%%%%%%%%
    bool2 = (ecc < 1E-10) & ((inc < 1E-4) | (abs(inc-pi) < 1E-4));
    if(any(bool2))
        l = real(acos(complex(rVect(1,:)./sqrt(sum(abs(rVect).^2,1)) )));
        if(any(rVect(2,:)<0))
            l(rVect(2,:)<0) = 2*pi-l(rVect(2,:)<0);
        end
        tru(bool2) = l(bool2);

        retBool = bool2 & (abs(inc-pi) < 1E-4);
        if(any(retBool))
            tru(retBool) = mod(2*pi - tru(retBool), 2*pi);
        end

        raan(bool2) = 0;
        arg(bool2) = 0;
    end
end
EOF

cat > "$SRC_DIR/crossARH.m" <<'EOF'
function [w] = crossARH(u,v)
%crossARH Summary of this function goes here
%   Detailed explanation goes here
%     w = zeros(3,1);
    w = [u(2)*v(3) - u(3)*v(2); ...
         u(3)*v(1) - u(1)*v(3); ...
         u(1)*v(2) - u(2)*v(1)];
end
EOF

cat > "$SRC_DIR/dotARH.m" <<'EOF'
function [dotP] = dotARH(v1,v2)
%dotARH Summary of this function goes here
%   Detailed explanation goes here
    dotP = v1'*v2;
end
EOF

echo "Sources written to $SRC_DIR"

# ---------------------------------------------------------------------------
# Code generation (MATLAB Coder required)
# ---------------------------------------------------------------------------
cat > "$SRC_DIR/build_codegen.m" <<EOF
codegen -config:mex getKeplerFromState_Alg.m -args {coder.typeof(zeros(3,1)), coder.typeof(zeros(3,1)), 398600.4418} -o getKeplerFromState_Alg;
codegen -config:mex getStatefromKepler_Alg.m -args {8000, 0.2, 0.5, 1.0, 2.0, 3.0, 398600.4418} -o getStatefromKepler_Alg;
codegen -config:mex vect_getKeplerFromState_Alg.m -args {coder.typeof(zeros(3,1),[3 inf]), coder.typeof(zeros(3,1),[3 inf]), 398600.4418} -o vect_getKeplerFromState_Alg_mex;
disp('codegen complete');
EOF

"$MATLAB_BIN" -batch "cd('$SRC_DIR'); build_codegen"

mv "$SRC_DIR/getKeplerFromState_Alg.mexa64" "$MEX_DIR/"
mv "$SRC_DIR/getStatefromKepler_Alg.mexa64" "$MEX_DIR/"
mv "$SRC_DIR/vect_getKeplerFromState_Alg_mex.mexa64" "$MEX_DIR/"

echo "MEX files generated:"
ls -la "$MEX_DIR"

# ---------------------------------------------------------------------------
# Sanity check: MEX vs .m on a degenerate-orbit corpus + round trips
# ---------------------------------------------------------------------------
cat > "$BUILD_DIR/sanity_check.m" <<EOF
addpath('$MEX_DIR');   % MEX takes precedence
addpath('$SRC_DIR');   % .m sources

D2R = pi/180;
mu = 398600.4418;

cases = [8000,0.2,45*D2R,30*D2R,60*D2R,120*D2R; ...
         7000,0.3,0,0,0,50*D2R; ...
         7000,0.3,pi,0,0,50*D2R; ...
         7000,0.0,45*D2R,30*D2R,0,60*D2R; ...
         7000,0.0,0,0,0,60*D2R; ...
         7000,0.0,pi,0,0,60*D2R; ...
         7000,0.2,0.002*D2R,0,0,30*D2R; ...
         7000,0.2,pi-0.002*D2R,0,0,30*D2R; ...
         -12000,1.4,30*D2R,40*D2R,60*D2R,30*D2R; ...
         8000,0.9,120*D2R,10*D2R,200*D2R,300*D2R];

fail = 0;
tol = 1e-9;
for i = 1:size(cases,1)
    el = cases(i,:);
    [r,v] = getStatefromKepler_Alg(el(1),el(2),el(3),el(4),el(5),el(6),mu);   % CO2RV MEX

    [a1,e1,i1,r1,a1g,t1] = getKeplerFromState_Alg(r,v,mu);                    % scalar MEX
    [a2,e2,i2,r2,a2g,t2] = vect_getKeplerFromState_Alg(r,v,mu);               % vect .m
    [a3,e3,i3,r3,a3g,t3] = vect_getKeplerFromState_Alg_mex(r,v,mu);           % vect MEX

    d = [abs(a1-a2), abs(e1-e2), abs(i1-i2), ...
         abs(mod(r1-r2+pi,2*pi)-pi), abs(mod(a1g-a2g+pi,2*pi)-pi), abs(mod(t1-t2+pi,2*pi)-pi)];
    if any(d > tol), fail = fail+1; fprintf('MEX-vs-.m mismatch case %d (%.2e)\n', i, max(d)); end

    d2 = [abs(a1-a3), abs(e1-e3), abs(i1-i3), ...
          abs(mod(r1-r3+pi,2*pi)-pi), abs(mod(a1g-a3g+pi,2*pi)-pi), abs(mod(t1-t3+pi,2*pi)-pi)];
    if any(d2 > tol), fail = fail+1; fprintf('scalar-vs-vect MEX mismatch case %d (%.2e)\n', i, max(d2)); end

    [r2,v2] = getStatefromKepler_Alg(a1,e1,i1,r1,a1g,t1,mu);                  % round trip
    d3 = max(abs([r-r2; v-v2]));
    if d3 > 1e-6, fail = fail+1; fprintf('round-trip mismatch case %d (%.2e)\n', i, d3); end
end

if fail == 0
    disp('sanity check PASSED');
else
    error('sanity check FAILED (%d mismatches)', fail);
end
EOF

"$MATLAB_BIN" -batch "cd('$BUILD_DIR'); sanity_check"

# ---------------------------------------------------------------------------
# Deploy
# ---------------------------------------------------------------------------
COMPILED_LINUX="$REPO_ROOT/helper_methods/_compiled/Linux"
VECT_DIR="$REPO_ROOT/helper_methods/astrodynamics/vectorized_elem_conv"

if [[ ! -d "$COMPILED_LINUX" ]]; then
    echo "Creating $COMPILED_LINUX"
    mkdir -p "$COMPILED_LINUX"
fi
if [[ ! -d "$VECT_DIR" ]]; then
    echo "ERROR: $VECT_DIR not found; refusing to create it." >&2
    exit 1
fi

cp "$MEX_DIR/getKeplerFromState_Alg.mexa64" "$COMPILED_LINUX/"
cp "$MEX_DIR/getStatefromKepler_Alg.mexa64" "$COMPILED_LINUX/"
cp "$MEX_DIR/vect_getKeplerFromState_Alg_mex.mexa64" "$VECT_DIR/"

echo "Deployed:"
ls -la "$COMPILED_LINUX"
ls -la "$VECT_DIR"
echo "build_linux_mex.sh: DONE"