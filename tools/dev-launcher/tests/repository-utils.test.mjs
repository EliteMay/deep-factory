import test from "node:test";
import assert from "node:assert/strict";

import {
  isExpectedDeepFactoryRemote,
  normalizeGitHubRemote,
  parseAheadBehind,
  parsePorcelainStatus
} from "../src/core/repository-utils.mjs";

test("normalizes common GitHub remote formats", () => {
  assert.equal(
    normalizeGitHubRemote("git@github.com:EliteMay/deep-factory.git"),
    "https://github.com/elitemay/deep-factory"
  );
  assert.equal(
    normalizeGitHubRemote("https://github.com/EliteMay/deep-factory.git"),
    "https://github.com/elitemay/deep-factory"
  );
});

test("accepts only the Deep Factory origin", () => {
  assert.equal(
    isExpectedDeepFactoryRemote("https://github.com/EliteMay/deep-factory.git"),
    true
  );
  assert.equal(
    isExpectedDeepFactoryRemote("https://github.com/EliteMay/other-project.git"),
    false
  );
});

test("parses dirty worktree lines", () => {
  const status = parsePorcelainStatus(" M project.godot\n?? notes.txt\n");
  assert.equal(status.dirty, true);
  assert.equal(status.changedCount, 2);
});

test("parses ahead and behind counts", () => {
  assert.deepEqual(parseAheadBehind("2\t3"), { ahead: 2, behind: 3 });
});
