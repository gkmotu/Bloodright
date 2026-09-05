extends SceneTree

func _init() -> void:
    var repository := ContentRepository.new()
    if not repository.load_published():
        quit(1)
        return
    var state := BloodrightGameState.new()
    state.begin(repository)
    # Put the player just outside the Fire Dragon's awareness range, then step in.
    state.player.x = 13
    state.player.y = 2
    state.try_move(Vector2i.LEFT)
    if not state.combat_active or state.combat_phase != "player":
        push_error("Expected Fire Dragon combat to begin on entering awareness range.")
        quit(1)
        return
    var position_before := Vector2i(state.player.x, state.player.y)
    state.try_move(Vector2i.RIGHT)
    if Vector2i(state.player.x, state.player.y) != position_before:
        push_error("Movement must be locked during combat.")
        quit(1)
        return
    state.shoot_broken_arrow()
    if not state.dead or state.player.hp != 0:
        push_error("Dragonfire after the broken-arrow action must be fatal.")
        quit(1)
        return
    print("Combat verification passed.")
    quit(0)
