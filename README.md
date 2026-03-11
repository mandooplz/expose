# Expose 🚀

Expose는 SwiftUI Observation, RxSwift, Combine을 하나의 통합된 상태 선언으로 연결해 주는 강력한 Swift 라이브러리입니다.

현대 iOS 개발에서는 서로 다른 프레임워크 간 상태를 관리해야 하는 경우가 자주 발생합니다. 특히 UIKit(RxSwift)에서 SwiftUI(Observation)로 점진적으로 마이그레이션할 때 이 문제가 더 두드러집니다. Expose는 단일 진실 공급원(Single Source of Truth)을 제공하여, 프로퍼티를 한 번 선언하고 여러 반응형 프레임워크에서 관찰할 수 있게 해줍니다.

## ✨ 특징

- 통합 상태 관리: `@Exposed`로 한 번 선언하면 어디서든 사용할 수 있습니다.

- 매크로 기반: 보일러플레이트가 필요 없습니다. `@Exposable`이 registrar 생성과 프로토콜 준수를 자동으로 처리합니다.

- 성능 우선: Apple의 네이티브 Observation 프레임워크를 활용해 SwiftUI 업데이트 성능을 높입니다.

- 하이브리드 지원: 레거시 SwiftUI 뷰(`@StateObject`/`@ObservedObject`) 호환을 위해 `ObservableObject`를 자동 준수합니다.

- 깔끔한 API: projected value(`$`) 문법으로 RxSwift `Driver` 또는 Combine `Publisher`에 접근할 수 있습니다.

## 📦 설치

Swift Package Manager를 통해 프로젝트에 **Expose**를 추가하세요.

```swift
dependencies: [
    .package(url: "https://github.com/mandooplz/Expose.git", from: "0.1.2")
]
```

타깃의 dependencies에 Expose product를 추가하세요.

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Expose", package: "Expose") // 이 줄을 추가하세요
    ]
)
```

`0.1.2`부터는 `RxCombine 2.x`를 사용하므로 `RxSwift 6.6+` 프로젝트와 패키지 해석 충돌 없이 함께 사용할 수 있습니다.

## 🛠 사용법

### 1. ViewModel 정의

클래스에 `@Exposable` 매크로를 붙이고, 상태 프로퍼티에는 `@Exposed` 프로퍼티 래퍼를 사용하세요.

> [!CAUTION]
> `@Observable` 매크로와 `@Exposable` 매크로를 함께 사용할 때 Apple이 언더스코어 접두어를 가진 백킹 프로퍼티(예: `_currentPrice`)를 자동 생성합니다. 이때 `@Exposed` 프로퍼티 래퍼의 내부 저장소와 이름 충돌이 발생할 수 있습니다.

```swift
import Expose
import Observation

@Exposable // registrar 생성 및 Exposable/ObservableObject 준수 자동 처리
final class AuctionViewModel {

    // 외부에서는 읽기 전용, 내부에서는 수정 가능
    @Exposed private(set) var currentPrice: Int = 1000

    func updatePrice(_ newPrice: Int) {
        self.currentPrice = newPrice
    }
}
```

### 2. SwiftUI에서 사용 (Observation)

#### Observation 방식 (iOS 17+ 권장)

일반 `@Observable` 프로퍼티처럼 사용할 수 있으며, `.contentTransition` 같은 최신 애니메이션과 자연스럽게 동작합니다.

```swift
struct AuctionView: View {
    @State private var viewModel = AuctionViewModel()

    var body: some View {
        VStack {
            Text("$\(viewModel.currentPrice)")
                .font(.system(.largeTitle, design: .monospaced))
                .contentTransition(.numericText()) // 숫자가 자연스럽게 스크롤되는 애니메이션

            Button("Bid") {
                viewModel.updatePrice(viewModel.currentPrice + 100)
            }
        }
    }
}
```

#### Combine 방식 (반응형 접근)

Expose는 `@Exposed` 프로퍼티를 Combine publisher로 자동 노출하므로, Combine의 선언형 스트림 모델로 상태 변화에 반응할 수 있습니다.

이 방식은 검증, 분석 로깅, 조건부 플로우처럼 UI 렌더링과 부수 효과/비즈니스 로직을 분리하고 싶을 때 특히 유용합니다.

> [!NOTE]
> 이 섹션은 Combine 스타일 API를 사용하지만, **Expose 내부 상태 전파는 Combine에 의존하지 않습니다**.
>
> 모든 상태 변경은 Apple의 **Observation 프레임워크**가 주도하며, `$property.publisher`로 노출되는 Combine publisher는
> Observation 업데이트를 Combine 스트림으로 연결해 주는 **어댑터 레이어**입니다.
>
> 따라서 SwiftUI 뷰는 Observation의 고성능 diff 및 업데이트 모델의 이점을 유지하면서,
> 필요 시 Combine을 부수 효과 처리, 흐름 제어, 레거시 호환 목적으로 함께 사용할 수 있습니다.

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

### 3. UIKit에서 사용 (RxSwift & Combine)

projected value(`$`)를 사용하면 필요에 따라 서로 다른 반응형 스트림에 접근할 수 있습니다.

```swift
final class AuctionViewController: UIViewController {
    let viewModel = AuctionViewModel()
    let disposeBag = DisposeBag()

    func setupBindings() {
        // 1. RxSwift 바인딩
        viewModel.$currentPrice.driver
            .map { "\($0)" }
            .drive(priceLabel.rx.text)
            .disposed(by: disposeBag)

        // 2. Combine 구독
        viewModel.$currentPrice.publisher
            .sink { price in
                print("Price updated to: \(price)")
            }
            .store(in: &cancellables)
    }
}
```

## ⚙️ 요구 사항

- Swift 5.9+

- iOS 17.0+ / macOS 14.0+ (Observation 프레임워크 필수)

- RxSwift 6.6+

## 📄 라이선스

Expose는 MIT 라이선스로 배포됩니다. 자세한 내용은 LICENSE를 참고하세요.
