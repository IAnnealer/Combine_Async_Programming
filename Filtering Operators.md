# Filtering Operators

<br>

### Filter
---

```swift
let numbers = (1...10).publisher

numbers.filter { $0 % 2 == 0 }
.sink(receiveValue: {
    print($0)
})
```

filter 연산자는 이름 그대로 필터링을 진행합니다.

numbers 라는 1~10 까지의 정수를 갖는 Publisher를 생성한 이후 해당 Publisher에 filter를 적용합니다.

filter의 closure에는 publisher의 output이 인자로 전달되고 이를 통해 filter 조건을 생성합니다.

filter의 조건이 참인 경우 downstream으로 내려가 sink 내부에서 print를 진행하게 됩니다.

따라서 위 코드의 결과는 2, 4, 6, 8, 10 이 됩니다.

<br>

### RemoveDuplicates
---

```swift
let words = "apple apple fruit apple mango watermelon apple".components(separatedBy: " ").publisher

words
    .removeDuplicates()
    .sink(receiveValue: {
        print($0)
    })
```

removeDuplicates 연산자는 이름에서 알 수 있듯 중복을 제거한 결과를 반환합니다.

하지만 모든 원소들에 대하여 중복 여부를 확인하지는 않습니다.

![image](https://user-images.githubusercontent.com/33051018/146187048-03e371f9-7df0-4d5d-a7b4-faa5f1980c90.png)

해당 연산자를 타고 들어가보니 Output이 `Equatable` 프로토콜을 채택하고 있는 경우에 대한 extension으로 removeDuplicates가 제공되고 있습니다.

`Equatable` 프로토콜을 채택하여 `==` 연산을 통해 값을 비교를 진행하는데 비교의 대상은 Upstream으로 부터 받아왔던 previous 값과 비교를 진행합니다.

따라서 현재 차례 이전의 원소와 동일 여부를 비교하고 동일하지 않는 경우 Downstream으로 흘려보냅니다.

위 예시에서는 words 라는 [String] 타입의 Publisher를 생성한 이후 해당 chain에 removeDuplicates 연산자를 체이닝하고 그 결과를 sink 하였습니다.

결과는 예상대로 "apple fruit apple mango watermelon apple" 이 순차적으로 찍힙니다.

<br>

### CompactMap
---

```swift
let stringArray = ["a", "1.24", "b", "3.45", "6.7"].publisher
    .compactMap { Float($0) }
    .sink {
        print($0)
    }
```

일반적으로 Swift에서 사용하는 CompactMap 연산자는 nil을 제거한 결과를 반환하는 용도로 사용됩니다.

Combine에도 해당 개념이 동일하게 적용되었습니다.

stringsArray라는 Publisher로 부터 compactMap을 연산합니다.

compactMap 내부에서는 Float 타입으로의 캐스팅을 시도하며 해당 결과가 nil이 아닌 경우 즉, 캐스팅에 성공한 경우에만 Downstream으로 흘러가게 됩니다.

따라서 결과는 "1.24, 3.45, 6.7"이 순차적으로 찍힙니다.

<br>

### IgnoreOutput
---

```swift
let numbers = (1...5000).publisher
    .ignoreOutput()
    .sink(receiveCompletion: {
        print($0)
    }, receiveValue: {
        print($0)
    })
```

1~5000 범위의 정수를 갖는 Publisher에 ignoreOutput 연산자를 체이닝하게 되면 이름 그대로 모든 Output이 무시됩니다.

다만 Sequence의 흐름이 종료되었는지에 대한 Completion은 전달이 되므로 위 예시 코드의 결과는 "finished"가 찍히게 됩니다.