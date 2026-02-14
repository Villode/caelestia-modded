import qs.components
import qs.services
import qs.config
import QtQuick
import "../../dashboard/dash"

Item {
    id: root

    readonly property QtObject calendarState: QtObject {
        property date currentDate: new Date()
    }

    implicitWidth: 280
    implicitHeight: cal.implicitHeight

    Calendar {
        id: cal
        anchors.fill: parent
        state: root.calendarState
    }
}
