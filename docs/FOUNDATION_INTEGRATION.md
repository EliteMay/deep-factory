# Godot Game Foundation Integration

## 目的

Deep FactoryはGodot Game Foundationの最初のPilot Gameとして、複数Gameで共通化できるRuntime基盤を利用する。

FoundationはGame固有Gameplayを持たない。Deep Factory固有の採掘、売却、Upgrade、Machine、Balance、Save Payload定義はこのRepository側へ残す。

## 導入情報

`.game-foundation.json` が導入状態の機械可読Source。

現在:

- Foundation Version: `0.8.0-dev`
- Foundation Commit: `12a018a2f6ef5e0a191602746068ce040caec5f9`
- Managed Path: `addons/game_foundation`

Game Dev HubはManaged PathだけをFoundation更新対象にする。

## 使用しているFoundation System

### Save

Deep Factoryの `SaveModel` がGame Payloadを作る。Foundation `SaveSystem` が次を担当する。

- Foundation / Game Schema Version envelope
- JSON compatibility validation
- Atomic write
- Backup
- Backup recovery
- Unknown newer version rejection

何を保存・復元するかのDomain ValidationはDeep Factory側。

### Auto Save

Foundation `AutoSaveService` を利用する。

Deep Factory側でSave timingを決める。

- 主要進行変更
- 15秒Periodic
- Safe Quit

### Settings

Foundation Settings SystemでAudio / DisplayとGameplay extensionを読み込む。

現在のGame固有Setting:

- `mouse_sensitivity`

Settings UIはまだ追加しない。Prototype 0.1ではRuntime ContractとPersistence基盤だけ導入する。

### Input

`InputSetup` はFoundation Input SystemのContract方式へ移行する。

Game固有Action名はDeep Factory側が定義する。

- move_forward
- move_backward
- move_left
- move_right
- interact
- toggle_cursor
- mine

FoundationはAction名を固定しない。

### Game Flow

Foundation Game Flow ServiceをRuntimeへ追加し、Safe Quit Hookから最新Saveを確定してから終了する。

Pause MenuやMain MenuはPrototype 0.1にまだ存在しないため、Foundationへ不要なGame固有Scene Contractは渡さない。

## 更新境界

Foundation更新で自動変更してよい場所:

```text
addons/game_foundation/
```

自動更新しない場所:

```text
project.godot
scripts/
scenes/
data/
tests/
docs/
README.md
```

Foundation API変更でGame側Adapter修正が必要な場合は、別のGame Repository変更としてReview / Testする。

## Validation

CIでは既存Gameplay Regressionに加えて次を確認する。

- Installation MetadataとFoundation Version一致
- Foundation Input Contractが既存Actionを作る
- Save PayloadがFoundation JSON Contractを満たす
- Game Flow Safe Quit Hook登録
- Headless通常Testが実Player Saveへ触れない
- Save → LoadでMoney / Inventory / Upgrade effect / Position / Small Minerを復元
- Primary破損時にBackupから復旧
- Backup復旧後もSave書込みを継続できる

Windows実機ではPhase 1〜5を再確認せず、今回追加したSave / Load / Foundation表示だけを確認する。
