//
//  HowToInvestGuide.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 20/04/26.
//

import SwiftUI

struct HowToInvestGuide: Identifiable {
    var id: String { instrumentName }
    let instrumentName: String
    let icon: String
    let color: Color
    let compactSteps: [String]
    let detailedSteps: [(title: String, detail: String)]
    let taxNote: String

    static let treasuryBills = HowToInvestGuide(
        instrumentName: "Treasury Bills",
        icon: "building.columns.fill",
        color: Color(hex: "#30D158"),
        compactSteps: [
            "Register on RBI Retail Direct portal",
            "Complete KYC with PAN & Aadhaar",
            "Select 91-day T-Bill from auction calendar",
            "Place a non-competitive bid",
            "Fund via net banking or UPI",
            "T-Bill credited to your CSGL demat account"
        ],
        detailedSteps: [
            ("Register on RBI Retail Direct",
             "Visit rbiretaildirect.org.in and create a Retail Direct Gilt (RDG) account. You'll need your PAN, Aadhaar, and a linked bank account. Registration is free and fully online."),
            ("Complete KYC",
             "Upload your PAN and Aadhaar for verification. The portal uses DigiLocker / UIDAI-based eKYC. Your Constituent SGL (CSGL) account is opened automatically — this is where your T-Bills are held in demat form."),
            ("Select 91-day T-Bill Auction",
             "Navigate to the 'Primary Issuance' section. Filter for 91-day Treasury Bills. Auctions are typically held fortnightly on Wednesdays. Check the auction calendar for upcoming dates."),
            ("Place a Non-Competitive Bid",
             "Choose 'Non-Competitive Bidding' — this guarantees allotment at the weighted average yield determined by competitive bidders. Minimum bid is ₹10,000 (face value) in multiples of ₹10,000."),
            ("Fund the Bid",
             "Transfer the discounted amount via net banking or UPI. For a 91-day T-Bill at ~6.9% yield, ₹10,000 face value costs approximately ₹9,830. The exact amount is shown before confirmation."),
            ("Receive in Demat Account",
             "On the settlement date (T+1), the T-Bill is credited to your CSGL account. At maturity (91 days), the face value ₹10,000 is automatically credited to your linked bank account. No action needed.")
        ],
        taxNote: "Interest on T-Bills is taxed as per your income tax slab under 'Income from Other Sources'. No TDS is deducted for Retail Direct purchases. Report the discount (face value − purchase price) as interest income in your ITR."
    )

    static let savingsAccount = HowToInvestGuide(
        instrumentName: "Saving Account",
        icon: "banknote.fill",
        color: Color(hex: "#007AFF"),
        compactSteps: [
            "Choose a bank with competitive savings rate",
            "Open account online with video KYC / eKYC",
            "Keep as dedicated emergency fund account",
            "Interest credited quarterly on daily balance"
        ],
        detailedSteps: [
            ("Choose the Right Bank",
             "Compare savings account interest rates across banks. Major banks: SBI ~2.70%, HDFC ~3.00%, Kotak ~3.50%. Small finance banks like AU SFB offer up to ~7.0%. Consider DICGC insurance (₹5L per depositor per bank) when splitting across banks."),
            ("Open Account Online",
             "Most banks offer instant account opening via video KYC (RBI guidelines allow it). You'll need PAN, Aadhaar, and a selfie/video. Some banks deliver the debit card within 2-3 days. No branch visit required."),
            ("Dedicate as Emergency Fund",
             "Open a separate savings account specifically for your emergency fund. Avoid linking it to UPI for daily spending. This psychological separation prevents accidental usage. Set up a standing instruction to auto-transfer a fixed amount monthly."),
            ("Quarterly Auto-Interest",
             "Interest is computed on daily closing balance and credited quarterly (March, June, September, December). This means even partial-month balances earn interest. Monitor your passbook/statement to verify credits.")
        ],
        taxNote: "Savings account interest up to ₹10,000/yr is exempt under Section 80TTA (₹50,000 for senior citizens under 80TTB). TDS is deducted by the bank if total interest exceeds ₹40,000/yr (₹50,000 for seniors). Submit Form 15G/15H to your bank if your total income is below the taxable limit to avoid TDS."
    )

    static let sweepInFD = HowToInvestGuide(
        instrumentName: "Sweep-in FD",
        icon: "arrow.2.squarepath",
        color: Color(hex: "#FF9F0A"),
        compactSteps: [
            "Log into your bank's app or net banking",
            "Enable auto-sweep in FD/deposits section",
            "Set preferred tenure (7–30 days recommended)",
            "Fund the account — excess auto-sweeps to FD",
            "Verify FD creation in account statement",
            "Withdrawal: FD breaks in reverse; funds next day"
        ],
        detailedSteps: [
            ("Log Into Bank App",
             "Open your bank's mobile app or net banking portal. Navigate to 'Fixed Deposits' or 'Sweep-in FD' section. Major banks (SBI, HDFC, ICICI, Axis) all support auto-sweep setup digitally."),
            ("Enable Auto-Sweep",
             "Look for 'Auto Sweep' or 'Sweep-in FD' option. Set the threshold amount — any balance above this threshold automatically moves into an FD. For example, set ₹25,000 as threshold; any amount above this sweeps into FD."),
            ("Set Tenure (7–30 Days)",
             "Choose a short tenure (7, 14, or 30 days) for maximum liquidity. Shorter tenures allow faster penalty-free access. The FD auto-renews at maturity. Rate is typically ~5.0–5.5% for 7-day sweep deposits at major banks."),
            ("Fund the Account",
             "Transfer your emergency fund amount into this savings account. Once the balance exceeds your set threshold, the excess is automatically swept into FDs. Each sweep creates a separate FD of that specific amount."),
            ("Verify FD Creation",
             "Check your account statement or FD section. You should see individual FDs created for each sweep. Note down the FD numbers and maturity dates. Your total balance = savings balance + sum of all sweep FDs."),
            ("Withdrawal Flow",
             "When you withdraw more than your savings balance, the bank automatically breaks FDs in reverse chronological order (newest first). This preserves interest on older FDs. Funds from broken FDs are typically credited by the next working day.")
        ],
        taxNote: "Sweep-in FD interest is taxed as per your income tax slab under 'Income from Other Sources'. TDS at 10% is deducted if total FD interest across the bank exceeds ₹40,000/yr (₹50,000 for senior citizens). Submit Form 15G (below 60 yrs) / Form 15H (60+ yrs) to avoid TDS if your total income is below the taxable limit."
    )
}

