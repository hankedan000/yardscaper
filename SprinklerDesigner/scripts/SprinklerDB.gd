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
				},
				'5000' : {
					'min_dist_ft' : 25.0,
					'max_dist_ft' : 50.0,
					'min_sweep_deg' : 40.0,
					'max_sweep_deg' : 360.0,
					'compatible_bodies' : ['5004', '5006', '5012'],
					'flow_characteristics' : [
						{
							'nozzle' : '1.5',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 33     , 1.12    , false],
								[ 35       , 34     , 1.35    , false],
								[ 45       , 35     , 1.54    , false],
								[ 55       , 35     , 1.71    , false],
								[ 65       , 34     , 1.86    , false]
							]
						},
						{
							'nozzle' : '2.0',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 35     , 1.50    , false],
								[ 35       , 36     , 1.81    , false],
								[ 45       , 37     , 2.07    , false],
								[ 55       , 37     , 2.30    , false],
								[ 65       , 35     , 2.52    , false]
							]
						},
						{
							'nozzle' : '2.5',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 35     , 1.81    , false],
								[ 35       , 37     , 2.17    , false],
								[ 45       , 37     , 2.51    , false],
								[ 55       , 37     , 2.76    , false],
								[ 65       , 37     , 3.01    , false]
							]
						},
						{
							'nozzle' : '3.0',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 36     , 2.26    , false],
								[ 35       , 38     , 2.71    , false],
								[ 45       , 40     , 3.09    , false],
								[ 55       , 40     , 3.47    , false],
								[ 65       , 40     , 3.78    , false]
							]
						},
						{
							'nozzle' : '4.0',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 37     , 2.91    , false],
								[ 35       , 40     , 3.50    , false],
								[ 45       , 42     , 4.01    , false],
								[ 55       , 42     , 4.44    , false],
								[ 65       , 42     , 4.83    , false]
							]
						},
						{
							'nozzle' : '5.0',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 39     , 3.72    , false],
								[ 35       , 41     , 4.47    , false],
								[ 45       , 45     , 5.09    , false],
								[ 55       , 45     , 5.66    , false],
								[ 65       , 45     , 6.16    , false]
							]
						},
						{
							'nozzle' : '6.0',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 39     , 4.25    , false],
								[ 35       , 43     , 5.23    , false],
								[ 45       , 46     , 6.01    , false],
								[ 55       , 47     , 6.63    , false],
								[ 65       , 48     , 7.22    , false]
							]
						},
						{
							'nozzle' : '8.0',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 36     , 5.90    , false],
								[ 35       , 43     , 7.06    , false],
								[ 45       , 47     , 8.03    , false],
								[ 55       , 50     , 8.86    , false],
								[ 65       , 50     , 9.63    , false]
							]
						},
						{
							'nozzle' : '1.0LA',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 25     , 0.76    , false],
								[ 35       , 28     , 0.92    , false],
								[ 45       , 29     , 1.05    , false],
								[ 55       , 29     , 1.17    , false],
								[ 65       , 29     , 1.27    , false]
							]
						},
						{
							'nozzle' : '1.5LA',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 27     , 1.15    , false],
								[ 35       , 30     , 1.38    , false],
								[ 45       , 31     , 1.58    , false],
								[ 55       , 31     , 1.76    , false],
								[ 65       , 31     , 1.92    , false]
							]
						},
						{
							'nozzle' : '2.0LA',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 29     , 1.47    , false],
								[ 35       , 31     , 1.77    , false],
								[ 45       , 32     , 2.02    , false],
								[ 55       , 33     , 2.24    , false],
								[ 65       , 33     , 2.45    , false]
							]
						},
						{
							'nozzle' : '3.0LA',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 29     , 2.23    , false],
								[ 35       , 33     , 2.68    , false],
								[ 45       , 35     , 3.07    , false],
								[ 55       , 36     , 3.41    , false],
								[ 65       , 36     , 3.72    , false]
							]
						},

					]
				},
				'5000PRS' : {
					'min_dist_ft' : 25.0,
					'max_dist_ft' : 47.0,
					'min_sweep_deg' : 40.0,
					'max_sweep_deg' : 360.0,
					'compatible_bodies' : ['5004', '5006', '5012'],
					'flow_characteristics' : [
						{
							'nozzle' : '1.5',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 33     , 1.12    , false],
								[ 35       , 34     , 1.35    , false],
								[ 45       , 35     , 1.54    , false],
								[ 55       , 35     , 1.59    , false]
							]
						},
						{
							'nozzle' : '2.0',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 35     , 1.50    , false],
								[ 35       , 36     , 1.81    , false],
								[ 45       , 37     , 2.07    , false],
								[ 55       , 37     , 2.14    , false]
							]
						},
						{
							'nozzle' : '2.5',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 35     , 1.81    , false],
								[ 35       , 37     , 2.17    , false],
								[ 45       , 37     , 2.51    , false],
								[ 55       , 37     , 2.60    , false]
							]
						},
						{
							'nozzle' : '3.0',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 36     , 2.26    , false],
								[ 35       , 38     , 2.71    , false],
								[ 45       , 40     , 3.09    , false],
								[ 55       , 40     , 3.20    , false]
							]
						},
						{
							'nozzle' : '4.0',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 37     , 2.91    , false],
								[ 35       , 40     , 3.50    , false],
								[ 45       , 42     , 4.01    , false],
								[ 55       , 42     , 4.15    , false]
							]
						},
						{
							'nozzle' : '5.0',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 39     , 3.72    , false],
								[ 35       , 41     , 4.47    , false],
								[ 45       , 45     , 5.09    , false],
								[ 55       , 45     , 5.27    , false]
							]
						},
						{
							'nozzle' : '6.0',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 39     , 4.25    , false],
								[ 35       , 43     , 5.23    , false],
								[ 45       , 46     , 6.01    , false],
								[ 55       , 46     , 6.22    , false]
							]
						},
						{
							'nozzle' : '8.0',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 36     , 5.90    , false],
								[ 35       , 43     , 7.06    , false],
								[ 45       , 47     , 8.03    , false],
								[ 55       , 47     , 8.31    , false]
							]
						},
						{
							'nozzle' : '1.0LA',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 25     , 0.76    , false],
								[ 35       , 28     , 0.92    , false],
								[ 45       , 29     , 1.05    , false],
								[ 55       , 29     , 1.09    , false]
							]
						},
						{
							'nozzle' : '1.5LA',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 27     , 1.15    , false],
								[ 35       , 30     , 1.38    , false],
								[ 45       , 31     , 1.58    , false],
								[ 55       , 31     , 1.64    , false]
							]
						},
						{
							'nozzle' : '2.0LA',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 29     , 1.47    , false],
								[ 35       , 31     , 1.77    , false],
								[ 45       , 32     , 2.02    , false],
								[ 55       , 32     , 2.09    , false]
							]
						},
						{
							'nozzle' : '3.0LA',
							'data' : [
								# press_psi, dist_ft, flow_gpm, optimal
								[ 25       , 29     , 2.23    , false],
								[ 35       , 33     , 2.68    , false],
								[ 45       , 35     , 3.07    , false],
								[ 55       , 35     , 3.18    , false]
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
	var manu_db = get_manufacturer_db(manufacturer)
	if manu_db is Dictionary:
		return manu_db['heads'].keys()
	return []

func get_head_info(manufacturer: String, head_model: String):
	var manu_db = get_manufacturer_db(manufacturer)
	if manu_db is Dictionary and head_model in manu_db['heads']:
		return manu_db['heads'][head_model]
	return null
