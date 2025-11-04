//
//  ContentView.swift
//  kaia
//
//  Simplified view showing centered test text.

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear
                Text("Hello, Word")
                    .font(.largeTitle)
                    .bold()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .navigationTitle("Kaia")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Intentionally left empty; add action as needed
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
