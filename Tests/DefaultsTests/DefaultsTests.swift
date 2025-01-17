import Foundation
import XCTest
import Defaults
import CoreData

let fixtureURL = URL(string: "https://sindresorhus.com")!
let fixtureURL2 = URL(string: "https://example.com")!

enum FixtureEnum: String, Codable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

let fixtureDate = Date()

@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
final class ExamplePersistentHistory: NSPersistentHistoryToken {

	let value: String

	init(value: String) {
		self.value = value
		super.init()
	}

	required init?(coder: NSCoder) {
		self.value = coder.decodeObject(forKey: "value") as! String
		super.init()
	}

	override func encode(with coder: NSCoder) {
		coder.encode(value, forKey: "value")
	}

	override class var supportsSecureCoding: Bool {
		return true
	}
}

extension Defaults.Keys {
	static let key = Key<Bool>("key", default: false)
	static let url = Key<URL>("url", default: fixtureURL)
	static let `enum` = Key<FixtureEnum>("enum", default: .oneHour)
	static let data = Key<Data>("data", default: Data([]))
	static let date = Key<Date>("date", default: fixtureDate)

	// NSSecureCoding
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
	static let persistentHistoryValue = ExamplePersistentHistory(value: "ExampleToken")
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
	static let persistentHistory = NSSecureCodingKey<ExamplePersistentHistory>("persistentHistory", default: persistentHistoryValue)
}

final class DefaultsTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.setUp()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<Bool>("independentKey", default: false)
		XCTAssertFalse(Defaults[key])
		Defaults[key] = true
		XCTAssertTrue(Defaults[key])
	}

	func testOptionalKey() {
		let key = Defaults.OptionalKey<Bool>("independentOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = true
		XCTAssertTrue(Defaults[key]!)
		Defaults[key] = nil
		XCTAssertNil(Defaults[key])
		Defaults[key] = false
		XCTAssertFalse(Defaults[key]!)
	}

	func testKeyRegistersDefault() {
		let keyName = "registersDefault"
		XCTAssertEqual(UserDefaults.standard.bool(forKey: keyName), false)
		_ = Defaults.Key<Bool>(keyName, default: true)
		XCTAssertEqual(UserDefaults.standard.bool(forKey: keyName), true)

		// Test that it works with multiple keys with `Defaults`.
		let keyName2 = "registersDefault2"
		_ = Defaults.Key<String>(keyName2, default: keyName2)
		XCTAssertEqual(UserDefaults.standard.string(forKey: keyName2), keyName2)
	}

	func testKeyWithUserDefaultSubscript() {
		let key = Defaults.Key<Bool>("keyWithUserDeaultSubscript", default: false)
		XCTAssertFalse(UserDefaults.standard[key])
		UserDefaults.standard[key] = true
		XCTAssertTrue(UserDefaults.standard[key])
	}

	func testKeys() {
		XCTAssertFalse(Defaults[.key])
		Defaults[.key] = true
		XCTAssertTrue(Defaults[.key])
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
	func testNSSecureCodingKeys() {
		XCTAssertEqual(Defaults.Keys.persistentHistoryValue.value, Defaults[.persistentHistory].value)
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		Defaults[.persistentHistory] = newPersistentHistory
		XCTAssertEqual(newPersistentHistory.value, Defaults[.persistentHistory].value)
	}

	func testUrlType() {
		XCTAssertEqual(Defaults[.url], fixtureURL)

		let newUrl = URL(string: "https://twitter.com")!
		Defaults[.url] = newUrl
		XCTAssertEqual(Defaults[.url], newUrl)
	}

	func testEnumType() {
		XCTAssertEqual(Defaults[.enum], FixtureEnum.oneHour)
	}

	func testDataType() {
		XCTAssertEqual(Defaults[.data], Data([]))

		let newData = Data([0xFF])
		Defaults[.data] = newData
		XCTAssertEqual(Defaults[.data], newData)
	}

	func testDateType() {
		XCTAssertEqual(Defaults[.date], fixtureDate)

		let newDate = Date()
		Defaults[.date] = newDate
		XCTAssertEqual(Defaults[.date], newDate)
	}

	func testRemoveAll() {
		let key = Defaults.Key<Bool>("removeAll", default: false)
		let key2 = Defaults.Key<Bool>("removeAll2", default: false)
		Defaults[key] = true
		Defaults[key2] = true
		XCTAssertTrue(Defaults[key])
		XCTAssertTrue(Defaults[key2])
		Defaults.removeAll()
		XCTAssertFalse(Defaults[key])
		XCTAssertFalse(Defaults[key2])
	}

	func testCustomSuite() {
		let customSuite = UserDefaults(suiteName: "com.sindresorhus.customSuite")!
		let key = Defaults.Key<Bool>("customSuite", default: false, suite: customSuite)
		XCTAssertFalse(customSuite[key])
		XCTAssertFalse(Defaults[key])
		Defaults[key] = true
		XCTAssertTrue(customSuite[key])
		XCTAssertTrue(Defaults[key])
		Defaults.removeAll(suite: customSuite)
	}

	func testObserveKey() {
		let key = Defaults.Key<Bool>("observeKey", default: false)
		let expect = expectation(description: "Observation closure being called")

		var observation: DefaultsObservation!
		observation = Defaults.observe(key, options: [.old, .new]) { change in
			XCTAssertFalse(change.oldValue)
			XCTAssertTrue(change.newValue)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = true

		waitForExpectations(timeout: 10)
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
	func testObserveNSSecureCodingKey() {
		let key = Defaults.NSSecureCodingKey<ExamplePersistentHistory>("observeNSSecureCodingKey", default: ExamplePersistentHistory(value: "TestValue"))
		let expect = expectation(description: "Observation closure being called")

		var observation: DefaultsObservation!
		observation = Defaults.observe(key, options: [.old, .new]) { change in
			XCTAssertEqual(change.oldValue.value, "TestValue")
			XCTAssertEqual(change.newValue.value, "NewTestValue")
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = ExamplePersistentHistory(value: "NewTestValue")

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.OptionalKey<Bool>("observeOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: DefaultsObservation!
		observation = Defaults.observe(key, options: [.old, .new]) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertTrue(change.newValue!)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = true

		waitForExpectations(timeout: 10)
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
	func testObserveNSSecureCodingOptionalKey() {
		let key = Defaults.NSSecureCodingOptionalKey<ExamplePersistentHistory>("observeNSSecureCodingOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: DefaultsObservation!
		observation = Defaults.observe(key, options: [.old, .new]) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertEqual(change.newValue?.value, "NewOptionalValue")
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = ExamplePersistentHistory(value: "NewOptionalValue")

		waitForExpectations(timeout: 10)
	}

	func testObserveKeyURL() {
		let fixtureURL = URL(string: "https://sindresorhus.com")!
		let fixtureURL2 = URL(string: "https://example.com")!
		let key = Defaults.Key<URL>("observeKeyURL", default: fixtureURL)
		let expect = expectation(description: "Observation closure being called")

		var observation: DefaultsObservation!
		observation = Defaults.observe(key, options: [.old, .new]) { change in
			XCTAssertEqual(change.oldValue, fixtureURL)
			XCTAssertEqual(change.newValue, fixtureURL2)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = fixtureURL2

		waitForExpectations(timeout: 10)
	}

	func testObserveKeyEnum() {
		let key = Defaults.Key<FixtureEnum>("observeKeyEnum", default: .oneHour)
		let expect = expectation(description: "Observation closure being called")

		var observation: DefaultsObservation!
		observation = Defaults.observe(key, options: [.old, .new]) { change in
			XCTAssertEqual(change.oldValue, .oneHour)
			XCTAssertEqual(change.newValue, .tenMinutes)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = .tenMinutes

		waitForExpectations(timeout: 10)
	}
	
	func testResetKey() {
		let defaultString1 = "foo1"
		let defaultString2 = "foo2"
		let defaultString3 = "foo3"
		let newString1 = "bar1"
		let newString2 = "bar2"
		let newString3 = "bar3"
		let key1 = Defaults.Key<String>("key1", default: defaultString1)
		let key2 = Defaults.Key<String>("key2", default: defaultString2)
		Defaults[key1] = newString1
		Defaults[key2] = newString2
		Defaults.reset(key1)
		XCTAssertEqual(Defaults[key1], defaultString1)
		XCTAssertEqual(Defaults[key2], newString2)

		if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
			let key3 = Defaults.NSSecureCodingKey<ExamplePersistentHistory>("key3", default: ExamplePersistentHistory(value: defaultString3))
			Defaults[key3] = ExamplePersistentHistory(value: newString3)
			Defaults.reset(key3)

			XCTAssertEqual(Defaults[key3].value, defaultString3)
		}
	}
	
	func testResetKeyArray() {
		let defaultString1 = "foo1"
		let defaultString2 = "foo2"
		let defaultString3 = "foo3"
		let newString1 = "bar1"
		let newString2 = "bar2"
		let newString3 = "bar3"
		let key1 = Defaults.Key<String>("akey1", default: defaultString1)
		let key2 = Defaults.Key<String>("akey2", default: defaultString2)
		let key3 = Defaults.Key<String>("akey3", default: defaultString3)
		Defaults[key1] = newString1
		Defaults[key2] = newString2
		Defaults[key3] = newString3
		Defaults.reset(key1, key2)
		XCTAssertEqual(Defaults[key1], defaultString1)
		XCTAssertEqual(Defaults[key2], defaultString2)
		XCTAssertEqual(Defaults[key3], newString3)
	}
	
	func testResetOptionalKey() {
		let newString1 = "bar1"
		let newString2 = "bar2"
		let newString3 = "bar3"
		let key1 = Defaults.OptionalKey<String>("optionalKey1")
		let key2 = Defaults.OptionalKey<String>("optionalKey2")
		Defaults[key1] = newString1
		Defaults[key2] = newString2
		Defaults.reset(key1)
		XCTAssertEqual(Defaults[key1], nil)
		XCTAssertEqual(Defaults[key2], newString2)

		if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
			let key3 = Defaults.NSSecureCodingOptionalKey<ExamplePersistentHistory>("optionalKey3")
			Defaults[key3] = ExamplePersistentHistory(value: newString3)
			Defaults.reset(key3)
			XCTAssertEqual(Defaults[key3], nil)
		}
	}
	
	func testResetOptionalKeyArray() {
		let newString1 = "bar1"
		let newString2 = "bar2"
		let newString3 = "bar3"
		let key1 = Defaults.OptionalKey<String>("aoptionalKey1")
		let key2 = Defaults.OptionalKey<String>("aoptionalKey2")
		let key3 = Defaults.OptionalKey<String>("aoptionalKey3")
		Defaults[key1] = newString1
		Defaults[key2] = newString2
		Defaults[key3] = newString3
		Defaults.reset(key1, key2)
		XCTAssertEqual(Defaults[key1], nil)
		XCTAssertEqual(Defaults[key2], nil)
		XCTAssertEqual(Defaults[key3], newString3)
	}
}
