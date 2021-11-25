import Foundation
import Combine

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
