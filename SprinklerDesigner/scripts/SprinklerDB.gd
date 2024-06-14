extends Node

const BUILTIN_DB = {
	'manufacturers' : {
		'Rain Bird' : {
			'bodies' : {
				'1804' : {
				},
				'1806' : {
				},
				'1812' : {
				}
			},
			'heads' : {
				'RVAN14' : {
					'min_dist_ft' : 8.0,
					'max_dist_ft' : 14.0,
					'min_sweep_deg' : 45.0,
					'max_sweep_deg' : 270.0,
					'compatible_bodies' : ['1804', '1806', '1812'],
					'flow_characteristics' : [
						{
							'sweep_deg' : 270.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      13.0,    0.84,     false],
								[ 35.0,      13.0,    0.87,     false],
								[ 40.0,      14.0,    0.92,     false],
								[ 45.0,      14.0,    0.94,     true],
								[ 50.0,      15.0,    1.11,     false],
								[ 55.0,      15.0,    1.17,     false]
							]
						},
						{
							'sweep_deg' : 210.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      13.0,    0.65,     false],
								[ 35.0,      13.0,    0.68,     false],
								[ 40.0,      14.0,    0.72,     false],
								[ 45.0,      14.0,    0.73,     true],
								[ 50.0,      15.0,    0.86,     false],
								[ 55.0,      15.0,    0.91,     false]
							]
						},
						{
							'sweep_deg' : 180.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      13.0,    0.56,     false],
								[ 35.0,      13.0,    0.58,     false],
								[ 40.0,      14.0,    0.61,     false],
								[ 45.0,      14.0,    0.63,     true],
								[ 50.0,      15.0,    0.74,     false],
								[ 55.0,      15.0,    0.78,     false]
							]
						},
						{
							'sweep_deg' : 90.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      13.0,    0.28,     false],
								[ 35.0,      13.0,    0.29,     false],
								[ 40.0,      14.0,    0.31,     false],
								[ 45.0,      14.0,    0.32,     true],
								[ 50.0,      15.0,    0.37,     false],
								[ 55.0,      15.0,    0.39,     false]
							]
						}
					]
				},
				'RVAN14-360' : {
					'min_dist_ft' : 8.0,
					'max_dist_ft' : 14.0,
					'min_sweep_deg' : 360.0,
					'max_sweep_deg' : 360.0,
					'compatible_bodies' : ['1804', '1806', '1812'],
					'flow_characteristics' : [
						{
							'sweep_deg' : 360.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      13.0,    1.10,     false],
								[ 35.0,      13.0,    1.12,     false],
								[ 40.0,      14.0,    1.22,     false],
								[ 45.0,      14.0,    1.27,     true],
								[ 50.0,      15.0,    1.41,     false],
								[ 55.0,      15.0,    1.45,     false]
							]
						}
					]
				},
				'RVAN18' : {
					'min_dist_ft' : 13.0,
					'max_dist_ft' : 18.0,
					'min_sweep_deg' : 45.0,
					'max_sweep_deg' : 270.0,
					'compatible_bodies' : ['1804', '1806', '1812'],
					'flow_characteristics' : [
						{
							'sweep_deg' : 270.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      16.0,    1.26,     false],
								[ 35.0,      16.0,    1.35,     false],
								[ 40.0,      17.0,    1.42,     false],
								[ 45.0,      17.0,    1.51,     true],
								[ 50.0,      18.0,    1.57,     false],
								[ 55.0,      18.0,    1.62,     false]
							]
						},
						{
							'sweep_deg' : 210.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      16.0,    0.98,     false],
								[ 35.0,      16.0,    1.05,     false],
								[ 40.0,      17.0,    1.10,     false],
								[ 45.0,      17.0,    1.17,     true],
								[ 50.0,      18.0,    1.22,     false],
								[ 55.0,      18.0,    1.26,     false]
							]
						},
						{
							'sweep_deg' : 180.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      16.0,    0.85,     false],
								[ 35.0,      16.0,    0.91,     false],
								[ 40.0,      17.0,    0.98,     false],
								[ 45.0,      17.0,    1.01,     true],
								[ 50.0,      18.0,    1.07,     false],
								[ 55.0,      18.0,    1.09,     false]
							]
						},
						{
							'sweep_deg' : 90.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      16.0,    0.42,     false],
								[ 35.0,      16.0,    0.47,     false],
								[ 40.0,      17.0,    0.50,     false],
								[ 45.0,      17.0,    0.50,     true],
								[ 50.0,      18.0,    0.54,     false],
								[ 55.0,      18.0,    0.58,     false]
							]
						}
					]
				},
				'RVAN18-360' : {
					'min_dist_ft' : 13.0,
					'max_dist_ft' : 18.0,
					'min_sweep_deg' : 360.0,
					'max_sweep_deg' : 360.0,
					'compatible_bodies' : ['1804', '1806', '1812'],
					'flow_characteristics' : [
						{
							'sweep_deg' : 360.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      16.0,    1.65,     false],
								[ 35.0,      16.0,    1.67,     false],
								[ 40.0,      17.0,    1.80,     false],
								[ 45.0,      17.0,    1.85,     true],
								[ 50.0,      18.0,    2.05,     false],
								[ 55.0,      18.0,    2.11,     false]
							]
						}
					]
				},
				'RVAN24' : {
					'min_dist_ft' : 17.0,
					'max_dist_ft' : 24.0,
					'min_sweep_deg' : 45.0,
					'max_sweep_deg' : 270.0,
					'compatible_bodies' : ['1804', '1806', '1812'],
					'flow_characteristics' : [
						{
							'sweep_deg' : 270.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      19.0,    1.80,     false],
								[ 35.0,      20.0,    1.95,     false],
								[ 40.0,      22.0,    2.31,     false],
								[ 45.0,      23.0,    2.52,     true],
								[ 50.0,      24.0,    2.82,     false],
								[ 55.0,      24.0,    2.88,     false]
							]
						},
						{
							'sweep_deg' : 210.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      19.0,    1.40,     false],
								[ 35.0,      20.0,    1.52,     false],
								[ 40.0,      22.0,    1.80,     false],
								[ 45.0,      23.0,    1.96,     true],
								[ 50.0,      24.0,    2.19,     false],
								[ 55.0,      24.0,    2.24,     false]
							]
						},
						{
							'sweep_deg' : 180.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      19.0,    1.20,     false],
								[ 35.0,      20.0,    1.30,     false],
								[ 40.0,      22.0,    1.54,     false],
								[ 45.0,      23.0,    1.68,     true],
								[ 50.0,      24.0,    1.88,     false],
								[ 55.0,      24.0,    1.92,     false]
							]
						},
						{
							'sweep_deg' : 90.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      19.0,    0.60,     false],
								[ 35.0,      20.0,    0.65,     false],
								[ 40.0,      22.0,    0.77,     false],
								[ 45.0,      23.0,    0.84,     true],
								[ 50.0,      24.0,    0.94,     false],
								[ 55.0,      24.0,    0.96,     false]
							]
						}
					]
				},
				'RVAN24-360' : {
					'min_dist_ft' : 17.0,
					'max_dist_ft' : 24.0,
					'min_sweep_deg' : 360.0,
					'max_sweep_deg' : 360.0,
					'compatible_bodies' : ['1804', '1806', '1812'],
					'flow_characteristics' : [
						{
							'sweep_deg' : 360.0,
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 30.0,      19.0,    2.35,     false],
								[ 35.0,      20.0,    2.52,     false],
								[ 40.0,      22.0,    3.13,     false],
								[ 45.0,      23.0,    3.48,     true],
								[ 50.0,      24.0,    3.61,     false],
								[ 55.0,      24.0,    3.74,     false]
							]
						}
					]
				}
			}
		}
	}
}

var _user_db = {
	'manufacturers' : {
	}
}

func get_manufacturers():
	var manus = []
	manus.append_array(BUILTIN_DB['manufacturers'].keys())
	manus.append_array(_user_db['manufacturers'].keys())
	return manus

func get_manufacturer_db(manufacturer: String):
	if manufacturer in BUILTIN_DB['manufacturers']:
		return BUILTIN_DB['manufacturers'][manufacturer]
	elif manufacturer in _user_db['manufacturers']:
		return _user_db['manufacturers'][manufacturer]
	return null

func get_head_models(manufacturer: String):
	var manu_db : Dictionary = get_manufacturer_db(manufacturer)
	if manu_db:
		return manu_db['heads'].keys()
	return null

func get_head_info(manufacturer: String, head_model: String):
	var manu_db : Dictionary = get_manufacturer_db(manufacturer)
	if manu_db and head_model in manu_db['heads']:
		return manu_db['heads'][head_model]
	return null
