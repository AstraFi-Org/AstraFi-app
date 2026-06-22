//
//  Component.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 22/04/26.
//

import SwiftUI

struct AuthFieldLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.primary)
            .padding(.bottom, 8)
    }
}

struct AuthInputField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(Color(uiColor: .systemGray2))
                .frame(width: 22)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .tint(.blue)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .tint(.blue)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct AuthPasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock")
                .font(.system(size: 17))
                .foregroundColor(Color(uiColor: .systemGray2))
                .frame(width: 22)
            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                } else {
                    SecureField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
            }
            .font(.system(size: 16))
            .foregroundColor(.primary)
            .tint(.blue)
            Button { showPassword.toggle() } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .font(.system(size: 17))
                    .foregroundColor(Color(uiColor: .systemGray2))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct AuthPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                }
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(brandGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading || isDisabled)
    }
}

struct AuthOrDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(.blue.opacity(0.4))
                .frame(height: 1)
            Text("or")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(brandGradient)
            Rectangle()
                .fill(.blue.opacity(0.4))
                .frame(height: 1)
        }
    }
}

struct AuthAppleButton: View {
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 10) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18, weight: .medium)).foregroundColor(Color(uiColor: .systemBackground))
                Text("Continue with Apple")
                    .font(.system(size: 17, weight: .medium)).foregroundColor(Color(uiColor: .systemBackground))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 15)
            .background(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
