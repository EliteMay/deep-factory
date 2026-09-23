import {
  app,
  BrowserWindow,
  dialog,
  ipcMain,
  session,
  shell
} from "electron";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

import {
  inspectGit,
  inspectRepository,
  prepareRepository,
  REPOSITORY_WEB_URL,
  syncRepository,
  LauncherError
} from "./services/repository.mjs";
import {
  detectGodot,
  inspectSelectedGodot,
  openGodotEditor,
  runGodotProject
} from "./services/godot.mjs";
import {
  loadSettings,
  saveSettings
} from "./services/settings.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rendererPath = path.join(__dirname, "renderer", "index.html");
const trustedRendererUrl = pathToFileURL(rendererPath).toString();

let mainWindow;

function defaultRepositoryPath() {
  return path.join(app.getPath("documents"), "Deep Factory", "deep-factory");
}

function assertTrustedSender(event) {
  if (!event.senderFrame || event.senderFrame.url !== trustedRendererUrl) {
    throw new Error("Rejected IPC sender.");
  }
}

function registerIpc(channel, handler) {
  ipcMain.handle(channel, async (event, ...args) => {
    assertTrustedSender(event);

    try {
      return await handler(...args);
    } catch (error) {
      const code = error instanceof LauncherError ? error.code : "UNKNOWN";
      const message = error instanceof LauncherError
        ? error.message
        : "処理に失敗しました。ログを確認して、もう一度試してください。";

      return {
        ok: false,
        code,
        message,
        detail: String(error?.message ?? error)
      };
    }
  });
}

async function currentSettings() {
  return loadSettings(app.getPath("userData"));
}

async function updateSettings(patch) {
  const current = await currentSettings();
  return saveSettings(app.getPath("userData"), { ...current, ...patch });
}

async function getState() {
  const settings = await currentSettings();
  const repositoryPath = settings.repositoryPath || defaultRepositoryPath();
  const git = await inspectGit();
  const repository = git.available
    ? await inspectRepository(repositoryPath)
    : { path: repositoryPath, exists: false, valid: false };

  const godot = await detectGodot(settings.godotPath);
  if (godot.available && godot.path !== settings.godotPath) {
    await updateSettings({ godotPath: godot.path });
  }

  return {
    ok: true,
    appVersion: app.getVersion(),
    repositoryPath,
    git,
    repository,
    godot
  };
}

async function ensureGodot() {
  const settings = await currentSettings();
  const godot = await detectGodot(settings.godotPath);

  if (!godot.available) {
    throw new LauncherError(
      "GODOT_MISSING",
      "Godotが見つかりません。Godot.exeを一度選んでください。"
    );
  }

  if (godot.path !== settings.godotPath) {
    await updateSettings({ godotPath: godot.path });
  }

  return godot;
}

async function ensureRepositoryPath() {
  const settings = await currentSettings();
  const repositoryPath = settings.repositoryPath || defaultRepositoryPath();

  if (!settings.repositoryPath) {
    await updateSettings({ repositoryPath });
  }

  return repositoryPath;
}

async function chooseRepository() {
  const result = await dialog.showOpenDialog(mainWindow, {
    title: "Deep FactoryのRepositoryフォルダを選ぶ",
    properties: ["openDirectory"]
  });

  if (result.canceled || !result.filePaths[0]) {
    return { ok: false, code: "CANCELED", message: "選択をキャンセルしました。" };
  }

  let selected = result.filePaths[0];
  const directProject = path.join(selected, "project.godot");
  const childProject = path.join(selected, "deep-factory", "project.godot");

  try {
    await fs.access(directProject);
  } catch {
    try {
      await fs.access(childProject);
      selected = path.join(selected, "deep-factory");
    } catch {
      return {
        ok: false,
        code: "REPOSITORY_INVALID",
        message: "選択した場所にproject.godotが見つかりません。deep-factoryフォルダを選んでください。"
      };
    }
  }

  const repository = await inspectRepository(selected);
  if (!repository.valid) {
    return {
      ok: false,
      code: "REPOSITORY_INVALID",
      message: "Deep FactoryのRepositoryとして確認できませんでした。"
    };
  }

  await updateSettings({ repositoryPath: selected });
  return { ok: true, message: "Repositoryを保存しました。", state: await getState() };
}

async function chooseGodot() {
  const result = await dialog.showOpenDialog(mainWindow, {
    title: "Godotの実行ファイルを選ぶ",
    properties: ["openFile"],
    filters: [{ name: "Godot", extensions: ["exe"] }]
  });

  if (result.canceled || !result.filePaths[0]) {
    return { ok: false, code: "CANCELED", message: "選択をキャンセルしました。" };
  }

  const godot = await inspectSelectedGodot(result.filePaths[0]);
  await updateSettings({ godotPath: godot.path });

  return {
    ok: true,
    message: "Godotを保存しました。",
    godot,
    state: await getState()
  };
}

async function startDevelopment() {
  const repositoryPath = await ensureRepositoryPath();
  const prepared = await prepareRepository(repositoryPath);
  const godot = await ensureGodot();
  openGodotEditor(godot.path, repositoryPath);

  return {
    ok: true,
    message: prepared.action === "cloned"
      ? "Deep Factoryを取得してGodotを開きました。"
      : "最新版を確認してGodotを開きました。",
    state: await getState()
  };
}

async function syncProject() {
  const repositoryPath = await ensureRepositoryPath();
  const current = await inspectRepository(repositoryPath);

  if (!current.exists) {
    const prepared = await prepareRepository(repositoryPath);
    return {
      ok: true,
      message: prepared.action === "cloned"
        ? "Deep FactoryをPCへ取得しました。"
        : "Repositoryを準備しました。",
      state: await getState()
    };
  }

  await syncRepository(repositoryPath);
  return {
    ok: true,
    message: "GitHubの最新版へ更新しました。",
    state: await getState()
  };
}

async function openEditor() {
  const repositoryPath = await ensureRepositoryPath();
  const repository = await inspectRepository(repositoryPath);
  if (!repository.valid) {
    throw new LauncherError(
      "REPOSITORY_INVALID",
      "先に「最新版にする」または「開発を開始」を実行してください。"
    );
  }

  const godot = await ensureGodot();
  openGodotEditor(godot.path, repositoryPath);
  return { ok: true, message: "Godotを開きました。" };
}

async function runGame() {
  const repositoryPath = await ensureRepositoryPath();
  const repository = await inspectRepository(repositoryPath);
  if (!repository.valid) {
    throw new LauncherError(
      "REPOSITORY_INVALID",
      "先にDeep FactoryのRepositoryを準備してください。"
    );
  }

  const godot = await ensureGodot();
  runGodotProject(godot.path, repositoryPath);
  return { ok: true, message: "ゲームを起動しました。" };
}

async function openRepositoryFolder() {
  const repositoryPath = await ensureRepositoryPath();

  try {
    await fs.access(repositoryPath);
  } catch {
    throw new LauncherError(
      "REPOSITORY_MISSING",
      "Repositoryフォルダがまだありません。先に「開発を開始」を押してください。"
    );
  }

  const errorMessage = await shell.openPath(repositoryPath);
  if (errorMessage) {
    throw new LauncherError("OPEN_FOLDER_FAILED", errorMessage);
  }

  return { ok: true, message: "Repositoryフォルダを開きました。" };
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1120,
    height: 760,
    minWidth: 860,
    minHeight: 620,
    backgroundColor: "#0b0f14",
    show: false,
    title: "Deep Factory Launcher",
    webPreferences: {
      preload: path.join(__dirname, "preload.cjs"),
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true
    }
  });

  mainWindow.removeMenu();
  mainWindow.webContents.setWindowOpenHandler(() => ({ action: "deny" }));
  mainWindow.webContents.on("will-navigate", (event) => {
    event.preventDefault();
  });

  mainWindow.once("ready-to-show", () => mainWindow.show());
  mainWindow.loadFile(rendererPath);
}

app.whenReady().then(() => {
  app.setAppUserModelId("com.elitemay.deepfactory.launcher");

  session.defaultSession.setPermissionRequestHandler((_webContents, _permission, callback) => {
    callback(false);
  });

  registerIpc("launcher:get-state", getState);
  registerIpc("launcher:choose-repository", chooseRepository);
  registerIpc("launcher:choose-godot", chooseGodot);
  registerIpc("launcher:start-development", startDevelopment);
  registerIpc("launcher:sync", syncProject);
  registerIpc("launcher:open-editor", openEditor);
  registerIpc("launcher:run-game", runGame);
  registerIpc("launcher:open-folder", openRepositoryFolder);
  registerIpc("launcher:open-github", async () => {
    await shell.openExternal(REPOSITORY_WEB_URL);
    return { ok: true, message: "GitHubを開きました。" };
  });

  createWindow();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
