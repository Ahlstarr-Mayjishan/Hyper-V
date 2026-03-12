# Hyper-V Rojo Setup

This project is mapped for Rojo with a single clean package root under `ReplicatedStorage`.

## Rojo Structure

After `rojo serve`, Studio should receive this tree:

```text
ReplicatedStorage
└─ HyperV
   ├─ Main
   ├─ HyperV
   └─ Hyper V

StarterPlayer
└─ StarterPlayerScripts
   └─ StudioLoader
```

`StudioLoader` is sourced from [StudioLoader.client.lua](./StudioLoader.client.lua) and opens the test UI plus the character preview panel flow.

## Start Studio Sync

```bash
rojo serve
```

Then connect the Rojo plugin in Roblox Studio to this project.

## Build a Place File

```bash
rojo build -o "UI roblox.rbxlx"
```

## Test Flow

1. Start `rojo serve`
2. Connect the project in Roblox Studio
3. Press `Play`
4. Open the `Preview` tab
5. Click `Open Character Preview`

## Notes

- `Main.lua` is the package bootstrap.
- `HyperV/` contains the new architecture.
- `Hyper V/` contains the legacy modules still bridged by parts of the new runtime.
- `StudioLoader.client.lua` is the recommended Studio test entrypoint.
