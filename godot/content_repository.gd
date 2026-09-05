class_name ContentRepository
extends RefCounted

const PUBLISHED_PATH := "res://content/published/content.json"

var content: Dictionary = {}
var terrain_by_id: Dictionary = {}
var item_by_id: Dictionary = {}
var description_by_id: Dictionary = {}

func load_published() -> bool:
    if not FileAccess.file_exists(PUBLISHED_PATH):
        push_error("Published content is missing. Run: npm run publish")
        return false
    var file := FileAccess.open(PUBLISHED_PATH, FileAccess.READ)
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        push_error("Published content is not valid JSON.")
        return false
    content = parsed
    terrain_by_id.clear()
    item_by_id.clear()
    description_by_id.clear()
    for terrain: Dictionary in content.get("terrain", []):
        terrain_by_id[terrain.id] = terrain
    for item: Dictionary in content.get("items", []):
        item_by_id[item.id] = item
    for description: Dictionary in content.get("descriptions", []):
        description_by_id[description.id] = description
    return true

func first_map() -> Dictionary:
    var maps: Array = content.get("maps", [])
    return maps[0] if not maps.is_empty() else {}

func validate() -> PackedStringArray:
    var errors := PackedStringArray()
    var ids := {}
    for collection_name: String in ["terrain", "items", "descriptions", "maps"]:
        for record: Dictionary in content.get(collection_name, []):
            var id: String = record.get("id", "")
            if id.is_empty(): errors.append("A %s record has no stable ID." % collection_name)
            elif ids.has(id): errors.append("Duplicate ID: %s" % id)
            ids[id] = true
    for description: Dictionary in content.get("descriptions", []):
        if description.get("name", "").is_empty(): errors.append("A description needs a name.")
        if description.get("tagId", "").is_empty(): errors.append("%s needs a tag ID." % description.get("id", "Description"))
        if not description.get("type", "") in ["prop", "item", "terrain", "character", "ui"]: errors.append("%s has an invalid type." % description.get("id", "Description"))
        if not description.get("glyphSize", "") in ["small", "large"]: errors.append("%s needs a small or large glyph size." % description.get("id", "Description"))
    for map: Dictionary in content.get("maps", []):
        for terrain_id: String in map.get("legend", {}).values():
            if not terrain_by_id.has(terrain_id): errors.append("Map references missing terrain: %s" % terrain_id)
        for actor: Dictionary in map.get("actors", []):
            if not description_by_id.has(actor.get("descriptionId", "")):
                errors.append("Map references missing description: %s" % actor.get("descriptionId", ""))
    return errors
