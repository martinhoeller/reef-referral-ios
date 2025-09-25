import Foundation
import Logging
#if os(iOS)
import UIKit
#endif
import Network


public protocol ReefReferralDelegate {
    func statusUpdated(referralStatus: ReefReferral.ReferralStatus)
}

public extension ReefReferralDelegate {
    func statusUpdated(referralStatus: ReefReferral.ReferralStatus) {}
}

public class ReefReferral {
    internal static var logger = Logger(label: "com.reef-referral.logger")
    private let reefReferralInternal = ReefReferralInternal()

    public static let shared = ReefReferral()
    public var delegate: ReefReferralDelegate? { didSet { delegateSet() }}



    public func start(apiKey: String, delegate: ReefReferralDelegate? = nil, logLevel: ReefReferral.LogLevel = .none) {
        self.delegate = delegate
        reefReferralInternal.start(apiKey: apiKey, delegate: self, logLevel: logLevel)
    }

    public func getReferralStatus(cached: Bool = true) async throws -> ReferralStatus {
        if cached {
            let new = try? await reefReferralInternal.status()
            if let newOrCached = new ?? getReferralStatusCached() {
                return newOrCached
            } else {
                throw ReefError.infoUnavailable
            }
        } else {
            return try await reefReferralInternal.status()
        }
    }

    public func getReferralStatus(cached: Bool = true, callback: @escaping (Result<ReferralStatus, Error>)->Void) {
        Task {
            do {
                let info = try await getReferralStatus(cached: cached)
                callback(.success(info))
            } catch {
                callback(.failure(error))
            }
        }
    }

    public func getReferralStatusCached() -> ReferralStatus? {
        return ReferralStatus(reefReferralInternal.data)
    }

    public func setUserId(_ id : String) {
        reefReferralInternal.setUserId(id)
    }

    public func canHandleDeepLink(url: URL) -> Bool {
        reefReferralInternal.canHandleDeepLink(url: url)
    }

    public func handleDeepLink(url: URL) {
        reefReferralInternal.handleDeepLink(url: url)
    }

#if os(iOS)
    /// Helper function, use on UIWindowSceneDelegate.func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>)
    public func handleDeepLink(URLContexts: Set<UIOpenURLContext>) {
        for link in URLContexts {
            handleDeepLink(url: link.url)
        }
    }

    /// Helper function, use on UIWindowSceneDelegate.scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions)
    public func handleDeepLink(connectionOptions: UIScene.ConnectionOptions) {
        handleDeepLink(URLContexts: connectionOptions.urlContexts)
    }
#endif

    public func setUserID(id: String)  {
        reefReferralInternal.setUserId(id)
    }

    //MARK: Manual mode

    public func triggerSenderSuccess() {
        reefReferralInternal.triggerSenderSuccess()
    }

    public func triggerReceiverSuccess() {
        reefReferralInternal.triggerReceiverSuccess()
    }
}

private extension ReefReferral {
    func delegateSet() {
        if let status = self.getReferralStatusCached() {
            delegate?.statusUpdated(referralStatus: status)
        }
    }
}

extension ReefReferral: ReefReferralDelegatePassThrough {
    func statusUpdated(referralStatus: ReferralStatus) {
        delegate?.statusUpdated(referralStatus: referralStatus)
    }
}
