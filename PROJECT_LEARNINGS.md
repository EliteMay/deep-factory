# Project Learnings

## DF-001 — Hub直起動でglobal class cacheへ依存しない

- Date: 2026-09-24
- Type: Godot / Runtime / Regression
- Status: Adopted
- Trigger: Phase 4導入後、岩は壊せるが鉱石取得HUDと空振り採掘Feedbackが動かなくなった。
- Root Cause: `main_controller.gd` が新規 `class_name UpgradeCatalog` をglobal class名で参照していた。Game Dev HubはGodot Editorや `--import` を介さず `godot --path <repo>` で直接起動するため、cold start時にglobal script class cacheが未生成だと `UpgradeCatalog` を解決できず、MainControllerだけParse Errorで読み込まれなかった。
- Why existing CI missed it: CIは毎回 `--import` を先に実行してglobal class cacheを生成してからMain SceneとSmoke Testを起動していたため、Hub実行条件を再現していなかった。
- Decision:
  - Runtime entry pathから新規Project Scriptへ依存する場合、必要なら `preload("res://...")` / explicit path dependencyを使い、起動可否をEditor cacheへ依存させない。
  - CIで `.godot` を削除したDirect Cold StartをImport前に実行する。
  - Main Scene loadだけでなく、採掘Feedback・Ore pickup・Inventory HUD・Sellを通すCore Loop Smoke Testを維持する。
  - Smoke Test logに `SCRIPT ERROR` / `ERROR:` が出た場合はPASS markerがあっても失敗扱いにする。
- Evidence:
  - PR #8 diagnostic cold start reproduced: `Identifier "UpgradeCatalog" not declared in the current scope`
  - After explicit preload fix, Direct Cold Start / Input Smoke / Upgrade Smoke / Core Loop Smoke all pass.
