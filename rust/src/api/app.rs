//! Internal application state for Brrk.

use std::path::PathBuf;

#[cfg(not(test))]
use std::sync::Mutex;

#[cfg(test)]
use std::cell::RefCell;

/// Global production data directory.
///
/// Production calls `init_app` once at startup. Tests use a thread-local data
/// directory below so Rust's parallel test runner does not race on global app
/// state.
#[cfg(not(test))]
static DATA_DIR: Mutex<Option<PathBuf>> = Mutex::new(None);

#[cfg(test)]
thread_local! {
    static TEST_DATA_DIR: RefCell<Option<PathBuf>> = const { RefCell::new(None) };
}

/// Returns the current data directory, or `None` if not initialized.
pub(super) fn data_dir() -> Option<PathBuf> {
    #[cfg(not(test))]
    {
        DATA_DIR.lock().unwrap().clone()
    }

    #[cfg(test)]
    {
        TEST_DATA_DIR.with(|cell| cell.borrow().clone())
    }
}

/// Returns true if the app has been initialized.
#[allow(dead_code)]
pub(super) fn is_initialized() -> bool {
    data_dir().is_some()
}

/// Resets the global state for test isolation.
#[cfg(test)]
pub(super) fn reset_for_test() {
    TEST_DATA_DIR.with(|cell| *cell.borrow_mut() = None);
}

/// Sets the data directory. Returns `Ok(())` if already set to the same path,
/// `Err(msg)` if set to a different path.
pub(super) fn set_data_dir(path: PathBuf) -> Result<(), String> {
    #[cfg(not(test))]
    {
        let mut guard = DATA_DIR.lock().unwrap();
        match guard.as_ref() {
            Some(existing) if existing != &path => {
                Err("DATA_DIR already set to a different path".to_string())
            }
            Some(_) => Ok(()),
            None => {
                *guard = Some(path);
                Ok(())
            }
        }
    }

    #[cfg(test)]
    {
        TEST_DATA_DIR.with(|cell| {
            let mut guard = cell.borrow_mut();
            match guard.as_ref() {
                Some(existing) if existing != &path => {
                    Err("DATA_DIR already set to a different path".to_string())
                }
                Some(_) => Ok(()),
                None => {
                    *guard = Some(path);
                    Ok(())
                }
            }
        })
    }
}
