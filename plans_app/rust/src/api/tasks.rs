use crate::db;
use crate::models::Task;
use uuid::Uuid;

pub fn get_all_tasks() -> Result<Vec<Task>, String> {
    db::with_db(|conn| {
        let mut stmt = conn
            .prepare("SELECT id, title, description, due_date, priority, is_completed, project_id, created_at, updated_at FROM tasks WHERE is_deleted = 0 ORDER BY created_at ASC")
            .map_err(|e| e.to_string())?;
        let rows = stmt
            .query_map([], |row| {
                Ok(Task {
                    id: row.get(0)?,
                    title: row.get(1)?,
                    description: row.get(2)?,
                    due_date: row.get(3)?,
                    priority: row.get(4)?,
                    is_completed: row.get::<_, i64>(5)? == 1,
                    project_id: row.get(6)?,
                    created_at: row.get(7)?,
                    updated_at: row.get(8)?,
                })
            })
            .map_err(|e| e.to_string())?;
        let mut tasks = Vec::new();
        for row in rows {
            tasks.push(row.map_err(|e| e.to_string())?);
        }
        Ok(tasks)
    })
}

pub fn create_task(
    title: String,
    description: Option<String>,
    due_date: Option<i64>,
    priority: i64,
    project_id: String,
) -> Result<Task, String> {
    let id = Uuid::new_v4().to_string();
    let now = chrono::Utc::now().timestamp_millis();
    let task = Task {
        id: id.clone(),
        title,
        description,
        due_date,
        priority,
        is_completed: false,
        project_id,
        created_at: now,
        updated_at: now,
    };
    db::with_db(|conn| {
        conn.execute(
            "INSERT INTO tasks (id, title, description, due_date, priority, is_completed, project_id, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, 0, ?6, ?7, ?8)",
            rusqlite::params![task.id, task.title, task.description, task.due_date, task.priority, task.project_id, task.created_at, task.updated_at],
        )
        .map_err(|e| e.to_string())?;
        Ok(task)
    })
}

pub fn update_task(task_json: String) -> Result<Task, String> {
    let task: Task = serde_json::from_str(&task_json).map_err(|e| e.to_string())?;
    db::with_db(|conn| {
        conn.execute(
            "UPDATE tasks SET title=?1, description=?2, due_date=?3, priority=?4, is_completed=?5, project_id=?6, updated_at=?7 WHERE id=?8",
            rusqlite::params![task.title, task.description, task.due_date, task.priority, task.is_completed as i64, task.project_id, chrono::Utc::now().timestamp_millis(), task.id],
        )
        .map_err(|e| e.to_string())?;
        Ok(task)
    })
}

pub fn delete_task(id: String) -> Result<(), String> {
    db::with_db(|conn| {
        conn.execute(
            "UPDATE tasks SET is_deleted=1, updated_at=?1 WHERE id=?2",
            rusqlite::params![chrono::Utc::now().timestamp_millis(), id],
        )
        .map_err(|e| e.to_string())?;
        Ok(())
    })
}

pub fn clear_completed() -> Result<(), String> {
    db::with_db(|conn| {
        conn.execute(
            "UPDATE tasks SET is_deleted=1, updated_at=?1 WHERE is_deleted=0 AND is_completed=1",
            rusqlite::params![chrono::Utc::now().timestamp_millis()],
        )
        .map_err(|e| e.to_string())?;
        Ok(())
    })
}
