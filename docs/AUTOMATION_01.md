# Phase 5 — First Automation

## 目的

Prototype 0.1で初めて、

```text
自分で掘る
↓
売る
↓
機械を買う
↓
機械を置く
↓
機械が自動で掘る
↓
機械から回収する
```

という「手作業が機械へ置き換わる」体験を成立させる。

Source of Truth:
- `docs/GAME_DESIGN.md`
- `docs/MVP.md`
- `docs/ROADMAP.md`

## Scope

Phase 5で実装するもの:

- 小型採掘機 1種類
- 購入
- 配置Preview
- 設置可能 / 不可能判定
- 一定時間ごとの鉄鉱石生成
- 内部Storage
- PlayerによるE回収

Phase 5では実装しないもの:

- Conveyor
- 自動売却
- 精錬
- 複数Machine Type
- Save / Load
- Offline進行

## Balance

`data/machines.json` を正本とする。

Prototype初期値:

| 項目 | 値 |
|---|---:|
| 小型採掘機価格 | 15 |
| 生成間隔 | 2秒 |
| 1回の生成量 | 鉄鉱石1個 |
| 内部Storage | 5個 |
| 同時設置数 | 1台 |

Fresh Sessionで岩3個を手掘りして売れば15円になり、最初の採掘機を購入できる。

## Purchase Flow

```text
UPGRADES端末へE
↓
自動化設備
↓
小型採掘機「購入して配置 ¥15」
↓
15円支払い
↓
端末を閉じて配置Mode
```

所持金不足時は配置Modeへ入らない。

購入後にEscで配置をキャンセルした場合は、まだMachineが設置されていないため購入代金を返金する。

## Placement Flow

配置中:

- Player前方約3mへPreviewを表示
- 設置可能: 緑
- 設置不可: 赤
- 左クリック: 設置
- Esc: キャンセル
- WASD / Mouse Lookは維持
- 採掘・E Interactionは配置中は実行しない

設置不可条件:

- Test Mapの範囲外
- Playerに近すぎる
- 岩と重なる
- SELL / UPGRADES端末と重なる
- Test Block等のSolid Objectと重なる
- 既設のMachineと重なる

## Automation

設置済みSmall MinerはTimerで自動生成する。

```text
2秒経過
↓
Storage < 5 ?
├─ yes → 鉄鉱石 +1
└─ no  → 生成停止
```

World Labelへ `現在数 / 5` を表示する。

## Collection

Playerが採掘機へ照準を合わせてE:

- 内部StorageからPlayer Inventoryへ移す
- Player容量を超えて移さない
- 入らなかった分はMachine側へ残す
- Player HUDとMachine Labelを即時更新

## Verification

Automated:
- Game Dev Hub相当のDirect Cold Start
- Existing Input / Upgrade / Core Loop smoke
- 15円購入
- Placement Mode
- Obstacle overlap rejection
- Esc cancel refund
- Valid placement
- 5個Storage cap
- E collection
- 5個売却 = 25円
- 1台制限UI

Actual Windows Playtest:
- Previewの色と位置が理解できる
- Collision判定が操作感として自然
- World Labelが読める
- E回収が迷わず行える
- 最初のAutomationとして「自分で掘らなくても増える」と認識できる
