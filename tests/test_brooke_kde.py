import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
import unittest.mock
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('brooke_kde',ROOT/'scripts/install-brooke-kde.py')
kde=importlib.util.module_from_spec(spec);spec.loader.exec_module(kde)

class BrookeKdeTests(unittest.TestCase):
    def test_backup_restores_originals_and_removes_new_payload(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);original=root/'settings';original.write_text('original')
            source=root/'source';source.mkdir();(source/'brush').write_text('data')
            b=kde.Backup(root/'backup');b.remember(original)
            original.write_text('changed');b.remember(original)
            b.install(source,root/'new-package')
            kde.restore(b.path)
            self.assertEqual(original.read_text(),'original')
            self.assertFalse((root/'new-package').exists())
    def test_plasma6_metadata_and_frame_elements(self):
        root=ROOT/'profiles/brooke-kde'
        for folder,kind in [('look-and-feel','LookAndFeel'),('desktoptheme','Theme')]:
            data=json.loads((root/folder/'metadata.json').read_text())
            self.assertEqual(data['KPackageStructure'],'Plasma/'+kind)
        svg=ET.parse(root/'desktoptheme/widgets/panel-background.svg')
        ids={x.get('id') for x in svg.iter()}
        self.assertTrue({'center','top','bottom','left','right','topleft','topright','bottomleft','bottomright'}.issubset(ids))
    def test_layout_executes_with_a_wallpaper_url_containing_quotes(self):
        # Exercise script behavior with a small Plasma API stand-in. A graphical
        # Plasma smoke test remains required; this checks logic and escaping.
        import shutil
        if not shutil.which('node'):self.skipTest('node unavailable')
        template=(ROOT/'profiles/brooke-kde/look-and-feel/contents/layouts/org.kde.plasma.desktop-layout.js').read_text()
        url='file:///home/test/a%20b/quote%22wallpaper.jpeg'
        layout=template.replace('@WALLPAPER_URL@',json.dumps(url)).replace('@LAUNCHERS@',json.dumps(['applications:example.desktop']))
        harness='''const assert = require('assert');
const created=[];const d={writeConfig(k,v){this[k]=v}};
function Panel(){this.widgets=[];this.writeConfig=function(k,v){this[k]=v};this.addWidget=function(id){this.widgets.push(id);return {writeConfig(){}}};created.push(this)}
function desktops(){return [d]}
'''+layout+'''
assert.equal(created.length,2);assert.equal(created[0].location,'top');assert.equal(created[1].location,'bottom');assert.equal(created[0].floating,false);assert.equal(d.Image,'''+json.dumps(url)+''');
'''
        subprocess.run(['node','-e',harness],check=True,capture_output=True)

    def test_launchers_use_exported_commands_and_asset_paths(self):
        model={'launchers':[{'name':'Paint','command':['krita','a b.kra'],'icon':'@DATA@/assets/icons/krita.png'},{'name':'Missing','command':['missing']} ]}
        with unittest.mock.patch.object(Path,'is_file',return_value=True):
            files=kde.launcher_files(model,Path('/target/assets'),which=lambda name:name=='krita')
        self.assertEqual(len(files),1)
        self.assertIn('Icon=/target/assets/assets/icons/krita.png',files[0][1])
        self.assertIn('Exec="krita" "a b.kra"',files[0][1])
    def test_panel_embeds_actual_texture(self):
        svg=(ROOT/'profiles/brooke-kde/desktoptheme/widgets/panel-background.svg').read_text()
        rendered=kde.textured_panel(svg,b'image-data')
        ET.fromstring(rendered)
        self.assertIn('data:image/jpeg;base64,aW1hZ2UtZGF0YQ==',rendered)

    def test_bridge_reuses_folder_and_category_artwork(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);original=root/'Chicago95';original.mkdir()
            (original/'folder.png').write_bytes(b'folder-art')
            (original/'applications-accessories.svg').write_text('<svg/>')
            aliases=kde.build_icon_bridge(original,root/'bridge')
            self.assertEqual(aliases['org.kde.dolphin'],'folder.png')
            self.assertEqual((root/'bridge/48x48/places/folder-documents.png').read_bytes(),b'folder-art')
            index=(root/'bridge/index.theme').read_text()
            self.assertIn('Inherits=Chicago95,breeze,hicolor',index)
            self.assertTrue((root/'bridge/scalable/categories/applications-utilities.svg').is_file())
    def test_panel_center_is_tiled_and_margins_are_small(self):
        svg=(ROOT/'profiles/brooke-kde/desktoptheme/widgets/panel-background.svg').read_text()
        rendered=kde.textured_panel(svg,b'image-data')
        elements={x.get('id'):x for x in ET.fromstring(rendered).iter()}
        self.assertIn('hint-tile-center',elements)
        self.assertEqual(elements['hint-top-margin'].get('height'),'1')
