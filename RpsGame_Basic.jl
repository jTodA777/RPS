# RPS GAME 
using DelimitedFiles, Random, StatsBase
# μ : 먹음, Predation
# σ : 생성, Reproduction
# ϵ : 자리바꿈, Exchange
using Profile


function InitMaker(L, PopulationRatio = [0.3, 0.3, 0.3])
    CumPopulationRatio = cumsum(PopulationRatio)

    if CumPopulationRatio[end] > 1
        error("인구 비율이 맞지 않습니다.")
    end
    
    State = zeros(Int64, L, L)
    temp_idx = 1
    for i = round.(Int, ceil.(length(State) * CumPopulationRatio)[end:-1:1])
        State[1:i] .= temp_idx
        temp_idx += 1
    end
    shuffle!(State)
    return State
end

function Predation(State1, State2, NumSpe)
    # 큰 수가 작은 수를 잡아먹음. 
    if State1 !== 0 && State2 !== 0 && ((State1 === State2 + 1) || (State1 === 1 && State2 === NumSpe))
        State2 = 0
    end
    return State1, State2
end


function Reproduction(State1, State2)
    if State2 == 0
        State2 = State1
    end

    return State1, State2
end

function Exchange(State1, State2)
    return State2, State1
end

function FindMatchingLocation(LocX, LocY, Compass, L)
    LocX̃, LocỸ = LocX, LocY
    if Compass === "E" 
        if LocX === L
            LocX̃ = 1
        else
            LocX̃ = LocX + 1
        end
    elseif Compass === "W"
        if LocX === 1
            LocX̃ = L
        else
            LocX̃ = LocX - 1
        end
    elseif Compass === "N"
        if LocY === L
            LocỸ = 1
        else
            LocỸ = LocY + 1
        end
    else # south
        if LocY === 1
            LocỸ = L
        else
            LocỸ = LocY - 1
        end
    end
    return LocX̃, LocỸ
end

function PairwiseInteraction(LocX, LocY, Compass, ActionProb, L, State, Nμ, Nσ, Nϵ, NumSpe)
    LocX̃, LocỸ = FindMatchingLocation(LocX, LocY, Compass, L)
    if ActionProb < Nμ
        State[LocX,LocY], State[LocX̃, LocỸ] = Predation(State[LocX,LocY], State[LocX̃, LocỸ], NumSpe)
    elseif ActionProb < Nμ + Nσ
        State[LocX,LocY], State[LocX̃, LocỸ] = Reproduction(State[LocX,LocY], State[LocX̃, LocỸ])
    else
        State[LocX,LocY], State[LocX̃, LocỸ] = Exchange(State[LocX,LocY], State[LocX̃, LocỸ])
    end
    return State
end

function Generation(L, State, Nμ, Nσ, Nϵ, NumSpe, WeightsList, SpeciesList, IdxMatrix)
    Compass = rand(["N" "S" "W" "E"], L^2, 1)
    ActionProb = rand(L^2, 1)
    WeightsSpecies = zeros(L, L)
    # time1 = 0
    # time2 = 0
    # time3 = 0
    # time = @elapsed 
    for i = 1:L^2
        # Loc = rand( IdxMatrix[State .== sample(SpeciesList, Weights(WeightsList))]) # 개체 수 무시 방법
        # println(State[IdxMatrix[1,1]])
        
        for j = SpeciesList
            WeightsSpecies[State .=== j] .= WeightsList[j]
            # for k = IdxMatrix[State .== j]
            #     @inbounds WeightsSpecies[k[1],k[2]] = WeightsList[j]
            # end
        end
        W = ProbabilityWeights(WeightsSpecies[:])
        Loc = sample(IdxMatrix[:], W) # 인구 수 고려
        
        State = PairwiseInteraction(Loc[1], Loc[2], Compass[i], ActionProb[i], L, State, Nμ, Nσ, Nϵ, NumSpe) 
        # if 0 == mod(i, L)
        #     println(time1,"  ", time2,"  ", time3)
        # end
        
    end
    # print(time, " seconds  ")
    return State
end

function MainRPS(FolderName, μ, σ, ϵ, L, PreIteration, TotalIteration, PopulationRatio, WeightsList)
 # Normalized parameters
    Nμ = μ / (μ + σ + ϵ)
    Nσ = σ / (μ + σ + ϵ)
    Nϵ = ϵ / (μ + σ + ϵ)
    
    State = InitMaker(L, PopulationRatio)
    NumSpe = length(PopulationRatio)
    IdxMatrix = [(x, y) for x = 1:L,y = 1:L]
    # count(State.==3)
    
    SpeciesList = 1:NumSpe
    if ~isdir(FolderName)
        mkdir(FolderName)
    else
        rm(FolderName, recursive = true)
        mkdir(FolderName)
    end

    for i = 1:TotalIteration
        
        # print(WeightsList[1]," // ", i,"    //    ", "계산 중... ")
        
        
        FileName = "\\" * string(i) * ".csv"
        
        
        State = Generation(L, State, Nμ, Nσ, Nϵ, NumSpe, WeightsList, SpeciesList, IdxMatrix)
        
        # print("계산 완료  // ")
        # println(State)
        
        # open(FileName, "w") do io
        #     CSV.write(io, DataFrame(State, :auto))
        # end
        
        if i > PreIteration
            # print("작성 중... ")
            open(FolderName * FileName, "w") do io
                writedlm(io, State)
            end
            
            # println(" 작성 완료")
        end
        println(WeightsList[1], " // ", i)
    end
end

Threads.@threads for i = 1:0.01:3
    for j = 1:100
        Random.seed!(j)
        MainRPS("data64_" * string(i) * "_" * string(j), 1, 1, 3 * 10^-6, 64, 0, 10000, [0.3,0.3,0.3], [i,1,1])
    end
end
