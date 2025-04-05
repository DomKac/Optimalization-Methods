/* Arrays and sets */
set Material;
set Product;
set FirstClassProduct;
set SecondClassProduct;

/* Parameters */
param material_storage_max{Material} >= 0.0; # max liczba kg surowców możliwa do przechowania
param material_storage_min{Material} >= 0.0; # min liczba kg surowców możliwa do przechowania

param material_cost{Material} >= 0.0; # koszt zakupu 1kg surowca
param product_value{Product} >= 0.0; # ceny sprzedaży 1kg każdego z produktów

param percentage_waste{Material, FirstClassProduct}; # procent surowca, który tracimy przy produkcji 'A' i 'B'
param waste_utilization_cost{Material, FirstClassProduct}; # koszt utylizacji odpadów z produkcji produktu A i B 

param mix_not_bigger_than_constraint{Material, Product}; # maksymalny procent zawartości surowca w produkcie
param mix_not_smaller_than_constraint{Material, Product}; # minimalny procent zawartości surowca w produkcie


/* Variables */
var mat_prod{i in Material, j in Product}, >= 0; # ile kg surowca i przeznaczamy na wytworzenie produktu j
var product_created{j in Product}, >= 0; # ile kg każdego z produktów tworzymy
var input_weight{j in Product}, >= 0; # ile kg surowców wkładamy do wytworzenia j-tego produktu A lub B

var utilizated_wastes{i in Material, j in FirstClassProduct} >= 0; # ilość surowców przeznaczonych do utylizacji po produkcji A lub B
var reused_wastes{i in Material, j in FirstClassProduct} >= 0; # ilość surowców przeznaczonych do ponownego użycia po produkcji A lub B
var wastes{i in Material, j in FirstClassProduct} >= 0; # ilość odpadów z kazdego surowca po produkcji A lub B


var product_profit >=0;
var materials_cost >= 0;
var utilization_cost >= 0;

var sum_material{Material} >= 0;

/* Objective function */
maximize Profit: product_profit - materials_cost - utilization_cost;

/* Constraints */
s.t. prod_profit: 
    product_profit = sum{j in Product} (product_created[j] * product_value[j]);
s.t. mat_cost: 
    materials_cost = sum{i in Material} (material_cost[i] * sum_material[i]);
s.t. uti_cost: 
    utilization_cost = sum{i in Material, j in FirstClassProduct} (utilizated_wastes[i,j] * waste_utilization_cost[i,j]);


s.t. min_storage{i in Material}: sum_material[i] >= material_storage_min[i]; # minimalna i maksymalna kupowana liczba kg
s.t. max_storage{i in Material}: sum_material[i] <= material_storage_max[i]; # minimalna kupowana liczba kg

s.t. sums{i in Material}: 
        sum_material[i] = sum{j in Product} mat_prod[i,j]; # ilość użytego surowca

s.t. wastes_sum{i in Material, j in FirstClassProduct}:
        wastes[i,j] = utilizated_wastes[i,j] + reused_wastes[i,j]; # waga wszytskich odpadów surowca i z porduktu j jest równa tej zutylizowanej + użytej ponownie

s.t. input_weight_first_class{j in FirstClassProduct}: 
        input_weight[j] = sum{i in Material} mat_prod[i,j]; # waga wszytskich surowców użytych do produkcji A i B

s.t. input_weight_product_C: 
        input_weight['C'] = mat_prod[1, 'C'] + (sum{i in Material} reused_wastes[i,'A']); # waga surowców do produkcji C

s.t. input_weight_product_D: 
        input_weight['D'] = mat_prod[2, 'D'] + (sum{i in Material} reused_wastes[i,'B']); # waga surowców do produkcji D

s.t. second_class_product_equal_input_weight{j in SecondClassProduct}:
        input_weight[j] = product_created[j]; # nie mamy odpadów po produkcji C i D

s.t. wastes_getted{i in Material, j in FirstClassProduct}:
        wastes[i,j] = mat_prod[i,j] * percentage_waste[i,j]; # ilość odpadów surowca i po produkcji A i B 

s.t. production_first_class_items{j in FirstClassProduct}: 
    input_weight[j] = product_created[j] + sum{i in Material} wastes[i, j];


s.t. resource_not_smaller_than_in_mix{i in Material, j in Product}:
    mat_prod[i,j] >= mix_not_smaller_than_constraint[i,j] * input_weight[j];

s.t. resource_not_bigger_than_in_mix{i in Material, j in Product}:
    mat_prod[i,j] <= mix_not_bigger_than_constraint[i,j] * input_weight[j];

solve;

printf "-------------------------- Solution --------------------------\n\n";

printf "1). Zyski i koszty\n";
printf "Profit: %f\n", Profit;
printf "Sprzedaz produktow: %f\n", product_profit;
printf "Koszt utylizacji: %f\n", utilization_cost;
printf "Koszt surowcow: %f\n", materials_cost;

printf "\n2). Ilosc zakupionych surowców\n";
printf{m in Material}: "Surowiec %d: %f\n", m, sum_material[m];

printf "\n3). Podział surowców na produkcje\n";
display mat_prod;

printf "\n4). Ilosc wyprodukowanych produktow\n";
display product_created;

printf "\n5). Utylizacja\n";
display utilizated_wastes;

printf "\n5). Ponowne użycie\n";
display reused_wastes;


printf "--------------------------------------------------------------\n";

end;
