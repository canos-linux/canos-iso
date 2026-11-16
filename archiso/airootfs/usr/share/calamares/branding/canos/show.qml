import QtQuick 2.15;
import calamares.slideshow 1.0;

Presentation {
    id: presentation
    Slide {
        anchors.fill: parent
        Rectangle { anchors.fill: parent; color: "#0f0d12" }
        Image {
            id: logo
            source: "logo.png"
            width: 160; height: 160
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -30
        }
        Text {
            anchors.top: logo.bottom
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Yes, I CanOS."
            color: "#e6e1e7"
            font.pixelSize: 22
        }
    }
    function onActivate() { }
    function onLeave() { }
}
