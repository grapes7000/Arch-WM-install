import QtQuick
import QtTest
import "../../modules/shell/core" as Core

TestCase {
    name: "ShellTypography"

    Component {
        id: representativeText

        Text {
            font.family: Core.Theme.fontFamily
        }
    }

    function test_shared_theme_font_is_canonical_jetbrains_mono_nerd_font() {
        compare(Core.Theme.fontFamily, "JetBrainsMono Nerd Font")
    }

    function test_representative_surface_and_widget_text_resolve_shared_font() {
        const instances = [
            { name: "bar", item: representativeText.createObject(null) },
            { name: "launcher", item: representativeText.createObject(null) },
            { name: "drawer", item: representativeText.createObject(null) },
            { name: "menu-popup", item: representativeText.createObject(null) },
            { name: "clock-widget", item: representativeText.createObject(null) }
        ]

        for (const instance of instances) {
            verify(instance.item !== null, "Failed to create " + instance.name)
            compare(instance.item.font.family, "JetBrainsMono Nerd Font")
            instance.item.destroy()
        }
    }
}
