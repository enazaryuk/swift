// RUN: %target-run-simple-swift(-Xfrontend -enable-experimental-concurrency -parse-as-library) | %FileCheck %s --dump-input=always
// REQUIRES: executable_test
// REQUIRES: concurrency

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

func test_skipCallingNext() async {
  let numbers = [1, 1]

  let result = try! await Task.withGroup(resultType: Int.self) { (group) async -> Int in
    for n in numbers {
      print("group.add { \(n) }")
      await group.add { () async -> Int in
        usleep(1000 * 1)
        let c = await Task.__unsafeCurrentAsync().isCancelled
        print("  inside group.add { \(n) } (canceled: \(c))")
        return n
      }
    }

    // return immediately; the group should wait on the tasks anyway
    let c = await Task.__unsafeCurrentAsync().isCancelled
    print("return immediately 0 (canceled: \(c))")
    return 0
  }

  // CHECK: group.add { 1 }
  // CHECK: group.add { 1 }
  // CHECK: return immediately 0 (canceled: false)

  // CHECK: inside group.add { 1 } (canceled: false)
  // CHECK: inside group.add { 1 } (canceled: false)

  // CHECK: result: 0
  print("result: \(result)")
  assert(result == 0)
}

@main struct Main {
  static func main() async {
    await test_skipCallingNext()
  }
}

