class_name ProjectMigrator extends RefCounted

var _migrations : Array[IProjectMigration] = []

func _init() -> void:
	_migrations.push_back(ProjectMigration_v1_1_1_to_v1_2_0.new())

func needs_migration_to_current(project_dir: String) -> bool:
	return _get_migration_path_to_current(project_dir).size() > 0

func migrate_to_current(project_dir: String) -> bool:
	var migrations = _get_migration_path_to_current(project_dir)
	return _apply_migrations(project_dir, migrations)

func _get_migration_path_to_current(project_dir: String) -> Array[IProjectMigration]:
	var from := Project.get_quick_info(project_dir).version
	var to := ProjectUtils.get_app_version()
	return _get_migration_path(from, to)

func _get_migration_path(from: Version, to: Version) -> Array[IProjectMigration]:
	var migrations : Array[IProjectMigration] = []
	for migration in _migrations:
		if from.compare(migration.from_version()) <= 0:
			if to.compare(migration.to_version()) <= 0:
				migrations.push_back(migration)
				from = migration.to_version()
			else:
				break # we've migrated as far as we need to go, so stop
	return migrations

static func _apply_migrations(project_dir: String, migrations: Array[IProjectMigration]) -> bool:
	for migration in migrations:
		print("migrating '%s' from %s to %s ..." % [project_dir, migration.from_version(), migration.to_version()])
		if ! migration.apply(project_dir):
			push_error("failed to migrate from project '%s' from %s to %s" % [project_dir, migration.from_version(), migration.to_version()])
			return false
	return true
