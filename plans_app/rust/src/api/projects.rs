use crate::db;
use crate::models::Project;
use uuid::Uuid;

pub fn get_all_projects() -> Result<Vec<Project>, String> {
    db::with_db(|conn| {
        let mut stmt = conn
            .prepare("SELECT id, name, color_index FROM projects WHERE is_deleted = 0 ORDER BY color_index ASC")
            .map_err(|e| e.to_string())?;
        let rows = stmt
            .query_map([], |row| {
                Ok(Project {
                    id: row.get(0)?,
                    name: row.get(1)?,
                    color_index: row.get(2)?,
                })
            })
            .map_err(|e| e.to_string())?;
        let mut projects = Vec::new();
        for row in rows {
            projects.push(row.map_err(|e| e.to_string())?);
        }
        Ok(projects)
    })
}

pub fn create_project(name: String, color_index: i64) -> Result<Project, String> {
    let id = Uuid::new_v4().to_string();
    let project = Project {
        id: id.clone(),
        name,
        color_index,
    };
    db::with_db(|conn| {
        conn.execute(
            "INSERT INTO projects (id, name, color_index, is_deleted) VALUES (?1, ?2, ?3, 0)",
            rusqlite::params![project.id, project.name, project.color_index],
        )
        .map_err(|e| e.to_string())?;
        Ok(project)
    })
}

pub fn update_project(id: String, name: String, color_index: i64) -> Result<Project, String> {
    let project = Project {
        id,
        name,
        color_index,
    };
    db::with_db(|conn| {
        conn.execute(
            "UPDATE projects SET name=?1, color_index=?2 WHERE id=?3",
            rusqlite::params![project.name, project.color_index, project.id],
        )
        .map_err(|e| e.to_string())?;
        Ok(project)
    })
}

pub fn delete_project(id: String) -> Result<(), String> {
    db::with_db(|conn| {
        conn.execute(
            "UPDATE projects SET is_deleted=1 WHERE id=?1",
            rusqlite::params![id],
        )
        .map_err(|e| e.to_string())?;
        Ok(())
    })
}
