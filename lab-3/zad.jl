# Autor: Dominik Kaczmarek

using JuMP, GLPK, LinearAlgebra

# Function to parse a problem instance from a file
function parse_gap_file(filename::String)
    problems = []

    open(filename, "r") do file
        content = read(file, String)
        int_strings = split(content)
        integers = parse.(Int, int_strings)

        i = 1
        num_problems = integers[i]
        i += 1
        for problem_index in 1:num_problems
            
            m = integers[i]
            n = integers[i+1]
            i += 2

            # println("P", problem_index, ':')
            # println("m = ", m, ", n = ", n)

            costs = []
            for _ in 1:m
                push!(costs, integers[i:i+n])
                i += n
            end

            resources = []
            for _ in 1:m
                push!(resources, integers[i:i+n])
                i += n
            end

            capacities = []
            j = i
            while j < i + m
                push!(capacities, integers[j])
                j += 1
            end
            i = j

            push!(problems, (m, n, costs, resources, capacities))
        end
    end
    return problems
end

# Linear Programming Model for the Generalized Assignment Problem
function solve_lp_ga(m, n, c, p, T, jobs, machines, x_zeros)

    M = collect(1:m)
    J = collect(1:n)
    
    model = Model(GLPK.Optimizer)

    @variable(model, 0 <= x[M, J]) 

    for (i, j) in x_zeros
        @constraint(model, x[i, j] == 0)
    end

    # Minimalizacja całkowitego kosztu
    @objective(model, Min, sum(c[i][j] * x[i, j] for i in M, j in jobs))
    # Każde z zadań musi być wykonane dokładnie raz
    @constraint(model, [j in jobs], sum(x[i, j] for i in M) == 1)
    # Nie możemy przekroczyć czasu, w którym maszyna jest dostępna 
    @constraint(model, [i in machines], sum(p[i][j] * x[i, j] for j in jobs) <= T[i]) 

    optimize!(model)
    return value.(x), objective_value(model)
end

# Iterative Generalized Assignment Algorithm
function iterative_relaxation(m, n, c, p, T)

    J = 1:n
    M = 1:m

    machines = collect(1:m)
    jobs = collect(1:n)

    x_zeros = Set{Tuple{Int, Int}}()
    
    # (i) Initialization
    F = falses(m, n)    # E(F) ← ∅,
    M_prime = deepcopy(machines) # M' ← M

    # (ii) While J not ∅ do
    while !isempty(jobs)
        # (a) Find an optimal extreme point solution x to LPga
        x, _ = solve_lp_ga(m, n, c, p, T, jobs, M_prime, x_zeros)
        # and remove every variable with x[i,j] = 0.
        for i in M
            for j in jobs
                if x[i, j] == 0
                    push!(x_zeros, (i, j))
                end
            end
        end

        # (b) If there is a variable with xij = 1, then update:
        jobs_to_remove = Set{Int}()
        for (i, j) in [(i, j) for i in M, j in jobs]
            if round(x[i, j]; digits=15) == 1
                F[i,j] = 1                  # F ← F ∪ {ij}
                push!(jobs_to_remove, j)    # J ← J\{j}
                T[i] -= p[i][j]             # T[i] ← T[i] − p[i][j]
            end
        end
        jobs = setdiff(jobs, jobs_to_remove) #J <- J\{j}

        # (c) (Relaxation) If there is a machine i with d(i) = 1, or a machine i with d(i) = 2 and ∑_{j ∈ J} x[i,j] >= 1, then update M' ← M' \ {i}.
        if !isempty(jobs)
            machines_to_remove = Set{Int}()
            for i in M_prime
                degree = sum(x[i, j] > 0 for j in jobs)
                sum_fractional_values = sum(x[i, :])
                if (degree == 1) || (degree == 2 && sum_fractional_values >= 1)
                    push!(machines_to_remove, i)
                end
            end
            M_prime = setdiff(M_prime, machines_to_remove)
        end
    end

    total_cost = sum(c[i][j] * F[i, j] for i in M, j in J)

    # (iii) Return F 
    return F, total_cost
end

# Function to evaluate the algorithm on a dataset
function evaluate_gap_dataset(file_path::String)

    problems = parse_gap_file(file_path)
    results = []
    ratios = []
    
    for (m, n, c, p, T) in problems
        
        T_original = deepcopy(T)
        F, cost = iterative_relaxation(m, n, c, p, T)
        maxratio = 0

        for i in 1:m 
            T_relax = sum(F[i,j] * p[i][j] for j in 1:n)
            ratio = T_relax / T_original[i]
            maxratio = max(ratio, maxratio)
        end 

        push!(ratios, maxratio)   
        push!(results, cost)
    end

    return results, ratios
end

function main()
    # Ensure the script receives the file path as an argument
    if length(ARGS) < 1
        println("Usage: julia script_name.jl path_to_gap_data_file")
        exit(1)
    end

    file_path = ARGS[1]
    results, ratios = evaluate_gap_dataset(file_path)
    results = Array{Int}(results)
    ratios = round.(ratios; digits=5)

    println(file_path)
    for i in 1:length(results)
        println(i, "\t", results[i], "\t", ratios[i])
    end

end

main()
