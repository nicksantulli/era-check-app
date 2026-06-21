import UIKit
import AppTrackingTransparency

// MARK: - AdMob scaffold (Owner-gated — inert until the SDK + real IDs land)
//
// Era Check is free but shows one interstitial after the quiz. This file is
// the ready-to-activate AdMob scaffold, mirroring Powell Prowl's `AdManager`
// so the test-device + Ad-Inspector safety rig is already in place the
// moment the Owner provides Era Check's App ID + interstitial unit.
//
// The whole implementation is gated on `#if canImport(GoogleMobileAds)`, so:
//   • TODAY  — the GMA SPM package is NOT linked → this compiles to nothing,
//              the app stays ad-free, and the build stays green.
//   • LATER  — the Owner adds the GMA package + real IDs → the scaffold
//              activates with the SAME invalid-traffic protections Powell
//              Prowl already uses (DEBUG/TestFlight always get TEST ads).
//
// Activation checklist (Owner-gated — see vault/engineering/admob-test-devices.md):
//   1. Add the GoogleMobileAds SPM package to the Era Check target.
//   2. Set GADApplicationIdentifier in Info.plist to Era Check's real app id.
//   3. Replace the placeholder release unit id below with the real one.
//   4. Call `AdManager.shared.start()` at app launch and wire
//      `EraCheckModel.maybeShowInterstitial()` to `AdManager.shared.present...`.

// MARK: - AdRegion (DUD-224 — EEA/UK ad geo-restriction)
//
// Owner decision (Jun 14): do NOT serve ads to EEA/UK users. Suppressing ad
// requests in those regions sidesteps GDPR / Google UMP consent entirely — no
// consent form, no UMP SDK call. No App Tracking Transparency prompt — ads are
// requested non-personalized (npa=1) everywhere ads are shown. The check uses
// and fails CLOSED: an unknown region is treated as restricted (no ads).
enum AdRegion {
    /// EEA member states + the United Kingdom.
    static let restrictedRegionCodes: Set<String> = [
        // EU 27
        "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR",
        "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK",
        "SI", "ES", "SE",
        // EEA (non-EU)
        "IS", "LI", "NO",
        // United Kingdom
        "GB",
    ]

    /// True when ads must be suppressed: the device region is in the EEA/UK, or
    /// it can't be determined (fail closed).
    static var isAdRestricted: Bool {
        let code: String?
        if #available(iOS 16, *) {
            code = Locale.current.region?.identifier
        } else {
            code = Locale.current.regionCode
        }
        guard let code, !code.isEmpty else { return true }
        return restrictedRegionCodes.contains(code.uppercased())
    }
}

#if canImport(GoogleMobileAds)
import GoogleMobileAds

/// Loads + presents AdMob interstitials for Vibe Rater's reveal cadence
/// (never on the first rate; every 2nd reveal after — see AppModel). Mirrors
/// Powell Prowl's AdManager, including the DEBUG test-device safety rig.
@MainActor
final class AdManager: NSObject {
    static let shared = AdManager()

    /// DEBUG uses Google's public TEST interstitial unit (safe — never
    /// bills/credits anyone). The Release id is Owner-provided and swapped in
    /// before the App Store build.
    private var adUnitID: String {
        #if DEBUG
        "ca-app-pub-3940256099942544/4411468910"   // Google's public test unit
        #else
        "ca-app-pub-9950526548980224/4339271654"    // ← Owner provides real unit
        #endif
    }

    private var interstitial: InterstitialAd?
    private var isLoading = false
    private var isPresenting = false

    /// Physical device hashes that must ALWAYS receive Google TEST ads —
    /// never live ones (invalid-traffic protection; the top AdMob
    /// account-suspension risk). Registered UNCONDITIONALLY (not #if DEBUG)
    /// so it also covers TestFlight (a RELEASE config that uses the real ad
    /// unit) AND the Owner's own production install. Registering a test
    /// device has ZERO effect on real users — it only forces test ads on
    /// THAT one device. The iOS Simulator is auto-registered by the GMA SDK
    /// and does NOT need to be listed here.
    ///
    /// The hash is per-DEVICE, not per-app, so the Owner's iPhone hash is the
    /// same one Powell Prowl uses. Full steps + how to capture a new device's
    /// hash: vault/engineering/admob-test-devices.md.
    static let testDeviceIdentifiers = [
        "ef5558e3631904432fb53d8a5955da9d",   // Owner iPhone
    ]

    /// Call once at app launch (after the Owner activates ads).
    func start() {
        // DUD-224: never serve ads in the EEA/UK (Owner decision) — bail before
        // the SDK starts or any ad is requested, which sidesteps GDPR/UMP.
        guard !AdRegion.isAdRestricted else {
            #if DEBUG
            NSLog("[AdManager] EEA/UK region — ads disabled")
            #endif
            return
        }
        requestTrackingAuthorization()
        // Register known internal devices as test devices BEFORE the SDK
        // starts or makes its first ad request. Unconditional on purpose —
        // covers DEBUG, TestFlight, and the Owner's production build.
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = Self.testDeviceIdentifiers
        MobileAds.shared.start { _ in
            Task { @MainActor in AdManager.shared.loadAd() }
        }
    }

    private func nonPersonalizedRequest() -> Request {
        let request = Request()
        let extras = Extras()
        extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        return request
    }

    private func requestTrackingAuthorization() {
        guard #available(iOS 14, *) else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        ATTrackingManager.requestTrackingAuthorization { _ in }
    }

    private func loadAd() {
        guard interstitial == nil, !isLoading else { return }
        isLoading = true
        InterstitialAd.load(with: adUnitID, request: nonPersonalizedRequest()) { [weak self] ad, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                self.interstitial = ad
                #if DEBUG
                NSLog("[AdManager] interstitial %@", ad == nil
                      ? "load failed: \(error?.localizedDescription ?? "unknown")" : "loaded")
                #endif
            }
        }
    }

    /// Present the loaded interstitial (no-op if none is ready — Vibe Rater
    /// never blocks the reveal on an ad).
    func presentInterstitial() async {
        // Remove Ads (DUD-219): paying users never see interstitials.
        guard !PurchaseManager.shared.isProUnlocked else { return }
        // DUD-224: no ads in the EEA/UK.
        guard !AdRegion.isAdRestricted else { return }
        guard !isPresenting else { return }
        isPresenting = true
        defer { isPresenting = false }
        // Non-personalized ads (Owner decision): we do NOT request App Tracking
        // Transparency, so AdMob serves non-personalized ads to everyone and the
        // privacy manifest can honestly declare no tracking.
        guard let ad = interstitial else { loadAd(); return }
        interstitial = nil
        ad.present(from: nil)   // nil = SDK presents from the key window's root VC
        loadAd()                // preload the next slot
    }

    #if DEBUG
    /// Present the AdMob Ad Inspector (DEBUG builds only) to inspect ad
    /// requests, mediation, latency, and fill. Wire to a debug-only entry once
    /// Vibe Rater has a settings/debug surface. Compiled out of RELEASE.
    func presentAdInspector() {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .windows.first(where: { $0.isKeyWindow })?.rootViewController
        MobileAds.shared.presentAdInspector(from: root) { error in
            if let error {
                NSLog("[AdManager] ad inspector error: %@", error.localizedDescription)
            }
        }
    }
    #endif
}
#endif
