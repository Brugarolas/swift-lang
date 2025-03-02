// RUN: %target-typecheck-verify-swift -disable-availability-checking -enable-experimental-feature GroupActorErrors
// REQUIRES: concurrency

@MainActor
protocol P {
  func f()
  nonisolated func g()
}

struct S_P: P {
  func f() { }
  func g() { }
}

// expected-error@+2{{calls to '@MainActor'-isolated' code in global function 'testP(x:p:)'}}
// expected-note@+1{{add '@MainActor' to make global function 'testP(x:p:)' part of global actor 'MainActor'}}
func testP(x: S_P, p: P) {
  p.f() // expected-note{{call to main actor-isolated instance method 'f()' in a synchronous nonisolated context}}
  p.f() // expected-note{{call to main actor-isolated instance method 'f()' in a synchronous nonisolated context}}
  p.f() // expected-note{{call to main actor-isolated instance method 'f()' in a synchronous nonisolated context}}
  p.g() // OKAY
  x.f() // expected-note{{call to main actor-isolated instance method 'f()' in a synchronous nonisolated context}}
  x.f() // expected-note{{call to main actor-isolated instance method 'f()' in a synchronous nonisolated context}}
  x.f() // expected-note{{call to main actor-isolated instance method 'f()' in a synchronous nonisolated context}}
  x.g() // OKAY
}

actor SomeActor { }

@globalActor
struct SomeGlobalActor {
  static let shared = SomeActor()
}

@propertyWrapper
struct WrapperOnActor<Wrapped: Sendable> {
  private var stored: Wrapped

  nonisolated init(wrappedValue: Wrapped) {
    stored = wrappedValue
  }

  @MainActor var wrappedValue: Wrapped {
    get { }
    set { }
  }

  @SomeGlobalActor var projectedValue: Wrapped {
    get {  }
    set { }
  }
}

struct HasWrapperOnActor {
  @WrapperOnActor var x: Int = 0
  @WrapperOnActor var y: String = ""
  @WrapperOnActor var z: (Double, Double) = (1.0,2.0)

  // expected-error@+2{{calls to '@MainActor'-isolated' code in instance method 'testWrapped()'}}
  // expected-note@+1{{add '@MainActor' to make instance method 'testWrapped()' part of global actor 'MainActor'}}
  func testWrapped() {
    _ = x // expected-note{{main actor-isolated property 'x' can not be referenced from a non-isolated context}}
    _ = y // expected-note{{main actor-isolated property 'y' can not be referenced from a non-isolated context}}
    _ = z // expected-note{{main actor-isolated property 'z' can not be referenced from a non-isolated context}}
  }

  // expected-error@+2{{calls to '@SomeGlobalActor'-isolated' code in instance method 'testProjected()'}}
  // expected-note@+1{{add '@SomeGlobalActor' to make instance method 'testProjected()' part of global actor 'SomeGlobalActor'}}
  func testProjected(){
    _ = $x // expected-note{{global actor 'SomeGlobalActor'-isolated property '$x' can not be referenced from a non-isolated context}}
    _ = $y // expected-note{{global actor 'SomeGlobalActor'-isolated property '$y' can not be referenced from a non-isolated context}}
    _ = $z // expected-note{{global actor 'SomeGlobalActor'-isolated property '$z' can not be referenced from a non-isolated context}}
  }

  @MainActor
  func testMA(){ }

  // expected-error@+2{{calls to '@MainActor'-isolated' code in instance method 'testErrors()'}}
  // expected-note@+1{{add '@MainActor' to make instance method 'testErrors()' part of global actor 'MainActor'}}
  func testErrors() {
    testMA() // expected-error{{call to main actor-isolated instance method 'testMA()' in a synchronous nonisolated context}}
  }
}
