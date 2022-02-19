# ===============================================================
# CHEBYQUAD FUNCTION (R. Fletcher, "Function Minimization Without
#		      Evaluating Derivatives -- A Review",
#		      Computer J. 8 (1965), pp. 163-168.)
# ===============================================================

param n > 0;

var x {j in 1..n} := j/(n+1);

var T {i in 0..n, j in 1..n} =
	    if (i = 0) then 1 else
            if (i = 1) then 2*x[j] - 1 else
            2 * (2*x[j]-1) * T[i-1,j] - T[i-2,j];

# =======================
# Equation form (for nl2)
# =======================

eqn {i in 1..n}:
   (1/n) * sum {j in 1..n} T[i,j] = if (i mod 2 = 0) then 1/(1-i^2) else 0;

# ========================
# Objective form (for mng)
# ========================

minimize ssq: 0.5*sum{i in 1..n}
	((1/n) * sum {j in 1..n} T[i,j] - if (i mod 2 = 0) then 1/(1-i^2))^2;
data;
  param n := 3;