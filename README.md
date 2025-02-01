# LumiChain

A decentralized application for managing and controlling lighting systems on the Stacks blockchain. This contract enables users to:

- Register lighting devices with unique identifiers
- Control light states (on/off)
- Set brightness levels 
- Manage device ownership
- Track light usage history
- Create and manage device groups
- Schedule automated lighting actions

## Features

- Secure device registration and ownership management
- Permission-based control system
- State management for lighting devices
- Usage tracking and history
- Device grouping for coordinated control
- Automated scheduling system

### Device Groups
Create logical groups of lighting devices for coordinated control. Perfect for managing multiple lights in:
- Rooms
- Zones
- Floor levels
- Building sections

### Scheduling System
Schedule automated lighting actions:
- Turn lights on/off at specific times
- Adjust brightness levels
- Apply actions to individual devices or groups
- Set recurring schedules

## Getting Started

1. Clone the repository
2. Install Clarinet
3. Run tests: `clarinet test`
4. Deploy contract

## Usage Examples

### Creating a Device Group
```clarity
(contract-call? .lumi-control create-group u1 "Living Room")
```

### Adding Device to Group
```clarity
(contract-call? .lumi-control add-to-group u1 u1)
```

### Creating a Schedule
```clarity
(contract-call? .lumi-control create-schedule u1 u1 "device" "toggle" u1 u100)
```
