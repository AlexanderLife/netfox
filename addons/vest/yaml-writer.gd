extends Object
class_name YAMLWriter

## YAML serializer.
##
## Used for adding extra data to [TAPReporter] reports.
## [br][br]
## For custom types, implement [code]_to_yaml[/code]. It should return a basic
## type, which will be then serialized.
## [br][br]
## Alternatively, implement [code]_to_yaml_raw[/code], which should return the
## raw YAML string.
## [br][br]
## [b]Not recommended for use outside of generating test reports.[/b]

## Convert a value to YAML.
static func stringify(what, indent: int = 0) -> String:
	if indent > 0:
		return _indented(stringify(what), indent)
	
	match typeof(what):
		TYPE_NIL:
			return "null"
		
		TYPE_INT,TYPE_FLOAT,TYPE_BOOL:
			return str(what)
		
		TYPE_STRING,TYPE_STRING_NAME,TYPE_NODE_PATH:
			what = str(what)
			if		(not what.contains("\n")) and								\
					(not what.contains("\"")) and								\
					(what.strip_edges() == what):
				return what
			return "\"%s\"" % what.c_escape()
		
		TYPE_PACKED_BYTE_ARRAY,													\
		TYPE_PACKED_INT32_ARRAY,												\
		TYPE_PACKED_INT64_ARRAY,												\
		TYPE_PACKED_FLOAT32_ARRAY,												\
		TYPE_PACKED_FLOAT64_ARRAY,												\
		TYPE_PACKED_STRING_ARRAY,												\
		TYPE_PACKED_VECTOR2_ARRAY,												\
		TYPE_PACKED_VECTOR3_ARRAY,												\
		TYPE_PACKED_COLOR_ARRAY,												\
		TYPE_PACKED_VECTOR4_ARRAY,												\
		TYPE_ARRAY:
			what = Array(what)
			var result = (what
			.map(func(it): return stringify(it))
			.map(func(it): return _indented_value(it, 2))
			.map(func(it): return "- " + it)
			)
			return "\n".join(result)
		
		TYPE_DICTIONARY:
			var result : PackedStringArray = []
			for key in what.keys():
				var value = what.get(key)
				result.append("%s: %s" % [_stringify_key(key), _stringify_value(value)])
			return "\n".join(result)
		
		TYPE_OBJECT:
			if what.has_method("_to_yaml"):
				return stringify(what.call("_to_yaml", indent))
			elif what.has_method("_to_yaml_raw"):
				return what.call("_to_yaml_raw", indent)
		
		TYPE_VECTOR2,TYPE_VECTOR2I,TYPE_RECT2,									\
		TYPE_RECT2I,TYPE_VECTOR3,TYPE_VECTOR3I,									\
		TYPE_TRANSFORM2D,TYPE_VECTOR4,TYPE_VECTOR4I,							\
		TYPE_PLANE,TYPE_QUATERNION,TYPE_AABB,									\
		TYPE_BASIS,TYPE_TRANSFORM3D,TYPE_PROJECTION,							\
		TYPE_RID,TYPE_CALLABLE,TYPE_SIGNAL,										\
		TYPE_MAX,_:
			pass
	return stringify(str(what))

static func _indented(what: String, level: int) -> String:
	if level == 0:
		return what

	var prefix := " ".repeat(level)
	var lines := what.split("\n")
	for i in range(lines.size()):
		lines[i] = prefix + lines[i]
	return "\n".join(lines)

static func _indented_value(what: String, level: int) -> String:
	if level == 0 or not what.contains("\n"):
		return what
	else:
		return "\n" + _indented(what, level)

static func _stringify_key(what) -> String:
	if typeof(what) == TYPE_STRING:
		if RegEx.create_from_string("[\\s\"']").search(what):
			return stringify(what)
		else:
			return what
	return stringify(str(what))

static func _stringify_value(what) -> String:
	if		what is Array or													\
			what is Dictionary or												\
			what is Object:
		return "\n" + stringify(what, 2)
	return stringify(what)
	
