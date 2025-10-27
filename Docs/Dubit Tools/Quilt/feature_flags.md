---
sidebar_position: 5
---

# Feature Flags

Feature flags are unique modifiers that alter default behavior of an interface for ex. change how overlapping interfaces interact with each other.

- **MatchingPriorityOverlap** - if two visible interfaces on matching Priority layer overlap, both interfaces ignore that overlap and are still visible

- **IgnoreLesserPriority** - the interface won't affect interfaces with lesser priority, just the ones with the same priority or higher

- **Ignore** - the interface is ignored and never will be hidden because of other interfaces