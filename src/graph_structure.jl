using Graphs
using MetaGraphs
# implement the graph structure for the Quoridor game
# each node is a cell on the board
# each edge is a possible move from one cell to another
# the graph is a 9x9 grid

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

struct Barrier
    id::Int
    barrier_type::Barrier_type
end


winning_positions = Dict(White => 1:BOARD_SIZE, Black => (BOARD_SIZE^2 - BOARD_SIZE+1):(BOARD_SIZE^2))

function create_graph(board_size::Int)
    g = MetaGraph(SimpleGraph(board_size * board_size))

    for i in 1:board_size
        for j in 1:board_size
            if i > 1
                add_edge!(g, (i-1)*(board_size)+j, (i-2)*board_size+j)
            end
            if i < board_size
                add_edge!(g, (i-1)*board_size+j, i*board_size+j)
            end
            if j > 1
                add_edge!(g, (i-1)*board_size+j, (i-1)*board_size+j-1)
            end
            if j < board_size
                add_edge!(g, (i-1)*board_size+j, (i-1)*board_size+j+1)
            end
        end
    end
    # add node information : x,y coordinates
    for i in 1:board_size
        for j in 1:board_size
            set_props!(g, (i-1)*board_size+j, Dict(:x => i, :y => j))
        end
    end
    return g
end


mutable struct GameState
    graph::MetaGraph
    players::Dict{Player, Int} # player -> position
    turn::Player # player who has to play
    played_barriers::Array{Barrier}
    barriers::Dict{Player, Int} # number of barriers left
end

# create a new game state
function GameState()
    g = create_graph(BOARD_SIZE)
    players = Dict(White => BOARD_SIZE*(BOARD_SIZE - 1) + (BOARD_SIZE + 1)/2, Black => (BOARD_SIZE + 1)/2)
    turn = White
    played_barriers = []
    barriers = Dict(White => WALLS, Black => WALLS)
    return GameState(g, players, turn, played_barriers,barriers)
end

function get_valid_moves(gs::GameState)
    # get valid moves for the current player
    # get Id of the current player
    cur_pos = gs.players[gs.turn]
    # get neighbors of the current player
    potential = neighbors(gs.graph, cur_pos)
    # check if other player in in neighbors
    # if yes, remove it
    other_player = gs.players[gs.turn == White ? Black : White]
    if other_player in potential
        # filter out other player position
        potential = filter(x -> x != other_player, potential)
        # get neighbors of the other player
        other_player_potential = filter(x -> x != cur_pos, neighbors(g, other_player))
        # if the neighborhood is size 3, there's one eligible move (the jump move)
        x_cur , y_cur = props(g, cur_pos)[:x] , props(g, cur_pos)[:y]
        x_oth , y_oth = props(g, other_player)[:x] , props(g, other_player)[:y]
        if x_cur == x_oth
            common_dim = :x
            common_val = x_cur
        else
            common_dim = :y
            common_val = y_cur
        end
        # check if one neighbor share the same dimension 
        opposite_check = filter(x -> props(g, x)[common_dim] == common_val, other_player_potential)
        # if there's one, that's the only valid move
        if length(opposite_check) == 0
            return vcat(potential, opposite_check)
        else
            # if not, add all neighbors
            return vcat(potential, other_player_potential)
        end
    else 
        return potential
    end
end

# function that makes the move
function move_pawn!(gs::GameState, new_id::Int)
    # move the pawn from id to new_id
    # check if the move is valid
    if new_id in get_valid_moves(gs)
        gs.players[gs.turn] = new_id
        gs.turn = gs.turn == White ? Black : White
    end
end

# function that lists the valid barriers move
function get_valid_barriers(gs::GameState)
    # check if the barrier move is valid
    # get the node Id of the upper left node of the barrier
    # so the eligible Barrier Ids are 1 to 8, 10 to 17, 19 to 26, 28 to 35, 37 to 44, 46 to 53, 55 to 62, 64 to 71
    if gs.barriers[gs.turn] == 0
        return []
    end
    valid_barrier = []
    # a barrier is valid if the potential edges are not already removed
    for i in 1:BOARD_SIZE^2
        if !(i in map(x -> x.id ,gs.played_barriers) )
            if i % BOARD_SIZE != 0
                if has_edge(gs.graph, i, i+1) && has_edge(gs.graph, i+BOARD_SIZE, i+BOARD_SIZE+1)
                    g = deepcopy(gs.graph)
                    rem_edge!(g, i, i + 1)
                    rem_edge!(g, i+BOARD_SIZE, i+BOARD_SIZE+1)
                    if ! is_cutting_barrier(gs, g) 
                        push!(valid_barrier, Barrier(i, Vertical))
                    end
                end
                if has_edge(gs.graph, i, i+BOARD_SIZE) && has_edge(gs.graph, i+1, i+BOARD_SIZE+1)
                    g = deepcopy(gs.graph)
                    rem_edge!(g, i, i+BOARD_SIZE)
                    rem_edge!(g, i+1, i+BOARD_SIZE+1)
                    if ! is_cutting_barrier(gs, g) 
                        push!(valid_barrier, Barrier(i, Horizontal))
                    end
                end
            end
        end
    end
    return valid_barrier
end




function is_cutting_barrier(gs::GameState,g::MetaGraph)
    # check if a barrier is cutting the path for the 2 players
    # costly function ...
    winning_nodes_cur = winning_positions[gs.turn]
    winning_nodes_other = winning_positions[gs.turn == White ? Black : White]
    #make a deep copy of the graph
    for node in winning_nodes_other
        if (has_path(g, gs.players[gs.turn == White ? Black : White] , node)) 
            for node in winning_nodes_cur
                if (has_path(g, gs.players[gs.turn] , node)) 
                    return false
                end
            end
        end
    end
    return true
end


function add_barrier!(gs::GameState, b::Barrier)
    # add a barrier to the graph
    # barrier are removing edges between two nodes
    # horizontal barrier remove the edge between (i,j) and (i,j+1)
    # vertical barrier remove the edge between (i,j) and (i+1,j)
    # get the node Id of the upper left node of the barrier
    # so the eligible nodes are 1 to 8, 10 to 17, 19 to 26, 28 to 35, 37 to 44, 46 to 53, 55 to 62, 64 to 71
    if b.barrier_type == Horizontal
        remove_edge!(gs.graph, id, id + BOARD_SIZE)
        remove_edge!(gs.graph, id+1, id+BOARD_SIZE+1)
    elseif b.barrier_type == Vertical
        remove_edge!(gs.graph, id, id+1)
        remove_edge!(gs.graph, id+BOARD_SIZE, id+BOARD_SIZE+1)
    end
    gs.played_barriers = vcat(gs.played_barriers, Barrier(id, barrier_type))
    gs.barriers[gs.turn] -= 1
    gs.turn = gs.turn == White ? Black : White

end