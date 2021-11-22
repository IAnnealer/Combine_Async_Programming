import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

/*:
 ## Chapter4: Filtering Operators
 ---

 앞서 Transforming Operators를 공부하면서 느끼셨겠지만 연산자는 Combine의 publisher로 부터 오는 시퀀스를 가공하는 역할입니다.

 이번 챕터에서는 upstream으로 부터 오는 데이터를 필터링 하는 FIltering Operators들에 대해서 알아보도록 할게요.

 ### Filtering basics

 필터링 연산자 또한 다른 연산자들과 마찬가지로 예제 코드를 보면 설명도 필요없이 바로 이해가 가능할 정도로 매우 직관적이에요!
 */

let numbers = (1...10)
    .publisher

numbers
    .filter { $0.isMultiple(of: 3) }
    .sink { value in
        print("\(value) is multiple of 3!")
    }
    .store(in: &subscriptions)

/*:
 1~10 까지의 정수를 순차적으로 방출하는 publisher를 생성하고 이를 구독했어요.

 구독을 진행하되 filter 연산자를 통해 value가 3의 배수인 경우만 downstream으로 흐르도록 필터를 진행했습니다.

 이번에는 중복을 제거해주는 필터 연산자를 사용해볼게요.
 */

let words = "hey hey there! want to listen to mister mister ?"
    .components(separatedBy: " ")
    .publisher

words
    .removeDuplicates()
    .sink(receiveValue: { print($0, terminator: " ") })
    .store(in: &subscriptions)

// Output: hey there! want to listen to mister ?

/*:
 `removeDuplicates()` 연산자를 통해 중복 제거 필터링을 거친 값만 downstream으로 흐르도록 해주었어요.

 별도의 설명이 없이도 이해가 잘 되는 코드입니다!

### Compacting and ignoring

`Combine` 을 사용하다보면 빈번하게 `Optional` 값을 다루어야 하는 경우를 맞닥뜨리게 됩니다.

Swift Standard Library 내부에 존재하는 `compactMap`을 연산자로 사용하는 방법에 대해 살펴보도록 할게요.
 */

let strings = ["a", "1.24", "3", "def", "45", "0.23"]
    .publisher

strings
    .compactMap { Float($0) }
    .sink { print($0) }
    .store(in: &subscriptions)

/*:
 Output:
     3.0
     45.0
     0.23

 유한한 문자열 배열 타입의 publisher를 생성했습니다.

 `compactMap` 을 통해 Float 타입으로 캐스팅을 진행하면서 실패한 경우는 nil이 반환되겠죠?

 `compactMap` nil이 제거되기 때문에 정상적으로 Float 타입으로 캐스팅이 정상적으로 진행된 값만 downstream으로 흘러 내려가게 됩니다.

 이번엔 `ignoreOutput` 이라는 연산자에 대해 알아보도록 할게요!

 이 연산자 또한 별도 설명이 없을 정도로 네이밍이 직관적입니다.

 */

let numbers2 = (1...10000).publisher

numbers2
    .ignoreOutput()
    .sink(receiveCompletion: { print("Completed with: \($0)") },
          receiveValue: { print($0 ) })
    .store(in: &subscriptions)

// Output: Completed with: finished

/*:
 `ignoreOutput()` 연산자 이름 그대로 Output을 무시하고 complete event만 전달됩니다.
 */

/*:
 ### Finding values

 이번에는 Swift standard library에도 내장되어있는 `first(where:)`, `last(where:)`

 함수에 이름 내포되어있듯 upstrem으로 부터 오는 값 중 첫번째, 마지막 값 만 방출되도록 합니다.

 */

(1...9)
    .publisher
    .first(where: { $0 % 2 == 0 })
    .sink(receiveCompletion: { print("Completed with: \($0)") },
          receiveValue: { print($0) })
    .store(in: &subscriptions)

/*:
 Output:
     2
     Completed with: finished
 */

(1...9)
    .publisher
    .last(where: { $0 % 2 == 0 })
    .sink(receiveCompletion: { print("completed with: \($0)") },
          receiveValue: { print($0 )})

/*:
 Output:
     8
     completed with: finished
 */

/*:
 1~9까지의 정수를 방출하는 upstream에서 2로 나뉘어지는 값 중 첫번째, 마지막 값만 downstream 으로 흘려보냅니다.
 */

