extends GutTest

class ValueChangeTester extends RefCounted:
	var was_called : bool = false
	
	func on_fvar_value_changed() -> void:
		was_called = true

func test_value_change_callback():
	var fsys := FSystem.new()
	var fnode := fsys.alloc_node()
	
	var listener := ValueChangeTester.new()
	fnode.h_psi.add_value_change_listener(listener.on_fvar_value_changed)
	assert_eq(fnode.h_psi.value_change_listener_count(), 1)
	
	# make sure the value_change callback logic works
	fnode.h_psi.value = 10.0
	assert_true(listener.was_called)
	assert_eq(fnode.h_psi.value_change_listener_count(), 1)
	
	# free our listener and make sure it gets pruned from the fvar
	listener = null
	fnode.h_psi.value = 20.0
	assert_eq(fnode.h_psi.value_change_listener_count(), 0)
