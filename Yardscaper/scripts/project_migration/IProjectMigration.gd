class_name IProjectMigration extends RefCounted

func from_version() -> Version:
	push_error('subclass should override')
	return Version.new()

func to_version() -> Version:
	push_error('subclass should override')
	return Version.new()

func apply(_project_dir: String) -> bool:
	push_error('subclass should override')
	return true

func _patch_project_version(project_file: String, new_vesion: Version) -> bool:
	if ! FileAccess.file_exists(project_file):
		push_error("%s doesn't exist. migration failed." % [project_file])
		return false
	var project_data = FileUtils.from_json_file(project_file)
	project_data['version'] = new_vesion.to_string()
	if ! FileUtils.to_json_file(project_data, project_file):
		push_error("to_json_file('%s') failed. migration failed." % [project_file])
		return false
	return true
