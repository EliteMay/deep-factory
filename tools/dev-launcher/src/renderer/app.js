const api = window.deepFactoryLauncher;

const elements = {
  refresh: document.querySelector("#refresh-button"),
  start: document.querySelector("#start-button"),
  run: document.querySelector("#run-button"),
  sync: document.querySelector("#sync-button"),
  editor: document.querySelector("#editor-button"),
  folder: document.querySelector("#folder-button"),
  github: document.querySelector("#github-button"),
  chooseRepository: document.querySelector("#choose-repository-button"),
  chooseGodot: document.querySelector("#choose-godot-button"),
  clearLog: document.querySelector("#clear-log-button"),
  overallLabel: document.querySelector("#overall-label"),
  heroTitle: document.querySelector("#hero-title"),
  heroDescription: document.querySelector("#hero-description"),
  gitDot: document.querySelector("#git-dot"),
  gitValue: document.querySelector("#git-value"),
  gitDetail: document.querySelector("#git-detail"),
  repoDot: document.querySelector("#repo-dot"),
  repoValue: document.querySelector("#repo-value"),
  repoDetail: document.querySelector("#repo-detail"),
  godotDot: document.querySelector("#godot-dot"),
  godotValue: document.querySelector("#godot-value"),
  godotDetail: document.querySelector("#godot-detail"),
  logList: document.querySelector("#log-list"),
  logEmpty: document.querySelector("#log-empty"),
  appVersion: document.querySelector("#app-version")
};

const actionButtons = [
  elements.refresh,
  elements.start,
  elements.run,
  elements.sync,
  elements.editor,
  elements.folder,
  elements.github,
  elements.chooseRepository,
  elements.chooseGodot
];

let currentState = null;
let busy = false;

function setBusy(value) {
  busy = value;
  document.body.classList.toggle("busy", value);
  for (const button of actionButtons) {
    button.disabled = value;
  }
}

function setDot(element, tone) {
  element.classList.remove("ok", "warning", "error");
  if (tone) element.classList.add(tone);
}

function setText(element, value) {
  element.textContent = value ?? "";
}

function appendLog(message, tone = "") {
  if (!message) return;

  if (elements.logEmpty) {
    elements.logEmpty.remove();
    elements.logEmpty = null;
  }

  const row = document.createElement("div");
  row.className = "log-entry" + (tone ? " " + tone : "");

  const time = document.createElement("span");
  time.className = "log-time";
  time.textContent = new Date().toLocaleTimeString("ja-JP", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit"
  });

  const body = document.createElement("span");
  body.className = "log-message";
  body.textContent = message;

  row.append(time, body);
  elements.logList.prepend(row);

  while (elements.logList.children.length > 100) {
    elements.logList.lastElementChild?.remove();
  }
}

function renderState(state) {
  if (!state?.ok) return;
  currentState = state;

  setText(elements.appVersion, "Launcher v" + state.appVersion);

  if (state.git?.available) {
    setDot(elements.gitDot, "ok");
    setText(elements.gitValue, "使用可能");
    setText(elements.gitDetail, state.git.version);
  } else {
    setDot(elements.gitDot, "error");
    setText(elements.gitValue, "見つかりません");
    setText(elements.gitDetail, "Git for Windowsが必要です。");
  }

  const repository = state.repository ?? {};
  if (repository.valid) {
    const cleanLabel = repository.dirty
      ? "変更あり " + repository.changedCount + "件"
      : "変更なし";
    setDot(elements.repoDot, repository.dirty ? "warning" : "ok");
    setText(
      elements.repoValue,
      repository.branch
        ? repository.branch + " / " + (repository.commit || "確認済み")
        : "確認済み"
    );
    setText(elements.repoDetail, cleanLabel + " ・ " + state.repositoryPath);
  } else if (repository.exists) {
    setDot(elements.repoDot, "error");
    setText(elements.repoValue, "要確認");
    setText(elements.repoDetail, "Deep Factoryとして確認できません ・ " + state.repositoryPath);
  } else {
    setDot(elements.repoDot, "warning");
    setText(elements.repoValue, "まだPCにありません");
    setText(elements.repoDetail, "「開発を開始」で自動取得します ・ " + state.repositoryPath);
  }

  if (state.godot?.available) {
    setDot(elements.godotDot, "ok");
    setText(elements.godotValue, state.godot.version || "使用可能");
    setText(elements.godotDetail, state.godot.path);
  } else {
    setDot(elements.godotDot, "warning");
    setText(elements.godotValue, "未設定");
    setText(elements.godotDetail, "初回だけGodot.exeを選択してください。");
  }

  const ready = Boolean(
    state.git?.available &&
    repository.valid &&
    !repository.dirty &&
    state.godot?.available
  );

  if (ready) {
    setText(elements.overallLabel, "準備OK");
    setText(elements.heroTitle, "このまま開発を始められます");
    setText(
      elements.heroDescription,
      "「開発を開始」でGitHubの最新版を確認して、そのままGodotを開きます。"
    );
  } else if (!state.git?.available) {
    setText(elements.overallLabel, "セットアップが必要");
    setText(elements.heroTitle, "Gitを先に準備してください");
    setText(
      elements.heroDescription,
      "Git for Windowsを入れたあと「状態を更新」を押せば、残りはランチャーから進められます。"
    );
  } else if (!state.godot?.available) {
    setText(elements.overallLabel, "初回設定");
    setText(elements.heroTitle, "Godotの場所だけ設定すればOKです");
    setText(
      elements.heroDescription,
      "「開発を開始」を押すとRepositoryを準備します。Godotが見つからない場合は選択画面を出します。"
    );
  } else if (repository.dirty) {
    setText(elements.overallLabel, "安全停止");
    setText(elements.heroTitle, "ローカル変更があるため自動更新を止めています");
    setText(
      elements.heroDescription,
      "内容を消さないための保護です。Godotで開くことはできます。"
    );
  } else {
    setText(elements.overallLabel, "準備中");
    setText(elements.heroTitle, "最初の準備をランチャーに任せられます");
    setText(
      elements.heroDescription,
      "「開発を開始」でRepositoryを取得・更新し、Godotを開きます。"
    );
  }
}

async function refreshState(log = false) {
  const state = await api.getState();
  if (state?.ok) {
    renderState(state);
    if (log) appendLog("状態を更新しました。", "success");
  } else {
    appendLog(state?.message || "状態確認に失敗しました。", "error");
  }
  return state;
}

async function runAction(label, action, options = {}) {
  if (busy) return;
  setBusy(true);
  appendLog(label + "を開始しました。");

  try {
    let result = await action();

    if (!result?.ok && result?.code === "GODOT_MISSING" && options.pickGodotOnMissing) {
      appendLog("Godotが未設定です。Godot.exeを選択してください。");
      const selected = await api.chooseGodot();
      if (selected?.ok) {
        appendLog(selected.message, "success");
        result = await action();
      } else {
        result = selected;
      }
    }

    if (result?.ok) {
      appendLog(result.message || label + "が完了しました。", "success");
      if (result.state) {
        renderState(result.state);
      } else {
        await refreshState(false);
      }
    } else if (result?.code !== "CANCELED") {
      appendLog(result?.message || label + "に失敗しました。", "error");
      if (result?.detail && result.detail !== result.message) {
        appendLog(result.detail, "error");
      }
      await refreshState(false);
    }
  } catch (error) {
    appendLog(String(error?.message || error), "error");
  } finally {
    setBusy(false);
  }
}

elements.refresh.addEventListener("click", () => runAction(
  "状態更新",
  async () => {
    const state = await api.getState();
    return { ok: state.ok, message: "状態を更新しました。", state };
  }
));

elements.start.addEventListener("click", () => runAction(
  "開発開始",
  () => api.startDevelopment(),
  { pickGodotOnMissing: true }
));

elements.run.addEventListener("click", () => runAction(
  "ゲーム起動",
  () => api.runGame(),
  { pickGodotOnMissing: true }
));

elements.sync.addEventListener("click", () => runAction(
  "最新版への更新",
  () => api.sync()
));

elements.editor.addEventListener("click", () => runAction(
  "Godot起動",
  () => api.openEditor(),
  { pickGodotOnMissing: true }
));

elements.folder.addEventListener("click", () => runAction(
  "フォルダ表示",
  () => api.openFolder()
));

elements.github.addEventListener("click", () => runAction(
  "GitHub表示",
  () => api.openGitHub()
));

elements.chooseRepository.addEventListener("click", () => runAction(
  "Repository選択",
  () => api.chooseRepository()
));

elements.chooseGodot.addEventListener("click", () => runAction(
  "Godot選択",
  () => api.chooseGodot()
));

elements.clearLog.addEventListener("click", () => {
  elements.logList.replaceChildren();
  const empty = document.createElement("p");
  empty.className = "log-empty";
  empty.textContent = "まだ操作はありません。";
  elements.logList.append(empty);
  elements.logEmpty = empty;
});

refreshState(false).catch((error) => {
  appendLog("初期状態の確認に失敗しました: " + String(error?.message || error), "error");
});
