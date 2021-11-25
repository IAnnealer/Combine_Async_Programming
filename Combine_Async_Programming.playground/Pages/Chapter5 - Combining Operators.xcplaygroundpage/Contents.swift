import Foundation
import Combine
import UIKit

/*:
 ## Chapter 5: Combining Operators
 ---

 이번 챕터에서는 Combining Operator에 대해 알아볼게요!

 이 연산자들을 통해서 `publisher`가 방출하는 값을 결합하여 사용할수 있습니다.

 ### Prepending

 `prepend` 연산자는 upstream에서 오는 값 이전에 인자로 전달한 값을 먼저 방출하는 연산자입니다.

 `prepend` 는 값 뿐만 아니라 publisher chain 을  붙일수도 있습니다.

 다만, 해당 연산자는 `publisher` 의 `Output` 과 동일한 타입이어야 합니다.
 */

var subscriptions = Set<AnyCancellable>()

// [3, 4] 값을 갖는 publisher를 생성합니다.
[3, 4]
    .publisher
    .prepend(1, 2)  // prepend 연산자를 통해 publisher Chain 제일 앞에 1, 2를 덧붙여줍니다.
    .prepend(-1, 0) // 위 prepend를 통해 덧붙인 상태에서 제일 앞에 한번더 덧붙입니다.
    .sink(receiveCompletion: { _ in print("\n")},
          receiveValue: { print($0) })
    .store(in: &subscriptions)

/*:
 Output:
    -1
    0
    1
    2
    3
    4
 */

[5, 6, 7]
    .publisher
    .prepend([3, 4])    // prepend 인자로 Sequence를 준수하는 타입을 전달할수 있습니다.
    .prepend(Set(1...2))
    .sink(receiveCompletion: { _ in print("\n")},
          receiveValue: { print($0) })
    .store(in: &subscriptions)

/*:
 Output:
    1
    2
    3
    4
    5
    6
    7
 */

/*:
 서로 다른 두 publisher에서 방출하는 값들을 결합하는것 또한 가능합니다.
 */

[3, 4]
    .publisher
    .prepend([1, 2].publisher)  // Publisher Chain을 prepend 합니다.
    .sink(receiveCompletion: { _ in print("\n") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)

/*:
 Output:
    1
    2
    3
    4

 다만 prepend로 붙인 publisher chain의 이벤트가 완료된 이후에 기존 publisher에서 이벤트가 방출됩니다.
 */

[1, 2, 3]
    .publisher
    .append([4, 5])         // Array(Ordered) 추가(순서 보장)
    .append([6, 7])         // Set(UnOrdered) 추가(순서 미보장)
    .sink(receiveCompletion: { _ in print("\n")},
          receiveValue: { print($0) })
    .store(in: &subscriptions)

/*:
 ## Advanced Combining
 ---

 앞서 append, prepend에 대해 알아보았으니 보다 복잡한 연산자에 대해 알아보도록 할게요.

 ### SwitchToLatest

 이 연산자는 publisher의 subscription을 기존의 것을 취소하고  최신으로 변경해줍니다.

 여러 Publisher중 제일 최근에 이벤트를 방출한 Publisher를 구독하도록 해줘요!

 직접 예제를 살펴보면서 이해해보도록 해요!
 */

// 1: 3개의 PublisherSubject를 생성합니다.
let publisher1 = PassthroughSubject<Int, Never>()
let publisher2 = PassthroughSubject<Int, Never>()
let publisher3 = PassthroughSubject<Int, Never>()

// 2: PassthroughSubject를 방출하는 PassthroughSubject를 생성합니다.
let publishers = PassthroughSubject<PassthroughSubject<Int, Never>, Never>()

// 3: switchToLatest연산자를 적용하여 publishers에서 publisher가 방출될때 마다 최근 publisher를 구독합니다.
publishers
    .switchToLatest()
    .sink(receiveCompletion: { _ in print("publishers completed")},
          receiveValue: { print($0) })
    .store(in: &subscriptions)


publishers.send(publisher1)
publisher1.send(1)
publisher1.send(2)

publishers.send(publisher2)
publisher2.send(3)
publisher2.send(4)

publishers.send(publisher3)
publisher3.send(5)
publisher3.send(6)

// 마지막으로 구독중이던 publisher에게 완료 이벤트를 전송한 이후 publishers에도 완료 이벤트를 방출함으로써 subscriptions를 완료합니다.
//publisher3.send(completion: .finished)
publishers.send(completion: .finished)

/*:
 이 `switchToLatest` 연산자를 실제 로직에서 어떻게 응용할수 있을까요?

 기존의 publisher chain에 대한 구독을 취소하고 새로운 publisher chain을 구독해야 하는 경우는 생각보다 빈번합니다.

 예를 들어, 어떠한 네트워크 I/O를 실행하는 버튼이 있다고 가정해볼게요.
 그 버튼을 터치하면 네트워크 요청이 가게되지만 성격이 급한 유저는 결과가 오기 이전에 다시 한 번 더 버튼을 터치할수도 있곘죠?

 이럴떄, switchToLatest를 사용해서 최신의 요청에 대한 결과만 받아올 수 있습니다.
 */

let url = URL(string: "https://source.unsplash.com/random")!

// 1: 네트워크 요청 -> 이미지를 반환하는 Publisher를 반환합니다.
func getImage() -> AnyPublisher<UIImage?, Never> {
    return URLSession.shared
        .dataTaskPublisher(for: url)
        .map { data, _ in UIImage(data: data) }
        .print("get Image")
        .replaceError(with: nil)            // Failure가 Never를 준수하기 위해 Error를 처리해줍니다.
        .eraseToAnyPublisher()
}

// 2: 유저의 탭 이벤트 Chain
let didTapSubject = PassthroughSubject<Void, Never>()

// 3: 탭 이벤트가 오면 map을 통해 Publisher<AnyPublisher<UIImage?, Never>, Never> 타입으로 변환
didTapSubject
    .map { _ in getImage() }
    .switchToLatest()       // Publisher 내 Publisher이기 때문에 switchToLatest 사용이 가능해집니다.
    .sink(receiveValue: { _ in })
    .store(in: &subscriptions)

didTapSubject.send(())      // finished

// 지연 버튼 탭 재현
DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
    didTapSubject.send()        // cancel
})

DispatchQueue.main.asyncAfter(deadline: .now() + 3.1, execute: {
    didTapSubject.send()        // finished
})

/*:
 위 코드는 3번의 요청 중 2번만 정상적으로 이미지를 받아오게 됩니다.

 첫 요청 이후 두번째 요청까지 3초의 시간이 있기 때문에 첫번째 요청은 정상적으로 이미지를 받아옵니다.

 그러나 두번째 요청 후 세번째 요청까지는 0.1초의 텀만 존재하기 때문에 이미지를 다운로드 받아서 가져오기까지에는 시간이 부족하죠.

 그래서 세번째 요청이 전송되고 이 chain으로 subscription이 진행되어 해당 요청에 대한 이미지만 받아오게 됩니다.

 ### merge

 이제는 각 publisher에서 방출하는 값들을 결합하는 방법에 대해 알아보도록 할게요.

 처음으로 살펴볼 `merge`연산자는 동일한 타입의 publisher들의 값들을 교차배치 합니다.

 */

// 1: 2개의 Subject를 생성합니다.
let firstPublisher = PassthroughSubject<Int, Never>()
let secondPublisher = PassthroughSubject<Int, Never>()

// 2: first, second publisher를 merge합니다.
firstPublisher
    .merge(with: secondPublisher)
    .sink(receiveCompletion: { _ in print("Merge Completed")},
          receiveValue: { print($0) })

// 3: 각각의 publisher에게 값을 방출합니다.
secondPublisher.send(1)
firstPublisher.send(2)

secondPublisher.send(3)
firstPublisher.send(4)

// 4: 각각의 publisher에게 finished를 전달합니다.
firstPublisher.send(completion: .finished)
secondPublisher.send(completion: .finished)

/*:
 Output:
     1
     2
     3
     4
     Merge Completed

 SecondPublisher에 firstPublisher를 merge해도 결과는 당연히 동일합니다.

어떠한 Publisher Chain이 merge 되었는지는 상관없이 어떠한 Publisher에 이벤트가 언제 방출되었는지가 결과에 영향을 줍니다.



 ### CombineLatest

 `combineLatest`연산자는 merge와는 다르게 서로 다른 타입의 publisher들을 결합하는것을 가능하게 해줍니다.

 또한 값들을 교차배치하는 것을 동일하지만 하나의 publisher가 값을 방출할 때 마다 각 publisher의 최근 값들을 tuple 형태로 방출합니다.

 rx의 combineLatest와 동일하게 기존 publisher들이 적어도 하나 이상의 값을 방출해야 동작하는 연산자입니다.
 */

// 1: 두개의 publisher를 생성합니다.
let publisherFirst = PassthroughSubject<Int, Never>()
let publisherSecond = PassthroughSubject<Int, Never>()

// 2: combineLatest를 통해 각 publisher들의 마지막 방출값들을 결합합니다.
publisherFirst
    .combineLatest(publisherSecond)
    .sink(receiveCompletion: { _ in print("Completed") },
          receiveValue: { print("P1: \($0), P2: \($1)") })

publisherFirst.send(1)
publisherSecond.send(2)

publisherFirst.send(3)

publisherFirst.send(completion: .finished)
publisherSecond.send(completion: .finished)

/*:
 Output:
     P1: 1, P2: 2
     P1: 3, P2: 2
     Completed
 */

/*:
 ### zip

 `zip` 연산자는 combineLatest와 매우 유사하게 동작합니다.

 다만 같은 index의 값들을 tuple 형태로 방출합니다.

 이 말인 즉 zip으로 묶인 모든 publisher가 동일한 index에 해당하는 값을 방출했을때 동작한다는 의미입니다.

 */

let zipFirstSubject = PassthroughSubject<Int, Never>()
let zipSecondSubject = PassthroughSubject<Int, Never>()

zipFirstSubject
    .zip(zipSecondSubject)
    .sink(receiveCompletion: { _ in print("zip completed") },
          receiveValue: { print("P1: \($0.0), P2: \($0.1)") })

zipFirstSubject.send(1)
zipFirstSubject.send(2)
zipFirstSubject.send(3)
zipSecondSubject.send(4)
zipSecondSubject.send(5)
zipSecondSubject.send(6)
zipFirstSubject.send(7)

zipFirstSubject.send(completion: .finished)
zipSecondSubject.send(completion: .finished)

/*:
 Output:
     P1: 1, P2: 4
     P1: 2, P2: 5
     P1: 3, P2: 6
     Completed
 */
