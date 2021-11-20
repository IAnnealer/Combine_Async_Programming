import Foundation
import Combine

/*:
 `Combine`에 대한 기초와 개념을 알아봤으니 이제 본격적으로 핵심에 대해 알아보도록 할게요.

 이번 챕터에서는 Publisher를 만들어보고 Subscriber를 이용하여 해당 Publisher Chain들을 구독해보도록 합니다.
 */

/*:
 ## Hello Publisher
 ---

 `Combine`의 중심에는 `Publisher` 프로토콜이 존재합니다.

 이 프로토콜 내에는 하나 혹은 그 이상의 구독자들에게 시퀀스를 전달할 수 있는 타입이 되기 위한 요구사항이 명세되어 있습니다.

 즉, Publisher는 값을 가지는 이벤트를 방출할수 있는 타입입니다.

 */

public func example(of description: String, action: () -> Void) {
    print("\n--- Example of:", description, "---")
    action()
}

example(of: "Publisher") {
    // 1
    let myNotification = Notification.Name("MyNotification")

    // 2
    let publisher = NotificationCenter.default
        .publisher(for: myNotification, object: nil)

    // 3
    let notificationCenter = NotificationCenter.default

    // 4
    let observer = notificationCenter.addObserver(forName: myNotification,
                                                  object: nil,
                                                  queue: nil, using: { notification in
        print("Notification Received: \(notification.description)")
    })

    // 5
    notificationCenter.post(name: myNotification, object: nil)

    // 6
    notificationCenter.removeObserver(observer)
}

/*:
 1. NotificationName을 생성합니다.
 2. NotifiationCenter 싱글톤 객체에 접근하여 publisher 메소드를 호출하여 Publisher 타입으로 초기화합니다.
 3. NotificationCenter 싱글톤 객체 참조를 얻어옵니다.
 4. 앞서 생성한 NotificationName에 대한 Observer를 등록합니다.
 5. NotificationName에 이벤트를 방출합니다.
 6. NotificationCenter로 부터 Observer를 제거합니다.

 `.publisher` 메소드를 Option-click 해보면 event를 방출하는 Publisher를 반환한다고 기재되어 있습니다.

 이를 통해 `publisher` 라는 상수를 NotificationCenter.Publisher 타입으로 초기화합니다.

 publisher는 두 가지 종류의 이벤트르 방출할수 있습니다.

 - 값(엘리멘트)
 - Completion 이벤트

 publisher는 0개 혹은 그 이상의 값을 방출할수 있으나 Completion 이벤트는 단 한 번만 방출이 가능합니다.

 따라서 publisher가 compeltion event를 방출하면 그 이후로는 더이상의 이벤트 방출이 불가합니다.
 */

/*:
 ## Hello Subscriber
 ---

 `Subscriber` 또한 `Publisher` 와 마찬가지로 프로토콜입니다.

 Subscriber 프로토콜은 publisher로 부터 방출된 이벤트를 받을수 있는 타입입니다.
 */

example(of: "Subscriber", action: {
    let myNotification = Notification.Name("MyNotification")

    // publisher 생성
    let publisher = NotificationCenter.default
        .publisher(for: myNotification, object: nil)

    let notificationCenter = NotificationCenter.default

    // 1
    let subscription = publisher
        .sink(receiveValue: { _ in
            print("Notification received from a publisher!")
        })

    // 2
    notificationCenter.post(name: myNotification, object: nil)

    // 3
    subscription.cancel()
})

/*:
 publisher chain에 `sink`를 통해 구독을 진행하고 value를 받으면 print log를 찍어봅니다.

 NotificationCenter에 post를 하면 앞서 생성한 subscription에서 print log가 찍히고 이후에 cancel() 함수로 구독이 취소됩니다.
 */

example(of: "Just", action: {
    //1
    let just = Just("Emit event just once!")

    // 2
    _ = just
        .sink(receiveCompletion: {
            print("Receive completion", $0)
        }, receiveValue: {
            print("Receive value", $0)
        })
})

/*:
 Just 연산자는 단 하나의 값만 방출하고 completion 이벤트를 방출하는 Publisher를 생성합니다.

 sink 함수를 통해 publisher chain을 구독하고 completion 이벤트를 받은 경우와 value 이벤트를 받은 경우에 대한 경우를 각기 다르게 처리할수 있습니다.
 */

example(of: "assing(to:on:)", action: {
    // 1: 클래스 정의
    class SomeObject {
        var value: String = "" {
            didSet {
                print("SomeObject didSet value: \(value)")
            }
        }
    }

    // 2: 객체 생성
    let object = SomeObject()

    // 3: publisher chain 생성
    let publisher = ["Hello", "Combine!"].publisher

    // 4: assing(to:on:)를 통해 구독하면서 전달받은 값을 object의 value에 할당합니다.
    _ = publisher
        .assign(to: \SomeObject.value, on: object)
})

/*:
 `assign(to:on:)` 함수는 publisher chain으로부터 전달받은 value를 Keypath에 따라 주어진 인스턴스의 프로퍼티에 할당합니다.

 단 주어지는 값이 반드시 있어야하기 때문에 `sink` 와는 달리 publisher의 failure. 타입이 Never인 경우에만 사용이 가능합니다.
 */

