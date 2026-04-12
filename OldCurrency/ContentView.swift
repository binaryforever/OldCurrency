//
//  ContentView.swift
//  OldCurrency
//
//  Created by Vincent Holmes on 10/04/2026.
//

import SwiftUI
import Foundation

// Shared app colours
extension Color {
    static let appBackground   = Color(red: 1.0,  green: 0.98, blue: 0.85)
    static let appAccent       = Color(red: 0.75, green: 0.60, blue: 0.10)
    static let appText         = Color(red: 0.20, green: 0.16, blue: 0.02)
    static let appSecondary    = Color(red: 0.55, green: 0.44, blue: 0.08)
}

struct ContentView: View {
    // Live or Test - true or false
    @State private var showSplash = true
    @State private var fromCurrency = "GBP"
    @State private var toCurrency = "EUR"
    @State private var date = Date()
    @State private var showingResult = false
    @State private var resultRate = ""
    @State private var resultDateNote: String? = nil
    @State private var isLoading = false
    @State private var fetchFailed = false
    @State private var lastRequest: (() -> Void)? = nil

    var body: some View {
        ZStack {
            if showSplash {
                VortexSplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                showSplash = false
                            }
                        }
                    }
            } else {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Text("Daily Currency")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.appText)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Conversion Rate")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.appText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 64)

                    HStack(spacing: 0) {
                        VStack(spacing: 6) {
                            Text("From:")
                                .font(.title3)
                                .foregroundStyle(Color.appSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Picker("From", selection: $fromCurrency) {
                                ForEach(supportedCurrencies, id: \.self) { currency in
                                    Text("\(currency) (\(currencySymbols[currency] ?? ""))")
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color.appAccent)
                            .frame(maxWidth: .infinity)
                        }

                        VStack(spacing: 6) {
                            Text("⇄")
                                .font(.title2)
                                .foregroundStyle(Color.appAccent)
                            Button {
                                let temp = fromCurrency
                                fromCurrency = toCurrency
                                toCurrency = temp
                            } label: {
                                Text("Swap")
                                    .font(.caption)
                                    .foregroundStyle(Color.appAccent)
                            }
                        }
                        .frame(width: 52)

                        VStack(spacing: 6) {
                            Text("To:")
                                .font(.title3)
                                .foregroundStyle(Color.appSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Picker("To", selection: $toCurrency) {
                                ForEach(supportedCurrencies, id: \.self) { currency in
                                    Text("\(currency) (\(currencySymbols[currency] ?? ""))")
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color.appAccent)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, 64)

                    HStack(spacing: 12) {
                        Text("Date:")
                            .font(.title3)
                            .foregroundStyle(Color.appSecondary)
                        Button {
                            date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundStyle(Color.appAccent)
                        }
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .fixedSize()
                            .tint(Color.appAccent)
                        if !Calendar.current.isDateInToday(date) && date < Date() {
                            Button {
                                date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundStyle(Color.appAccent)
                            }
                        }
                    }
                    .padding(.bottom, 64)

                    Button("Submit") {
                        fetchConversion()
                    }
                    .font(.title3)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.appAccent)
                    .disabled(isLoading)

                    Spacer()

                    Text("Rate shown is sourced from the Frankfurter open-source currency data API, which aggregates official daily exchange rates published by central banks and financial institutions worldwide.")
                        .font(.caption)
                        .foregroundStyle(Color.appSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)

                    Link("☕ Buy me a coffee", destination: URL(string: "https://ko-fi.com/vincentholmes")!)
                        .font(.footnote)
                        .foregroundStyle(Color.appAccent)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal)
                .padding(.top, 60)
                .sheet(isPresented: $showingResult) {
                    ZStack {
                        Color.appBackground
                            .ignoresSafeArea()
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(1.5)
                                .tint(Color.appAccent)
                        } else {
                            VStack(spacing: 0) {
                                let formatter: DateFormatter = {
                                    let f = DateFormatter()
                                    f.dateStyle = .long
                                    return f
                                }()
                                Text("Conversion Rate for")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.appText)
                                    .padding(.bottom, 4)
                                Text("\(formatter.string(from: date))\(resultDateNote != nil ? " *" : "")")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.appText)
                                    .padding(.bottom, 36)

                                if fetchFailed {
                                    Text("Unable to fetch data.")
                                        .font(.title3)
                                        .foregroundStyle(Color.appText)
                                        .padding(.bottom, 24)
                                    Button("Retry") {
                                        lastRequest?()
                                    }
                                    .font(.title3)
                                    .buttonStyle(.borderedProminent)
                                    .tint(Color.appAccent)
                                    .padding(.bottom, 24)
                                } else {
                                    Text(resultRate)
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.appText)
                                        .multilineTextAlignment(.center)
                                        .padding(.bottom, 48)
                                }

                                Button("Close") {
                                    showingResult = false
                                }
                                .font(.title3)
                                .buttonStyle(.bordered)
                                .tint(Color.appAccent)

                                Spacer()

                                if let note = resultDateNote {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundStyle(Color.appSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 8)
                                        .padding(.bottom, 24)
                                }
                            }
                            .padding()
                            .padding(.top, 24)
                        }
                    }
                    .presentationDetents([.medium])
                }
            }
        }
    }

    private func fetchConversion() {
        isLoading = true
        fetchFailed = false
        showingResult = true
        lastRequest = fetchConversion

        Task {
            do {
                let response = try await CurrencyService.shared.fetchConversion(from: fromCurrency, to: toCurrency, date: date)
                await MainActor.run {
                    let fromSymbol = currencySymbols[fromCurrency] ?? ""
                    let toSymbol = currencySymbols[toCurrency] ?? ""
                    resultRate = "1 \(fromCurrency) (\(fromSymbol)) = \(String(format: "%.4f", response.rate)) \(toCurrency) (\(toSymbol))"
                    if !Calendar.current.isDate(response.actualDate, inSameDayAs: date) {
                        let f = DateFormatter()
                        f.dateStyle = .long
                        resultDateNote = "* Value displayed is from \(f.string(from: response.actualDate)) as no rate was available for \(f.string(from: date))"
                    } else {
                        resultDateNote = nil
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    fetchFailed = true
                    resultDateNote = nil
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
