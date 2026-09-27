#!/usr/bin/env python3
"""Compile real model/sync code; substitute only CloudKit, screenshots and defaults boundaries."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2]
app=root/'Farkle Score.'
files=['Models.swift','GameStore.swift','PlayerAppearanceAssignment.swift','PlayerStandings.swift','AppearanceMode.swift','AvatarImageStore.swift']
for directory in ['Persistence','Profiles','Scoring']:
    files += [str(p.relative_to(app)) for p in (app/directory).glob('*.swift')]
files += ['Rules/RuleSet.swift','Rules/RulesLibrary.swift','Rules/Markdown/MarkdownBlock.swift','Rules/Markdown/MarkdownParser.swift']
files += ['Sync/AppSettings.swift','Sync/CloudDeletionJournal.swift','Sync/CloudSyncing.swift','Sync/HistoryMerge.swift','Sync/RosterSeeding.swift','Sync/CloudSyncController.swift']
with tempfile.TemporaryDirectory(prefix='farkle-sync-checks-') as temporary:
    d=Path(temporary)
    paths=[]
    for n,f in enumerate(files):
        s=(app/f).read_text()
        if f=='Sync/CloudSyncController.swift': s=s.replace('CloudKitSyncService()', 'FakeCloud()')
        if f=='Sync/AppSettings.swift': s=s.replace('UserDefaults.standard','TestEnvironment.defaults')
        p=d/f'{n}.swift';p.write_text(s);paths.append(str(p))
    display=(app/'HistoryContentView.swift').read_text()
    display=display[display.index('enum HistoryDisplayMode:'):display.index('struct HistoryContentView:')]
    displayFile=d/'HistoryDisplayMode.swift';displayFile.write_text('import Foundation\n'+display)
    paths.append(str(displayFile))
    paths.append(str(root/'Tools/CloudSyncChecks/SyncChecks.swift'))
    binary=d/'checks'
    subprocess.run(['xcrun','swiftc','-swift-version','5','-default-isolation','MainActor','-parse-as-library',*paths,'-o',str(binary)],check=True)
    subprocess.run([str(binary)],check=True)
