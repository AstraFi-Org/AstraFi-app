import SwiftUI
import AVFoundation
import Photos
import CoreLocation
import Contacts
import UserNotifications
import AppTrackingTransparency
import LocalAuthentication

@Observable
class PrivacyPermissionManager {
    var cameraStatus: AVAuthorizationStatus = .notDetermined
    var microphoneStatus: AVAuthorizationStatus = .notDetermined
    var photosStatus: PHAuthorizationStatus = .notDetermined
    var locationStatus: CLAuthorizationStatus = .notDetermined
    var contactsStatus: CNAuthorizationStatus = .notDetermined
    var notificationsStatus: UNAuthorizationStatus = .notDetermined
    var trackingStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    
    init() {
        refreshAll()
    }
    
    func refreshAll() {
        // Camera
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        // Microphone
        microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        // Photos
        photosStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        // Location
        locationStatus = locationManager.authorizationStatus
        
        // Contacts
        contactsStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        // Notifications
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationsStatus = settings.authorizationStatus
            }
        }
        
        // Tracking
        trackingStatus = ATTrackingManager.trackingAuthorizationStatus
    }
    
    // Request functions
    func requestCamera(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.refreshAll()
                completion(granted)
            }
        }
    }
    
    func requestMicrophone(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                self?.refreshAll()
                completion(granted)
            }
        }
    }
    
    func requestPhotos(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.refreshAll()
                completion(status == .authorized || status == .limited)
            }
        }
    }
    
    func requestLocation(completion: @escaping (Bool) -> Void) {
        // Location requires requesting via the manager itself
        locationManager.requestWhenInUseAuthorization()
        // We'll delay slightly to let status change, or let the OS dialog handle it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshAll()
            let status = self?.locationStatus ?? .notDetermined
            completion(status == .authorizedWhenInUse || status == .authorizedAlways)
        }
    }
    
    func requestContacts(completion: @escaping (Bool) -> Void) {
        CNContactStore().requestAccess(for: .contacts) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.refreshAll()
                completion(granted)
            }
        }
    }
    
    func requestNotifications(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.refreshAll()
                completion(granted)
            }
        }
    }
    
    func requestTracking(completion: @escaping (Bool) -> Void) {
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.refreshAll()
                completion(status == .authorized)
            }
        }
    }
}

struct PrivacyControlsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStateManager.self) var appState
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var permissionManager = PrivacyPermissionManager()
    
    // Custom app-level consents stored in AppStorage
    @AppStorage("privacyAnalyticsSharingEnabled") private var analyticsSharingEnabled = true
    @AppStorage("privacyThirdPartySharingEnabled") private var thirdPartySharingEnabled = true
    @AppStorage("privacyPersonalizationEnabled") private var personalizationEnabled = true
    
    // Alerts state
    @State private var alertMessage: String?
    @State private var showingAlert = false
    @State private var showingSettingsRedirectAlert = false
    @State private var redirectedPermissionName = ""
    
    // Account deletion state
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteFinalSuccess = false
    @State private var isDeleting = false
    
    var body: some View {
        List {
            Section {
                privacyHeader
            }
            .listRowBackground(Color.clear)
            
            Section {
                // Notifications Toggle
                makePermissionToggleRow(
                    title: "Push Notifications",
                    subtitle: "Receive alerts for plan updates and insurance renewal reminders.",
                    icon: "bell.badge.fill",
                    color: Color(hex: "#FF3B30"),
                    status: notificationStatusString,
                    isOn: isNotificationAuthorized,
                    onToggleChanged: { _ in handleToggleTap("Notifications") }
                )
                
                // Camera Toggle
                makePermissionToggleRow(
                    title: "Camera",
                    subtitle: "Scan financial documents and capture profile pictures.",
                    icon: "camera.fill",
                    color: Color(hex: "#007AFF"),
                    status: cameraStatusString,
                    isOn: isCameraAuthorized,
                    onToggleChanged: { _ in handleToggleTap("Camera") }
                )
                
                // Photos Toggle
                makePermissionToggleRow(
                    title: "Photo Library",
                    subtitle: "Access document screenshots and upload profile images.",
                    icon: "photo.on.rectangle.angled",
                    color: Color(hex: "#FF2D55"),
                    status: photosStatusString,
                    isOn: isPhotosAuthorized,
                    onToggleChanged: { _ in handleToggleTap("Photos") }
                )
                
                // Microphone Toggle
                makePermissionToggleRow(
                    title: "Microphone",
                    subtitle: "Enable voice commands for searching insights.",
                    icon: "mic.fill",
                    color: Color(hex: "#5856D6"),
                    status: microphoneStatusString,
                    isOn: isMicrophoneAuthorized,
                    onToggleChanged: { _ in handleToggleTap("Microphone") }
                )
                
                // Location Toggle
                makePermissionToggleRow(
                    title: "Location Services",
                    subtitle: "Enhance security by detecting region-specific access.",
                    icon: "location.fill",
                    color: Color(hex: "#34C759"),
                    status: locationStatusString,
                    isOn: isLocationAuthorized,
                    onToggleChanged: { _ in handleToggleTap("Location") }
                )
                
                // Contacts Toggle
                makePermissionToggleRow(
                    title: "Contacts",
                    subtitle: "Easily split expenses with your friends and family.",
                    icon: "person.2.fill",
                    color: Color(hex: "#FF9F0A"),
                    status: contactsStatusString,
                    isOn: isContactsAuthorized,
                    onToggleChanged: { _ in handleToggleTap("Contacts") }
                )
                
                // Tracking Toggle
                makePermissionToggleRow(
                    title: "App Tracking",
                    subtitle: "Help improve AstraFi by allowing anonymous tracking.",
                    icon: "person.and.arrow.left.and.arrow.right",
                    color: Color(hex: "#8E8E93"),
                    status: trackingStatusString,
                    isOn: isTrackingAuthorized,
                    onToggleChanged: { _ in handleToggleTap("Tracking") }
                )
            } header: {
                Text("System Permissions")
            } footer: {
                Text("Enable permissions to access native features. Toggling will ask or direct you to iPhone System Settings.")
            }
            
            Section {
                NativeSettingsToggleRow(
                    title: "Analytics & Crashes",
                    subtitle: "Share anonymous diagnostic data to help us improve.",
                    icon: "chart.xyaxis.line",
                    color: Color(hex: "#5856D6"),
                    isOn: $analyticsSharingEnabled
                )
                
                NativeSettingsToggleRow(
                    title: "Personalization",
                    subtitle: "Allow recommendations tailored to your profile.",
                    icon: "sparkles",
                    color: Color(hex: "#FF9F0A"),
                    isOn: $personalizationEnabled
                )
                
                NativeSettingsToggleRow(
                    title: "Third-Party Data Sharing",
                    subtitle: "Allow secure sharing with financial institutions.",
                    icon: "arrow.up.right.and.arrow.down.left.rectangle",
                    color: Color(hex: "#34C759"),
                    isOn: $thirdPartySharingEnabled
                )
            } header: {
                Text("Data & Consent")
            } footer: {
                Text("These settings apply to app-level storage and local custom analytics.")
            }
            
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Delete Account")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 5)
                }
            } header: {
                Text("Account Deletion")
            } footer: {
                Text("Deleting your account will permanently delete all financial data, profile, and settings from our secure servers.")
            }
        }
        .navigationTitle("Privacy Controls")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                permissionManager.refreshAll()
            }
        }
        .onAppear {
            permissionManager.refreshAll()
        }
        // Redirect Alert
        .alert(isPresented: $showingSettingsRedirectAlert) {
            Alert(
                title: Text("Modify \(redirectedPermissionName) Permission"),
                message: Text("To change this permission, please open system Settings and toggle \(redirectedPermissionName)."),
                primaryButton: .default(Text("Open Settings")) {
                    openSystemSettings()
                },
                secondaryButton: .cancel()
            )
        }
        // General Alert
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Privacy Consent"),
                message: Text(alertMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
        // Account Deletion Alert Flow
        .alert("Permanently Delete Account?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Account", role: .destructive) {
                performAccountDeletion()
            }
        } message: {
            Text("This action is permanent. All your data, active synced credentials, and financial plans will be deleted instantly. You cannot undo this.")
        }
        .sheet(isPresented: $showingDeleteFinalSuccess) {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                VStack(spacing: 8) {
                    Text("Account Deleted")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("All your data has been permanently deleted from AstraFi servers.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                Button(action: {
                    showingDeleteFinalSuccess = false
                    Task {
                        await appState.signOut()
                    }
                }) {
                    Text("Done")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
            }
            .interactiveDismissDisabled()
        }
    }
    
    // Header View
    private var privacyHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)
                .shadow(color: .blue.opacity(0.2), radius: 10, y: 5)
            
            Text("AstraFi Privacy Center")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("We respect your choices. Manage system permissions, customize third-party data sharing consents, or request account removal instantly.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    // Permission Status Checkers
    private var notificationStatusString: String {
        switch permissionManager.notificationsStatus {
        case .authorized, .provisional, .ephemeral: return "Allowed"
        case .denied: return "Denied"
        case .notDetermined: return "Not Requested"
        @unknown default: return "Not Requested"
        }
    }
    
    private var isNotificationAuthorized: Bool {
        permissionManager.notificationsStatus == .authorized || permissionManager.notificationsStatus == .provisional
    }
    
    private var cameraStatusString: String {
        switch permissionManager.cameraStatus {
        case .authorized: return "Allowed"
        case .denied, .restricted: return "Denied"
        case .notDetermined: return "Not Requested"
        @unknown default: return "Not Requested"
        }
    }
    
    private var isCameraAuthorized: Bool {
        permissionManager.cameraStatus == .authorized
    }
    
    private var microphoneStatusString: String {
        switch permissionManager.microphoneStatus {
        case .authorized: return "Allowed"
        case .denied, .restricted: return "Denied"
        case .notDetermined: return "Not Requested"
        @unknown default: return "Not Requested"
        }
    }
    
    private var isMicrophoneAuthorized: Bool {
        permissionManager.microphoneStatus == .authorized
    }
    
    private var photosStatusString: String {
        switch permissionManager.photosStatus {
        case .authorized, .limited: return "Allowed"
        case .denied, .restricted: return "Denied"
        case .notDetermined: return "Not Requested"
        @unknown default: return "Not Requested"
        }
    }
    
    private var isPhotosAuthorized: Bool {
        permissionManager.photosStatus == .authorized || permissionManager.photosStatus == .limited
    }
    
    private var locationStatusString: String {
        switch permissionManager.locationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return "Allowed"
        case .denied, .restricted: return "Denied"
        case .notDetermined: return "Not Requested"
        @unknown default: return "Not Requested"
        }
    }
    
    private var isLocationAuthorized: Bool {
        permissionManager.locationStatus == .authorizedAlways || permissionManager.locationStatus == .authorizedWhenInUse
    }
    
    private var contactsStatusString: String {
        switch permissionManager.contactsStatus {
        case .authorized: return "Allowed"
        case .denied, .restricted: return "Denied"
        case .notDetermined: return "Not Requested"
        @unknown default: return "Not Requested"
        }
    }
    
    private var isContactsAuthorized: Bool {
        permissionManager.contactsStatus == .authorized
    }
    
    private var trackingStatusString: String {
        switch permissionManager.trackingStatus {
        case .authorized: return "Allowed"
        case .denied, .restricted: return "Denied"
        case .notDetermined: return "Not Requested"
        @unknown default: return "Not Requested"
        }
    }
    
    private var isTrackingAuthorized: Bool {
        permissionManager.trackingStatus == .authorized
    }
    
    // Toggles logic
    private func handleToggleTap(_ type: String) {
        switch type {
        case "Notifications":
            if permissionManager.notificationsStatus == .notDetermined {
                permissionManager.requestNotifications { _ in }
            } else {
                redirectedPermissionName = "Notifications"
                showingSettingsRedirectAlert = true
            }
        case "Camera":
            if permissionManager.cameraStatus == .notDetermined {
                permissionManager.requestCamera { _ in }
            } else {
                redirectedPermissionName = "Camera"
                showingSettingsRedirectAlert = true
            }
        case "Microphone":
            if permissionManager.microphoneStatus == .notDetermined {
                permissionManager.requestMicrophone { _ in }
            } else {
                redirectedPermissionName = "Microphone"
                showingSettingsRedirectAlert = true
            }
        case "Photos":
            if permissionManager.photosStatus == .notDetermined {
                permissionManager.requestPhotos { _ in }
            } else {
                redirectedPermissionName = "Photos"
                showingSettingsRedirectAlert = true
            }
        case "Location":
            if permissionManager.locationStatus == .notDetermined {
                permissionManager.requestLocation { _ in }
            } else {
                redirectedPermissionName = "Location Services"
                showingSettingsRedirectAlert = true
            }
        case "Contacts":
            if permissionManager.contactsStatus == .notDetermined {
                permissionManager.requestContacts { _ in }
            } else {
                redirectedPermissionName = "Contacts"
                showingSettingsRedirectAlert = true
            }
        case "Tracking":
            if permissionManager.trackingStatus == .notDetermined {
                permissionManager.requestTracking { _ in }
            } else {
                redirectedPermissionName = "App Tracking"
                showingSettingsRedirectAlert = true
            }
        default:
            break
        }
    }
    
    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url)
    }
    
    private func performAccountDeletion() {
        isDeleting = true
        // Mock API deletion delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isDeleting = false
            showingDeleteFinalSuccess = true
        }
    }
    
    // Helper builder for permission rows
    private func makePermissionToggleRow(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        status: String,
        isOn: Bool,
        onToggleChanged: @escaping (Bool) -> Void
    ) -> some View {
        HStack(spacing: 12) {
            NativeSettingsIcon(systemName: icon, color: color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 8)
            
            // Text indicator of status (Allowed / Denied / Not Requested)
            Text(status)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Interactive toggle
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { value in onToggleChanged(value) }
            ))
            .labelsHidden()
            .tint(Color(hex: "#34C759"))
        }
        .padding(.vertical, 5)
    }
}

// Replicating helper Views locally for self-containment and compile safety
private struct NativeSettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                NativeSettingsIcon(systemName: icon, color: color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Color(hex: "#34C759"))
        .padding(.vertical, 5)
    }
}

private struct NativeSettingsIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        PrivacyControlsView()
            .environment(AppStateManager())
    }
}
