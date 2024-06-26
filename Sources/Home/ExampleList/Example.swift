import SwiftUI
import ActomatonUI

protocol Example: Sendable
{
    var exampleTitle: String { get }
    var exampleIcon: Image { get }
    var exampleInitialState: Home.State.Current { get }

    @MainActor
    func exampleView(store: Store<Home.Action, Home.State, Home.Environment>) -> AnyView
}

extension Example
{
    var exampleTitle: String
    {
        let title = String(describing: self)
        if let index = title.range(of: "Example")?.lowerBound { // trim "-Example()"
            return String(title.prefix(upTo: index))
        }
        else {
            return title
        }
    }
}

extension Example
{
    /// Helper method to transform parent `Store` into child `Store`, then `makeView`.
    @MainActor
    static func exampleView<ChildAction, ChildState, ChildEnvironment, V: View>(
        store: Store<Home.Action, Home.State, Home.Environment>,
        action: @escaping (ChildAction) -> Home.Action,
        statePath: CasePath<Home.State.Current, ChildState>,
        environment: @escaping (Home.Environment) -> ChildEnvironment,
        makeView: @MainActor (Store<ChildAction, ChildState, ChildEnvironment>) -> V
    ) -> AnyView
    {
        @MainActor
        @ViewBuilder
        func _exampleView() -> some View
        {
            if let substore = store
                .map(state: \.current)
                .optionalize()?
                .caseMap(state: statePath)
                .optionalize()?
                .contramap(action: action)
                .map(environment: environment)
            {
                makeView(substore)
            }
        }

        return AnyView(_exampleView())
    }

    /// Helper method to transform parent `Store` into child `Store` (with child `Environment` as `Void`), then `makeView`.
    @MainActor
    static func exampleView<ChildAction, ChildState, V: View>(
        store: Store<Home.Action, Home.State, Home.Environment>,
        action: @escaping (ChildAction) -> Home.Action,
        statePath: CasePath<Home.State.Current, ChildState>,
        makeView: @MainActor (Store<ChildAction, ChildState, Void>) -> V
    ) -> AnyView
    {
        @MainActor
        @ViewBuilder
        func _exampleView() -> some View
        {
            if let substore = store
                .map(state: \.current)
                .optionalize()?
                .caseMap(state: statePath)
                .optionalize()?
                .contramap(action: action)
                .map(environment: { _ in () })
            {
                makeView(substore)
            }
        }

        return AnyView(_exampleView())
    }
}
