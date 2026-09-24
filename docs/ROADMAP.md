# Development Roadmap

## Phase 0 — Project Foundation

状態: **基盤作成済み / Windows起動確認済み / Godot 4.7.2固定済み**

目的: 実装を始める前に、壊れにくい開発基盤を作る。

- [x] Repository初期化
- [x] Godotプロジェクト初期化
- [x] 基本フォルダ構成
- [x] README
- [x] ゲーム仕様
- [x] MVP範囲
- [x] セーブ形式方針
- [x] Godotバージョン固定
  - Game Dev Hub共有パックで Godot 4.7.2 stable を確認
  - READMEの開発環境を Godot 4.7.2 stable に固定
  - 同VersionでProjectを開けることを2026-09-24に確認済み
- [x] Windows起動確認

完了条件:
使用するGodot VersionがRepositoryに明記され、そのVersionでRepository内のプロジェクトを開ける。

## Phase 1 — First-Person Controller

状態: **完了 / Windows実機で移動・視点・衝突・カーソル切替確認済み**

- [x] プレイヤーシーン
- [x] WASD移動
- [x] Windows実機でWASD移動確認
- [x] マウスルック
- [x] 重力
- [x] 衝突
- [x] 簡易テストマップ
- [x] インタラクション用RayCast
- [x] 簡易クロスヘア
- [x] Escでカーソル切替
- [x] Windows実機でマウス視点確認
  - 担当: あなた
  - Game Dev Hubからゲームを起動し、マウス左右で水平視点、上下で縦視点が動くことを確認する
  - 上下を大きく動かしても視点が裏返らないことを確認する
- [x] Windows実機で衝突確認
  - 担当: あなた
  - テストブロックへ正面から移動し、プレイヤーがブロックを通り抜けないことを確認する
  - 地面から落ちず通常通り歩けることを確認する
- [x] Windows実機でEscカーソル切替確認
  - 担当: あなた
  - Escでマウスカーソルが表示され、もう一度Escでゲーム操作へ戻れることを確認する

完了条件:
小さな3D空間を問題なく歩き回れる。

ローカルGodotで起動し、移動・視点・衝突・カーソル切替を確認できた時点でPhase 1完了とする。

## Phase 2 — Mining

状態: **完了 / Windows実機で採掘・破壊・鉱石Drop確認済み**

- [x] 岩シーン
  - 担当: ChatGPT
  - テストマップへ採掘対象の岩を1つ配置する
  - PlayerのInteractionRayで岩を狙えるようCollisionを持たせる
- [x] 耐久値
  - 担当: ChatGPT
  - 岩が最大耐久値と現在耐久値を持つようにする
  - 採掘ダメージで耐久値が減り、0で破壊処理へ進むようにする
- [x] 採掘処理
  - 担当: ChatGPT
  - 照準が岩に合っている時だけ採掘入力を受け付ける
  - 連打速度に依存しすぎないよう採掘間隔を管理する
- [x] 採掘フィードバック
  - 担当: ChatGPT
  - 採掘入力が成功したことを画面または岩の変化で分かるようにする
  - 空振りと成功を区別できる最低限のFeedbackを入れる
- [x] 岩破壊
  - 担当: ChatGPT
  - 耐久値0で岩をWorldから安全に消す
  - 破壊処理が複数回走らないようにする
- [x] 鉱石ドロップ
  - 担当: ChatGPT
  - 岩破壊時に代表鉱石をWorldへ生成する
  - 鉱石がPlayerから見て確認でき、次Phaseの取得処理へつなげられる状態にする
- [x] Windows実機で採掘ループ確認
  - 担当: あなた
  - ゲームを起動し、中央の岩へ照準を合わせて左クリックすると「採掘成功」と表示されることを確認する
  - 岩以外へ照準を向けて左クリックすると「採掘対象なし」と表示されることを確認する
  - 岩を3回採掘すると岩が消え、「岩を破壊した。鉱石がドロップした」と表示されることを確認する
  - 岩が消えた場所に茶色い鉱石が落ちて見えることを確認する

完了条件:
狙った岩を掘り、壊して鉱石を出せる。

## Phase 3 — Inventory and Selling

状態: **完了 / Windows実機で回収・売却ループ確認済み**

- [x] 鉱石取得
  - 担当: ChatGPT
  - Dropした鉱石へ照準を合わせてEを押すとInventoryへ入る
  - 取得成功時に鉱石名と個数をFeedback表示する
- [x] インベントリ
  - 担当: ChatGPT
  - 鉱石IDごとの数量をPlayer stateとして保持する
  - 合計所持数を計算できるようにする
- [x] 容量制限
  - 担当: ChatGPT
  - 初期容量を10にし、容量を超えて取得しない
  - 満杯時は「バッグがいっぱい」と表示する
- [x] HUD
  - 担当: ChatGPT
  - 画面右上へ現在鉱石数 / 容量を表示する
  - 所持金を同じ領域へ表示する
- [x] 売却所
  - 担当: ChatGPT
  - Test MapへSELL端末を配置する
  - 照準を合わせてEを押すと所持鉱石をまとめて売却する
- [x] 所持金
  - 担当: ChatGPT
  - 鉄鉱石1個を5として売却額を計算する
  - 売却後に所持金を増やしHUDへ反映する
- [x] Windows実機で回収・売却ループ確認
  - 担当: あなた
  - ゲーム画面をクリックして操作へ戻れ、WASD移動・マウス視点・左クリック採掘・E操作が反応することを確認する
  - 岩を3回採掘して茶色い鉱石をDropさせる
  - 鉱石へ照準を合わせてEを押し、鉱石が消えて「鉄鉱石を1個拾った」と表示され、HUDが「鉱石: 1 / 10」になることを確認する
  - 右側のSELL端末へ照準を合わせてEを押し、「1個売却 +¥5」と表示されることを確認する
  - 売却後にHUDが「鉱石: 0 / 10」「所持金: ¥5」になることを確認する

完了条件:
採掘 → 回収 → 売却のループが成立する。

## Phase 4 — Upgrades

状態: **完了 / Windows実機でアップグレードループ確認済み**

- [x] 採掘速度
  - 担当: ChatGPT
  - アップグレード端末で5円を支払うと採掘間隔を0.45秒から0.25秒へ短縮する
  - 購入後は端末UIに現在値0.25秒と「購入済み」を表示する
- [x] 所持容量
  - 担当: ChatGPT
  - 10円を支払うと鉱石バッグ容量を10から15へ増やす
  - 購入後はHUDの容量表示へ即時反映する
- [x] 移動速度
  - 担当: ChatGPT
  - 10円を支払うと移動速度を5.0から6.5へ上げる
  - 購入後は端末UIに現在値6.5と「購入済み」を表示する
- [x] アップグレードデータ
  - 担当: ChatGPT
  - 価格・説明・最大Level・効果を `data/upgrades.json` へ分離する
  - Playerは購入済みLevelだけをRuntime Stateとして保持する
- [x] 購入UI
  - 担当: ChatGPT
  - Test Map左側へUPGRADES端末を配置し、照準を合わせてEで開く
  - 端末Panelで採掘速度・所持容量・移動速度の価格、効果、現在値を確認して購入できる
  - EscでPanelを閉じてゲーム操作へ戻れる
  - SatisfactoryのHUB Terminalにある「World内の端末へEで入り、必要Cost/RewardをUIで確認する」Interaction Patternだけを参考にし、見た目や名称はコピーしない
- [x] Windows実機でアップグレードループ確認
  - 担当: あなた
  - 岩以外へ照準を向けて左クリックし、「採掘対象なし」が表示されることを確認する
  - 5個の岩を採掘し、各鉱石をEで拾うたびにHUDの鉱石数が1ずつ増えて最終的に「鉱石: 5 / 10」になることを確認する
  - SELL端末でまとめて売り、HUDが「鉱石: 0 / 10」「所持金: ¥25」になることを確認する
  - 左側のUPGRADES端末へ照準を合わせてEを押し、3種類のアップグレード・価格・現在値が表示されることを確認する
  - 採掘速度を5円で購入し、所持金20円・現在0.25秒・「購入済み」になることを確認する
  - 所持容量を10円で購入し、所持金10円・HUDが「鉱石: 0 / 15」になることを確認する
  - 移動速度を10円で購入し、所持金0円・現在6.5・「購入済み」になることを確認する
  - Escで端末を閉じ、WASD・マウス視点・採掘操作へ戻れることを確認する

完了条件:
売却したお金を使って3種類のアップグレードを購入でき、購入直後に効果と表示が変わる。

## Phase 5 — First Automation

状態: **完了 / Windows実機で最初の自動化ループ確認済み**

- [x] 小型採掘機
  - 担当: ChatGPT
  - Worldへ設置できる `SmallMiner` Sceneを追加する
  - Collision、機械本体、内部ストレージ数を表示するWorld Labelを持たせる
  - Prototype 0.1では同時設置数を1台に制限する
- [x] 購入
  - 担当: ChatGPT
  - UPGRADES端末へ「自動化設備 / 小型採掘機」を追加する
  - 価格は15円とし、購入するとそのまま配置Modeへ入る
  - 所持金不足時は購入できず、配置をEscでキャンセルした場合は15円を返金する
- [x] 配置プレビュー
  - 担当: ChatGPT
  - 購入後、Player前方約3mへ半透明のPreviewを表示する
  - 設置可能なら緑、設置不可なら赤で表示する
  - 左クリックで設置、Escでキャンセルできる
- [x] 設置判定
  - 担当: ChatGPT
  - Test Map外、Player直近、岩・端末・障害物・既存機械と重なる場所には設置できない
  - 設置不可時に左クリックしても消費・確定せず、Previewを維持する
- [x] 自動生成
  - 担当: ChatGPT
  - 小型採掘機は2秒ごとに鉄鉱石を1個生成する
  - 内部ストレージが満杯の時は生成を停止する
- [x] 内部ストレージ
  - 担当: ChatGPT
  - 最大5個まで保持する
  - World Labelへ現在数 / 5を表示する
  - Balance値は `data/machines.json` へ分離する
- [x] 回収
  - 担当: ChatGPT
  - 採掘機へ照準を合わせてEを押すと内部鉱石をPlayer Inventoryへ移す
  - Player Inventory容量を超えた分は採掘機側へ残す
  - 回収後は採掘機LabelとHUD双方へ即時反映する
- [x] Windows実機で最初の自動化ループ確認
  - 担当: あなた
  - ゲームを新しく起動し、岩を3個掘って拾い、SELL端末で売って所持金15円にする
  - UPGRADES端末を開き「小型採掘機 / 購入して配置 ¥15」が表示されることを確認する
  - 購入後に配置Previewへ切り替わり、岩や端末に重なる場所では赤く「ここには置けない」と表示され、左クリックしても設置されないことを確認する
  - Escで配置をキャンセルすると所持金15円へ戻ることを確認する
  - もう一度購入し、何もない場所でPreviewが緑の「設置可能」になり、左クリックで小型採掘機を設置できることを確認する
  - 約10秒待つと採掘機のWorld Labelが「5 / 5」になり、それ以上増えないことを確認する
  - 採掘機へ照準を合わせてEを押し、採掘機が「0 / 5」、HUDが「鉱石: 5 / 10」になることを確認する
  - SELL端末で5個を売却し、所持金が25円になることを確認する

完了条件:
プレイヤーが手で掘らなくても小型採掘機が資源を生成し、内部ストレージから回収して売却できる。

## Phase 6 — Save / Load

- [ ] セーブモデル
- [ ] セーブバージョン
- [ ] 自動保存
- [ ] 手動保存の要否判断
- [ ] ロード
- [ ] 破損時の最低限の保護

完了条件:
ゲーム再起動後に主要進行状況が復元される。

## Phase 7 — Prototype 0.1 Validation

- [ ] MVP機能通しテスト
- [ ] UIの分かりにくさ修正
- [ ] 採掘テンポ調整
- [ ] アップグレード価格調整
- [ ] 採掘機の価値調整
- [ ] Windows Export確認
- [ ] README更新

ここまででPrototype 0.1。

---

## Prototype 0.2 — Conveyor

- [ ] コンベア配置
- [ ] 向き
- [ ] 入出力
- [ ] 鉱石搬送
- [ ] 採掘機との接続
- [ ] 売却所への自動搬送

## Prototype 0.3 — Processing

- [ ] 精錬機
- [ ] レシピ
- [ ] 処理時間
- [ ] 入力 / 出力
- [ ] 加工品
- [ ] 売却価値上昇

## Prototype 0.4 — Factory Expansion

- [ ] 工場スペース拡張
- [ ] 複数機械
- [ ] 物流改善
- [ ] 次の目標
- [ ] 契約システム候補

## Prototype 0.5 — Research and New Area

- [ ] 研究
- [ ] アンロック
- [ ] 新鉱石
- [ ] 新エリア
- [ ] 高度な設備

## 1.0候補

Prototypeを通して面白さが確認できてから正式版範囲を再定義する。最初から1.0の全機能を固定しない。


## 2026-09-24 Windows実機確認

Game Dev Hub経由でDeep Factoryを起動し、Phase 1の一人称操作をWindows実機で確認した。

確認済み:

- WindowsでGameを起動できる
- WASD移動が反応する
- マウス左右・上下で視点が動き、大きく上下を向いても裏返らない
- テストブロックを通り抜けず、地面から落ちずに歩ける
- Escでカーソル表示へ切り替わり、もう一度Escでゲーム操作へ戻れる

Game Dev Hub共有パックでは、Phase 1の追加3確認TaskがすべてPassだった。確認対象Repository commitは `7c7140cb`、Godotは `4.7.2.stable.official.ed1daf0bf`。

Phase 2のWindows実機確認もRepository commit `53e2c234` / Godot `4.7.2.stable.official.ed1daf0bf` で4/4すべてPassした。

確認済み:
- 岩へ左クリックすると採掘成功Feedbackが出る
- 岩以外では「採掘対象なし」が出る
- 岩を3回採掘すると破壊される
- 茶色い鉱石がWorldへDropする

Phase 3の回収・売却実装はRepository側で追加済み。2026-09-24に「ゲーム画面へカーソルを合わせても操作できない」入力Regressionが発生した。

確定したRoot Causeは `player_controller.gd` のInventory追加部分で、Variantから型推論する `:= max(...)` がGodot 4.7.2のWarning-as-errorに該当し、Player Script全体がParse Errorで読み込まれていなかったこと。これによりWASD・Mouse Look・採掘・E操作・Esc切替がすべて停止した。該当箇所は型付きの `maxi()/mini()` へ修正した。

最初の `_unhandled_input()` → `_input()` 変更だけではRoot Causeへ届いていなかったため、追加でWindow FocusとMouse Captureも明示管理するようHardeningした。起動時に `Window.grab_focus()` を要求し、Focus復帰時にMouse Captureを再適用、Focusを失った時はCursorを表示する。操作可能でない時はHUDへ「ゲーム画面をクリックして操作開始」と表示し、HUD LabelはMouse Inputを遮らないよう `mouse_filter = IGNORE` にした。

再発防止としてGodot 4.7.2 CIへGameplay Input Smoke Testを追加し、Input Action存在・WASD移動・EscでCapture解除Intent・左クリックでCapture再要求Intentを確認する。またGodotがScript Errorを出してもProcess exit code 0になる場合があるため、Import/Main Scene logの `SCRIPT ERROR` / `ERROR:` もCIで明示検出して失敗させる。

Game Dev Hub共有パックで、Repository commit `4e8b92a7` / Godot `4.7.2.stable.official.ed1daf0bf` のPhase 3確認5項目がすべてPassした。

確認済み:
- 修正版でWASD・マウス視点・左クリック採掘・E操作が反応する
- 岩を3回採掘して鉱石がDropする
- Eで鉄鉱石を取得しHUDが1 / 10になる
- SELL端末で1個売却して+5円になる
- 売却後に鉱石0 / 10・所持金5円になる

このEvidenceによりPhase 3を完了とする。Phase 4はRepository側で実装済みだが、購入UI・購入後効果・ゲーム操作への復帰はWindows実機確認が終わるまでPhase 4完了とは扱わない。

### 2026-09-24 Phase 4導入後のCore Loop Regression

Phase 4 merge後、Windows実機で「岩は壊せるが、鉱石を拾ってもHUDカウントが増えず、空振り採掘の『採掘対象なし』も表示されない」Regressionが発生した。

Game Dev Hubと同じEditorを介さないDirect StartをCIで再現した結果、`main_controller.gd` が新規 `UpgradeCatalog` のglobal class cacheへ依存し、cold startでは `Identifier "UpgradeCatalog" not declared in the current scope` でParse ErrorになっていたことをRoot Causeとして確定した。

Player Scriptは正常だったため採掘・鉱石取得のDomain Logic自体は動いていたが、MainControllerが読み込まれず、Feedback signalとInventory HUD更新が失われていた。

修正:
- `UpgradeCatalog` をglobal class名で参照せず、`main_controller.gd` からScript Pathを`preload()`して使用する
- `upgrade_catalog.gd` の `class_name` 依存を削除する
- CIへGame Dev Hub相当のDirect Cold Startを追加する
- Phase 2/3回帰Guardとして「空振り採掘Feedback → OreDrop取得 → Inventory/HUD更新 → 売却」を通すCore Loop Smoke Testを追加する

この修正のWindows実機確認はPhase 4のUser確認Task内で再確認する。

### 2026-09-24 Phase 4 Windows実機確認完了

Game Dev Hub共有パックでRepository commit `cc733107` / Godot `4.7.2.stable.official.ed1daf0bf` のPhase 4確認8項目がすべてPassし、結果はstaleではない。

確認済み:
- 空振り採掘で「採掘対象なし」が表示される
- 5個の鉱石取得でHUDが1個ずつ増えて5 / 10になる
- 5個売却で0 / 10・所持金25円になる
- UPGRADES端末で3種類の価格・効果・現在値を確認できる
- 採掘速度購入後に20円・0.25秒・購入済みになる
- 所持容量購入後に10円・0 / 15になる
- 移動速度購入後に0円・6.5・購入済みになる
- Escで端末を閉じ、WASD・マウス視点・採掘へ復帰できる

このEvidenceによりPhase 4を完了とする。

### 2026-09-24 Phase 5 Windows実機確認完了

Game Dev Hub共有パックでRepository commit `a14b80a6` / Godot `4.7.2.stable.official.ed1daf0bf` のPhase 5確認8項目がすべてPassし、結果はstaleではない。

確認済み:
- 岩3個を採掘・回収・売却して所持金15円にできる
- UPGRADES端末に「小型採掘機 / 購入して配置 ¥15」が表示される
- 岩や端末と重なる配置Previewは赤くなり、設置不可のまま維持される
- Escで配置をキャンセルすると15円が返金される
- 何もない場所では緑の配置Previewになり、左クリックで小型採掘機を設置できる
- 約10秒で内部ストレージが5 / 5になり、それ以上増えない
- Eで回収すると採掘機が0 / 5、Player HUDが鉱石5 / 10になる
- 5個売却後に所持金25円になる

このEvidenceによりPhase 5を完了とする。次はPhase 6 — Save / Loadへ進む。

