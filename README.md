# Bluetooth on sleep

Switches Bluetooth off while the Mac sleeps, so headphones in a bag stop connecting to it.

A Droplet for [Droppy](https://getdroppy.app), built with [DroppyKit](https://getdroppy.app/docs/droppykit).

## What it does

- **Turn Bluetooth off when the Mac sleeps.** If Bluetooth was already off before sleep, it is left alone and stays off on wake.
- **Turn Bluetooth back on when the Mac wakes.** Only when this droplet was the one that switched it off.

Both options can be switched off separately in the droplet's settings page. The droplet has no notch or shelf surface; it works in the background and is configured from Droppy's settings.

## Requirements

- macOS 14 or later, Droppy 15.3 or later
- Tested on a MacBook Pro (M3) running macOS 27.2 with Bluetooth headphones. The bundle is universal (Apple silicon and Intel), but it has only been tested on Apple silicon.

## Install

1. Download `Bluetoothsleep.droplet.zip` from the [latest release](https://github.com/fevrdyn/droppy-bluetooth-sleep/releases/latest) and unzip it.
2. In Droppy, open Settings → Store → Local droplets and add `Bluetoothsleep.droplet`.
3. Approve the droplet when Droppy asks.

If you use another app that toggles Bluetooth on sleep (Bluesnooze, for example), turn that off first so the two don't fight.

## Caveats

- **Private API.** Apple provides no public API for switching Bluetooth power. This droplet calls `IOBluetoothPreferenceGetControllerPowerState` and `IOBluetoothPreferenceSetControllerPowerState` from IOBluetooth, which are undocumented and could change or stop working in a future macOS release. They are resolved at runtime, so if they go missing the droplet does nothing rather than crashing.
- No DroppyKit capability covers Bluetooth or sleep/wake events, so the manifest declares none.

## Developing

With the [DroppyKit](https://gitlab.com/droppyformac1/droppykit) scripts on your `PATH`:

```bash
droppykit run        # open it in the development harness
droppykit build      # produce .build/Bluetoothsleep.droplet
droppykit validate   # the checks the Store runs
```

The development harness never touches the system, so the sleep and wake behavior has to be tested in Droppy itself.

## Credits

The idea, and the technique of switching Bluetooth power through IOBluetooth's private preference functions, come from [Bluesnooze](https://github.com/odlp/bluesnooze) by odlp, which is MIT licensed. This droplet is an independent implementation written for DroppyKit and contains no Bluesnooze source code.

Made with the help of Claude.

## License

[MIT](LICENSE)
