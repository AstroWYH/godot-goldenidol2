extends RefCounted



static  var revealed_segments: Array[String] = []

static func reveal_segment(segment_node_name: String) -> void :
    if segment_node_name in revealed_segments:
        return
    revealed_segments.append(segment_node_name)


static func is_segment_revealed(segment_node_name: String) -> bool:
    return segment_node_name in revealed_segments
