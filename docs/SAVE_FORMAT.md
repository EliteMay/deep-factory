# Save Format

## 方針

セーブデータは、アップデート後も可能な限り古いデータを読み込めることを重視する。

静的なゲーム定義と、プレイヤーの進行データを分離する。

- 鉱石・機械・アップグレード定義: Repositoryの `data/*.json`
- プレイヤー進行: `user://` 配下のセーブファイル
- Runtime Snapshot生成: `scripts/systems/save_model.gd`

## MVP形式

MVPではJSONを使用する。

理由:

- 内容を確認しやすい
- デバッグしやすい
- バージョン移行処理を書きやすい
- 小規模なシングルプレイデータとして十分

## 正式MVPスキーマ

Phase 6のセーブモデル実装時点で、MVPのSnapshot形を次のように固定する。

```json
{
  "save_version": 1,
  "money": 25,
  "inventory": {
    "iron_ore": 5
  },
  "upgrades": {
    "mining_speed": 1,
    "inventory_capacity": 1,
    "move_speed": 1
  },
  "player": {
    "position": [1.5, 1.0, -2.0]
  },
  "machines": [
    {
      "type": "small_miner",
      "position": [4.0, 0.0, 2.0],
      "stored_amount": 3
    }
  ]
}
```

### 保存するもの

- `save_version`
- 所持金
- 鉱石IDごとの所持数
- Upgrade IDごとのLevel
- Player位置
- 設置済みMachine Type
- Machine位置
- Machine内部Storage数

### 保存しないもの

名称、価格、売却額、Upgrade効果、生成間隔、最大Storageなどの静的定義はセーブへ複製しない。

これらは `data/upgrades.json` と `data/machines.json` などRepository側のGame Definitionを正本とし、Load時にIDから現在定義を解決する。

この方針によりBalance変更だけで古いセーブの静的値が取り残されることを避ける。

## バージョニング

Deep FactoryのGame SchemaはMVPでVersion 1。

Foundation導入後は2層でVersionを持つ。

```text
Foundation Save Envelope
├─ foundation_schema_version
└─ game_schema_version = 1
        ↓
Deep Factory Payload
└─ save_version = 1
```

Foundation側はFoundation SchemaとGame Schemaの互換性を判定し、未知の新Versionを既存Fileへ上書きしない。Deep Factory側はPayload内の `save_version` とDomain FieldをValidationしてからRuntimeへ反映する。

## 保存先

Godotの `user://` 配下を使用する。

Path:

```text
user://save.json
user://save.json.bak
```

Primary Saveは一時Fileへ完全なJSONを書いて再読込Validation後に置換する。既存の正常Primaryは更新前にBackupへ保持する。

Repository内に実プレイヤーのセーブデータをコミットしない。

## Runtime Snapshot

`MainController.build_save_snapshot()` が `SaveModel.build_snapshot()` を使用し、現在のGame StateをJSON互換のDictionaryへ変換する。

Disk I/OはGodot Game Foundationの `SaveSystem` / `AutoSaveService` へ委譲する。FoundationはMoneyやMachine等のGame固有Fieldを解釈しない。

## Auto Save Policy

Prototype 0.1では手動保存Buttonを置かずAuto Saveのみとする。

- Inventory / Money等の主要進行変更後: Debounce Save
- Upgrade / Machine設置・キャンセル後: Save要求
- Machine Storageの自然増加: 15秒Periodic Save
- Window終了: Safe Quit Hookで最新Snapshotを即時保存
- Machine配置途中: 購入確定前Stateを保存しない
- 配置途中で終了: 購入代金を返金してから保存

手動保存UIは、Playtestで明確な必要性が出た場合に再評価する。

## Load / Recovery

起動時にPrimary Saveを読み込み、Payloadを全体ValidationしてからRuntimeへ反映する。

復元対象:

- Money
- Inventory
- Upgrade Levelと効果
- Player位置
- Small Miner位置
- Small Miner内部Storage
- Machine設置数

Inventoryの名称・売却額、Upgrade効果、Machine生成間隔・最大StorageはSaveへ複製せず、現在の `data/*.json` から再解決する。

Primaryが壊れていて正常Backupがある場合はBackupから復旧する。Primary / Backupとも利用できない、または非対応Versionの場合はCrashせず新規Runtime Stateで起動するが、そのSessionでは元Saveを自動上書きしない。

## 将来候補

- セーブスロット
- オフライン進行用timestamp
- 統計
- 実績
