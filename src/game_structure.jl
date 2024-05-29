using StaticArrays# define constant values for the game
BOARD_SIZE = 9
WALLS = 10
PLAYERS = 2


@enum Player begin
    White
    Black
end

@enum Barrier_type begin
    Horizontal
    Vertical
end

@enum Intersection_type begin
    None
    Horiz
    Vert
end


# define a structure for a board of Quoridor
# define enum for players
struct GameState
    walls::SMatrix{BOARD_SIZE-1, BOARD_SIZE-1, Int8}
    players::Dict{Player, Int8} # player -> position
    turn::Player # player who has to play
    barriers::Dict{Player, Int8} # number of barriers left
end

# add pretty print for the game state
function Base.show(io::IO, state::GameState)
    println(io, "Players: $(state.players)")
    println(io, "Turn: $(state.turn)")
    println(io, "Barriers: $(state.barriers)")
    println(io, "Walls:")
    for i in 1:BOARD_SIZE-1
        for j in 1:BOARD_SIZE-1
            print(io, state.walls[i, j], " ")
        end
        println(io)
    end
end

function GameState()
    walls = zeros(BOARD_SIZE-1, BOARD_SIZE-1)
    players = Dict(White => 4, Black => 76)
    turn = White
    barriers = Dict(White => WALLS, Black => WALLS)
    return GameState(walls, players, turn, barriers)
end

function barrierId2RowCol(id::Int8)
    #throw an error if id > 2*BOARD_SIZE*(BOARD_SIZE-1)
    if id > (BOARD_SIZE-1)^2
        throw(ArgumentError("Barrier id is out of bounds"))
    end
    col = (id - 1) % 8 + 1
    row = ((id - col) / 8) + 1
    return (Int8(row),Int8(col))
end

function pawnId2RowCol(id::Int8)
    if id > (BOARD_SIZE)^2
        throw(ArgumentError("Barrier id is out of bounds"))
    end
    col = (id - 1) % BOARD_SIZE + 1
    row = ((id - col) / BOARD_SIZE) + 1
    return (Int8(row),Int8(col))
end
