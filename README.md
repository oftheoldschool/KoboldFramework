# Kobold Framework

Creates a Swift Playground app with a Metal view and basic input support. Very early alpha.

## Getting Started

1. Create a new Swift Playground, choosing the Playground Type 'App'
2. Long press on the left side bar below the code section
3. Choose Add Swift Package
4. Paste the Web Url of this project: `https://github.com/oftheoldschool/KoboldFramework.git` and hit return
5. When the Package has been resolved, choose 'Add to App Playground'
6. Delete ContentView.swift, and replace the code in MyApp.swift with the following:
```
import SwiftUI
import KoboldFramework

@main
struct KoboldMain: App {
    var koboldApp = ExampleApp()
    var body: some Scene {
        koboldApp.body
    }
}

class ExampleApp: KoboldApp {
    override var appName: String { "Example App" }
    // override things from KoboldApp here
}
```
7. Run the Playground. You should see a loading screen followed by a Metal view that changes colour

## Customising Behaviour

See [/Sources/KoboldFramework/KoboldApp.swift] for a list of all the open vars and funcs that can be overridden to customise the behaviour.

Of particular note is `override public func createFrameHandler(sysLink: KSysLink) -> KFrameHandler` - KFrameHandler being the protocol for the class that will be executed each frame. The example implementation provided here is [Sources/KoboldFramework/Examples/Basic/ExampleBasicFrameHandler.swift]

## Disclaimer

Use at your own risk.
