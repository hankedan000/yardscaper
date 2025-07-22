extends GutTest

class PropChainTestObject extends RefCounted:
	var propA : PropChainTestObject = null
	var propB : float = 0.0
	var propC : int = 10

func test_get_property_w_path():
	var test_obj := PropChainTestObject.new()
	test_obj.propA = PropChainTestObject.new()
	test_obj.propA.propA = null
	test_obj.propA.propB = 1234.0
	test_obj.propA.propC = 5678
	
	var res := Utils.get_property_w_path(test_obj, "")
	assert_true(is_instance_valid(res))
	assert_eq(res.found, true)
	assert_eq(res.parent_obj, null)
	assert_eq(res.last_prop_key, "")
	assert_eq(res.value, test_obj)
	
	res = Utils.get_property_w_path(test_obj, "propA")
	assert_true(is_instance_valid(res))
	assert_eq(res.found, true)
	assert_eq(res.parent_obj, test_obj)
	assert_eq(res.last_prop_key, "propA")
	assert_eq(res.value, test_obj.propA)
	
	res = Utils.get_property_w_path(test_obj, "propB")
	assert_true(is_instance_valid(res))
	assert_eq(res.found, true)
	assert_eq(res.parent_obj, test_obj)
	assert_eq(res.last_prop_key, "propB")
	assert_eq(res.value, test_obj.propB)
	
	res = Utils.get_property_w_path(test_obj, "propC")
	assert_true(is_instance_valid(res))
	assert_eq(res.found, true)
	assert_eq(res.parent_obj, test_obj)
	assert_eq(res.last_prop_key, "propC")
	assert_eq(res.value, test_obj.propC)
	
	res = Utils.get_property_w_path(test_obj, "propA.propA")
	assert_true(is_instance_valid(res))
	assert_eq(res.found, true)
	assert_eq(res.parent_obj, test_obj.propA)
	assert_eq(res.last_prop_key, "propA")
	assert_eq(res.value, test_obj.propA.propA)
	
	res = Utils.get_property_w_path(test_obj, "propA.propB")
	assert_true(is_instance_valid(res))
	assert_eq(res.found, true)
	assert_eq(res.parent_obj, test_obj.propA)
	assert_eq(res.last_prop_key, "propB")
	assert_eq(res.value, test_obj.propA.propB)
	
	res = Utils.get_property_w_path(test_obj, "propA.propC")
	assert_true(is_instance_valid(res))
	assert_eq(res.found, true)
	assert_eq(res.parent_obj, test_obj.propA)
	assert_eq(res.last_prop_key, "propC")
	assert_eq(res.value, test_obj.propA.propC)
	
	res = Utils.get_property_w_path(test_obj, "propA.i.dont.exist")
	assert_true(is_instance_valid(res))
	assert_eq(res.found, false)
	assert_eq(res.last_prop_key, "propA")
	
	res = Utils.get_property_w_path(test_obj, "badProp")
	assert_true(is_instance_valid(res))
	assert_eq(res.found, false)
	assert_eq(res.last_prop_key, "")
	
	res = Utils.get_property_w_path(test_obj, "propB.cant.get.here.because.B.isnt.an.object")
	assert_true(is_instance_valid(res))
	assert_eq(res.found, false)
	assert_eq(res.last_prop_key, "propB")
