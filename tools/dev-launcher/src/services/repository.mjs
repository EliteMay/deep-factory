import fs from "node:fs/promises";
import path from "node:path";
import { runFile } from "../core/process.mjs";
import {
  isExpectedDeepFactoryRemote,
  parseAheadBehind,
  parsePorcelainStatus
} from "../core/repository-utils.mjs";

export const REPOSITORY_URL = "https://github.com/EliteMay/deep-factory.git";
export const REPOSITORY_WEB_URL = "https://github.com/EliteMay/deep-factory";

export class LauncherError extends Error {
  constructor(code, message) {
    super(message);
    this.name = "LauncherError";
    this.code = code;
  }
}

async function exists(targetPath) {
  try {
    await fs.access(targetPath);
    return true;
  } catch {
    return false;
  }
}

async function directoryIsEmpty(targetPath) {
  try {
    const entries = await fs.readdir(targetPath);
    return entries.length === 0;
  } catch {
    return true;
  }
}

async function git(args, cwd, timeout = 60_000) {
  return runFile("git", args, { cwd, timeout });
}

export async function inspectGit() {
  try {
    const result = await runFile("git", ["--version"], { timeout: 10_000 });
    return { available: true, version: result.stdout || "git" };
  } catch {
    return { available: false, version: "" };
  }
}

export async function inspectRepository(repositoryPath) {
  const base = {
    path: repositoryPath,
    exists: false,
    valid: false,
    projectFile: false,
    expectedRemote: false,
    branch: "",
    commit: "",
    dirty: false,
    changedCount: 0,
    ahead: 0,
    behind: 0,
    origin: ""
  };

  if (!repositoryPath || !(await exists(repositoryPath))) {
    return base;
  }

  base.exists = true;
  base.projectFile = await exists(path.join(repositoryPath, "project.godot"));

  if (!(await exists(path.join(repositoryPath, ".git")))) {
    return base;
  }

  try {
    const [
      branchResult,
      commitResult,
      statusResult,
      originResult
    ] = await Promise.all([
      git(["rev-parse", "--abbrev-ref", "HEAD"], repositoryPath),
      git(["rev-parse", "--short=8", "HEAD"], repositoryPath),
      git(["status", "--porcelain=v1"], repositoryPath),
      git(["remote", "get-url", "origin"], repositoryPath)
    ]);

    const status = parsePorcelainStatus(statusResult.stdout);
    base.branch = branchResult.stdout;
    base.commit = commitResult.stdout;
    base.dirty = status.dirty;
    base.changedCount = status.changedCount;
    base.origin = originResult.stdout;
    base.expectedRemote = isExpectedDeepFactoryRemote(base.origin);
    base.valid = base.projectFile && base.expectedRemote;

    try {
      const delta = await git(
        ["rev-list", "--left-right", "--count", "HEAD...origin/main"],
        repositoryPath,
        10_000
      );
      const parsed = parseAheadBehind(delta.stdout);
      base.ahead = parsed.ahead;
      base.behind = parsed.behind;
    } catch {
      // Remote tracking data may not exist before the first fetch.
    }

    return base;
  } catch {
    return base;
  }
}

export async function cloneRepository(repositoryPath) {
  const gitState = await inspectGit();
  if (!gitState.available) {
    throw new LauncherError(
      "GIT_MISSING",
      "Gitが見つかりません。Git for Windowsをインストールしてから再試行してください。"
    );
  }

  const parent = path.dirname(repositoryPath);
  await fs.mkdir(parent, { recursive: true });

  if (await exists(repositoryPath)) {
    const empty = await directoryIsEmpty(repositoryPath);
    if (!empty) {
      throw new LauncherError(
        "PATH_NOT_EMPTY",
        "保存先に別のファイルがあります。既存のDeep Factoryフォルダを選ぶか、空の保存先を使ってください。"
      );
    }
  }

  await git(["clone", "--origin", "origin", REPOSITORY_URL, repositoryPath], parent, 180_000);
  return inspectRepository(repositoryPath);
}

export async function syncRepository(repositoryPath) {
  const state = await inspectRepository(repositoryPath);

  if (!state.valid) {
    throw new LauncherError(
      "REPOSITORY_INVALID",
      "Deep FactoryのRepositoryとして確認できません。Repositoryフォルダを選び直してください。"
    );
  }

  if (state.dirty) {
    throw new LauncherError(
      "DIRTY_WORKTREE",
      "ローカルに未保存の変更があります。安全のため自動更新を停止しました。"
    );
  }

  if (state.branch !== "main") {
    throw new LauncherError(
      "WRONG_BRANCH",
      "現在のブランチがmainではありません。安全のため自動更新を停止しました。"
    );
  }

  await git(["fetch", "--prune", "origin"], repositoryPath, 120_000);
  await git(["pull", "--ff-only", "origin", "main"], repositoryPath, 120_000);

  return inspectRepository(repositoryPath);
}

export async function prepareRepository(repositoryPath) {
  const state = await inspectRepository(repositoryPath);

  if (!state.exists) {
    return {
      action: "cloned",
      repository: await cloneRepository(repositoryPath)
    };
  }

  if (!state.valid) {
    throw new LauncherError(
      "REPOSITORY_INVALID",
      "指定フォルダにDeep FactoryのRepositoryがありません。別のフォルダを選んでください。"
    );
  }

  return {
    action: "synced",
    repository: await syncRepository(repositoryPath)
  };
}
