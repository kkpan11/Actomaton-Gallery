import SwiftUI
import ActomatonStore
import Stopwatch
import ExampleListUIKit

public struct StopwatchExample: Example
{
    public init() {}

    public var exampleIcon: Image { Image(systemName: "stopwatch") }

    @MainActor
    public func build() -> UIViewController
    {
        HostingViewController.make(
            store: Store(
                state: .init(),
                reducer: Stopwatch.reducer,
                environment: .live(commonEffects: .live)
            ),
            makeView: StopwatchView.init
        )
    }
}
