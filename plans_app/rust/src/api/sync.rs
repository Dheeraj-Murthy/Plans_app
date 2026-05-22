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

pub struct SyncSnapshotResult {
    pub encrypted: Vec<u8>,
    pub manifest_json: String,
}

pub fn create_snapshot(
    key: Vec<u8>,
    db_path: String,
    device_id: String,
    device_name: String,
    schema_version: i64,
    app_version: String,
) -> Result<SyncSnapshotResult, String> {
    let k: [u8; 32] = key.try_into().map_err(|_| "key must be 32 bytes".to_string())?;
    let r = sync::create_snapshot(
        &k,
        &db_path,
        &device_id,
        &device_name,
        schema_version,
        &app_version,
    )?;
    Ok(SyncSnapshotResult {
        encrypted: r.encrypted,
        manifest_json: r.manifest_json,
    })
}

pub fn install_snapshot(
    encrypted: Vec<u8>,
    manifest_json: String,
    key: Vec<u8>,
    db_path: String,
) -> Result<i64, String> {
    let k: [u8; 32] = key.try_into().map_err(|_| "key must be 32 bytes".to_string())?;
    sync::install_snapshot(&encrypted, &manifest_json, &k, &db_path)
}
