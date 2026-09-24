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

全セーブは必ず `save_version` を持つ。

MVPの最初のSchemaはVersion 1。

後続の「セーブバージョン」Taskで次を実装する。

1. 現在Versionと一致 → 通常ロード
2. 古いVersion → Migration入口へ渡す
3. 未知の新しいVersion → セーブを上書きせず安全に拒否する

## 保存先

Godotの `user://` 配下を使用する。

予定Path:

```text
user://save.json
```

Repository内に実プレイヤーのセーブデータをコミットしない。

## Runtime Snapshot

`MainController.build_save_snapshot()` が `SaveModel.build_snapshot()` を使用し、現在のGame StateをJSON互換のDictionaryへ変換する。

この段階ではDisk書き込みは行わない。Disk I/O、自動保存、Load、Backupは後続Taskで追加する。

## 将来候補

- セーブスロット
- オフライン進行用timestamp
- 統計
- 実績
