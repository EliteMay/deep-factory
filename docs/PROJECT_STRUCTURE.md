# Project Structure

初期構成は、細分化しすぎずMVPで必要な責務だけ分ける。

```text
deep-factory/
├─ project.godot
├─ README.md
├─ LICENSE
├─ .gitignore
├─ .gitattributes
│
├─ assets/
│  ├─ models/
│  ├─ materials/
│  ├─ textures/
│  ├─ audio/
│  ├─ ui/
│  └─ fonts/
│
├─ scenes/
│  ├─ main/
│  ├─ player/
│  ├─ world/
│  ├─ resources/
│  ├─ machines/
│  └─ ui/
│
├─ scripts/
│  ├─ player/
│  ├─ world/
│  ├─ resources/
│  ├─ machines/
│  ├─ systems/
│  └─ ui/
│
├─ data/
│  ├─ ores/
│  ├─ machines/
│  ├─ upgrades/
│  └─ balance/
│
└─ docs/
   ├─ GAME_DESIGN.md
   ├─ MVP.md
   ├─ ROADMAP.md
   ├─ SAVE_FORMAT.md
   └─ PROJECT_STRUCTURE.md
```

## データ方針

静的なゲームデータは、Godot標準のResourceを第一候補にする。

例:

- OreDefinition
- MachineDefinition
- UpgradeDefinition

これにより、GDScriptへ鉱石や価格を大量に直書きせず、Godotエディタから調整しやすくする。

## シーンとスクリプト

シーンとロジックを1ファイルへ集約しない。

例:

```text
scenes/player/player.tscn
scripts/player/player_controller.gd
```

機械が増えた場合も、共通処理と個別処理を分離する。

## assets

外部アセットを追加する場合は、ライセンスを確認し、必要なら出典・ライセンス情報を別途記録する。

## builds

ビルド成果物はRepositoryへ直接コミットせず、基本的にはGitHub Releasesなどで配布する。
