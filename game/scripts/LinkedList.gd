extends RefCounted
class_name LinkedList

class LinkedListItem:
	extends RefCounted
	
	var next: LinkedListItem = null
	var previous: LinkedListItem = null
	var data: Variant
	
	func _init(v: Variant) -> void:
		data = v
	
	func link(other: LinkedListItem) -> void:
		other.previous = self
		next = other
	
	func unlink() -> void:
		var _next := next
		var _previous := previous
		if _previous:
			_previous.next = next
		if _next:
			_next.previous = previous

var _tail: LinkedListItem = null
var _head: LinkedListItem = _tail
var _len := 0

func size() -> int:
	return _len

func push_back(val: Variant) -> void:
	if _len == 0:
		_head = LinkedListItem.new(val)
		_tail = _head
	else:
		var new_head := LinkedListItem.new(val)
		_head.link(new_head)
		_head = new_head
	_len += 1

func push_front(val: Variant) -> void:
	if _len == 0:
		_head = LinkedListItem.new(val)
		_tail = _head
	else:
		var new_tail := LinkedListItem.new(val)
		new_tail.link(_tail)
		_tail = new_tail
	_len += 1

func pop_back() -> Variant:
	if _len == 0:
		return null
	else:
		var result: Variant = _head.data
		_head = _head.previous
		_len -= 1
		return result

func pop_front() -> Variant:
	if _len == 0:
		return null
	else:
		if !_tail:
			return null
		var result: Variant = _tail.data
		_tail = _tail.next
		_len -= 1
		return result
