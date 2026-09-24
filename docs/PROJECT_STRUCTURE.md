# Project Structure

MVPで必要な責務を分け、静的BalanceとRuntime Logicを分離する。

```text
deep-factory/
├─ project.godot
├─ README.md
├─ PROJECT_LEARNINGS.md
│
├─ scenes/
│  ├─ main/
│  │  └─ main.tscn
│  ├─ player/
│  │  └─ player.tscn
│  ├─ resources/
│  │  ├─ mineable_rock.tscn
│  │  └─ ore_drop.tscn
│  └─ world/
│     ├─ sell_station.tscn
│     ├─ upgrade_station.tscn
│     ├─ small_miner.tscn
│     └─ placement_preview.tscn
│
├─ scripts/
│  ├─ main/
│  ├─ player/
│  ├─ resources/
│  ├─ world/
│  └─ systems/
│     └─ save_model.gd
│
├─ data/
│  ├─ upgrades.json
│  └─ machines.json
│
├─ tests/
│  ├─ input_smoke.*
│  ├─ core_loop_smoke.*
│  ├─ upgrade_smoke.*
│  ├─ automation_smoke.*
│  └─ save_model_smoke.*
│
└─ docs/
   ├─ GAME_DESIGN.md
   ├─ MVP.md
   ├─ ROADMAP.md
   ├─ SAVE_FORMAT.md
   ├─ PROJECT_STRUCTURE.md
   ├─ UPGRADE_UI.md
   └─ AUTOMATION_01.md
```

## データ方針

価格、効果量、生成間隔、Storage容量などのBalance値はCodeへ分散させず、現在はJSONを正本にする。

- Player Upgrade → `data/upgrades.json`
- Machine → `data/machines.json`

Runtime側は明示PathからDataを読み込み、Godot Editorのglobal class cacheが無くてもGame Dev HubからDirect Startできる構造を維持する。

## シーンとスクリプト

SceneとLogicを分離する。

例:

```text
scenes/player/player.tscn
scripts/player/player_controller.gd

scenes/world/small_miner.tscn
scripts/world/small_miner.gd
```

Machine Typeが増えた時点で、共通Machine責務を `scripts/machines/` 等へ抽出するか判断する。1種類のPrototype段階で不要なBase Class階層は増やさない。

## Tests

主要Gameplay FlowはScene loadだけでなくBehavior Smoke Testで守る。

- Input
- Mining / Pickup / Sell
- Upgrade
- First Automation
- Save Model Snapshot

Game Dev HubはEditorを介さず起動するため、CIではImport前のDirect Cold Startも継続する。

## assets

外部Assetを追加する場合はLicenseを確認し、必要なら出典・License情報を記録する。

## builds

Build成果物はRepositoryへ直接Commitせず、MVP後にWindows ExportとGitHub Releasesの手順を整備する。
