import UIKit

extension UIImage {
    /// Добавляет белые пиксели снизу — для transparent-карточек, чтобы продукт поднялся вверх при scaleAspectFit
    func withBottomPadding(_ padding: CGFloat) -> UIImage {
        let newSize = CGSize(width: size.width, height: size.height + padding)
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: newSize))
        draw(at: .zero)
        let result = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return result
    }

    /// Возвращает true если нижние 30% изображения светлые (белый/светлый фон)
    func isBottomLight(threshold: CGFloat = 0.72) -> Bool {
        // Уменьшаем до маленького размера для скорости
        let sampleSize = CGSize(width: 20, height: 20)
        let fullRect = CGRect(origin: .zero, size: sampleSize)

        guard let cgImage = self.cgImage else { return false }

        // Вырезаем только нижние 30% оригинала
        let cropRect = CGRect(
            x: 0,
            y: CGFloat(cgImage.height) * 0.7,
            width: CGFloat(cgImage.width),
            height: CGFloat(cgImage.height) * 0.3
        )
        guard let cropped = cgImage.cropping(to: cropRect) else { return false }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixels = [UInt8](repeating: 0, count: Int(sampleSize.width * sampleSize.height) * 4)
        guard let context = CGContext(
            data: &pixels,
            width: Int(sampleSize.width),
            height: Int(sampleSize.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(sampleSize.width) * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return false }

        context.draw(cropped, in: fullRect)

        var totalBrightness: CGFloat = 0
        let count = Int(sampleSize.width * sampleSize.height)

        for i in 0..<count {
            let offset = i * 4
            let r = CGFloat(pixels[offset]) / 255
            let g = CGFloat(pixels[offset + 1]) / 255
            let b = CGFloat(pixels[offset + 2]) / 255
            // Стандартная формула яркости (перцептивная)
            totalBrightness += 0.299 * r + 0.587 * g + 0.114 * b
        }

        return (totalBrightness / CGFloat(count)) > threshold
    }
}
