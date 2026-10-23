<!-- Purpose: Map the current source components for maintainers. -->
# Architecture

`ClipVaultApp.swift` owns the app lifecycle, menu, history/settings windows,
monitor, global hotkey, and shared stores.

| Component | Responsibility |
| --- | --- |
| ClipboardMonitor | Poll changeCount and decode supported representations |
| ClipStore | SQLite persistence, search, pins, pruning, and image ownership |
| ClipImages | Normalize image data and produce downsampled previews |
| SettingsStore | Persist preferences in UserDefaults |
| HistoryView | Present query results and selection |
| HistorySearchFocus | Focus and select the native search field |
| HistoryKeyboardShortcuts | Scope row actions to the history window |
| PasteController | Track the previous app and coordinate simulated paste |
| LoginItemStore | Read and change system login-item registration |

Capture flows from the monitor into the store, then into the observing views.
Restoring a clip updates the monitor's change counter to avoid recording its
own clipboard write as a new capture. SQLite is the source for search results.
