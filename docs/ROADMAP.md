# Development Roadmap

## Phase 0 — Project Foundation

状態: **基盤作成済み / ローカルGodot確認待ち**

目的: 実装を始める前に、壊れにくい開発基盤を作る。

- [x] Repository初期化
- [x] Godotプロジェクト初期化
- [x] 基本フォルダ構成
- [x] README
- [x] ゲーム仕様
- [x] MVP範囲
- [x] セーブ形式方針
- [ ] Godotバージョン固定
- [ ] Windows起動確認

完了条件:
GodotでRepository内のプロジェクトを開ける。

## Phase 1 — First-Person Controller

状態: **実装済み / 実機確認待ち**

- [x] プレイヤーシーン
- [x] WASD移動
- [x] マウスルック
- [x] 重力
- [x] 衝突
- [x] 簡易テストマップ
- [x] インタラクション用RayCast
- [x] 簡易クロスヘア
- [x] Escでカーソル切替

完了条件:
小さな3D空間を問題なく歩き回れる。

ローカルGodotで起動し、移動・視点・衝突・カーソル切替を確認できた時点でPhase 1完了とする。

## Phase 2 — Mining

- 岩シーン
- 耐久値
- 採掘処理
- 採掘フィードバック
- 岩破壊
- 鉱石ドロップ

完了条件:
狙った岩を掘り、壊して鉱石を出せる。

## Phase 3 — Inventory and Selling

- 鉱石取得
- インベントリ
- 容量制限
- HUD
- 売却所
- 所持金

完了条件:
採掘 → 回収 → 売却のループが成立する。

## Phase 4 — Upgrades

- 採掘速度
- 所持容量
- 移動速度
- アップグレードデータ
- 購入UI

完了条件:
売却したお金を使って明確に強くなれる。

## Phase 5 — First Automation

- 小型採掘機
- 購入
- 配置プレビュー
- 設置判定
- 自動生成
- 内部ストレージ
- 回収

完了条件:
プレイヤーが掘らなくても資源が増える最初の自動化を体験できる。

## Phase 6 — Save / Load

- セーブモデル
- セーブバージョン
- 自動保存
- 手動保存の要否判断
- ロード
- 破損時の最低限の保護

完了条件:
ゲーム再起動後に主要進行状況が復元される。

## Phase 7 — Prototype 0.1 Validation

- MVP機能通しテスト
- UIの分かりにくさ修正
- 採掘テンポ調整
- アップグレード価格調整
- 採掘機の価値調整
- Windows Export確認
- README更新

ここまででPrototype 0.1。

---

## Prototype 0.2 — Conveyor

- コンベア配置
- 向き
- 入出力
- 鉱石搬送
- 採掘機との接続
- 売却所への自動搬送

## Prototype 0.3 — Processing

- 精錬機
- レシピ
- 処理時間
- 入力 / 出力
- 加工品
- 売却価値上昇

## Prototype 0.4 — Factory Expansion

- 工場スペース拡張
- 複数機械
- 物流改善
- 次の目標
- 契約システム候補

## Prototype 0.5 — Research and New Area

- 研究
- アンロック
- 新鉱石
- 新エリア
- 高度な設備

## 1.0候補

Prototypeを通して面白さが確認できてから正式版範囲を再定義する。最初から1.0の全機能を固定しない。
