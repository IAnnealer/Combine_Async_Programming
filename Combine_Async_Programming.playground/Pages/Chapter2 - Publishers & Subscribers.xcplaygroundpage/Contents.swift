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

/*:
 ## Hello Cancellable

 Subscriber가 Publisher로 부터 더이상 이벤트를 받고 싶지 않거나 할 일이 끝났다면 구독을 취소해서 리소스를 해제해야합니다.

 Subscription은 `AnyCancellable` 타입을 반환하게 되며 이는 `Cancellable` 이라는 프로토콜을 준수하고 `cancel()` 메소드를 수행할수 있게 설계되어 있습니다.

 `cancel()` 을 호출하지 않을 경우, 구독이 계속하여 진행되므로 subscriber의 모든 일이 끝나면 cancel을 반드시 호출해주어야 합니다.
 */

/*:
 ## Understanding what's going on
 ---

 ![publisher-subscriber-diagram](publisher-subscriber-diagram.png)

 1. subscriber가 publisher를 구독합니다.
 2. publisher가 subscription을 만들어서 subscriber에게 전달합니다.
 3. subscriber가 publisher에게 value를 요청합니다.
 4. publisehr가 value를 방출합니다.
 5. publisher의 업무가 끝나면 completion event를 전달합니다.
 */

/*:
 ## Hello Subject
---

 subject또한 rxSwift에서의 subject와 유사합니다.

 subject는 publisher의 일종이며 Publisher 프로토콜을 준수합니다.

 ```
 protoocl Subject: AnyObject, Publisher
 ```

 subject는 sink를 통해 구독도 가능하며 send를 통해 자체적으로 이벤트 방출 또한 가능합니다.
 (즉, Publsiher이며 Subscriber이죠!)


 ### PassthroughSubject
 */

example(of: "PassthroughSubject", action: {
    // 1: 사용자 정의 커스텀 Error
    enum MyError: Error {
        case test
    }

    // 2: String과 MyError를 receive 하는 커스텀 Subscriber
    final class StringSubscriber: Subscriber {
        typealias Input = String

        typealias Failure = MyError

        func receive(subscription: Subscription) {
            subscription.request(.max(2))
        }

        func receive(_ input: String) -> Subscribers.Demand {
            print("Received value", input)
            return input == "World" ? .max(1) : .none
        }

        func receive(completion: Subscribers.Completion<MyError>) {
            print("Received completion", completion)
        }
    }

    // 4: Passthroughsubject 객체  생성
    let subject = PassthroughSubject<String, MyError>()

//    subject.subscribe(subscriber)

    // 5: sink를 이용하여 subscription1 생성
    let subscription1 = subject
        .sink(receiveCompletion: { completion in
            print("Received completion (sink1)", completion)
        }, receiveValue: { value in
            print("Received value (sink1)", value)
        })

    // 6: sink를 이용하여 subscription2 생성
    let subscription2 = subject
        .sink(receiveCompletion: { completion in
            print("Received completion (2)", completion)
        }, receiveValue: { value in
            print("Received value (2)", value)
        })

    // 7. 값 방출
    subject.send("Hello")
    subject.send("World")

    // 8. 구독 취소
    subscription1.cancel()
    subscription2.cancel()
})

/*:
 `PassthroudhSubject` 를 사용하면 `send(_:)` 를 통해 새로운 값을 방출할수 있습니다.
 또한 이는 broadcast 방식으로 진행되므로 해당 subject를 구독하고 있는 모든 subscriber에게 값이 보내지게 됩니다.

 즉, `subject`는 `subscriber`에게 `element`를 `broadcas` 하는 타입입니다.

 만일 subject에 completion 이벤트를 전달하거나 subject에 대한 구독이 cancel되면 그 이후에는 값이 전달되지 않습니다.

 완료 이벤트를 받으면 더이상의 다른 완료 이벤트 혹은 값을 받지 않는것은 당연히 Publisher와 동일합니다.

 */

/*:
 ### CurrentValueSubject
 ---

 `PassthorughSubject` 와는 달리 초기값을 가지며 가장 최근에 방출된 value에 대한 buffer를 갖는 subject 입니다.

 Rx에서는 BehaviorSubject에 대응되는 개념입니다.

 아래 예시를 통해 보다 자세히 살펴보도록 할게요.
 */

example(of: "CurrentValueSubejct", action: {
    var subscriptions = Set<AnyCancellable>()

    // 1. Int와 Never 타입을 갖는 CurrentValueSubject 생성
    let subject = CurrentValueSubject<Int, Never>(0)

    // 2. sink를 통해 subject chain을 구독합니다.
    subject
        .sink(receiveCompletion: { _ in
            print("Received Completion")
        }, receiveValue: {
            print("Received value: \($0)")
        })
        .store(in: &subscriptions)
        // 3. sink를 통해 생성한 subscription을 subscriptions Set에 저장합니다.

    subject.send(1)
    subject.send(2)

    print("CurrentValueSubjct 객체에 담겨있는 값: \(subject.value)")

    // 4. 현재 CurrentValue값 수정
    subject.value = 999

    print("CurrentValueSubjct 객체에 담겨있는 값: \(subject.value)")

    subject.send(completion: .finished)
})

/*:
 PassthourghSubject 예제에서는 `subscription`을 값으로 저장한 이후 취소를 별도로 진행해주었죠.

 ```
 let subscription1 = passthroughSubject
    .sink()

 subscription1.cancel()
 ```

 이를 CurrentValueSubject 에서는 `store(in:)` 을 통해 처리합니다.

 `in` 에 전달되는 파라미터는 `Set<AnyCancellable>` 타입으로 다양한 Subscription을 저장할수 있습니다.

 여기에 저장되는 모든 Subscription들은 해당 Set이 deinit 될 때 함께 자동으로 취소가 됩니다.

 */
