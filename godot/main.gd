extends Control

const TILE_SIZE := 42
var GOLD := Color("c6a15b")
var INK := Color("d8d0ba")
var MUTED := Color("918b7d")
var BACKGROUND := Color("0b0e0f")

var repository := ContentRepository.new()
var game := BloodrightGameState.new()
var page: Control
var map_grid: GridContainer
var stats_label: Label
var inventory_box: VBoxContainer
var message_label: Label
var selected_terrain := 0
var selected_item := 0
var description_index := 0
var story_popup: PanelContainer
var story_title: Label
var story_text: Label
var story_button: Button
var dragon_warning_shown := false
var combat_actions: VBoxContainer
var notification_stack: VBoxContainer
var push_status: Label
var push_button: Button
var push_in_progress := false
var push_last_message := ""
var push_last_stage := ""

func _ready() -> void:
    _create_notification_stack()
    if not repository.load_published(): return
    var errors := repository.validate()
    if not errors.is_empty():
        push_error("\n".join(errors)); return
    _apply_visual_settings()
    game.begin(repository)
    _show_home()
    if OS.get_environment("BLOODRIGHT_UPDATED") == "1":
        call_deferred("show_notification", "NEW BUILD INSTALLED", "Bloodright updated from main and is ready to play.", Color("6bab76"), "RESTART ENGINE", _restart_engine)
    else:
        call_deferred("show_notification", "BLOODRIGHT ENGINE", "The First Vault is ready for play.")

func _unhandled_key_input(event: InputEvent) -> void:
    if not event.pressed or event.echo or not is_instance_valid(map_grid): return
    var key: String = event.as_text_keycode().to_lower()
    var directions := {"w": Vector2i.UP, "up": Vector2i.UP, "s": Vector2i.DOWN, "down": Vector2i.DOWN, "a": Vector2i.LEFT, "left": Vector2i.LEFT, "d": Vector2i.RIGHT, "right": Vector2i.RIGHT}
    if directions.has(key): game.try_move(directions[key]); _render_game()
    elif key == "g": game.pickup(); _render_game()
    elif key == "r": game.begin(repository); _render_game()

func _process(_delta: float) -> void:
    if not push_in_progress: return
    _refresh_push_status()

func _shell(_title: String) -> VBoxContainer:
    if is_instance_valid(story_popup):
        story_popup.queue_free()
        story_popup = null
    for child in get_children():
        if child != notification_stack: child.queue_free()
    map_grid = null
    var root := VBoxContainer.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_theme_constant_override("separation", 0); add_child(root)
    var header := HBoxContainer.new(); header.custom_minimum_size.y = 76; header.add_theme_constant_override("separation", 10); root.add_child(header)
    var brand := Label.new(); brand.text = "  ◇  BLOODRIGHT\n      A DARK FANTASY ROGUELIKE"; brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL; brand.add_theme_color_override("font_color", GOLD); header.add_child(brand)
    for entry in [["HOME", _show_home], ["PLAY", _show_game], ["TERRAIN", _show_terrain_editor], ["ITEMS", _show_item_editor], ["DESCRIPTIONS", _show_description_editor], ["MAPS", _show_map_editor], ["SETTINGS", _show_settings], ["PUSH", _show_push_build]]:
        var button := Button.new(); button.text = entry[0]; button.pressed.connect(entry[1]); header.add_child(button)
    var rule := HSeparator.new(); root.add_child(rule)
    page = MarginContainer.new(); page.add_theme_constant_override("margin_left", 48); page.add_theme_constant_override("margin_right", 48); page.add_theme_constant_override("margin_top", 32); page.add_theme_constant_override("margin_bottom", 32); page.size_flags_vertical = Control.SIZE_EXPAND_FILL; root.add_child(page)
    return root

func _show_home() -> void:
    _shell("Home")
    var center := CenterContainer.new(); page.add_child(center)
    var box := VBoxContainer.new(); box.custom_minimum_size.x = 720; box.add_theme_constant_override("separation", 20); center.add_child(box)
    var eyebrow := Label.new(); eyebrow.text = "FIRST PLAYABLE CHRONICLE"; eyebrow.add_theme_color_override("font_color", GOLD); box.add_child(eyebrow)
    var title := Label.new(); title.text = "The First Vault\nawaits."; title.add_theme_font_size_override("font_size", 56); box.add_child(title)
    var copy := Label.new(); copy.text = "Walk its forgotten halls, recover the Rustblade, and discover\nthe beginnings of Isabelle's world."; copy.add_theme_color_override("font_color", MUTED); copy.add_theme_font_size_override("font_size", 21); box.add_child(copy)
    var enter := Button.new(); enter.text = "ENTER BLOODRIGHT"; enter.custom_minimum_size = Vector2(230, 54); enter.pressed.connect(_show_game); box.add_child(enter)

func _show_game() -> void:
    _shell("Play")
    var layout := HBoxContainer.new(); layout.add_theme_constant_override("separation", 20); page.add_child(layout)
    var map_panel := PanelContainer.new(); map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; layout.add_child(map_panel)
    var center := CenterContainer.new(); map_panel.add_child(center)
    map_grid = GridContainer.new(); map_grid.columns = int(game.map.width); center.add_child(map_grid)
    var sidebar := VBoxContainer.new(); sidebar.custom_minimum_size.x = 280; sidebar.add_theme_constant_override("separation", 14); layout.add_child(sidebar)
    stats_label = Label.new(); sidebar.add_child(_panel("WAYFARER", stats_label))
    inventory_box = VBoxContainer.new(); sidebar.add_child(_panel("PACK", inventory_box))
    combat_actions = VBoxContainer.new(); sidebar.add_child(_panel("COMBAT", combat_actions))
    var help := Label.new(); help.text = "WASD / ARROWS   Move\nG               Take\nR               Restart"; help.add_theme_color_override("font_color", MUTED); sidebar.add_child(_panel("COMMANDS", help))
    message_label = Label.new(); message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; sidebar.add_child(_panel("CHRONICLE", message_label))
    _create_story_popup()
    _render_game()

func _panel(title: String, body: Control) -> PanelContainer:
    var panel := PanelContainer.new(); var margin := MarginContainer.new(); margin.add_theme_constant_override("margin_left", 16); margin.add_theme_constant_override("margin_right", 16); margin.add_theme_constant_override("margin_top", 14); margin.add_theme_constant_override("margin_bottom", 14); panel.add_child(margin)
    var box := VBoxContainer.new(); margin.add_child(box); var heading := Label.new(); heading.text = title; heading.add_theme_color_override("font_color", GOLD); box.add_child(heading); box.add_child(HSeparator.new()); box.add_child(body); return panel

func _render_game() -> void:
    if not is_instance_valid(map_grid): return
    for child in map_grid.get_children(): child.queue_free()
    for y in int(game.map.height):
        for x in int(game.map.width):
            var terrain := game.terrain_at(x, y); var glyph: String = terrain.get("glyph", "?"); var color := Color(terrain.get("color", "#ffffff"))
            for actor: Dictionary in game.map.get("actors", []):
                if int(actor.x) == x and int(actor.y) == y:
                    var description: Dictionary = repository.description_by_id[actor.descriptionId]
                    glyph = description.symbol; color = Color(description.color)
            for placed: Dictionary in game.ground_items:
                if int(placed.x) == x and int(placed.y) == y:
                    var item: Dictionary = repository.item_by_id[placed.itemId]; glyph = item.glyph; color = Color(item.color)
            if game.player.x == x and game.player.y == y: glyph = "@"; color = Color("f7e1a1")
            var tile := Label.new(); tile.text = glyph; tile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tile.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; tile.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE); tile.add_theme_font_size_override("font_size", 27); tile.add_theme_color_override("font_color", color); map_grid.add_child(tile)
    stats_label.text = "Health  %d / %d\nTurn    %d" % [game.player.hp, game.player.max_hp, game.turn]
    for child in inventory_box.get_children(): child.queue_free()
    if game.player.inventory.is_empty(): var empty := Label.new(); empty.text = "Empty"; empty.add_theme_color_override("font_color", MUTED); inventory_box.add_child(empty)
    for id: String in game.player.inventory: var item: Dictionary = repository.item_by_id[id]; var label := Label.new(); label.text = "%s  %s" % [item.glyph, item.name]; inventory_box.add_child(label)
    message_label.text = "› " + "\n› ".join(game.messages.slice(maxi(0, game.messages.size() - 5)))
    _render_combat_actions()
    if game.dead:
        _show_death_popup()
    elif game.combat_active and not dragon_warning_shown:
        dragon_warning_shown = true
        _show_dragon_encounter()

func _render_combat_actions() -> void:
    if not is_instance_valid(combat_actions): return
    for child in combat_actions.get_children(): child.queue_free()
    if not game.combat_active:
        var quiet := Label.new(); quiet.text = "No enemy engaged."; quiet.add_theme_color_override("font_color", MUTED); combat_actions.add_child(quiet)
        return
    var phase := Label.new(); phase.text = "YOUR TURN — Choose an action"; phase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; combat_actions.add_child(phase)
    var arrow := Button.new(); arrow.text = "SHOOT BROKEN ARROW"; arrow.tooltip_text = "A desperate opening attack against the Fire Dragon."; arrow.pressed.connect(_shoot_broken_arrow); combat_actions.add_child(arrow)
    var locked := Label.new(); locked.text = "Movement and pickup are locked during combat."; locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; locked.add_theme_color_override("font_color", MUTED); combat_actions.add_child(locked)

func _create_story_popup() -> void:
    if is_instance_valid(story_popup): story_popup.queue_free()
    story_popup = PanelContainer.new()
    story_popup.set_anchors_preset(Control.PRESET_CENTER)
    story_popup.offset_left = -290
    story_popup.offset_top = -155
    story_popup.offset_right = 290
    story_popup.offset_bottom = 155
    add_child(story_popup)
    var margin := MarginContainer.new(); margin.add_theme_constant_override("margin_left", 38); margin.add_theme_constant_override("margin_right", 38); margin.add_theme_constant_override("margin_top", 32); margin.add_theme_constant_override("margin_bottom", 32); story_popup.add_child(margin)
    var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 16); margin.add_child(box)
    story_title = Label.new(); story_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; story_title.add_theme_color_override("font_color", GOLD); story_title.add_theme_font_size_override("font_size", 32); box.add_child(story_title)
    var line := HSeparator.new(); box.add_child(line)
    story_text = Label.new(); story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; story_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; story_text.size_flags_vertical = Control.SIZE_EXPAND_FILL; story_text.add_theme_font_size_override("font_size", 19); box.add_child(story_text)
    story_button = Button.new(); story_button.custom_minimum_size.y = 44; box.add_child(story_button)
    story_popup.visible = false

func _show_dragon_encounter() -> void:
    show_notification("THE LONG NIGHT STIRS", "The Fire Dragon has seen you. Combat has begun.", Color("b84a40"))
    story_popup.visible = true
    story_title.text = "THE LONG NIGHT STIRS"
    story_text.text = "A red shape fills the northern dark. The Fire Dragon has found you.\n\nCOMBAT BEGINS. The vault seals away every path but action. Your broken arrow is all you can reach."
    story_button.text = "SHOOT THE BROKEN ARROW"
    story_button.pressed.connect(_shoot_broken_arrow, CONNECT_ONE_SHOT)

func _shoot_broken_arrow() -> void:
    if is_instance_valid(story_popup): story_popup.visible = false
    game.shoot_broken_arrow()
    _render_game()

func _show_death_popup() -> void:
    story_popup.visible = true
    story_title.text = "THE LONG NIGHT"
    story_text.text = "Fire falls like a star upon your brow. The vault takes your breath, your name, and the warmth from your hands.\n\nBeyond the last ember, the Long Night gathers its dead. Bloodright remembers you."
    story_button.text = "RETURN TO THE VAULT"
    if not story_button.pressed.is_connected(_restart_after_death): story_button.pressed.connect(_restart_after_death)

func _restart_after_death() -> void:
    game.begin(repository)
    dragon_warning_shown = false
    story_popup.visible = false
    _render_game()

func _create_notification_stack() -> void:
    notification_stack = VBoxContainer.new()
    notification_stack.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    notification_stack.offset_left = 22
    notification_stack.offset_right = 410
    notification_stack.offset_top = -340
    notification_stack.offset_bottom = -22
    notification_stack.alignment = BoxContainer.ALIGNMENT_END
    notification_stack.add_theme_constant_override("separation", 8)
    notification_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(notification_stack)

func show_notification(title: String, message: String, accent := GOLD, action_text := "", action := Callable()) -> void:
    if not is_instance_valid(notification_stack): return
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(360, 0)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    card.add_child(margin)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 4)
    margin.add_child(box)
    var heading := Label.new()
    heading.text = title
    heading.add_theme_color_override("font_color", accent)
    heading.add_theme_font_size_override("font_size", 13)
    box.add_child(heading)
    var copy := Label.new()
    copy.text = message
    copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    copy.add_theme_color_override("font_color", INK)
    box.add_child(copy)
    if not action_text.is_empty() and action.is_valid():
        var action_button := Button.new()
        action_button.text = action_text
        action_button.custom_minimum_size.y = 32
        action_button.pressed.connect(action)
        box.add_child(action_button)
    notification_stack.add_child(card)
    card.modulate = Color(1, 1, 1, 0)
    card.scale = Vector2(0.92, 0.92)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(card, "modulate:a", 1.0, 0.2)
    tween.tween_property(card, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.chain().tween_interval(4.4)
    tween.tween_property(card, "modulate:a", 0.0, 0.35)
    tween.tween_callback(card.queue_free)

func _show_terrain_editor() -> void: _show_record_editor("TERRAIN ATELIER", "terrain")
func _show_item_editor() -> void: _show_record_editor("ITEM FORGE", "items")
func _show_record_editor(title: String, collection: String) -> void:
    _shell(title); var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 14); page.add_child(box)
    var heading := Label.new(); heading.text = title; heading.add_theme_font_size_override("font_size", 40); heading.add_theme_color_override("font_color", GOLD); box.add_child(heading)
    var note := Label.new(); note.text = "Published Bloodright definitions · Disk publishing: npm run publish"; note.add_theme_color_override("font_color", MUTED); box.add_child(note)
    var grid := GridContainer.new(); grid.columns = 5; grid.add_theme_constant_override("h_separation", 12); grid.add_theme_constant_override("v_separation", 12); box.add_child(grid)
    for record: Dictionary in repository.content.get(collection, []):
        var card := PanelContainer.new(); card.custom_minimum_size = Vector2(210, 150); var text := Label.new(); text.text = "%s   %s\n\n%s\n\n%s" % [record.get("glyph", "?"), record.name, record.id, record.get("description", "")]; text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; card.add_child(text); grid.add_child(card)

func _show_description_editor() -> void:
    _shell("Descriptions")
    var layout := HBoxContainer.new(); layout.add_theme_constant_override("separation", 18); page.add_child(layout)
    var library := VBoxContainer.new(); library.custom_minimum_size.x = 270; library.add_theme_constant_override("separation", 8); layout.add_child(_panel("DESCRIPTION LIBRARY", library))
    var descriptions: Array = repository.content.get("descriptions", [])
    for index in descriptions.size():
        var entry: Dictionary = descriptions[index]
        var button := Button.new(); button.text = "%s  %s" % [entry.get("symbol", "?"), entry.get("name", "Unnamed")]; button.tooltip_text = entry.get("tagId", "")
        if index == description_index: button.disabled = true
        button.pressed.connect(func() -> void: description_index = index; _show_description_editor())
        library.add_child(button)
    var create := Button.new(); create.text = "+ NEW DESCRIPTION"; create.pressed.connect(_new_description); library.add_child(create)
    if descriptions.is_empty(): return
    description_index = clampi(description_index, 0, descriptions.size() - 1)
    var selected_entry: Dictionary = descriptions[description_index]
    var editor := VBoxContainer.new(); editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL; editor.add_theme_constant_override("separation", 12); layout.add_child(_panel("DESCRIPTION DETAILS", editor))
    var guidance := Label.new(); guidance.text = "A reusable visual definition. Changes save locally as you make them; use PUSH to send them to master."; guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; guidance.add_theme_color_override("font_color", MUTED); editor.add_child(guidance)
    var form := GridContainer.new(); form.columns = 2; form.add_theme_constant_override("h_separation", 16); form.add_theme_constant_override("v_separation", 10); editor.add_child(form)
    var name_input := _description_text_field(form, "Name", selected_entry.get("name", ""))
    var symbol_input := _description_text_field(form, "Symbol", selected_entry.get("symbol", "?"))
    var tag_input := _description_text_field(form, "Tag ID", selected_entry.get("tagId", ""))
    var id_input := _description_text_field(form, "Stable ID", selected_entry.get("id", ""))
    var type_select := OptionButton.new()
    var type_options: Array[String] = ["prop", "item", "terrain", "character", "ui"]
    for option: String in type_options:
        type_select.add_item(option)
    var selected_type_index := type_options.find(str(selected_entry.get("type", "prop")))
    type_select.select(maxi(0, selected_type_index))
    _description_labeled_control(form, "Type", type_select)
    var size_select := OptionButton.new(); size_select.add_item("small"); size_select.add_item("large"); size_select.select(1 if selected_entry.get("glyphSize", "small") == "large" else 0); _description_labeled_control(form, "Symbol size", size_select)
    var color_picker := ColorPickerButton.new(); color_picker.color = Color(selected_entry.get("color", "#ffffff")); _description_labeled_control(form, "Colour", color_picker)
    var thumb_label := Label.new(); thumb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; thumb_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; thumb_label.custom_minimum_size = Vector2(100, 76); _description_labeled_control(form, "Visual thumbnail", thumb_label)
    var description_input := TextEdit.new(); description_input.text = selected_entry.get("description", ""); description_input.custom_minimum_size.y = 110; editor.add_child(_description_labeled_control(editor, "Description", description_input, false))
    var refresh_thumbnail := func() -> void:
        thumb_label.text = symbol_input.text.left(1) if not symbol_input.text.is_empty() else "?"
        thumb_label.add_theme_font_size_override("font_size", 48 if size_select.selected == 1 else 26)
        thumb_label.add_theme_color_override("font_color", color_picker.color)
    refresh_thumbnail.call()
    name_input.text_changed.connect(func(value: String) -> void: selected_entry.name = value; _persist_description_draft_silently())
    symbol_input.text_changed.connect(func(value: String) -> void: selected_entry.symbol = value.left(1); refresh_thumbnail.call(); _persist_description_draft_silently())
    tag_input.text_changed.connect(func(value: String) -> void: selected_entry.tagId = value; _persist_description_draft_silently())
    id_input.text_changed.connect(func(value: String) -> void: selected_entry.id = value; _persist_description_draft_silently())
    type_select.item_selected.connect(func(index: int) -> void: selected_entry.type = type_select.get_item_text(index); _persist_description_draft_silently())
    size_select.item_selected.connect(func(index: int) -> void: selected_entry.glyphSize = size_select.get_item_text(index); refresh_thumbnail.call(); _persist_description_draft_silently())
    color_picker.color_changed.connect(func(value: Color) -> void: selected_entry.color = "#%s" % value.to_html(false); refresh_thumbnail.call(); _persist_description_draft_silently())
    description_input.text_changed.connect(func() -> void: selected_entry.description = description_input.text; _persist_description_draft_silently())
    var save := Button.new(); save.text = "SAVE AND PUBLISH DESCRIPTION"; save.custom_minimum_size = Vector2(300, 44); save.pressed.connect(_save_description_draft); editor.add_child(save)

func _description_labeled_control(parent: Control, label_text: String, control: Control, add_to_parent := true) -> VBoxContainer:
    var box := VBoxContainer.new(); var label := Label.new(); label.text = label_text.to_upper(); label.add_theme_color_override("font_color", MUTED); label.add_theme_font_size_override("font_size", 12); box.add_child(label); box.add_child(control)
    if add_to_parent: parent.add_child(box)
    return box

func _description_text_field(parent: Control, label_text: String, value: String) -> LineEdit:
    var input := LineEdit.new(); input.text = value; _description_labeled_control(parent, label_text, input); return input

func _new_description() -> void:
    var entries: Array = repository.content.get("descriptions", [])
    entries.append({"id": "bloodright.prop.new_description", "tagId": "prop.uncategorized", "type": "prop", "name": "New Description", "symbol": "?", "glyphSize": "small", "color": "#ffffff", "thumbnail": "glyph", "description": ""})
    repository.content.descriptions = entries
    description_index = entries.size() - 1
    _show_description_editor()

func _save_description_draft() -> void:
    var errors := repository.validate()
    if not errors.is_empty():
        push_error("Description draft was not saved:\n" + "\n".join(errors))
        return
    var file := FileAccess.open("res://content/source/descriptions.json", FileAccess.WRITE)
    if file == null:
        push_error("Could not write the description draft to content/source/descriptions.json")
        return
    file.store_string(JSON.stringify(repository.content.descriptions, "  ") + "\n")
    if not repository.save_published():
        push_error("Description was saved to source, but could not be published.")
        return
    show_notification("DESCRIPTION SAVED", "The published game data now includes this description after restart.", Color("6bab76"))

func _persist_description_draft_silently() -> void:
    var file := FileAccess.open("res://content/source/descriptions.json", FileAccess.WRITE)
    if file == null: return
    file.store_string(JSON.stringify(repository.content.descriptions, "  ") + "\n")
    repository.save_published()

func _show_map_editor() -> void:
    _shell("Map Scriptorium"); var box := VBoxContainer.new(); page.add_child(box)
    var heading := Label.new(); heading.text = "MAP SCRIPTORIUM"; heading.add_theme_font_size_override("font_size", 40); heading.add_theme_color_override("font_color", GOLD); box.add_child(heading)
    var note := Label.new(); note.text = "The visual painting workspace is scaffolded next; the First Vault already loads from editable JSON."; note.add_theme_color_override("font_color", MUTED); box.add_child(note)
    var map_info := Label.new(); var current := repository.first_map(); map_info.text = "\n%s\n%d × %d tiles\nStable ID: %s" % [current.name, current.width, current.height, current.id]; map_info.add_theme_font_size_override("font_size", 24); box.add_child(map_info)

func _show_push_build() -> void:
    _shell("Push Build")
    var center := CenterContainer.new(); page.add_child(center)
    var box := VBoxContainer.new(); box.custom_minimum_size.x = 680; box.add_theme_constant_override("separation", 16); center.add_child(box)
    var heading := Label.new(); heading.text = "PUSH BUILD"; heading.add_theme_font_size_override("font_size", 42); heading.add_theme_color_override("font_color", GOLD); box.add_child(heading)
    var copy := Label.new(); copy.text = "Finish a session by publishing content, running tests, committing the current local work, and pushing it to origin/main."; copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; copy.add_theme_color_override("font_color", MUTED); copy.add_theme_font_size_override("font_size", 19); box.add_child(copy)
    var update_note := Label.new(); update_note.text = "Installed Bloodright workspaces silently check main when launched. A new version shows as a lower-left notification."; update_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; box.add_child(update_note)
    push_button = Button.new(); push_button.text = "PUSH CURRENT CHANGES TO MAIN"; push_button.custom_minimum_size = Vector2(360, 52); push_button.pressed.connect(_push_current_build); box.add_child(push_button)
    var restart := Button.new(); restart.text = "RESTART ENGINE"; restart.custom_minimum_size = Vector2(220, 40); restart.pressed.connect(_restart_engine); box.add_child(restart)
    push_status = Label.new(); push_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; push_status.add_theme_color_override("font_color", MUTED); box.add_child(push_status)

func _push_current_build() -> void:
    if push_in_progress or not is_instance_valid(push_status): return
    push_status.text = "Starting Push Build…"
    push_last_message = ""
    push_last_stage = ""
    if is_instance_valid(push_button): push_button.disabled = true
    show_notification("PUSH BUILD", "Validating Bloodright before sending it to main.")
    var status_path := ProjectSettings.globalize_path("res://tools/push-status.json")
    if FileAccess.file_exists(status_path): DirAccess.remove_absolute(status_path)
    var script_path := ProjectSettings.globalize_path("res://tools/push-build.ps1")
    var process_id := OS.create_process("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script_path])
    if process_id == -1:
        push_status.text = "Could not start the Push Build process."
        if is_instance_valid(push_button): push_button.disabled = false
        show_notification("PUSH FAILED", "PowerShell could not start the build process.", Color("b84a40"))
        return
    push_in_progress = true

func _refresh_push_status() -> void:
    var status_path := "res://tools/push-status.json"
    if not FileAccess.file_exists(status_path): return
    var file := FileAccess.open(status_path, FileAccess.READ)
    var status: Variant = JSON.parse_string(file.get_as_text())
    if not status is Dictionary: return
    var stage: String = status.get("stage", "")
    var message: String = status.get("message", "")
    if not message.is_empty() and message != push_last_message:
        push_last_message = message
        if is_instance_valid(push_status): push_status.text = message
    if stage in ["complete", "failed"] and stage != push_last_stage:
        push_last_stage = stage
        push_in_progress = false
        if is_instance_valid(push_button): push_button.disabled = false
        if stage == "complete":
            show_notification("BUILD PUSHED", "Bloodright is now on main. Installed workspaces update on their next launch.", Color("6bab76"))
        else:
            show_notification("PUSH FAILED", "The build was not sent. Check the Push page for details.", Color("b84a40"))

func _restart_engine() -> void:
    var launcher_path := ProjectSettings.globalize_path("res://tools/start-bloodright.ps1")
    if FileAccess.file_exists(launcher_path):
        OS.create_process("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden", "-File", launcher_path])
        get_tree().quit()
    else:
        get_tree().reload_current_scene()

func _apply_visual_settings() -> void:
    var visual_theme: Dictionary = repository.content.get("settings", {}).get("theme", {})
    GOLD = Color(visual_theme.get("accent", "#c6a15b"))
    INK = Color(visual_theme.get("text", "#d8d0ba"))
    MUTED = Color(visual_theme.get("muted", "#918b7d"))
    BACKGROUND = Color(visual_theme.get("background", "#0b0e0f"))
    RenderingServer.set_default_clear_color(BACKGROUND)
    get_window().content_scale_factor = float(visual_theme.get("uiScale", 1.0))

func _show_settings() -> void:
    _shell("Settings")
    var center := CenterContainer.new(); page.add_child(center)
    var box := VBoxContainer.new(); box.custom_minimum_size.x = 640; box.add_theme_constant_override("separation", 14); center.add_child(box)
    var heading := Label.new(); heading.text = "APPLICATION SETTINGS"; heading.add_theme_font_size_override("font_size", 40); heading.add_theme_color_override("font_color", GOLD); box.add_child(heading)
    var note := Label.new(); note.text = "Saved settings are loaded every time Bloodright starts. Choose the visual language for this workspace, then save and publish it."; note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; note.add_theme_color_override("font_color", MUTED); box.add_child(note)
    var form := GridContainer.new(); form.columns = 2; form.add_theme_constant_override("h_separation", 18); form.add_theme_constant_override("v_separation", 12); box.add_child(form)
    var visual_theme: Dictionary = repository.content.get("settings", {}).get("theme", {})
    _settings_colour(form, "Accent colour", "accent", Color(visual_theme.get("accent", "#c6a15b")))
    _settings_colour(form, "Text colour", "text", Color(visual_theme.get("text", "#d8d0ba")))
    _settings_colour(form, "Muted text colour", "muted", Color(visual_theme.get("muted", "#918b7d")))
    _settings_colour(form, "Background colour", "background", Color(visual_theme.get("background", "#0b0e0f")))
    var scale_picker := OptionButton.new(); scale_picker.add_item("90%"); scale_picker.add_item("100%"); scale_picker.add_item("110%"); scale_picker.add_item("125%"); var values := [0.9, 1.0, 1.1, 1.25]; scale_picker.select(values.find(float(visual_theme.get("uiScale", 1.0)))); scale_picker.item_selected.connect(func(index: int) -> void: repository.content.settings.theme.uiScale = values[index]; _persist_settings_silently()); _description_labeled_control(form, "Interface scale", scale_picker)
    var save := Button.new(); save.text = "SAVE AND PUBLISH SETTINGS"; save.custom_minimum_size = Vector2(300, 48); save.pressed.connect(_save_visual_settings); box.add_child(save)

func _settings_colour(parent: Control, label_text: String, key: String, value: Color) -> void:
    var picker := ColorPickerButton.new(); picker.color = value
    picker.color_changed.connect(func(selected: Color) -> void: repository.content.settings.theme[key] = "#%s" % selected.to_html(false); _persist_settings_silently())
    _description_labeled_control(parent, label_text, picker)

func _save_visual_settings() -> void:
    if not repository.save_settings_source() or not repository.save_published():
        push_error("Bloodright could not save the application settings.")
        return
    _apply_visual_settings()
    show_notification("SETTINGS SAVED", "Colours and interface scale will load exactly the same after restart.", Color("6bab76"))

func _persist_settings_silently() -> void:
    repository.save_settings_source()
    repository.save_published()
