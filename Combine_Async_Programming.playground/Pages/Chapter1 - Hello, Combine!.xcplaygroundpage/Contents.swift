import UIKit
import Foundation
import Combine

/*:
 이 문서는 Combine Framework를 소개하는 것을 목표로 제작되었습니다.

 Combine framework는 잠재적인 여러 delegate 콜백 또는 completion handler을 대신하여 선언적 방식의 접근을 통해 앱의 이벤트 처리를 도와줍니다.

 주어진 이벤트 시퀀스로 부터 단일 Processing 체인을 생성하고 이에 여러가지 다양한 기능을 제공하는 Operator를 접목하여 데이터들을 가공하고 처리할수 있습니다.

 실제로 코드를 작성해보기 이전에는 다소 추상적으로 들릴수 있으나 아래 예제를 통해 직접 Combine 익혀보도록 합시다!
 */

/*:
 ## Asynchronous Programming
 ---

 단일 스레드를 사용하는 언어에서는 한 줄 한 줄 순차적으로 코드가 실행됩니다.

 마치 아래의 의사코드 처럼요.

 ```
 begin
 var name = "Tom"
 print(name)
 name += " Harding"
 print(name)
 end
 ```

 위와 같은 코드의 결과값은 "Tom"이 프린트 된 이후에 "Tom Harding"이 프린트되겠죠?

 Sync 방식의 코드는 상대적으로 이해하기도 수월하며 데이터의 상태 또한 유추하기 쉽습니다.

 자 이제 멀티스레드를 제공하는 언어로 구현된 프로그램에서 비동기적으로 이벤트 기반의 UI를 그리는 환경을 생각해보겠습니다.

 ```
 --- Thread 1 ---
 begin
 var name = "Tom"
 print(name)

 --- Thread 2 ---
 name = "Billy Bob"

 --- Thread 3 ---
 name += "Harding"
 print(name)
 end
 ```

 위 예시 또한 앞서 살펴봤던 예시와 같이 `name` 이라는 변수에 "Tom"이라는 문자열을 대입하고 그 이후에 "Harding" 이라는 문자열을 대입합니다.

 하지만 Thread1 과 Thread3 실행 사이에 Thread2가 동작하게 된다면 `name` 이라는 변수는 "Billy Bob" 으로 초기화됩니다.

 이 코드의 결과는 시스템 로드에 의존함으로 매 실행에 따라 서로 다른 결과를 보여주게 될 것 입니다.

 비동기 코드를 실행하면 앱에서 가변한 상태를 관리하는 작업이 됩니다.

 */

/*:
 ## Foundation and UIKit/AppKit
 ---

 Apple은 async한 프로그래밍이 가능하도록 여러 기능들을 서로 다른 시스템 레벨에서 제공합니다.

 간단한 예시로 아래와 같은 것들이 있죠.

 - `NotificationCenter`: 이벤트를 수신하게 되면 언제든 특정 코드를 실행할수 있도록 합니다. 예를 들면 핸드폰 orientation 변경에 따른 화면 변경 또는 키보드 show/hide 제어 등이 있습니다.
 - `Grand Central Dispatch and Operations`:  코드를 스케줄링하여 작업이 가능하도록 도와줍니다. 예를 들어 Serial Queue에 넣어 순차적으로 실행하도록 하거나 다른 우선순위를 갖는 작업들을 다른 Queue에 넣어 동시다발적으로 실행되는것 처럼 작업 또한 가능하죠.
 - `Closures`:  코드를 분리하여 다른 스코프로 전달합니다. 이를 전달받은 다른 객체들은 해당 코드를 실행할지 말지, 얼마나 실행할지, 어느 흐름에 실행할지 또한 제어가 가능합니다.

 스위프트 생태계에 Combine을 도입하여 다양한 비동기 프로그래밍 방법 속에서 질서를 가져올 수 있도록 돕는 것을 목표로 고안되었습니다.


 ## Publishers
 ---

 Combine의 핵심 3가지는 `Publisher`, `Operator`, `Subscriber` 입니다.

 이번 챕터에서는 Publisher에 대하여 알아보도록 하겠습니다.

 Publisher란 값을 방출할수 있는 타입을 의미합니다.

 Publisher는 0개 혹은 n개의 값을 방출할수 있으며 이벤트 방출 작업이 성공적으로 끝나거나 중도 실패 이후에는 어떠한 이벤트도 방출하지 않습니다.

 아래 예시는 Publisher가 어떻게 Int 타입의 값을 방출하는지를 시간의 흐름에 따라 시각화한 이미지입니다.

 ![Publisher_emit_example](Publisher_emit_example.png)

 시간에 흐름에 따라 순차적으로 특정 정수값들이 방출됩니다.

 그리고 타임라인의 최우측에는 | 바가 있으며 이는 성공적으로 시퀀스가 완료되었음을 의미합니다.

 Publisher의 핵심 기능중 한가지는 내부에 에러를 핸들링하는 기능을 가지고 있다는 것 입니다.

 주어진 Publisher를 구독하여 이벤트를 받아보게 되면 해당 시퀀스로부터 어떠한 이벤트가 도착할지 상황에 따라 예측이 가능하며 또한 에러 상황에 대한 경우도 처리가 가능합니다.

 ## Operators
 ---

 Operator는 메소드를 의미합니다.

 Publisher 프로토콜 내에 선언되어 있으며 이를 통해 기존 Publisher와 동일하거나 다른 새로운 Publisher를 생성할수 있습니다.

 Combine 내에는 매우 다양한 Operator가 제공되며 이를 Chaning하여 시퀀스로 부터 방출된 데이터를 가공하여 사용합니다.

 이를 통해 단일의 구독에서 매우 복잡한 연산 로직들을 보다 수월하게 해결하며 가독성 또한 챙길수 있죠.

 */

/*:
 ## Subscribers
 ---

 ![Subscriber_example](Subscriber_example.png)

 모든 구독은 Subscriber를 통해 완성됩니다.

 Subscriber는 방출된 Output 혹은 성공적을 완료된 이벤트들을 기반으로 무언가를 진행합니다.

 Combine 내에는 2가지 Subscriber를 제공합니다.

 - sink: 수신한 Output 결과값과 Completion Closure를 제공 합니다. RxSwift의 `.subscribe` 와 동일합니다.
 - assign: 수신한 Output을 데이터 모델 혹은 UI에 즉각 bind 합니다. RxSwift의 `.bind` 와 동일합니다.

 ## Subscription
 ---

 이 문서에서는 Combine의 `subscription` 프로토콜과 이를 채택하는 객체들을 설명하기 위한 용어로 `subscription` 이라는 단어를 사용합니다.

 `subscription`에 구독을 진행하게 되면 이는 `publisher` 체인을 활성화 합니다.

 즉, `publisher`는 결과값을 받는 구독자가 없다면 이벤트를 방출할수 없습니다.

 또한, 우리는 구독 행위에 대한 메모리 관리를 위해 `Cancellable` 이라는 프로토콜을 사용합니다.

 `Cancellable` 프로토콜을 준수하는 구독자는 `Cancellable` 객체를 반환하게 됩니다.

 해당 객체를 해제하게 되면 해당 시퀀스에 대한 구독이 취소됩니다.

 이를 보다 더욱 편리하게 사용학 위해 `[AnyCancellable]` 타입의 콜렉션 프로퍼티를 소유하고 해당 프로퍼티 내에 모든 구독 모델들을 추가할수 있습니다.

 이를 release함으로써  해당 콜렉션 내에 들어가있는 `Cancellable` 프로토콜을 준수하는 객체들에 대한 구독을 해제하고 메모리를 해제할수 있습니다. (RxSwift의 `disposeBag` 과 동일한 기능을 제공하는 클래스입니다.


 ## Key Points
 ---

 - `Combine`은 비동기 이벤트 처리를 선언형 & 반응형으로 풀어내도록 돕는 프레임워크입니다.
 - 이는 기존의 비동기를 위해 사용되던 다양한 기술들을 통합하기 위해 고안되었으며 변하는 상태값을 다루며 에러 핸들링이 가능합니다.
 - `Combine`의 핵심 3가지는 아래와 같습니다.
    - Publisher(Observable): 이벤트를 방출합니다.
    - Operator: Upstream으로 부터 전달되어 오는 이벤트를 비동기로 처리하고 조작합니다.
    - Subscriber(Observer): publisher chain으로부터 시작되어 operator를 통해 연산되어 오는 시퀀스를 구독하여 이벤트를 받습니다.

 */

