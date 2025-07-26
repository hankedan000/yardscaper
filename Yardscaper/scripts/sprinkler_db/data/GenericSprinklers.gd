class_name GenericSprinklerData extends RefCounted

const RAW_DATA := {
	"name" : "Generic",
	"bodies" : {
		"BasicBody" : {
		}
	},
	"heads" : {
		"BasicSmallFan" : {
			"min_dist_ft" : 8.0,
			"max_dist_ft" : 14.0,
			"min_sweep_deg" : 45.0,
			"max_sweep_deg" : 360.0,
			"compatible_bodies" : ["BasicBody"],
			"flow_model" : "Fan",
			"flow_characteristics" : [
				{
					"sweep_deg" : 270.0,
					"data" : [
						# press_psi, dist_ft, flow_gpm, optimal
						[ 45.0,      14.0,    0.94,     true]
					]
				},
				{
					"sweep_deg" : 210.0,
					"data" : [
						# press_psi, dist_ft, flow_gpm, optimal
						[ 45.0,      14.0,    0.73,     true]
					]
				},
				{
					"sweep_deg" : 180.0,
					"data" : [
						# press_psi, dist_ft, flow_gpm, optimal
						[ 45.0,      14.0,    0.63,     true]
					]
				},
				{
					"sweep_deg" : 90.0,
					"data" : [
						# press_psi, dist_ft, flow_gpm, optimal
						[ 45.0,      14.0,    0.32,     true]
					]
				}
			]
		},
		"BasicMediumFan" : {
			"min_dist_ft" : 14.0,
			"max_dist_ft" : 25.0,
			"min_sweep_deg" : 45.0,
			"max_sweep_deg" : 360.0,
			"compatible_bodies" : ["BasicBody"],
			"flow_model" : "Fan",
			"flow_characteristics" : [
				{
					"sweep_deg" : 270.0,
					"data" : [
						# press_psi, dist_ft, flow_gpm, optimal
						[ 45.0,      23.0,    2.52,     true]
					]
				},
				{
					"sweep_deg" : 210.0,
					"data" : [
						# press_psi, dist_ft, flow_gpm, optimal
						[ 45.0,      23.0,    1.96,     true]
					]
				},
				{
					"sweep_deg" : 180.0,
					"data" : [
						# press_psi, dist_ft, flow_gpm, optimal
						[ 45.0,      23.0,    1.68,     true]
					]
				},
				{
					"sweep_deg" : 90.0,
					"data" : [
						# press_psi, dist_ft, flow_gpm, optimal
						[ 45.0,      23.0,    0.84,     true]
					]
				}
			]
		}
	}
}
