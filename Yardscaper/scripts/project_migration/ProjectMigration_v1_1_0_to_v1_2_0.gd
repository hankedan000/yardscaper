class_name ProjectMigration_v1_1_1_to_v1_2_0 extends IProjectMigration

func from_version() -> Version:
	return Version.from_ints(1,1,0)

func to_version() -> Version:
	return Version.from_ints(1,2,0)

func apply(project_dir: String) -> bool:
	# layout_pref.json -> preferences.json
	var old_prefs_file = project_dir.path_join('layout_pref.json')
	var new_prefs_file = project_dir.path_join('preferences.json')
	if ! FileAccess.file_exists(old_prefs_file):
		push_error("%s doesn't exist. migration failed." % [old_prefs_file])
		return false
	DirAccess.rename_absolute(old_prefs_file, new_prefs_file)
	
	# lastly, update the project's version
	return _patch_project_version(project_dir.path_join('project.json'), to_version())
