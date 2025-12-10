# API

The Roblox Engagement tool is a package that enables developers to easily query and handle events, objects, interfaces engagements from within a Roblox experience.

---

IAB (Interactive Advertising Bureau) provides a generalized set of rules/guidelines that we can follow in order to better evaluate if a player has engaged with an event or not.

Sources in order for us to be IAB (Interactive Advertising Bureau) compliance are as follows: https://www.iab.com/wp-content/uploads/2015/06/dig_vid_imp_meas_guidelines_finalv2.pdf

## Functions

### TrackGui
```luau { .fn_type }
Engagements.TrackGui(gui: ScreenGui, identifier: string): ()
```

Tracks when a GUI is viewed or interacted with by:

- Setting a unique identifier as an attribute on the GUI.
- Tagging the GUI so it can be recognized later.
- This allows the client side system to detect and respond to GUI visibility and interactions.

!!! info ""
	This is a client only method.

---

### TrackVideo
```luau { .fn_type }
Engagements.TrackVideo(video: VideoFrame, identifier: string?): ()
```

Tracks when a video is watched by:

- Setting a unique identifier as an attribute on the video.
- Tagging the video so it can be recognized later.
- This allows the client side system to detect and respond to video playback. The WatchedVideo signal will be triggered when the video ends or loops.

!!! success ""
	This is a server only method.

---

### TrackZone
```luau { .fn_type }
Engagements.TrackZone(zone: Model, identifier: string?): ()
```

Tracks when a player enters or leaves a zone by:

- Setting a unique identifier as an attribute on the zone.
- Tagging the zone so it can be recognized later.
- This allows the client side system to detect and respond to player movement in and out of designated zones. The ZoneEntered and ZoneLeft signals will be triggered when relevant.

!!! success ""
	This is a server only method.

---

### TrackObject
```luau { .fn_type }
Engagements.TrackObject(object: Model, identifier: string?): ()
```

Tracks when an object enters the players viewport:

- Setting a unique identifier as an attribute on the zone.
- Tagging the zone so it can be recognized later.

This allows the client side system to detect and respond to objects appearing in the players viewport. This function will invoke the following signals:

- InScreenshot

!!! success ""
	This is a server only method.

---

### Initialize
```luau { .fn_type }
Engagements.Initialize(): ()
```

Initializes the Engagements package by setting up necessary event listeners and tracking systems.

How It Works:

  - Ensures initialization only happens once.
  - Retrieves the package's remote event for communication.
  - If running on the **server**, it listens for `ZoneEntered` and `ZoneLeft` events
   from clients and fires corresponding signals.
  - If running on the **client**, it:
    - Tracks engagement zones by binding to tagged objects.
    - Runs validation checks each frame (`Heartbeat`).
    - Updates character overlap parameters when the player’s character is added or removed.

!!! warning
	The Engagements package initializes itself automatically. Developers requiring this module do not need to call this function.