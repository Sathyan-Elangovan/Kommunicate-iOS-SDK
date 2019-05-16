# CHANGELOG

The changelog for [Kommunicate-iOS-SDK](https://github.com/Kommunicate-io/Kommunicate-iOS-SDK). Also see the [releases](https://github.com/Kommunicate-io/Kommunicate-iOS-SDK/releases) on Github.

1.5.0
---
### Enhancements
- [AL-2816] Added support for showing FAQ.
- Now, contact details will be shown for one-to-one chat also.
- Assignee details will now be updated real-time provided MQTT/APNS is connected.

### Fixes
- Fixed a crash where viewModel was nil while opening the controller.

1.4.1

### Fixes

- [AL-3493] Fixed an issue where Kommunicate localization file was not part of the pod.

1.4.0

### Enhancments

- [AL-3393] Added support for passing send message metadata in create group.

1.3.0

### Enhancments

- Now if the parent VC(from where the conversation is shown) doesn't have a navigation controller then the Conversation VC will still be shown.

1.2.0

### Enhancements

- [AL-2993] Updated Kommunicate framework to Swift 4.2.
- [AL-3071] Added support to show conversation assignee details in conversation list screen.

1.1.0

### Enhancements

- [AL-3189] Add localization support.

1.0.0
---

### Enhancements

- [AL-2853]Added support for showing Away message.
- [AL-3062]While creating a conversation, a default agent will be fetched and added. Now it's not required  to pass the agent Ids.
- [AL-3188]Send notification when conversation view is launched and closed.