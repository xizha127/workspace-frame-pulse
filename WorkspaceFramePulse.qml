pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Modules.Frame
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property int pulseDuration: 1000
    readonly property real peakOpacity: 0.45

    Variants {
        id: frames
        model: Quickshell.screens

        delegate: PanelWindow {
            id: panel

            required property var modelData
            property bool ready: false
            property real pulseAmount: 0
            property int pulseCount: 0

            readonly property string workspaceKey: {
                const workspace = CompositorService.activeWorkspaceForScreen(modelData.name);
                return workspace?.id === undefined || workspace?.id === null ? "" : String(workspace.id);
            }
            readonly property bool focused: CompositorService.getFocusedScreenName() === modelData.name
            readonly property bool frameAvailable: CompositorService.frameWindowVisibleForScreen(modelData)

            screen: modelData
            color: "transparent"
            visible: frameAvailable && pulseAmount > 0
            updatesEnabled: visible
            WlrLayershell.namespace: "workspace-frame-pulse"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}
            anchors { top: true; bottom: true; left: true; right: true }

            function pulse() {
                if (!ready || !frameAvailable)
                    return;
                pulseCount++;
                animation.restart();
            }

            function stopPulse() {
                animation.stop();
                pulseAmount = 0;
            }

            onWorkspaceKeyChanged: {
                if (workspaceKey !== "")
                    pulse();
            }
            onFocusedChanged: {
                if (focused)
                    pulse();
                else
                    stopPulse();
            }
            onFrameAvailableChanged: {
                if (!frameAvailable)
                    stopPulse();
            }
            Component.onCompleted: ready = true

            FrameBorder {
                anchors.fill: parent
                opacity: panel.pulseAmount
                cutoutTopInset: Math.max(0, Math.round(SettingsData.frameEdgeReservation(panel.modelData, "top")))
                cutoutBottomInset: Math.max(0, Math.round(SettingsData.frameEdgeReservation(panel.modelData, "bottom")))
                cutoutLeftInset: Math.max(0, Math.round(SettingsData.frameEdgeReservation(panel.modelData, "left")))
                cutoutRightInset: Math.max(0, Math.round(SettingsData.frameEdgeReservation(panel.modelData, "right")))
                cutoutRadius: Math.max(0, Math.round(SettingsData.frameRounding))
                borderColor: Theme.withAlpha(Theme.blend(Theme.surfaceText, Theme.primary, 0.15), 1)
            }

            SequentialAnimation {
                id: animation

                NumberAnimation {
                    target: panel
                    property: "pulseAmount"
                    to: root.peakOpacity
                    duration: root.pulseDuration / 2
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: panel
                    property: "pulseAmount"
                    to: 0
                    duration: root.pulseDuration / 2
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    IpcHandler {
        target: "workspaceFramePulse"

        function pulse(screenName: string): string {
            const frame = frames.instances.find(instance => instance.modelData.name === screenName);
            if (!frame)
                return "Unknown screen: " + screenName;
            frame.pulse();
            return "ok";
        }

        function status(): string {
            return JSON.stringify(frames.instances.map(frame => ({
                screen: frame.modelData.name,
                workspace: frame.workspaceKey,
                focused: frame.focused,
                enabled: frame.frameAvailable,
                pulses: frame.pulseCount,
                opacity: frame.pulseAmount
            })));
        }
    }
}
