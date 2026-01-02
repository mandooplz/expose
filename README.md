# Expose 🚀

Expose is a powerful Swift library that bridges SwiftUI Observation, RxSwift, and Combine into a single, unified state declaration.

In modern iOS development, you often face the challenge of managing state across different frameworks—especially when incrementally migrating from UIKit (RxSwift) to SwiftUI (Observation). Expose provides a Single Source of Truth, allowing you to declare a property once and observe it from any reactive framework.

## ✨ Features

- Unified State: Declare once with `@Exposed` and use it everywhere.

- Macro-Powered: Zero boilerplate. `@Exposable` automatically generates the registrar and handles protocol conformances.

- Performance First: Leverages Apple's native Observation framework on iOS 17+, with Combine `ObservableObject` fallback for iOS 15–16.

- Hybrid Support: Automatically conforms to `ObservableObject` for compatibility with legacy SwiftUI views (`@StateObject`/`@ObservedObject`).

- Clean API: Access RxSwift `Driver` or Combine `Publisher` through the projected value (`$`) syntax.

## 📦 Installation

Add **Expose** to your project via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/mandooplz/expose-swift.git", from: "1.0.0")
]
```

In your target's dependencies, add the Expose product:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Expose", package: "Expose") // Add this line
    ]
)
```


## 🛠 Usage

### 1. Define your ViewModel

Simply annotate your class with `@Exposable` macro, then use `@Exposed` property wrapper for your state properties.

> [!CAUTION]
> When using the `@Observable` macro with `@Exposable` macro, Apple automatically generates a backing property with an underscore prefix (e.g., `_currentPrice`). This can cause a naming collision with the `@Exposed` property wrapper's internal storage.

```swift
import Expose
import Observation

@Exposable // Generates registrar and conforms to Exposable & ObservableObject
final class AuctionViewModel {
    
    // Read-only from outside, mutable from inside
    @Exposed private(set) var currentPrice: Int = 1000
    
    func updatePrice(_ newPrice: Int) {
        self.currentPrice = newPrice
    }
}
```



### 2. In SwiftUI (Observation)

#### Via Observation (Recommended for iOS 17+)
Use it like a standard @Observable property. It works seamlessly with modern animations like `.contentTransition`.

```swift
struct AuctionView: View {
    @State private var viewModel = AuctionViewModel()
    
    var body: some View {
        VStack {
            Text("$\(viewModel.currentPrice)")
                .font(.system(.largeTitle, design: .monospaced))
                .contentTransition(.numericText()) // Smooth scrolling digit animation
            
            Button("Bid") {
                viewModel.updatePrice(viewModel.currentPrice + 100)
            }
        }
    }
}
```

> [!NOTE]
> On iOS 15–16, SwiftUI updates flow through `ObservableObject` (`@StateObject`/`@ObservedObject`) instead of Observation tracking.

### Via Combine (Reactive approach)

Expose automatically exposes `@Exposed` properties as Combine publishers, allowing you to react to state changes using Combine’s declarative, stream-based model. On iOS 15–16, updates flow through `ObservableObject`/`objectWillChange` to keep SwiftUI in sync.

This approach is particularly useful when you want to separate UI rendering from side effects or business logic, such as validation, analytics, or conditional flows.

```swift
struct AuctionCombineView: View {
    @StateObject private var viewModel = AuctionViewModel()
    @State private var alertVisible = false

    var body: some View {
        VStack {
            Text("$\(viewModel.currentPrice)")
                .font(.system(.largeTitle, design: .monospaced))
        }
        .onReceive(viewModel.$currentPrice.publisher) { newPrice in
            if newPrice > 5000 {
                alertVisible = true
            }
        }
        .alert("High Price Alert", isPresented: $alertVisible) {
            Button("OK", role: .cancel) {}
        }
    }
}

```

### 3. In UIKit (RxSwift & Combine)

By using the projected value (`$`), you can access different reactive streams depending on your needs:

```swift
final class AuctionViewController: UIViewController {
    let viewModel = AuctionViewModel()
    let disposeBag = DisposeBag()
    
    func setupBindings() {
        // 1. RxSwift Binding
        viewModel.$currentPrice.driver
            .map { "\($0)" }
            .drive(priceLabel.rx.text)
            .disposed(by: disposeBag)
            
        // 2. Combine Subscription
        viewModel.$currentPrice.publisher
            .sink { price in
                print("Price updated to: \(price)")
            }
            .store(in: &cancellables)
    }
}
```

## ⚙️ Requirements

- Swift 5.9+

- iOS 15.0+ / macOS 14.0+ (Observation tracking enabled on iOS 17+)

- RxSwift 6.0+

## 📄 License

Expose is released under the MIT license. See LICENSE for details.
