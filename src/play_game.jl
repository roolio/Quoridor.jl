using Quoridor
using Statistics


function run_game()
    gs = Quoridor.GameState()
    while ! Quoridor.is_terminal(gs)
        my_move = rand(Quoridor.get_valid_moves(gs))
        if typeof(my_move) == Quoridor.Barrier
            Quoridor.add_barrier!(gs, my_move)
        else
            Quoridor.move_pawn!(gs, my_move)
        end
    end
end

result = @timed run_game()