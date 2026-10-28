# Workspace Frame Pulse

Local DMS daemon that adds a click-through highlight over the existing frame.
It uses DMS's frame geometry, rounding, monitor preferences and theme colors.
Only the affected monitor pulses when its active workspace changes or it gains
monitor focus, including when the destination workspace is already visible.

Each pulse smoothly brightens for 500 ms and fades for 500 ms, peaking at the
midpoint and returning to zero at 1000 ms. Rapid changes
restart the animation from its current brightness. No polling or subprocesses
run in the plugin; the overlay is unmapped when idle. Existing bars, frame,
ambient effects and Hyprland navigation timings are unchanged.

`~/.config/hypr/custom/rules.lua` disables compositor map/unmap animations for
the `workspace-frame-pulse` layer, so the brightness fade stays in place.

Live checks:

```sh
dms ipc call workspaceFramePulse status
dms ipc call workspaceFramePulse pulse DP-4
```

Disable or re-enable:

```sh
dms ipc call plugins disable workspaceFramePulse
dms ipc call plugins enable workspaceFramePulse
```

If DMS IPC cannot find the embedded shell instance, pass `-c` with the config
path shown by the running `qs -p ...` process.
