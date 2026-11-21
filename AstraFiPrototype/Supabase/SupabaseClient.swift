//
//  SupabaseClient.swift
//  AstraFiPrototype
//
//  Created by Akash Kumar Kashyap Created on 05/09/2026
//

import Foundation
import Supabase
import Auth
import os

// MARK: - Supabase Network Diagnostics Logger
/// Monitors Supabase HTTP transactions for latency, connection reuse, HTTP status, and errors
/// without logging sensitive credentials, tokens, or financial payload data.
final class SupabaseNetworkDiagnosticsDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    static let shared = SupabaseNetworkDiagnosticsDelegate()

    private let logger = Logger(subsystem: "com.astrafi.app", category: "SupabaseNetwork")

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        let duration = metrics.taskInterval.duration
        let durationMs = Int(duration * 1000)

        guard let request = task.originalRequest ?? task.currentRequest,
              let url = request.url else { return }

        // Sanitize path (strip query parameters to avoid leaking tokens or private params)
        let sanitizedPath = url.path.isEmpty ? "/" : url.path
        let method = request.httpMethod ?? "GET"

        let response = task.response as? HTTPURLResponse
        let statusCode = response?.statusCode ?? 0
        let statusText = statusCode > 0 ? "\(statusCode)" : "None"

        let latestMetric = metrics.transactionMetrics.last
        let isReused = latestMetric?.isReusedConnection ?? false
        let protocolName = latestMetric?.networkProtocolName ?? "unknown"
        let remoteIP = latestMetric?.remoteAddress ?? "unknown"

        if let error = task.error as? NSError {
            // Log sanitized failure
            print("⚠️ [SUPABASE NETWORK] \(method) \(sanitizedPath) -> ERROR \(error.domain)(\(error.code)): \(error.localizedDescription) (\(durationMs)ms, remote: \(remoteIP))")
            logger.error("Supabase request failed: \(method) \(sanitizedPath, privacy: .public) code: \(error.code) in \(durationMs)ms")
        } else if statusCode >= 400 {
            // Log HTTP error response
            print("⚠️ [SUPABASE NETWORK] \(method) \(sanitizedPath) -> HTTP \(statusText) (\(durationMs)ms, proto: \(protocolName), reused: \(isReused))")
            logger.warning("Supabase HTTP error: \(method) \(sanitizedPath, privacy: .public) status: \(statusCode) in \(durationMs)ms")
        } else {
            // Successful request
            #if DEBUG
            let reuseTag = isReused ? " [reused]" : ""
            print("✅ [SUPABASE NETWORK] \(method) \(sanitizedPath) -> HTTP \(statusText) (\(durationMs)ms, proto: \(protocolName)\(reuseTag))")
            #endif
        }
    }
}

// MARK: - Dedicated Supabase URLSession
/// A dedicated URLSession optimized for Supabase API interactions.
/// - Enables HTTP/2 connection multiplexing and keep-alive so subsequent PostgREST queries reuse active sockets.
/// - Caps request timeouts safely to avoid indefinite stalls.
/// - Integrates privacy-safe network diagnostics.
private let supabaseSession: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 20
    config.timeoutIntervalForResource = 60
    config.httpMaximumConnectionsPerHost = 8
    config.waitsForConnectivity = true
    config.requestCachePolicy = .useProtocolCachePolicy
    return URLSession(
        configuration: config,
        delegate: SupabaseNetworkDiagnosticsDelegate.shared,
        delegateQueue: nil
    )
}()

// MARK: - Supabase Client
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://vldnxejhmiovdhjxxgdz.supabase.co")!,
    supabaseKey: "sb_publishable_PXbdp55T-1W50F6_18twdg_laCNJKqR",
    options: .init(
        auth: .init(flowType: .implicit),
        global: .init(headers: [:], session: supabaseSession)
    )
)
