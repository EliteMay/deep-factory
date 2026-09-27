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


## DF-002 — 固定Playtestの判定はScreenshotではなくGame StateをPrimaryにする

- Date: 2026-09-27
- Type: Testing / Runtime Integration
- Status: Adopted
- Evidence: UI-TARSによるWASD / Mouse固定テストはWindows上で実入力まで到達しても、Vision推論の待ち時間と画面差分判定により120秒timeoutや自己矛盾Verdictが発生した。
- Decision: Deep FactoryはFoundation Runtime Test BridgeへPlayer / Camera / Inventory / Upgrade / Machine等のread-only Stateを提供し、固定テストのPrimary verdictを内部StateのBefore / After比較へ移す。
- Boundary: Bridgeは明示Test Runだけ有効でNetwork / Command capabilityを持たない。Human PlaytestやScreenshotはUX / 見た目 / 未知BugのEvidenceとして残す。
- Regression Guard: `runtime_test_bridge_integration_smoke` でGame ProviderとBridge JSON SnapshotをCI検証する。


## DF-003 — Runtime Test操作を本番Saveへ書き込まない

- Date: 2026-09-27
- Type: Testing / Save Safety
- Status: Adopted
- Problem: Hubの固定テストが実GameへWASD等を入力すると、通常Auto Save経路がTest中のPlayer位置を本番Saveへ保存し得る。
- Decision: Runtime Test Bridgeが有効なRunではPeriodic / Event / Safe Quit Saveをno-opにし、既存Saveは読み込んでもTest操作を永続化しない。
- Regression Guard: Runtime Test Bridge integration smokeで `save_now()` が `runtime_test_mode` を返すことを確認する。
