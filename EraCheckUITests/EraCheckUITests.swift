import XCTest

final class EraCheckUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Skip the studio intro overlay in UI tests so first taps target app UI.
        app.launchArguments += ["-skipStudioIntro", "-skipInterstitialAds"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Smoke: home screen loads

    func testHomeScreenLoads() throws {
        let startButton = app.buttons["FIND YOUR ERA"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 10), "Home CTA must appear within 10 s")

        let settingsButton = app.buttons["Open settings"]
        XCTAssertTrue(settingsButton.exists, "Settings gear must be present on home")
    }

    // MARK: - Smoke: quiz flow end-to-end → reveal

    func testQuizFlowLeadsToReveal() throws {
        let startButton = app.buttons["FIND YOUR ERA"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 10))
        startButton.tap()

        // Answer all 10 questions by picking the first visible answer each time.
        for q in 1...10 {
            // Wait for the question counter to appear ("Q{q} of 10").
            let qLabel = app.staticTexts["Q\(q) of 10"]
            XCTAssertTrue(qLabel.waitForExistence(timeout: 5), "Q\(q) counter should appear")

            // Pick the first answer button (not the NEXT/SEE MY ERA CTA).
            let answerButtons = app.buttons.matching(NSPredicate(format: "label != 'NEXT' AND label != 'SEE MY ERA'"))
            let firstAnswer = answerButtons.element(boundBy: 0)
            XCTAssertTrue(firstAnswer.waitForExistence(timeout: 3), "Answer option must be present for Q\(q)")
            firstAnswer.tap()

            let cta = q < 10 ? app.buttons["NEXT"] : app.buttons["SEE MY ERA"]
            XCTAssertTrue(cta.waitForExistence(timeout: 3), "CTA button must appear for Q\(q)")
            cta.tap()
        }

        // After the last question the reveal screen shows a settings gear.
        let revealSettings = app.buttons["Open settings"]
        XCTAssertTrue(revealSettings.waitForExistence(timeout: 5), "Reveal screen settings gear must appear")
    }

    // MARK: - Smoke: settings sheet opens from home

    func testSettingsOpensFromHome() throws {
        let startButton = app.buttons["FIND YOUR ERA"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 10))

        let settingsGear = app.buttons["Open settings"]
        settingsGear.tap()

        // Settings sheet must appear; it contains a "Remove Ads" entry or similar.
        // We just verify something from settings is visible within 5 s.
        let settingsSheet = app.otherElements["settings-sheet"].firstMatch
        // Fallback: any navigation title or close button signals the sheet opened.
        let sheetVisible = settingsSheet.waitForExistence(timeout: 5)
            || app.buttons["Close"].waitForExistence(timeout: 5)
            || app.staticTexts["Settings"].waitForExistence(timeout: 5)
            || app.staticTexts["Remove Ads"].waitForExistence(timeout: 5)
        XCTAssertTrue(sheetVisible, "Settings sheet must open from home gear tap")
    }

    // MARK: - Remove Ads CTA visible when not purchased

    func testRemoveAdsCTAVisible() throws {
        let startButton = app.buttons["FIND YOUR ERA"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 10))

        // In a fresh sandbox build the IAP is not purchased; the CTA must exist.
        let removeAdsButton = app.buttons["Remove Ads"]
        // This may appear below the fold on small devices — just check existence, not hittable.
        XCTAssertTrue(
            removeAdsButton.waitForExistence(timeout: 5),
            "Remove Ads CTA must appear on home when IAP not purchased"
        )
    }
}
