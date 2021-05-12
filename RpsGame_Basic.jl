# RPS GAME 
using DelimitedFiles, Random, StatsBase
# μ : 먹음, Predation
# σ : 생성, Reproduction
# ϵ : 자리바꿈, Exchange

function InitMaker(L, PopulationRatio = [0.3, 0.3, 0.3])
    CumPopulationRatio = cumsum(PopulationRatio)

    if CumPopulationRatio[end] > 1
        error("인구 비율이 맞지 않습니다.")
    end
    
    State = zeros(L, L)
    temp_idx = 1
    for i = round.(Int,ceil.(length(State) * CumPopulationRatio)[end:-1:1])
        State[1:i] .= temp_idx
        temp_idx += 1
    end
    shuffle!(State)
    return State
end

function Predation(State1, State2,NumSpe)
    if State1 != State2 && State1 != 0 && State2 != 0
        if (State1 == State2 + 1) || (State1 == 1 && State2 == NumSpe)
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

function PairwiseInteraction(LocX, LocY, Compass, ActionProb, L, State, Nμ, Nσ, Nϵ,NumSpe)
    LocX̃, LocỸ = FindMatchingLocation(LocX, LocY, Compass, L)
    if ActionProb < Nμ
        State[LocX,LocY], State[LocX̃, LocỸ] = Predation(State[LocX,LocY], State[LocX̃, LocỸ],NumSpe)
    elseif ActionProb < Nμ + Nσ
        State[LocX,LocY], State[LocX̃, LocỸ] = Reproduction(State[LocX,LocY], State[LocX̃, LocỸ])
    else
        State[LocX,LocY], State[LocX̃, LocỸ] = Exchange(State[LocX,LocY], State[LocX̃, LocỸ])
    end
    return State
end

function Generation(L, State, Nμ, Nσ, Nϵ,NumSpe,WeightsList,SpeciesList,IdxMatrix)
    Compass = rand(["N" "S" "W" "E"], L^2, 1)
    ActionProb = rand(L^2, 1)
    for i = 1:L^2
        Loc = rand( IdxMatrix[State .== sample(SpeciesList, Weights(WeightsList))])
        State = PairwiseInteraction(Loc[1], Loc[2], Compass[i], ActionProb[i], L, State, Nμ, Nσ, Nϵ,NumSpe)
    end
    return State
end

function MainRPS(μ, σ, ϵ, L, TotalIteration,PopulationRatio,WeightsList)
 # Normalized parameters
    Nμ = μ / (μ + σ + ϵ)
    Nσ = σ / (μ + σ + ϵ)
    Nϵ = ϵ / (μ + σ + ϵ)
    
    State = InitMaker(L, PopulationRatio)
    NumSpe = length(PopulationRatio)
    IdxMatrix = [(x,y) for x=1:L,y=1:L]
    #count(State.==3)
    
    SpeciesList = 1:NumSpe
        # 
    for i = 1:TotalIteration
        
        State = Generation(L, State, Nμ, Nσ, Nϵ,NumSpe,WeightsList,SpeciesList,IdxMatrix)
        writedlm("C:\\Users\\rlarb\\Desktop\\code\\RPS\\data\\" * string(i) * ".csv", State, ',', )
        println(i)
    end
end


MainRPS(1, 1, 3 * 10^-6, 64, 5000,[0.3,0.3,0.3],[1,1,1])

