use crate::sync;

pub fn get_sync_state() -> Result<String, String> {
    let state = sync::get_sync_state()?;
    serde_json::to_string(&state).map_err(|e| e.to_string())
}

pub fn set_sync_state(json: String) -> Result<(), String> {
    let state: sync::SyncState = serde_json::from_str(&json).map_err(|e| e.to_string())?;
    sync::set_sync_state(&state)
}

pub fn get_or_create_device_id() -> Result<String, String> {
    sync::get_or_create_device_id()
}
