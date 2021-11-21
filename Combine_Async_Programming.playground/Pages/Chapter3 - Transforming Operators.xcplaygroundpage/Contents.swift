import Foundation
import Combine
import Darwin

/*:
 ## Transforming Operators
 ---

 `Combine` 에서 publisher로 부터 오는 값에 대해서 어떠한 연산을 진행하는 메소드들을 `Oeprator` 라고 부릅니다.

 각각의 Combine Operator들은 publisher를 반환합니다.

 upstream으로 부터 값을 받아오고 -> 값을 가공하고 -> downstream으로 흘려보냅니다.

 */

/*:
 ## Collectiong Values
 ---

 앞서 공부했듯 Publisher들은 각각의 값 또는 값의 콜렉션을 방출할수 있습니다.

 이 콜렉션을 다루는 연산자들에 대해서 먼저 살펴보도록 할게요.

 ### `collect()`

 `collect` 연산자는 publisher로 부터 받은 값들을 배열로 만들어서 반환할수 있도록 합니다.

 직접 코드로 예시를 살펴보도록 할게요!

 */

var subscriptions = Set<AnyCancellable>()

//["A", "B", "C", "D", "E"].publisher
//    .sink(receiveCompletion: { print($0) },
//          receiveValue: { print($0) })
//    .store(in: &subscriptions)
(0...5).publisher
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0) })
    .store(in: &subscriptions)

/*:
 위 코드의 결과값은 아래와 같습니다.

 0
 1
 2
 3
 4
 5
 finished

 이제 위 코드에 collect 연산자를 사용해볼게요.

 */

(0...5).publisher
    .collect()
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0) })
    .store(in: &subscriptions)

/*:
 위 코드의 결과값은 아래와 같습니다.

 [0, 1, 2, 3, 4, 5]
 finished

 각각 단일로 방출되던 값들을 모아다가 1차원 배열로 반환하죠!

 위 예시에서는 0~5까지의 정수 즉 6개의 값만 사용했으나 값의 개수가 무한대일 수 있습니다.

 collect는 내부에서 이를 저장하기 위해 버퍼를 사용하기 때문에 매우 큰 element 집합을 이용할때는 메모리에 영향을 줄 수 있으니 주의해서 사용해야 합니다.

 */

/*:
 ## Mapping Values
 ---

 transoform과 관련된 연산자 collect()에 이어서 `map()` 에 대해 알아보도록 할게요.

 Combine은 매우 다양한 mapping 연산자를 제공합니다.

 ### `map(_:)`

 처음으로 배워볼 연산자는 `map(_:)` 입니다.

 이는 Swift 표준 라이브러리의 `map` 과 동일하게 동작합니다.

 예상하다시피 publisher로 부터 방출된 값을 map 클로저 내 특정 연산을 통한 결과값으로 가공하여 downstream으로 흘려보냅니다.

 실제 예시 코드를 살펴보도록 해요!

 */

(0...5).publisher
    .map { $0 * 2 }
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0) })
    .store(in: &subscriptions)

/*:
 결과값은 예상하다시피 아래와 같습니다.

 0
 2
 4
 6
 8
 10
 finished

 */

/*:
 ### tryMap(_:)

 map을 포함하는 다양한 연산자중 `try` 연산자를 포함하는 map이 존재합니다.

 이 연산자는 error를 throw 할 수 있도록 설계되었어요.

 만일 error를 throw하게 되면 downstrema에 error를 방출하게 됩니다.

 */

Just("Dir name that does not exist")
    .tryMap { try FileManager.default.contentsOfDirectory(atPath: $0) }
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0) })
    .store(in: &subscriptions)

/*:
 ## `Flatening publishers`
 ---

 ### `flatMap(maxPublishers:)`

 `flatMap` 연산자는 upstrema으로부터 오는 여러개의 publisher 체인들을 하나로 만들어 downstream으로 흘려보냅니다.

 보다 자세히 말하자면 여러개의 publisher에서 방출되는 값들을 하나의 publisher에 꾹꾹 눌러 담아서 보냅니다.

 */

func decode(_ codes: [Int]) -> AnyPublisher<String, Never> {
    Just(
        codes.compactMap { code in
            guard (32...255).contains(code) else { return nil }
            return String(UnicodeScalar(code) ?? " ")
        }
        .joined()
    )
    .eraseToAnyPublisher()
}

[72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]
    .publisher
    .collect()
    .flatMap(decode)
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

// Hello, World!

/*:
 위 예제에서는 publisher에서 방출된 array를 단일 string으로 변환했습니다.

 여기서는 와닿지는 않지만 다수의 upstream으로 부터 무한정의 value가 전달된다면 memory 이슈가 발생할수 있습니다.

 이를 위해 Combine에서는 `flatMap(maxPublishers:)` 라는 연산자를 제공하며 최대 upstream의 갯수를 제한할수 있으며 기본값은 unlimited로 설정됩니다.
 */

/*:
 ## Replacing upstream output

 Combine은 nil을 대체하여 안정성을 더해주는 연산자 또한 제공합니다.

 ### `replaceNil(with:)`

 `replaceNil(with:)` 연산자는 이름 그대로 upstrema으로 부터 온 값이 `nil` 인 경우, 파라미터로 전달한 값으로 대체하여 downstream으로 흘려보냅니다.

 */

["A", nil, "C"]
    .publisher
    .replaceNil(with: "-")
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

/*:
 Optional("A")
 Optional("-")
 Optional("C")

 다만 `replaceNil(with:)` 을 사용하면 모든 값이 optional 타입으로 반환되기 때문에 이를 unwrapping 하고자 할때는 아래와 같이 map을 응용하여 사용할수 있습니다.
 */

["A", nil, "C"]
    .publisher
    .replaceNil(with: "-")
    .map { $0! }
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)

/*:
 A
 -
 C

 replaceNil을 사용하여 nil이 없음을 보장받고 이후에 map을 통해 강제 언래핑을 진행하였습니다.

 ### `replaceEmpty(with:)`

 이번에 upstream으로 부터 잔달된 값이 없는 경우 특정값으로 처리할수 있도록 해주는 연산자 replaceEmpty에 대해 알아보도록 할게요.

 */

let empty = Empty<Int, Never>()

empty
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0) })
    .store(in: &subscriptions)

// Output: finished
// 위 코드는 upstream으로 어떠한 값도 오지 않기 때문에 completion 이벤트만 전달됩니다.

empty
    .replaceEmpty(with: 1)
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0) })
    .store(in: &subscriptions)

/*:
 Output:
    1
    finished

 replaceEmpty를 사용하면 위와 같이 upstream으로 부터 어떠한 값도 받지 않고 completion이 나는 경우 with으로 전달한 인자 값을 방출한 이후에 completion을 받게 됩니다.
 */

/*:
 ## Key Points
 ---

 - publisher로 부터 전달받은 값에 연산을 하는 연산자를 operator 라고 부릅니다.
 - Operator 또한 publisher 입니다.
 - 변환 Operater는 upstream으로 부터 받은 input을 변환하여 적절히 가공하여 downstream으로 흘러보냅니다.
 - 하나의 subscription내에서 여러개의 operator들이 chaining 되어 사용될수 있습니다.

 */
