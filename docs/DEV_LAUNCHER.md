# Deep Factory Development Launcher

## 目的

Deep Factoryの開発時に、初心者がGitHub Desktop、PowerShell、Godot Project Managerを行き来しなくてもよいようにする。

Primary Taskは **「Deep Factoryを安全に最新版へして、Godotで開く」**。

## Target Type

- 種類: 個人用Windows開発ランチャー / 状態Dashboard
- Primary Task: Repository更新 → Godot起動
- Audience: Git / Godotの操作を覚えることを前提にしない利用者
- Usage: 開発開始時に繰り返し使う
- Density: 中
- Device: Windows Desktop
- Tone: 暗め、技術的だが説明は日本語で簡潔

## Visual / Flow Research

### GitHub Desktop

参考:
- https://docs.github.com/en/desktop/overview/creating-your-first-repository-using-github-desktop
- https://docs.github.com/en/desktop

参考にする原則:

- 現在のRepository / Branch / Sync状態を操作前に見せる
- Gitコマンドを覚えなくてもGUIから状態を理解できる
- 変更状態を隠さない

### Godot Project Manager

参考:
- https://docs.godotengine.org/en/latest/tutorials/editor/project_manager.html

参考にする原則:

- Projectを中心に「Import / Open / Play」へ到達しやすくする
- 初回設定と通常起動を分ける
- Pathが正しいか確認できる

### Local AI Lab

`EliteMay/local-ai-lab` のDesktop Controllerから、次の学びだけを再利用する。

- 状態表示と実行Actionを分離する
- Repository同期は明示的なUser操作にする
- clean worktree + fast-forward onlyで同期する
- Folderを毎回選ばせず前回Pathを記憶する
- Rendererへ任意Shell capabilityを渡さない
- Setup.exe版の設定はElectron userDataへ保存する

UIそのものや機能量はコピーしない。

## Design Direction

- 1画面で完結するDashboard
- 最上部に「開発を開始」をPrimary Actionとして置く
- Git / Repository / Godotを3つのStatus Cardで常時確認できる
- 詳細操作はPrimary Actionより下に置く
- 実行結果は右側または下側のLogへ残す
- Dark UIを基本とし、白い全面Surfaceを使わない
- 状態色だけに意味を依存せず、必ずTextを併記する
- 初回だけGodot / Repository Pathを選択できる
- 通常利用ではFolder Pickerを要求しない

## Safety Contract

Repository自動同期は次を満たす場合だけ実行する。

1. Gitが使用可能
2. Repositoryに `project.godot` がある
3. originが `EliteMay/deep-factory`
4. branchが `main`
5. working treeがclean

実行するGit Operation:

```text
git fetch --prune origin
git pull --ff-only origin main
```

実行しないOperation:

- reset
- checkoutによる強制切替
- rebase
- commit
- push
- force
- clean

## v0.1 Completion

- Repositoryが無い場合にCloneできる
- Repository状態を表示できる
- dirty時に同期を安全停止できる
- Godotを自動検出または手動選択できる
- Godot Editorを起動できる
- Godotゲームを起動できる
- Pathを次回起動へ保持できる
- Rendererから任意Shellを実行できない
- Windowsで実機確認できる

最後のWindows実機確認が終わるまでは完成扱いにしない。
