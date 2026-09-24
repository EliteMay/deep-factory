# Deep Factory

**Deep Factory** は、Godotで開発するWindows向け3D採掘・工場自動化ゲームです。

プレイヤー自身の手作業から始まり、採掘機・搬送・精錬・加工を段階的に自動化して、採掘拠点そのものを成長させていく体験を目標にしています。

## 現在の段階

現在は **Prototype 0.1の初期実装段階** です。Phase 1の一人称3D操作とPhase 2の採掘ループはWindows実機確認まで完了しました。Phase 3では鉱石取得、容量10の簡易Inventory、HUD、SELL端末、所持金まで実装し、Windows実機で回収・売却ループを確認する段階です。

最初の目標は、以下を満たす **Prototype 0.1 / MVP** の完成です。

- 一人称3Dで移動・視点操作ができる
- 岩を採掘できる
- 鉱石がドロップする
- 鉱石を拾える
- 鉱石を売却できる
- お金を使ってアップグレードできる
- 小型採掘機を購入・設置できる
- 採掘機が自動で資源を生成する
- セーブ・ロードできる

コンベア、精錬、研究、新エリアなどはMVP完成後に追加します。

## 開発環境

- Engine: Godot 4.7.2 stable
- Renderer: Forward+
- Language: GDScript
- Target: Windows
- Version control: Git / GitHub
- Distribution: Windows executable
- 基本方針: 可能な限り無料・Godot標準機能を優先

開発バージョンは **Godot 4.7.2 stable** に固定します。Game Dev Hubの共有パックで実環境のVersionを確認し、このVersionでProjectを開けることを2026-09-24に確認済みです。

## ゲームの基本ループ

```text
採掘
  ↓
回収
  ↓
売却
  ↓
アップグレード
  ↓
採掘機
  ↓
自動化
  ↓
搬送・加工
  ↓
工場拡張
```

序盤はプレイヤー自身が作業し、進行するほど「以前は自分でやっていた作業」が機械へ置き換わる設計を重視します。

## 設計方針

- 最初から巨大なゲームを作らない
- まず小さく遊べるMVPを完成させる
- 機能ごとに責務を分割する
- 鉱石・機械・アップグレードなどの静的データをコードへ大量に直書きしない
- セーブデータにバージョンを持たせる
- 数値バランスを後から調整しやすくする
- 不要な外部プラグインを増やさない
- 既存ゲームは体験設計の参考にし、名称・アセット・UI・実装をコピーしない

## ドキュメント

- `docs/GAME_DESIGN.md` — ゲーム全体の設計
- `docs/MVP.md` — 最小版の範囲と完成条件
- `docs/ROADMAP.md` — 開発順序
- `docs/SAVE_FORMAT.md` — セーブデータ方針
- `docs/PROJECT_STRUCTURE.md` — プロジェクト構成

## 開発開始

通常は **Game Dev Hub** を使います。

- Hub Repository: `EliteMay/game-dev-hub`
- Deep FactoryはGame Dev Hubの初期登録Gameです
- HubからRepositoryの安全確認、最新版取得、Godot Editor起動、Game直接起動を行えます

Game Dev HubはDeep Factory固有の仕様を持たず、このRepositoryをSource of Truthとして扱います。

### Godotから直接開く場合

1. このRepositoryをPCへCloneする
2. Godot Project Managerを開く
3. **Import** を選ぶ
4. Repository直下の `project.godot` を選ぶ
5. プロジェクトを開く
6. 右上の実行ボタンで現在のテストシーンを起動する

現在のテストシーンでは、WASD移動・マウス視点操作・衝突・Escによるカーソル切替に加え、中央の岩を左クリックで採掘できます。岩は3回で壊れて鉄鉱石がDropし、Eで拾えます。右側のSELL端末へ照準を合わせてEを押すと所持鉱石を売却でき、画面右上の鉱石数と所持金へ反映されます。

## Windowsビルド

MVP実装後、GodotのWindows Export PresetとGitHub Releasesを使う配布手順を追加予定です。

## License

コード・ゲームデータ・アセットの扱いは `LICENSE` を参照してください。
