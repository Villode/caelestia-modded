pragma Singleton

import ".."
import qs.config
import qs.utils
import Quickshell
import QtQuick

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${Config.launcher.actionPrefix}variant `.length);
    }

    list: [
        Variant {
            variant: "vibrant"
            icon: "sentiment_very_dissatisfied"
            name: qsTr("鲜艳")
            description: qsTr("高色度调色板。主调色板的色度达到最大值。")
        },
        Variant {
            variant: "tonalspot"
            icon: "android"
            name: qsTr("色调点")
            description: qsTr("Material 主题颜色默认值。低色度的柔和调色板。")
        },
        Variant {
            variant: "expressive"
            icon: "compare_arrows"
            name: qsTr("表现力")
            description: qsTr("中等色度调色板。主调色板的色调与种子颜色不同，以增加多样性。")
        },
        Variant {
            variant: "fidelity"
            icon: "compare"
            name: qsTr("保真度")
            description: qsTr("匹配种子颜色，即使种子颜色非常鲜艳（高色度）。")
        },
        Variant {
            variant: "content"
            icon: "sentiment_calm"
            name: qsTr("内容")
            description: qsTr("几乎与保真度相同。")
        },
        Variant {
            variant: "fruitsalad"
            icon: "nutrition"
            name: qsTr("水果沙拉")
            description: qsTr("活泼主题 - 种子颜色的色调不会出现在主题中。")
        },
        Variant {
            variant: "rainbow"
            icon: "looks"
            name: qsTr("彩虹")
            description: qsTr("活泼主题 - 种子颜色的色调不会出现在主题中。")
        },
        Variant {
            variant: "neutral"
            icon: "contrast"
            name: qsTr("中性")
            description: qsTr("接近灰度，带有一丝色度。")
        },
        Variant {
            variant: "monochrome"
            icon: "filter_b_and_w"
            name: qsTr("单色")
            description: qsTr("所有颜色都是灰度，无色度。")
        }
    ]
    useFuzzy: Config.launcher.useFuzzy.variants

    component Variant: QtObject {
        required property string variant
        required property string icon
        required property string name
        required property string description

        function onClicked(list: AppList): void {
            list.visibilities.launcher = false;
            Quickshell.execDetached(["caelestia", "scheme", "set", "-v", variant]);
        }
    }
}
