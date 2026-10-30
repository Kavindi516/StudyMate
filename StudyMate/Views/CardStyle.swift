import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .softCard(cornerRadius: 16)
    }
}
