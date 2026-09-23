const EXPECTED_OWNER = "EliteMay";
const EXPECTED_REPOSITORY = "deep-factory";

export function normalizeGitHubRemote(value) {
  if (typeof value !== "string") return "";

  let remote = value.trim();
  if (!remote) return "";

  remote = remote.replace(/^git@github\.com:/i, "https://github.com/");
  remote = remote.replace(/^ssh:\/\/git@github\.com\//i, "https://github.com/");
  remote = remote.replace(/\.git$/i, "");
  remote = remote.replace(/\/$/, "");

  return remote.toLowerCase();
}

export function isExpectedDeepFactoryRemote(value) {
  return normalizeGitHubRemote(value) ===
    ("https://github.com/" + EXPECTED_OWNER + "/" + EXPECTED_REPOSITORY).toLowerCase();
}

export function parsePorcelainStatus(output) {
  const lines = String(output ?? "")
    .split(/\r?\n/)
    .map((line) => line.trimEnd())
    .filter(Boolean);

  return {
    dirty: lines.length > 0,
    changedCount: lines.length,
    lines
  };
}

export function parseAheadBehind(output) {
  const parts = String(output ?? "").trim().split(/\s+/);
  const ahead = Number.parseInt(parts[0] ?? "0", 10);
  const behind = Number.parseInt(parts[1] ?? "0", 10);

  return {
    ahead: Number.isFinite(ahead) ? ahead : 0,
    behind: Number.isFinite(behind) ? behind : 0
  };
}
