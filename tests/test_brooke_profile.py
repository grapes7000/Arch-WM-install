import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
SPEC=importlib.util.spec_from_file_location('brooke',Path(__file__).resolve().parents[1]/'scripts/brooke-profile.py')
m=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(m)
class ImportTests(unittest.TestCase):
    def test_apply_idempotency_and_rollback_preserve_user_edits(self):
        with tempfile.TemporaryDirectory() as tmp:
            home=Path(tmp);p=home/'existing';p.write_text('before')
            state=m.apply({'existing':b'after','new':b'owned'},home)
            second=m.apply({'existing':b'after','new':b'owned'},home)
            self.assertFalse((second/'journal.jsonl').exists())
            (home/'new').write_text('user edit')
            m.rollback(state,home)
            self.assertEqual(p.read_text(),'before')
            self.assertEqual((home/'new').read_text(),'user edit')
    def test_destination_symlink_rejected_before_writes(self):
        with tempfile.TemporaryDirectory() as tmp:
            home=Path(tmp)/'home';home.mkdir();outside=Path(tmp)/'outside';outside.mkdir()
            (home/'linked').symlink_to(outside,target_is_directory=True)
            with self.assertRaises(ValueError):m.apply({'first':b'x','linked/file':b'bad'},home)
            self.assertFalse((home/'first').exists())
    def test_private_export_paths_and_commands_are_translated(self):
        with tempfile.TemporaryDirectory() as tmp:
            base=Path(tmp);home=base/'target';src=base/'export/assets/rootfs/home/source';src.mkdir(parents=True)
            panel=src/'.config/xfce4/panel/launcher-9';panel.mkdir(parents=True)
            (panel/'app.desktop').write_text('[Desktop Entry]\nName=ChatGPT\nIcon=test\nExec=sh -c steal-secrets\n')
            xml=src/'.config/xfce4/xfconf/xfce-perchannel-xml';xml.mkdir(parents=True)
            (xml/'xfce4-panel.xml').write_text('<channel><property name="panel-0"><property name="plugin-ids"><value value="9"/></property></property></channel>')
            files,gaps=m.build(base/'export',home)
            model=json.loads(files['.local/share/brooke-desktop/assets.json'])
            self.assertEqual(model['launchers'][0]['command'],['xdg-open','https://chatgpt.com'])
            self.assertFalse(home.exists())
    def test_external_export_symlink_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            base=Path(tmp);folder=base/'assets';folder.mkdir();(base/'secret').write_text('private')
            (folder/'link').symlink_to(base/'secret')
            with self.assertRaises(ValueError):list(m.safe_files(folder))
if __name__=='__main__':unittest.main()
