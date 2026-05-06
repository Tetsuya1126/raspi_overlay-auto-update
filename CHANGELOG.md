# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-05-03

### Added

* YAML-based task configuration via `maintenance_tasks.yaml`
* JSON task result logging
* Improved duplicate-run lock control

### Changed

* Major refactor of maintenance engine
* Main workflow consolidated into `maintenance.sh`
* Internal logic reorganized into reusable function modules
* Improved reboot / OverlayFS switching flow
* Better Raspberry Pi boot partition handling during upgrades
* Add PC mode
* Eliminate LED status

### Improved

* Better maintainability and extensibility
* Cleaner code structure
* Safer unattended update workflow
* Long-term real-world stability improvements

### Notes

This release transforms the project from a fixed update script into a flexible maintenance framework for Raspberry Pi OverlayFS systems.
