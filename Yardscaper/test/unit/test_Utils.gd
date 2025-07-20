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
	
	assert_eq(Utils.get_property_w_path(test_obj, ""), test_obj)
	assert_eq(Utils.get_property_w_path(test_obj, "propA"), test_obj.propA)
	assert_eq(Utils.get_property_w_path(test_obj, "propB"), test_obj.propB)
	assert_eq(Utils.get_property_w_path(test_obj, "propC"), test_obj.propC)
	assert_eq(Utils.get_property_w_path(test_obj, "propA.propA"), test_obj.propA.propA)
	assert_eq(Utils.get_property_w_path(test_obj, "propA.propB"), test_obj.propA.propB)
	assert_eq(Utils.get_property_w_path(test_obj, "propA.propC"), test_obj.propA.propC)
	assert_eq(Utils.get_property_w_path(test_obj, "propA.i.dont.exist"), null)
	assert_eq(Utils.get_property_w_path(test_obj, "badProp"), null)
	assert_eq(Utils.get_property_w_path(test_obj, "propB.cant.get.here.because.B.isnt.an.object"), null)
