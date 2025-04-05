/* Arrays and Sets */
set Cities;

/* Parameters */
param deficit_standard{Cities} >= 0; # deficyt kamperów typu standard w każdy mieście
param deficit_vip{Cities} >= 0; # deficyt kamperów typu VIP w każdy mieście

param surplus_standard{Cities} >=0; # nadmiar kamperów typu standard w każdy mieście
param surplus_vip{Cities} >= 0; # nadmiar kamperów typu VIP w każdy mieście

param distances{Cities, Cities} >= 0; # odleglosci między miastami
param cost_standard >= 0; # koszt transportu kampera typu standard za 1 km
param cost_vip >= 0; # koszt transportu kampera typu VIP za 1 km


/* Variables */
var campers_standard{i in Cities, j in Cities}, >= 0, <= surplus_standard[i]; # liczba kamperów typu standard przesłanych z miasta i do miasta j
var campers_vip{i in Cities, j in Cities}, >= 0, <= surplus_vip[i]; # liczba kamperów typu VIP przesłanych z miasta i do miasta j


/* Objective function */
minimize Cost: sum{i in Cities, j in Cities} distances[i,j] * (cost_standard * campers_standard[i,j] + cost_vip * campers_vip[i,j]);


/* Constraints */
# s.t. same_city_standard{i in Cities}: campers_standard[i,i] == 0; # nie wysyłamy kamperów w tym samym mieście;
# s.t. same_city_vip{i in Cities}: campers_vip[i,i] == 0; # nie wysyłamy kamperów w tym samym mieście;

s.t. send_less_than_surplus_S{i in Cities}: sum{j in Cities} campers_standard[i,j] <= surplus_standard[i]; # nie możemy przesłać więcej kamperów z miasta i niż wynosi jego nadmiar
s.t. send_less_than_surplus_V{i in Cities}: sum{j in Cities} campers_vip[i,j] <= surplus_vip[i]; # nie możemy przesłać więcej kamperów z miasta i niż wynosi jego nadmiar

s.t. fill_deficit_S{j in Cities}: sum{i in Cities} (campers_standard[i,j] + campers_vip[i,j]) >= deficit_standard[j]; # musimy uzupełnić deficyt kamperów typu standard w każdym mieście (VIP może zastąpić standard)
s.t. fill_deficit_V{j in Cities}: sum{i in Cities} campers_vip[i,j] >= deficit_vip[j]; # musimy uzupełnić deficyt kamperów typu VIP w każdym mieście
s.t. deficit_equal_getted{j in Cities}: sum{i in Cities} (campers_standard[i,j] + campers_vip[i,j]) >= deficit_standard[j] + deficit_vip[j]; # suma wszystkich kamperów, które przyszły do miasta j musi być większa równa sumie deficytów w tym mieście

solve;

printf "------------------------ Standard ------------------------\n\t";
printf{i in Cities}: "%s\t", i;
printf "\n";
for{i in Cities} {
    printf "%s\t", i; 
    for{j in Cities} {
        printf "%d/%d\t", campers_standard[i,j], campers_vip[i,j];
    }
    printf "\n";
}
display Cost;

for{i in Cities, j in Cities}
printf "SEND VIP: %s to %s amount %d\n", i, j, campers_vip[i, j];
for{i in Cities, j in Cities}
printf "SEND BASIC: %s to %s amount %d\n", i, j, campers_standard[i, j];

printf "----------------------------------------------------------\n";

