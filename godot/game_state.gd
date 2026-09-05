class_name BloodrightGameState
extends RefCounted

var repository: ContentRepository
var map: Dictionary
var player := {"x": 0, "y": 0, "hp": 10, "max_hp": 10, "inventory": []}
var ground_items: Array = []
var messages: PackedStringArray = []
var turn := 0
var dragon_seen := false
var combat_active := false
var combat_phase := ""
var dead := false

func begin(repo: ContentRepository) -> void:
    repository = repo
    map = repo.first_map().duplicate(true)
    player.x = int(map.playerStart.x)
    player.y = int(map.playerStart.y)
    player.hp = 10
    player.inventory = []
    ground_items = map.get("items", []).duplicate(true)
    messages = PackedStringArray(["You enter %s." % map.name, "Find the Rustblade and Redleaf Tonic."])
    turn = 0
    dragon_seen = false
    combat_active = false
    combat_phase = ""
    dead = false

func terrain_at(x: int, y: int) -> Dictionary:
    if x < 0 or y < 0 or x >= int(map.width) or y >= int(map.height): return {}
    var symbol: String = map.tiles[y][x]
    return repository.terrain_by_id.get(map.legend.get(symbol, ""), {})

func try_move(delta: Vector2i) -> bool:
    if dead: return false
    if combat_active:
        messages.append("Navigation has stopped. You are engaged with the Fire Dragon; choose a combat action.")
        return false
    var x: int = player.x + delta.x
    var y: int = player.y + delta.y
    var terrain := terrain_at(x, y)
    if terrain.is_empty() or not terrain.get("walkable", false):
        messages.append("%s blocks your path." % terrain.get("name", "The dark"))
        return false
    player.x = x
    player.y = y
    turn += 1
    if _dragon_can_see_player():
        dragon_seen = true
        combat_active = true
        combat_phase = "player"
        messages.append("A vast presence stirs in the north-east. The Fire Dragon has seen you.")
        messages.append("COMBAT BEGINS — Your turn. Navigation is locked until this encounter resolves.")
    for placed: Dictionary in ground_items:
        if int(placed.x) == x and int(placed.y) == y:
            messages.append("You see %s. Press G to take it." % repository.item_by_id[placed.itemId].name)
            break
    return true

func pickup() -> bool:
    if dead: return false
    if combat_active:
        messages.append("You cannot search the floor while the Fire Dragon is engaged.")
        return false
    for index in ground_items.size():
        var placed: Dictionary = ground_items[index]
        if int(placed.x) == player.x and int(placed.y) == player.y:
            ground_items.remove_at(index)
            player.inventory.append(placed.itemId)
            messages.append("You take %s." % repository.item_by_id[placed.itemId].name)
            turn += 1
            return true
    messages.append("There is nothing here to take.")
    return false

func dragon() -> Dictionary:
    var actors: Array = map.get("actors", [])
    return actors[0] if not actors.is_empty() else {}

func _dragon_can_see_player() -> bool:
    var actor := dragon()
    if actor.is_empty() or dragon_seen: return false
    var distance := absi(int(actor.x) - player.x) + absi(int(actor.y) - player.y)
    return distance <= int(actor.get("awarenessRange", 10))

func shoot_broken_arrow() -> void:
    if dead or not combat_active or combat_phase != "player": return
    var attack_roll := randi_range(1, 20)
    messages.append("YOUR TURN — You loose a broken arrow at the Fire Dragon. Attack roll: 1d20 = %d." % attack_roll)
    messages.append("The arrow shatters harmlessly against its ember-red scales.")
    combat_phase = "dragon"
    messages.append("DRAGON'S TURN — The Fire Dragon draws in a furnace breath.")
    _fire_dragon_attack()

func _fire_dragon_attack() -> void:
    var damage_roll := randi_range(1, 20)
    var damage := damage_roll + 10
    messages.append("The Fire Dragon rolls 1d20 for dragonfire: %d + 10 = %d damage." % [damage_roll, damage])
    player.hp = maxi(0, player.hp - damage)
    dead = true
    combat_active = false
    combat_phase = ""
    messages.append("A ball of fire strikes you full in the head. You die.")
