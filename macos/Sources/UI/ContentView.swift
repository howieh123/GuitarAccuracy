import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "guitars.fill").font(.system(size: 48))
            Text("GuitarAccuracy").font(.title)
            Text("Welcome!")
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 320)
    }
}

#Preview {
    ContentView()
}
