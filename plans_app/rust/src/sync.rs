use serde::{Serialize, Deserialize};
use crate::db;

#[derive(Debug, Serialize, Deserialize)]
pub struct SyncState {
    pub snapshot_version: i64,
    pub last_synced_at: Option<String>,
    pub last_remote_checksum: Option<String>,
    pub device_id: String,
    pub last_uploaded_version: i64,
}

pub fn get_sync_state() -> Result<SyncState, String> {
    db::with_db(|conn| {
        conn.query_row(
            "SELECT snapshot_version, last_synced_at, last_remote_checksum, device_id, last_uploaded_version \
             FROM sync_state WHERE id = 1", [],
            |row| Ok(SyncState {
                snapshot_version: row.get(0)?,
                last_synced_at: row.get(1)?,
                last_remote_checksum: row.get(2)?,
                device_id: row.get(3)?,
                last_uploaded_version: row.get(4)?,
            })
        ).map_err(|e| e.to_string())
    })
}

pub fn set_sync_state(state: &SyncState) -> Result<(), String> {
    db::with_db(|conn| {
        conn.execute(
            "UPDATE sync_state SET snapshot_version=?1, last_synced_at=?2, \
             last_remote_checksum=?3, device_id=?4, last_uploaded_version=?5 WHERE id=1",
            rusqlite::params![
                state.snapshot_version,
                state.last_synced_at,
                state.last_remote_checksum,
                state.device_id,
                state.last_uploaded_version,
            ],
        ).map_err(|e| e.to_string())?;
        Ok(())
    })
}

pub fn get_or_create_device_id() -> Result<String, String> {
    let mut state = get_sync_state()?;
    if state.device_id.is_empty() {
        state.device_id = uuid::Uuid::new_v4().to_string();
        set_sync_state(&state)?;
    }
    Ok(state.device_id)
}
