# RPS_GAME_speed_up 
using DelimitedFiles, Random, StatsBase,Traceur,Printf
# μ : 먹음, Predation
# σ : 생성, Reproduction
# ϵ : 자리바꿈, Exchange


function InitMaker(L, PopulationRatio = [0.3, 0.3, 0.3])
    CumPopulationRatio = cumsum(PopulationRatio)

    if CumPopulationRatio[end] > 1
        error("인구 비율이 맞지 않습니다.")
    end
    
    State = zeros(Int64, L, L)
    temp_idx = 1
    @inbounds for i = round.(Int, ceil.(length(State) * CumPopulationRatio)[end:-1:1])
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
    SpeciesProb = rand(L^2, 1)
    Loc = rand(1:L, L^2, 2)

    @inbounds for i = 1:L^2
        if State[Loc[i,1],Loc[i,2]] !== zero(Int64)
            if SpeciesProb[i] < WeightsList[State[Loc[i,1],Loc[i,2]]]
                State = PairwiseInteraction(Loc[i,1], Loc[i,2], Compass[i], ActionProb[i], L, State, Nμ, Nσ, Nϵ, NumSpe) 
            end
        end

    end
    return State
end

function MainRPS(FolderName, SimStepSize, μ, σ, ϵ, L, PreIteration, TotalIteration, PopulationRatio, WeightsList)
 # Normalized parameters
    Nμ = μ / (μ + σ + ϵ)
    Nσ = σ / (μ + σ + ϵ)
    Nϵ = ϵ / (μ + σ + ϵ)
    WeightsList = WeightsList / sum(WeightsList)
    State = InitMaker(L, PopulationRatio)
    NumSpe = length(PopulationRatio)
    IdxMatrix = [(x, y) for x = 1:L,y = 1:L]
    # count(State.==3)
    EndFlag = false
    SpeciesList = 1:NumSpe
    if ~isdir(FolderName)
        mkdir(FolderName)
    else
        rm(FolderName, recursive = true)
        mkdir(FolderName)
    end

    @inbounds for i = 1:TotalIteration
        
        # print(WeightsList[1]," // ", i,"    //    ", "계산 중... ")
        
        
        
        
        State = Generation(L, State, Nμ, Nσ, Nϵ, NumSpe, WeightsList, SpeciesList, IdxMatrix)
        
        # print("계산 완료  // ")
        # println(State)
        
        # open(FileName, "w") do io
        #     CSV.write(io, DataFrame(State, :auto))
        # end
        if mod(i, SimStepSize) == 0
            if i > PreIteration
            
                FileName = "\\" * string(Int(i / SimStepSize)) * ".csv"
            # print("작성 중... ")
                open(FolderName * FileName, "w") do io
                    writedlm(io, State)
                end
            
            # println(" 작성 완료")
            end
            if mod(Int(i / SimStepSize), 1) == 0
                @printf("%i // %.3f  //  %i \n", L,WeightsList[1], Int(i / SimStepSize))
            end
            EmptySpaceN = count(State .=== Int8(0))
            @inbounds for j = SpeciesList
                if count(State .=== j) + EmptySpaceN === L^2
                    EndFlag = true
                    break
                end
            end
            if EndFlag === true
            
                @printf("%i // %.3f  //  %i // Done!! \n", L,WeightsList[1], Int(i / SimStepSize))
                break
            end
        end
        
    end
    return EndFlag
end


ParaStepSize = 0.1
SimStepSize = 100
for j = 1:100
    for k = [256, 512, 1024]
        Threads.@threads for i = [1:ParaStepSize:3; (1 - ParaStepSize):-ParaStepSize:0.5] 
    
        
            FolderName = "../RPS_data/" * string(k) * " - " * string(i) * " - " * string(j)
            if ~isfile(FolderName * "/done")
                Random.seed!(j)
                EndFlag = MainRPS(FolderName, SimStepSize, 1, 1, 3 * 10^-6, k, 0, 40000, [0.3,0.3,0.3], [i,1,1])
                io = open(FolderName * "/done", "w")
                close(io)
                if EndFlag == true
                    io = open(FolderName * "/death", "w")
                else
                    io = open(FolderName * "/survived", "w")
                end
                close(io)
            end
        end
    end
end