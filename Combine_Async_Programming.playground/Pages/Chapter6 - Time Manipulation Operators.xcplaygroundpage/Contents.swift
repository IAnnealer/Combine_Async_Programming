import Foundation
import Combine
import SwiftUI

public func example(of description: String, action: () -> Void) {
    print("\n--- Example of:", description, "---")
    action()
}

var subscriptions = Set<AnyCancellable>()

/*:
 # Chapter 6: Time Manipulation Operators
 ---

 반응현 프로그래밍의 핵심은 시간의 흐름에 따른 비동기 이벤트 흐름을 모델링 할 수 있다는 것 입니다.

 이러한 측면에서 Combine 프레임워크는 시간을 다룰 수 있는 다양한 Operator를 제공합니다.

 이번 챕터에서는 시간을 조작하는 연산자들에 대해 알아보도록 하겠습니다.

 ## Shifting Time
 ---

 가장 기본적인 시간 조작 operator는 publisher의 Event emit을 지연시켜서 실제 발생하는 것 보다 늦게 받아볼 수 있도록 하는 operator 입니다.

 `delay(for:tolerance:scheduler:options)` 는 값 시퀀스 전체의 시간을 이동시킵니다.

 즉 upstream publisher 에서 값이 emit 될 때 마다 `delay` 를 통해 Scheduler에 명시해놓은 시간만큼 지연 시킵니다.

 */

example(of: "delay", action: {
    let valuePerSecond = 1.0

    let sourcePublisher = PassthroughSubject<Date, Never>()

    let delayedPublisher = sourcePublisher
        .delay(for: .seconds(1.5), scheduler: DispatchQueue.main)

    let subscription = Timer
        .publish(every: 1.0 / valuePerSecond, on: .main, in: .common)
        .autoconnect()      // value를 emit 하기 이전에 connect를 위하여 autoconnect 사용.
        .subscribe(sourcePublisher)
})

// value를 1초 마다 emit하고 1.5초 delay를 진행합니다.

/*:
 ## Collecting Values
 ---

 - 특정 기간 동안 방출된 values를 모아줍니다.
 - collect된 value들을 모아서 array 타입으로 반환합니다.
 */

example(of: "collect", action: {
    let valuesPerSecond = 1.0
    let collectTimeStride = 4

    let sourcePublisher = PassthroughSubject<Date, Never>()
    let collectedPublisher = sourcePublisher
        .collect(.byTime(DispatchQueue.main, .seconds(collectTimeStride)))
        .flatMap { dates in dates.publisher }

    let subscription = Timer
        .publish(every: 1.0 / valuesPerSecond, on: .main, in: .common)
        .autoconnect()
        .subscribe(sourcePublisher)
})

/*:
 ## Holding off on events
 ---

 - debounce: 입력 주기가 끝났을때 event를 방출합니다.
 - throttle: 입력 주기 내 입력값 중 첫번쨰 || 마지막 event를 방출합니다.
 */

example(of: "debounce", action: {
    let subject = PassthroughSubject<String, Never>()

    let debounced = subject
        .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
        .share()        // 여러 subscriber에게 해당 publisher를 공유하기 위함.
})

/*:
 `debounce` operator는 입력 주기가 끝나면 마지막 값을 출력합니다.
 이후 추가로 value가 들어올 경우 주기가 다시 갱신됩니다.
 */

example(of: "throttle", action: {
    let throttleDelay = 1.0

    let subject = PassthroughSubject<String, Never>()

    let throttled = subject
        .throttle(for: .seconds(throttleDelay), scheduler: DispatchQueue.main, latest: false)
        .share()
})

/*:
 `throttle` 은 처음에 구독한 시점에 value를 바로 방출합니다.

 latest 값을 false 로 줄 경우 특정 주기 안의 첫번째 value를 출력합니다.

 버튼 이벤트를 여러번 하는 경우 이를 통해 대응할수 있습니다.
 */




