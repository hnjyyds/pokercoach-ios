import SwiftUI
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .portrait

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        Self.orientationLock
    }
}

enum AppOrientationController {
    static func lock(_ orientation: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = orientation

        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) else {
                return
            }

            scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()

            if #available(iOS 16.0, *) {
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation)) { error in
                    print("Orientation request failed: \(error.localizedDescription)")
                }
            } else {
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }
}

@main
struct PokerCoachApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
    }
}
