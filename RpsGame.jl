# RPS GAME 
using DelimitedFiles
# μ : 먹음, Predation
# σ : 생성, Reproduction
# ϵ : 자리바꿈, Exchange

function InitMaker(L)
    RandMatrix = rand(L, L)
    State = zeros(L, L)
    State[RandMatrix .< 0.3] .= 1
    State[0.3 .<= RandMatrix .< 0.6] .= 2
    State[0.6 .<= RandMatrix .< 0.9] .= 3
    State[0.9 .<= RandMatrix .< 1] .= 0
    return State
end

function Predation(State1, State2)
    if State1 != State2 && State1 != 0 && State2 != 0
        if (State1 == 1 && State2 == 2) || (State1 == 2 && State2 == 3) || (State1 == 3 && State2 == 1)
            State1 = 0
        else
            State2 = 0
        end
    end
    return State1, State2
end


function Reproduction(State1, State2)
    if State1 == 0 
        State1 = State2
    elseif State2 == 0
        State2 = State1
    end

    return State1, State2
end

function Exchange(State1, State2)
    return State2, State1
end

function FindMatchingLocation(LocX, LocY, Compass, L)
    LocX̃, LocỸ = LocX, LocY
    if Compass == "E" 
        if LocX == L
            LocX̃ = 1
        else
            LocX̃ = LocX + 1
        end
    elseif Compass == "W"
        if LocX == 1
            LocX̃ = L
        else
            LocX̃ = LocX - 1
        end
    elseif Compass == "N"
        if LocY == L
            LocỸ = 1
        else
            LocỸ = LocY + 1
        end
    else # south
        if LocY == 1
            LocỸ = L
        else
            LocỸ = LocY - 1
        end
    end
    return LocX̃, LocỸ
end

function PairwiseInteraction(LocX, LocY, Compass, ActionProb, L, State, Nμ, Nσ, Nϵ)
    LocX̃, LocỸ = FindMatchingLocation(LocX, LocY, Compass, L)
    if ActionProb < Nμ
        State[LocX,LocY], State[LocX̃, LocỸ] = Predation(State[LocX,LocY], State[LocX̃, LocỸ])
    elseif ActionProb < Nμ + Nσ
        State[LocX,LocY], State[LocX̃, LocỸ] = Reproduction(State[LocX,LocY], State[LocX̃, LocỸ])
    else
        State[LocX,LocY], State[LocX̃, LocỸ] = Exchange(State[LocX,LocY], State[LocX̃, LocỸ])
    end
    return State
end

function Generation(L, State, Nμ, Nσ, Nϵ)
    Loc = rand(1:L, L^2, 2)
    Compass = rand(["N" "S" "W" "E"], L^2, 1)
    ActionProb = rand(L^2, 1)
    for i = 1:L^2
        State = PairwiseInteraction(Loc[i,1], Loc[i,2], Compass[i], ActionProb[i], L, State, Nμ, Nσ, Nϵ)
    end
    return State
end

function MainRPS(μ, σ, ϵ, L, TotalIteration)
 # Normalized parameters
    Nμ = μ / (μ + σ + ϵ)
    Nσ = σ / (μ + σ + ϵ)
    Nϵ = ϵ / (μ + σ + ϵ)
    State = InitMaker(L)
    for i = 1:TotalIteration
        State = Generation(L, State, Nμ, Nσ, Nϵ)
        writedlm("C:\\Users\\rlarb\\Desktop\\code\\RPS\\data\\" * string(i) * ".csv", State, ',', )
        println(i)
    end
end


MainRPS(1, 1, 3 * 10^-6, 512, 5000)