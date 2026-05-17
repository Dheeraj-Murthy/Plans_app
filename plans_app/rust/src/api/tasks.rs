use crate::db;
use crate::models::Task;
use uuid::Uuid;

pub fn get_all_tasks() -> Result<Vec<Task>, String> {
    db::with_db(|conn| {
        let mut stmt = conn
            .prepare("SELECT id, title, description, due_date, priority, is_completed, project_id, created_at, updated_at, sort_order FROM tasks WHERE is_deleted = 0 ORDER BY sort_order ASC")
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
                    sort_order: row.get(9)?,
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
    db::with_db(|conn| {
        let max_order: i64 = conn
            .query_row("SELECT COALESCE(MAX(sort_order), -1) FROM tasks WHERE is_deleted = 0", [], |r| r.get(0))
            .map_err(|e| e.to_string())?;
        let sort_order = max_order + 1;
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
            sort_order,
        };
        conn.execute(
            "INSERT INTO tasks (id, title, description, due_date, priority, is_completed, project_id, created_at, updated_at, sort_order) VALUES (?1, ?2, ?3, ?4, ?5, 0, ?6, ?7, ?8, ?9)",
            rusqlite::params![task.id, task.title, task.description, task.due_date, task.priority, task.project_id, task.created_at, task.updated_at, task.sort_order],
        )
        .map_err(|e| e.to_string())?;
        Ok(task)
    })
}

pub fn update_task(task_json: String) -> Result<Task, String> {
    let task: Task = serde_json::from_str(&task_json).map_err(|e| e.to_string())?;
    db::with_db(|conn| {
        conn.execute(
            "UPDATE tasks SET title=?1, description=?2, due_date=?3, priority=?4, is_completed=?5, project_id=?6, updated_at=?7, sort_order=?9 WHERE id=?8",
            rusqlite::params![task.title, task.description, task.due_date, task.priority, task.is_completed as i64, task.project_id, chrono::Utc::now().timestamp_millis(), task.id, task.sort_order],
        )
        .map_err(|e| e.to_string())?;
        Ok(task)
    })
}

pub fn reorder_tasks(task_ids: Vec<String>) -> Result<(), String> {
    db::with_db(|conn| {
        for (i, id) in task_ids.iter().enumerate() {
            conn.execute(
                "UPDATE tasks SET sort_order=?1, updated_at=?2 WHERE id=?3",
                rusqlite::params![i as i64, chrono::Utc::now().timestamp_millis(), id],
            )
            .map_err(|e| e.to_string())?;
        }
        Ok(())
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

pub fn restore_task(id: String) -> Result<(), String> {
    db::with_db(|conn| {
        conn.execute(
            "UPDATE tasks SET is_deleted=0, updated_at=?1 WHERE id=?2",
            rusqlite::params![chrono::Utc::now().timestamp_millis(), id],
        )
        .map_err(|e| e.to_string())?;
        Ok(())
    })
}
