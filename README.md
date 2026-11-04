# Bluetooth on sleep

Switches Bluetooth off while the Mac sleeps, so headphones in a bag stop connecting to it.

A Droplet for [Droppy](https://getdroppy.app), built with [DroppyKit](https://getdroppy.app/docs/droppykit).

## What it does

Pretty straightforward. Close your Mac, Bluetooth switches off. Wake your Mac, Bluetooth turns on again.

## Credits

Made with the help of Claude

## Developing

With the [DroppyKit](https://gitlab.com/droppyformac1/droppykit) scripts on your `PATH`:

```bash
droppykit run        # open it in the development harness
droppykit build      # produce .build/Bluetoothsleep.droplet
droppykit validate   # the checks the Store runs
```

## License

MIT.
