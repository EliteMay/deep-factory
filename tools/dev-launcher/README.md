# Deep Factory Launcher

Deep Factoryを開発するときに、GitHub DesktopやPowerShellを毎回操作しなくても済むようにするWindows向けElectronランチャーです。

## v0.1の目的

普段の操作を次の2つへ縮めます。

1. ランチャーを開く
2. **開発を開始** を押す

「開発を開始」は、可能な範囲で次を行います。

- Gitが使えるか確認
- Deep Factory Repositoryが無ければClone
- 既存Repositoryなら安全条件を確認して最新版へ更新
- Godotを検出
- Godot EditorでDeep Factoryを開く

## 主な機能

- Git / Repository / Godotの状態表示
- Repositoryの保存先を記憶
- Godotの場所を記憶
- GitHubから最新版へ更新
- Godot Editorを起動
- ゲームを直接起動
- Repositoryフォルダを開く
- GitHub Repositoryを開く
- 操作ログ

## 安全なRepository更新

自動更新では次だけを使用します。

```text
git fetch --prune origin
git pull --ff-only origin main
```

次の場合は勝手に変更せず停止します。

- 未コミット変更がある
- main以外のブランチにいる
- originがEliteMay/deep-factoryではない
- 指定フォルダがDeep Factoryではない

reset / rebase / force push / commit / pushはランチャーから実行しません。

## 開発起動

Node.js 20以上が必要です。

```powershell
cd tools\dev-launcher
npm install
npm test
npm run dev
```

## Windows Installer

```powershell
npm run build:win
```

`dist/` にNSIS Setup.exeを生成します。

## 保存される設定

Electronの `userData` 配下に次だけを保存します。

- Deep Factory Repositoryのローカルパス
- Godot.exeのパス

GitHub Token、Password、API Keyなどは保存しません。

## Security

- `nodeIntegration: false`
- `contextIsolation: true`
- `sandbox: true`
- Rendererへ任意Shell実行機能を公開しない
- IPCは固定Channelのみ
- IPC senderをRenderer URLで検証
- 外部URLは固定のDeep Factory GitHub URLのみ
- Godot起動は検証済みGodot.exeだけ
- Git操作は固定引数で `execFile` を使用し、Shell文字列連結をしない

## 現在の確認状態

- Source implementation: Implemented
- Pure utility tests: Added
- Electron runtime test: 未確認
- Windows Setup.exe build: 未確認
- Windows実機でのClone / Pull / Godot起動: 未確認

実機確認後に、必要な修正と配布方法を確定します。
