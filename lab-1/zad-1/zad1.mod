/* Sets and Parameters */
param n, integer, > 0;

set N := 1..n;

param a{i in N, j in N} := 1.0 / (i + j - 1.0);
param c{i in N} := sum{j in N} a[i,j];
param b{j in N} := sum{i in N} a[i,j];

/* Variables */
var x{i in N}, >= 0.0;

/* Objective function */
minimize cTx: sum{i in N} (x[i] * c[i]);

/* Constraints */
s.t. ax_b{i in N}: sum{j in N} a[i,j]*x[j] = b[i];

solve;

# Wyświetlenie wyników
printf "--------------------------------------------------------------";
printf "\nn = %d\n", n;
printf "Wektor x:\n";
for {i in N} {
    printf "x[%d] = %.20f\tc[%d] = %.20f\n", i, x[i], i, c[i];
}

# Błąd względny
param RelativeError := sqrt(sum{i in N} (x[i] - 1.0)*(x[i] - 1.0)) / sqrt(n);
printf "Błąd względny: %g\n", RelativeError;
printf "--------------------------------------------------------------";
