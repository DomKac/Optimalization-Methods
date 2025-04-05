#  Autor: Dominik Kaczmarek

using JuMP
using GLPK

function solve_problem(n::Int, m::Int, T::Vector{Int}, q::Vector{Vector{Int}}, verbose=true)
    
    # n - liczba serwerów
    # m - liczba cech populacji
    # T - wektor czasów obsługi serwerów
    # q[i, j] - czy cecha j jest obsługiwana przez serwer i


    model = Model(GLPK.Optimizer)
    servers = 1:n
    attributes = 1:m

    # zmienne x[i] = 1, jesli wybierzemy serwer i do przeszukania
    @variable(model, x[servers], Bin)


    # każda cecha musi być obsługiwana przez co najmniej jeden serwer
    for j in attributes
        @constraint(model, sum( (x[i] * q[i][j]) for i in servers) >= 1)
    end


    @objective(model, Min, sum(T[i]*x[i] for i in servers))


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
        return status, objective_value(model), value.(x)
    else
        return status, nothing, nothing
    end


end

function main()
    n = 3
    m = 4
    T = [8, 2, 3]
    
    q = [[1, 0, 1], 
         [1, 1, 0], 
         [0, 1, 1], 
         [1, 0, 1]]

    qq =   [[1,1,0,1],
            [0,1,1,0],
            [1,0,1,1]]  

    status, cost, x = solve_problem(n, m, T, qq)
    println("status: ", status)
    println("cost: ", cost)
    println("x: ", x)
    

end

main()
