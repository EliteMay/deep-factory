# Phase 4 Upgrade UI Decision

## 目的

Prototype 0.1の最初のProgressionとして、売却したお金を使い「手作業が明確に楽になる」ことを短いFlowで確認する。

## 現在のGame Context

- 一人称視点でWorld内Objectへ照準を合わせ、Eで操作する
- SELL端末もWorld内Objectとして存在する
- HUDは最低限の鉱石数・所持金・操作説明を常時表示する
- Phase 4はPrototypeなので、大規模なSkill TreeやFull-screen Management画面はまだ不要

## Reference Research

SatisfactoryのOfficial Wikiでは、HUB Terminalへ近づいてEでInteractionし、Terminal UIでMilestoneを選び、必要ResourceとRewardを確認するFlowが説明されている。

参考:
- https://satisfactory.wiki.gg/wiki/HUB
- https://satisfactory.wiki.gg/wiki/Tiers
- https://satisfactory.wiki.gg/wiki/Tutorial:How_to_play

採用するのは「World内の端末 → Interaction → Cost / Effectが分かるLocal UI」というInteraction Patternだけで、名称・Visual・Layout・Assetはコピーしない。

## Deep FactoryでのDecision

### Surface

```text
World
↓
UPGRADES端末へ照準
↓
E
↓
中央のLocal Panel
↓
3種類から購入
↓
EscでWorldへ戻る
```

### Phase 4で表示する情報

各Upgradeは最低限以下を見せる。

- 名前
- 効果
- 現在値
- 価格
- 購入済み状態
- 現在所持金

### Prototype 0.1のUpgrade

| ID | 効果 | Cost |
|---|---|---:|
| mining_speed | 採掘間隔 0.45秒 → 0.25秒 | 5 |
| inventory_capacity | 容量 10 → 15 | 10 |
| move_speed | 移動速度 5.0 → 6.5 | 10 |

1Sessionで5個の岩を売ると25を得られ、3種類をすべて1回ずつ購入できる。

## Input Contract

- World中: Mouse Capture
- 端末を開く: E
- Panel中: Cursor visible / Player movement停止
- 購入: Mouse click
- 閉じる: Esc
- 閉じた後: Mouse Captureを復帰しGameplayへ戻る

## Completion Gate

Static / CI:
- Upgrade dataを読める
- 3種類を購入できる
- Costが正しく減る
- 各EffectがPlayerへ反映される
- 2回購入できない
- Menu modeへ入って閉じられる

Actual Playtest:
- World端末からPanelへ自然に入れる
- Cost / Current value / Purchased stateが分かる
- 購入直後に効果が分かる
- EscでGameplayへ戻れる
