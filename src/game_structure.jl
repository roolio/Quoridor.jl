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


function move_pawn(state::GameState, id::Int8, new_id::Int8)
    # move the pawn from id to new_id
    if is_valid_move(state, id, new_id)
        state.players[state.turn] = new_id
        state.turn = state.turn == White ? Black : White
    end
end

function place_barrier(state::GameState, id::Int8, barrier_type::Barrier_type)
    # place a barrier at id
    row, col = barrierId2RowCol(id)
    if barrier_type == Horizontal
        if state.walls[row, col] == 0 && state.walls[row, col+1] == 0
            state.walls[row, col] = 1
            state.walls[row, col+1] = 1
            state.barriers[state.turn] -= 1
            state.turn = state.turn == White ? Black : White
        end
    else
        if state.walls[row, col] == 0 && state.walls[row+1, col] == 0
            state.walls[row, col] = 2
            state.walls[row+1, col] = 2
            state.barriers[state.turn] -= 1
            state.turn = state.turn == White ? Black : White
        end
    end
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

function neighbours(id::Int8)
    # return the neighbours of a pawn (in the form of ids)
    row, col = pawnId2RowCol(id)
    neighbours = []
    if row > 1
        push!(neighbours, id - BOARD_SIZE)
    end
    if row < BOARD_SIZE
        push!(neighbours, id + BOARD_SIZE)
    end
    if col > 1
        push!(neighbours, id - 1)
    end
    if col < BOARD_SIZE
        push!(neighbours, id + 1)
    end
    return neighbours
end

function is_valid_move(state::GameState, id::Int8, new_id::Int8)
    # check if the move is valid
    # check if the new_id is a neighbour of id
    if new_id in neighbours(id)
        # check if the new_id is not occupied by a pawn
        if new_id in values(state.players)
            return false
        end
        # check if the new_id is not occupied by a barrier
        row, col = pawnId2RowCol(new_id)
        if row == BOARD_SIZE
            if state.walls[row-1, col] == 1
                return false
            end
        elseif row == 1
            if state.walls[row, col] == 1
                return false
            end
        elseif col == BOARD_SIZE
            if state.walls[row, col-1] == 2
                return false
            end
        elseif col == 1
            if state.walls[row, col] == 2
                return false
            end
        else
            if state.walls[row, col] == 1 && state.walls[row-1, col] == 1
                return false
            end
            if state.walls[row, col] == 2 && state.walls[row, col-1] == 2
                return false
            end
        end

        return true
    end
    return false
end


