#  Autor: Dominik Kaczmarek

using JuMP
using GLPK

function solve_problem(work_time::Matrix{Int};
    verbose=true)
    (m, n) = size(work_time)

    #  m - liczba zadan
    #  n - liczba maszyn
    #  d - macierz mxn zawierajaca czasy wykonania i-tego zadania na j-tej maszynie
    # verbose - true, to kominikaty solvera na konsole 

    B = sum(work_time) #duza liczba wraz z inicjalizacja

    println("B = ", B)  
    # wybor solvera
    #model = Model(CPLEX.Optimizer) # CPLEX		
    model = Model(GLPK.Optimizer) # GLPK
    # model = Model(Cbc.Optimizer) # Cbc the solver for mixed integer programming

    Task = 1:m
    Machine = 1:n
    Precedence = [(i, k) for i in Task, k in Task if i < k]

    #  zmienne moment rozpoczecia i-tego zadania na j-tej maszynie
    @variable(model, t[Task, Machine] >= 0)
    # zmienna czas zakonczenia wykonawania wszystkich zadan - makespan 
    @variable(model, ms >= 0)

    # zmienne pomocnicze 
    # potrzebne przy zamienia ograniczen zasobowych
    @variable(model, y[Precedence], Bin)

    # minimalizacja czasu zakonczenia wszystkich zadan
    @objective(model, Min, ms)


    # każde zadanie musi być wykonane po kolei na pocesorach 1, 2, 3, ..., m  
    for i in Task, j in Machine
        if j < n
            @constraint(model, t[i, j] + work_time[i, j] <= t[i, j+1])
        end
    end

    # ograniczenia zosobowe tj,. tylko jedno zadanie wykonywane jest
    # w danym momencie na j-tej maszynie 
    for j in Machine
        for (i, k) in Precedence
            @constraint(model, t[k, j] + work_time[k, j] <= t[i, j] + B * y[(i, k)])
            @constraint(model, t[i, j] + work_time[i, j] <= t[k, j] + B * (1 - y[(i, k)]))

        end
    end

    # ms rowna sie czas zakonczenia wszystkich zadan na ostatniej maszynie	
    for i in Task
        @constraint(model, t[i, n] + work_time[i, n] <= ms)
    end

    print(model) # drukuj model

    # rozwiaz egzemplarz
    if verbose
        optimize!(model)
    else
        set_silent(model)
        optimize!(model)
        unset_silent(model)
    end

    status = termination_status(model)

    if status == MOI.OPTIMAL
        return status, objective_value(model), value.(t)
    else
        return status, nothing, nothing
    end

end #jobshop


function gantt_print(tasks_start, tasks_end)
    last_time = maximum(tasks_end) + 1
    n, m = size(tasks_start)
    matrix = zeros(Int, m, last_time + 1)
    for j in 1:m
        for i in 1:n
            start_time = tasks_start[i, j]
            end_time = tasks_end[i, j]
            for t in start_time:end_time
                matrix[j, t+1] = i
            end
        end
    end
        
    for j in 1:m
        print("Maszyna: ", j, "\t|")
        for t in 1:last_time
            if matrix[j, t] != 0
                print(matrix[j, t])
            else
                print(" ")                
            end
        end
        println()
    end

end


function main()
    # czasy wykonia i-tego zadania na j-tej maszynie 
    d = [3 3 2;
        9 3 8;
        9 8 5;
        4 8 4;
        6 10 3;
        6 3 1;
        7 10 3]

    (status, makespan, tasks_start) = solve_problem(d)

    if status == MOI.OPTIMAL
        println("makespan: ", makespan)
        println("czasy rozpoczecia zadan: ", tasks_start)
    else
        println("Status: ", status)
    end

    tasks_end = tasks_start + d

    tasks_end= Array{Int}(tasks_end)
    tasks_start = Array{Int}(tasks_start)

    println()
    gantt_print(tasks_start, tasks_end)

end


main()
