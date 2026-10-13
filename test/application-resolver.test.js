import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, chmodSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { BINARY_CANDIDATES, binaryInApplication, resolveApplication } from '../src/application-resolver.js';

test('resolves all supported bundle layouts and resolves again after update', () => {
  const root = mkdtempSync(join(tmpdir(), 'usage-app-'));
  try {
    const app = join(root, 'Renamed Application.app'); mkdirSync(join(app, 'Contents'), {recursive:true}); writeFileSync(join(app,'Contents/Info.plist'), '<plist/>');
    for (const relative of BINARY_CANDIDATES) {
      const path = join(app, relative); mkdirSync(join(path, '..'),{recursive:true}); writeFileSync(path,'#!/bin/sh\n'); chmodSync(path,0o755);
      assert.equal(binaryInApplication(app),path);
      assert.equal(resolveApplication({applicationPath:app,env:{}}),path);
      assert.equal(resolveApplication({roots:[root],identifier:()=> 'com.openai.codex',useSavedSelection:false,env:{}}),path);
      rmSync(path);
    }
    assert.throws(()=>binaryInApplication(app)); assert.throws(()=>binaryInApplication(root));
  } finally { rmSync(root,{recursive:true,force:true}); }
});
test('explicit binary wins and invalid explicit choices do not silently fall back',()=>{
  assert.equal(resolveApplication({env:{CODEX_BIN:process.execPath,CODEX_APP:'/missing.app'}}),process.execPath);
  assert.throws(()=>resolveApplication({env:{CODEX_BIN:'/missing'}}));
  assert.throws(()=>resolveApplication({env:{CODEX_APP:'/missing.app'}}));
  assert.throws(()=>resolveApplication({roots:[],useSavedSelection:false,env:{}}));
});
