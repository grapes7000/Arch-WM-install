from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from installer import runtime

class SessionIdentityTests(unittest.TestCase):
    def test_old_global_identity_is_repaired_for_plasma_coexistence(self):
        with tempfile.TemporaryDirectory() as tmp:
            config=Path(tmp);target=config/'environment.d/90-arch-wm.conf'
            target.parent.mkdir();target.write_text('XDG_CURRENT_DESKTOP=Hyprland\n')
            def write(path,text):
                path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text)
            ctx=SimpleNamespace(config=config,write=write,options=SimpleNamespace(dry_run=False))
            self.assertFalse(runtime.session_check(ctx))
            runtime.session_apply(ctx)
            self.assertTrue(runtime.session_check(ctx))
            self.assertTrue(runtime.session_verify(ctx))
            self.assertNotIn('XDG_CURRENT_DESKTOP',target.read_text())
            self.assertNotIn('XDG_SESSION_DESKTOP',target.read_text())
