import { accessSync, constants, readdirSync, existsSync } from 'node:fs';
import { join, extname } from 'node:path';
import { homedir } from 'node:os';
import { execFileSync } from 'node:child_process';

export const BINARY_CANDIDATES = ['Contents/Resources/codex-cli/bin/codex', 'Contents/Resources/codex', 'Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex'];
function executable(path) { try { accessSync(path, constants.X_OK); return true; } catch { return false; } }
function identifier(app) {
  try { return JSON.parse(execFileSync('/usr/bin/plutil', ['-convert', 'json', '-o', '-', join(app, 'Contents/Info.plist')], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] })).CFBundleIdentifier; } catch { return null; }
}
export function binaryInApplication(app) {
  if (extname(app).toLowerCase() !== '.app' || !existsSync(join(app, 'Contents/Info.plist'))) throw new Error('Select a valid application bundle.');
  for (const relative of BINARY_CANDIDATES) { const binary = join(app, relative); if (executable(binary)) return binary; }
  throw new Error(`No Codex executable in ${app}. Select the application again.`);
}
function savedApplication() {
  if (process.platform !== 'darwin') return null;
  const read = key => { try { return execFileSync('/usr/bin/defaults', ['read', 'dev.local.CodexUsageStatus', key], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim(); } catch { return null; } };
  const mode = read('ApplicationDiscoveryMode');
  if (mode === 'automatic') return null;
  const selected = read('SelectedApplicationPath');
  if (mode === 'manual' && !selected) throw new Error('Choose an application location in Settings.');
  return selected;
}
export function resolveApplication(options = {}) {
  const env = options.env ?? process.env;
  const explicit = options.codexBin ?? env.CODEX_BIN;
  if (explicit) { if (!executable(explicit)) throw new Error(`Codex executable not found: ${explicit}`); return explicit; }
  const app = options.applicationPath ?? env.CODEX_APP ?? (options.useSavedSelection === false ? null : savedApplication());
  if (app) return binaryInApplication(app);
  for (const root of options.roots ?? ['/Applications', join(homedir(), 'Applications')]) {
    let entries; try { entries = readdirSync(root).sort(); } catch { continue; }
    for (const name of entries) {
      const candidate = join(root, name);
      if ((options.identifier ?? identifier)(candidate) !== 'com.openai.codex') continue;
      try { return binaryInApplication(candidate); } catch { /* try another installed official bundle */ }
    }
  }
  throw new Error('No compatible application found. Select one in Settings, or set CODEX_APP.');
}
