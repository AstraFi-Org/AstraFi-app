import Combine
import Foundation
import SwiftUI

struct UpstoxInvestmentSnapshot {
    var equity: [UpstoxHolding] = []
    var mutualFunds: [UpstoxMutualFundHolding] = []
    var mutualFundOrders: [UpstoxMutualFundOrder] = []
    var mutualFundSIPs: [UpstoxMutualFundSIP] = []
}

@MainActor
final class UpstoxViewModel: ObservableObject {
    nonisolated(unsafe) static let shared = UpstoxViewModel()

    @Published var isConnected = false
    @Published var isLoading = false
    @Published var isSyncingHoldings = false
    @Published var profile: UpstoxProfile?
    @Published var holdings: [UpstoxHolding] = []
    @Published var mutualFundHoldings: [UpstoxMutualFundHolding] = []
    @Published var holdingsSyncMessage: String?
    @Published var errorMessage: String?

    private let service: UpstoxService
    private let profileStorageKey = "upstox.profile"

    nonisolated private init(service: UpstoxService = .shared) {
        self.service = service
        Task { @MainActor in
            UpstoxViewModel.shared.loadStoredConnection()
        }
    }

    func connect() {
        do {
            isLoading = true
            errorMessage = nil
            let url = try service.authorizationURL()
            UIApplication.shared.open(url) { [weak self] success in
                Task { @MainActor in
                    guard let self else { return }
                    if !success {
                        self.isLoading = false
                        self.errorMessage = "Unable to open Upstox authentication."
                    }
                }
            }
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func handleRedirect(_ url: URL) async {
        guard isUpstoxRedirect(url) else { return }

        if let failure = queryValue("error", in: url) {
            isLoading = false
            errorMessage = queryValue("error_description", in: url) ?? "Upstox authentication failed: \(failure)"
            return
        }

        guard let code = queryValue("code", in: url), !code.isEmpty else {
            isLoading = false
            errorMessage = "Upstox did not return an authorization code."
            return
        }

        await exchangeAndLoadProfile(code: code)
    }

    func fetchProfile() async {
        guard service.storedAccessToken != nil else {
            isConnected = false
            profile = nil
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let connectedDate = profile?.connectedDate ?? Date()
            let fetchedProfile = try await service.fetchProfile(connectedDate: connectedDate)
            profile = fetchedProfile
            holdings = (try? await service.fetchInvestments()) ?? []
            mutualFundHoldings = await fetchMutualFundHoldingsSilently()
            isConnected = true
            persistProfile(fetchedProfile)
        } catch {
            handle(error)
        }

        isLoading = false
    }

    func disconnect() {
        do {
            try service.logout()
        } catch {
            errorMessage = error.localizedDescription
        }

        UserDefaults.standard.removeObject(forKey: profileStorageKey)
        profile = nil
        holdings = []
        mutualFundHoldings = []
        isConnected = false
        isLoading = false
    }

    func fetchConnectedInvestments() async -> UpstoxInvestmentSnapshot {
        guard service.storedAccessToken != nil else {
            holdings = []
            mutualFundHoldings = []
            holdingsSyncMessage = "Connect Upstox to sync investments."
            return UpstoxInvestmentSnapshot()
        }

        isSyncingHoldings = true
        holdingsSyncMessage = nil
        defer { isSyncingHoldings = false }

        var syncError: Error?
        var fetchedHoldings: [UpstoxHolding] = []
        var fetchedMutualFunds: [UpstoxMutualFundHolding] = []
        var fetchedMutualFundOrders: [UpstoxMutualFundOrder] = []
        var fetchedMutualFundSIPs: [UpstoxMutualFundSIP] = []

        do {
            fetchedHoldings = try await service.fetchInvestments()
        } catch {
            syncError = error
        }

        do {
            fetchedMutualFunds = try await service.fetchMutualFundHoldings()
        } catch {
            syncError = syncError ?? error
        }

        // Order history provides each executed SIP date, amount, units, and NAV.
        // SIP registrations provide the authoritative investment mode and schedule.
        fetchedMutualFundOrders = (try? await service.fetchMutualFundOrders()) ?? []
        fetchedMutualFundSIPs = (try? await service.fetchMutualFundSIPs()) ?? []

        holdings = fetchedHoldings
        mutualFundHoldings = fetchedMutualFunds

        let totalCount = fetchedHoldings.count + fetchedMutualFunds.count
        if totalCount > 0 {
            holdingsSyncMessage = "Synced \(totalCount) Upstox investment\(totalCount == 1 ? "" : "s")."
        } else if let syncError {
            handle(syncError)
            holdingsSyncMessage = syncError.localizedDescription
        } else {
            holdingsSyncMessage = "Upstox returned no stocks, positions, or mutual funds for this account."
        }

        return UpstoxInvestmentSnapshot(
            equity: fetchedHoldings,
            mutualFunds: fetchedMutualFunds,
            mutualFundOrders: fetchedMutualFundOrders,
            mutualFundSIPs: fetchedMutualFundSIPs
        )
    }

    func fetchHoldings() async -> [UpstoxHolding] {
        let investments = await fetchConnectedInvestments()
        return investments.equity
    }

    func loadStoredConnection() {
        if let data = UserDefaults.standard.data(forKey: profileStorageKey),
           let storedProfile = try? JSONDecoder().decode(UpstoxProfile.self, from: data) {
            profile = storedProfile
        }

        isConnected = service.storedAccessToken != nil

        if isConnected {
            Task { await fetchProfile() }
        } else {
            profile = nil
        }
    }

    private func exchangeAndLoadProfile(code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let token = try await service.exchangeCodeForToken(code)
            let connectedDate = Date()
            let fetchedProfile = try await service.fetchProfile(accessToken: token, connectedDate: connectedDate)
            let fetchedHoldings = (try? await service.fetchInvestments(accessToken: token)) ?? []
            let fetchedMutualFunds = await fetchMutualFundHoldingsSilently(accessToken: token)
            profile = fetchedProfile
            holdings = fetchedHoldings
            mutualFundHoldings = fetchedMutualFunds
            isConnected = true
            persistProfile(fetchedProfile)
        } catch {
            handle(error)
        }

        isLoading = false
    }

    private func handle(_ error: Error) {
        errorMessage = error.localizedDescription

        if case UpstoxServiceError.expiredToken = error {
            try? service.logout()
            isConnected = false
        }
    }

    private func persistProfile(_ profile: UpstoxProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileStorageKey)
        }
    }

    private func fetchMutualFundHoldingsSilently(accessToken: String? = nil) async -> [UpstoxMutualFundHolding] {
        (try? await service.fetchMutualFundHoldings(accessToken: accessToken)) ?? []
    }

    private func isUpstoxRedirect(_ url: URL) -> Bool {
        if url.scheme == "astrafi", url.host == "upstox-callback" {
            return true
        }

        guard !APIConfig.redirectURI.isEmpty,
              let configuredURL = URL(string: APIConfig.redirectURI) else {
            return url.query?.contains("code=") == true
        }

        return url.scheme == configuredURL.scheme && url.host == configuredURL.host
    }

    private func queryValue(_ name: String, in url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == name })?
            .value
    }
}
