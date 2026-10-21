import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let text: String
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        if let image = generate() {
            Image(uiImage: image).interpolation(.none).resizable().scaledToFit()
        } else {
            Text("Could not generate QR")
        }
    }

    private func generate() -> UIImage? {
        filter.message = Data(text.utf8)
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
