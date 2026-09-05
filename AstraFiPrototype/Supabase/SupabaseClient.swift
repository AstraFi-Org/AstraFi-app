//
//  SupabaseClient.swift
//  AstraFiPrototype
//
//  Created by Akash Kumar Kashyap Created on 05/09/2026
//
import Foundation
import Supabase
import Auth

let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://vldnxejhmiovdhjxxgdz.supabase.co")!,
  supabaseKey: "sb_publishable_PXbdp55T-1W50F6_18twdg_laCNJKqR",
  options: .init(
      auth: .init(flowType: .implicit)
  )
)
