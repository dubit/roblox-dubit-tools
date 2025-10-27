# Tool Name

The Notifications tool is intended to let you easily queue up and manage notifications for your game. It manages a
queue of notification requests and signals when various notification states are ready.

## Research & Development

[R&D Document](https://dubitlimited.atlassian.net/wiki/spaces/PROD/pages/4744839169/Notification+System+Tool)

### development.project.json

Basic client runtime to test some queueing with logs. As the UI is intended to be handled by the game using this package, it doesn't need to implement a UI to test behaviour.

### project packages

Signal - standard Sleitnick signalling package
