import fs from "node:fs/promises";
import path from "node:path";

const SETTINGS_VERSION = 1;

function cleanPath(value) {
  if (typeof value !== "string") return "";
  const trimmed = value.trim();
  if (!trimmed || trimmed.length > 4096) return "";
  return path.isAbsolute(trimmed) ? trimmed : "";
}

export function sanitizeSettings(value = {}) {
  return {
    version: SETTINGS_VERSION,
    repositoryPath: cleanPath(value.repositoryPath),
    godotPath: cleanPath(value.godotPath)
  };
}

export async function loadSettings(userDataPath) {
  const filePath = path.join(userDataPath, "settings.json");

  try {
    const raw = await fs.readFile(filePath, "utf8");
    return sanitizeSettings(JSON.parse(raw));
  } catch {
    return sanitizeSettings();
  }
}

export async function saveSettings(userDataPath, settings) {
  const filePath = path.join(userDataPath, "settings.json");
  await fs.mkdir(userDataPath, { recursive: true });
  const safe = sanitizeSettings(settings);
  await fs.writeFile(filePath, JSON.stringify(safe, null, 2) + "\n", "utf8");
  return safe;
}
