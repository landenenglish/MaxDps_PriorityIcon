# MaxDps Priority Icon

A standalone addon that adds a centralized priority ability icon to MaxDps rotation helper. This icon displays the next recommended ability in one convenient location, perfect for players who have memorized their keybinds but still want rotation guidance.

## Features

- **Centralized Priority Display** - Shows the next recommended ability in a single, movable icon
- **Draggable Positioning** - Click and drag to place the icon anywhere on your screen
- **Configurable Appearance** - Adjust position and scale
- **Independent Updates** - Won't be overwritten when MaxDps updates
- **Easy Configuration** - Simple UI and chat commands

## Requirements

- **MaxDps** (main addon) must be installed and enabled
- Works with all MaxDps class modules and custom rotations

## Installation

1. Extract the `MaxDps_PriorityIcon` folder to your `Interface/AddOns/` directory
2. Enable the addon in your addon manager
3. Restart World of Warcraft or reload UI (`/reload`)

## Usage

### Basic Operation

- The priority icon will appear automatically when MaxDps is active
- Icon shows the same ability that MaxDps would highlight on your action bars
- Move the icon by dragging it to your preferred location

### Configuration

- **Chat Commands**: `/maxdpspriority` or `/mdpspri`
- **Right-click** the icon to open configuration
- **Interface Options**: Available under MaxDps → Priority Icon

### Configuration Options

- **Enable Priority Icon** - Master on/off toggle
- **Enable Priority/Cooldown Icons**
- **Lock Position** - Prevent accidental movement
- **Scale** - Overall scaling multiplier (0.5-2.0x)

### Useful Buttons

- **Test Icon** - Shows a test spell (useful for positioning)
- **Reset Position** - Returns icon to default center-bottom position

## Compatibility

- Works with current MaxDps builds
- Compatible with MaxDps class modules (Warrior, Paladin, etc.)
- Supports custom rotations
- Works with WeakAuras integration
- No conflicts with other addons

## Troubleshooting

### Icon Not Showing

1. Ensure MaxDps is installed and enabled
2. Check that MaxDps Priority Icon is enabled in config
3. Make sure MaxDps rotation is active (`/maxdps` to open MaxDps config)

### Icon Position Lost

- Use the "Reset Position" button in config
- Or manually reposition by dragging

### Performance

- This addon is extremely lightweight
- Uses the same spell detection as MaxDps with minimal overhead

## Commands

- `/maxdpspriority` - Open configuration window
- `/mdpspri` - Shorthand for configuration
- `/reload` - Reload UI after major changes

## Version History

### 1.0.0

- Initial release
- Full feature set with configuration UI
- Robust MaxDps integration
- Drag and drop positioning

## Support

This is a community-created extension for MaxDps. For issues:

1. Check that MaxDps is working properly first
2. Try disabling and re-enabling the addon
3. Reset configuration if needed

## Technical Notes

- Uses function hooking to integrate with MaxDps
- Automatically detects MaxDps load order
- Saves settings per character in `MaxDpsPriorityIconDB`
- Uses standard WoW UI frameworks for maximum compatibility
