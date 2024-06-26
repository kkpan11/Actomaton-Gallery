import Foundation
import SwiftUI
import Actomaton
import Utilities
import Tabs
import Home
import SettingsScene
import Counter
import Login
import UserSession
import AnimationDemo
import Physics
import UniversalLink

// MARK: - Action

public enum Action: Sendable
{
    case tab(Tabs.Action<TabCaseAction, TabCaseState, TabID>)

    case userSession(UserSession.Action)
    case loggedOut(Login.Action)

    case universalLink(URL)

    case didFinishOnboarding
    case resetOnboarding

    /// Inserts random tab by tab index.
    case insertRandomTab(index: Int)

    /// Removes tab by tab index.
    /// - Note: If `index = nil`, random tab index will be removed.
    case removeTab(index: Int?)
}

// MARK: - State

public struct State: Equatable, Sendable
{
    public var tab: Tabs.State<TabCaseState, TabID>

    public var userSession: UserSession.State
    {
        // NOTE: Uses `didSet` to also update Settings state.
        didSet {
            guard let user = self.userSession.loggedInUser else { return }

            self.updateSettingsState {
                $0.user = user
            }
        }
    }

    public var isOnboardingComplete: Bool

    public init(
        tab: Tabs.State<TabCaseState, TabID>,
        userSession: UserSession.State,
        isOnboardingComplete: Bool
    )
    {
        self.tab = tab
        self.userSession = userSession
        self.isOnboardingComplete = isOnboardingComplete
    }
}

extension State
{
    public var homeState: Home.State?
    {
        self.tab.tabs.first(where: { $0.id == .home })?.inner.home
    }

    fileprivate mutating func updateHomeState(_ update: (inout Home.State) -> Void)
    {
        guard let tabIndex = self.tab.tabs.firstIndex(where: { $0.id == .home }),
              var homeState = self.homeState else { return }

        update(&homeState)

        self.tab.tabs[tabIndex].inner = .home(homeState)
    }

    public var settingsState: SettingsScene.State?
    {
        self.tab.tabs.first(where: { $0.id == .settings })?.inner.settings
    }

    fileprivate mutating func updateSettingsState(_ update: (inout SettingsScene.State) -> Void)
    {
        guard let tabIndex = self.tab.tabs.firstIndex(where: { $0.id == .settings }),
              var settingsState = self.settingsState else { return }

        update(&settingsState)

        self.tab.tabs[tabIndex].inner = .settings(settingsState)
    }

    public var isDebuggingTab: Bool
    {
        self.homeState?.common.isDebuggingTab ?? false
    }
}

public func counterTabItem(index: Int) -> Tabs.TabItem<TabCaseState, TabID>
{
    Tabs.TabItem(
        id: .counter(UUID()),
        inner: .counter(Counter.State(count: 0)),
        tabItemTitle: "Counter \(index)",
        tabItemIcon: Image(systemName: "\(index).square.fill")
    )
}

// MARK: - Environment

public typealias Environment = HomeEnvironment

// MARK: - Reducer

public func reducer() -> Reducer<Action, State, Environment>
{
    .combine(
        tabReducer,
        settingsReducer,

        UserSession.reducer
            .contramap(action: /Action.userSession)
            .contramap(state: \.userSession)
            .contramap(environment: { _ in () }),

        universalLinkReducer(),

        onboardingReducer(),
        loggedOutReducer,
        debugTabInsertRemoveReducer
    )
}

private var tabReducer: Reducer<Action, State, Environment>
{
    Tabs
        .reducer(
            innerReducers: { tabID in
                switch tabID {
                case .home:
                    return Home.reducer
                        .contramap(action: /TabCaseAction.home)
                        .contramap(state: /TabCaseState.home)

                case .settings:
                    return SettingsScene.reducer
                        .contramap(action: /TabCaseAction.settings)
                        .contramap(state: /TabCaseState.settings)
                        .contramap(environment: { _ in () })

                case .counter:
                    return Counter.reducer
                        .contramap(action: /TabCaseAction.counter)
                        .contramap(state: /TabCaseState.counter)
                        .contramap(environment: { _ in () })

                case .animationDemo:
                    return AnimationDemo.reducer
                        .contramap(action: /TabCaseAction.animationDemo)
                        .contramap(state: /TabCaseState.animationDemo)
                        .contramap(environment: { _ in () })
                }
            }
        )
        .contramap(action: /Action.tab)
        .contramap(state: \.tab)
}

private var settingsReducer: Reducer<Action, State, Environment>
{
    .init { action, state, environment in
        guard case let .tab(.inner(_, .settings(action))) = action else { return .empty }

        switch action {
        case .logout:
            return .nextAction(.userSession(.logout))

        case .onboarding:
            return .nextAction(.resetOnboarding)

        case .insertTab:
            return .nextAction(.insertRandomTab(index: Int.random(in: 0 ... 4)))

        case .removeTab:
            return .nextAction(.removeTab(index: Int.random(in: 0 ... 4)))
        }
    }
}

private func universalLinkReducer() -> Reducer<Action, State, Environment>
{
    .init { action, state, environment in
        guard case let .universalLink(url) = action,
              let route = UniversalLink.Route(url: url) else
        {
            return .empty
        }

        switch route {
        case .home:
            state.updateHomeState {
                $0.current = nil
            }
            state.tab.currentTabID = .home

        case let .counter(count: count):
            state.updateHomeState {
                $0.current = .counter(.init(count: count))
            }
            state.tab.currentTabID = .home

        case .physicsRoot:
            state.updateHomeState {
                $0.current = .physics(.init(current: nil))
            }
            state.tab.currentTabID = .home

        case .physicsGravityUniverse:
            state.updateHomeState {
                $0.current = .physics(.gravityUniverse)
            }
            state.tab.currentTabID = .home

        case let .tab(index):
            let adjustedIndex = min(max(index, 0), state.tab.tabs.count - 1)
            state.tab.currentTabID = state.tab.tabs[adjustedIndex].id
        }

        return .empty
    }
}

private func onboardingReducer() -> Reducer<Action, State, Environment>
{
    .init { action, state, environment in
        switch action {
        case .didFinishOnboarding:
            state.isOnboardingComplete = true

        case .resetOnboarding:
            state.isOnboardingComplete = false

        default:
            break
        }
        return .empty
    }
}

public var loggedOutReducer: Reducer<Action, State, Environment>
{
    .init { action, state, environment in
        guard case let .loggedOut(action) = action else { return .empty }

        switch action {
        case .login:
            return .nextAction(Action.userSession(.login))

        case .loginError:
            return .nextAction(Action.userSession(.loginError(.loginFailed)))

        case .onboarding:
            return .nextAction(.resetOnboarding)
        }
    }
}

public var debugTabInsertRemoveReducer: Reducer<Action, State, Environment>
{
    Reducer { action, state, environment in
        switch action {
        case let .insertRandomTab(index):
            return Effect {
                // Random alphabet "A" ... "Z".
                let char = (65 ... 90).map { String(UnicodeScalar($0)) }.randomElement()!

                return .tab(.insertTab(
                    Tabs.TabItem(
                        id: .counter(UUID()),
                        inner: .counter(.init(count: 0)),
                        tabItemTitle: "Tab \(char)",
                        tabItemIcon: Image(systemName: "\(char.lowercased()).circle")
                    ),
                    index: index
                ))
            }

        case let .removeTab(index):
            guard !state.tab.tabs.isEmpty else { return .empty }

            // Always keep `TabID.home` and `.settings`.
            if state.tab.tabs.count == TabID.protectedTabIDs.count {
                return .empty
            }

            print("===> state.tab.tabs.count", state.tab.tabs.count)

            let adjustedIndex: Int = {
                if let index = index {
                    return min(max(index, 0), state.tab.tabs.count - 1)
                }
                else {
                    return Int.random(in: 0 ..< state.tab.tabs.count)
                }
            }()

            let tabID = state.tab.tabs[adjustedIndex].id

            if TabID.protectedTabIDs.contains(tabID) {
                // Retry with same `removeTab` action with `index = nil` as random index.
                return .nextAction(.removeTab(index: nil))
            }

            return .nextAction(.tab(.removeTab(tabID)))

        default:
            return .empty
        }
    }
}
