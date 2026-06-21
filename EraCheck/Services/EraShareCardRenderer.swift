import SwiftUI
import UIKit

final class EraShareCardRenderer {
    static func render(result: EraResult) -> UIImage {
        let size = CGSize(width: 1080, height: 1080)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let context = ctx.cgContext
            let backgroundColor = UIColor(result.primary.shareBackgroundColor)
            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
            drawDecorations(in: context, size: size, color: backgroundColor)
            drawHeader(in: ctx, size: size)
            drawTitle(result: result, in: ctx, size: size)
            drawDescription(result: result, in: ctx, size: size)
            drawFooter(in: ctx, size: size)
        }
    }

    private static func drawHeader(in ctx: UIGraphicsImageRendererContext, size: CGSize) {
        let headerText = "ERA CHECK"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        let text = NSString(string: headerText)
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(x: 72, y: 54, width: size.width - 144, height: textSize.height)
        text.draw(in: textRect, withAttributes: attributes)
    }

    private static func drawTitle(result: EraResult, in ctx: UIGraphicsImageRendererContext, size: CGSize) {
        let primary = NSString(string: result.primary.name)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 96, weight: .bold),
            .foregroundColor: UIColor(result.primary.textColor)
        ]
        let titleSize = primary.size(withAttributes: titleAttributes)
        let titleRect = CGRect(x: 72, y: size.height / 3, width: size.width - 144, height: titleSize.height)
        primary.draw(in: titleRect, withAttributes: titleAttributes)

        let subtitle = NSString(string: result.subtitle)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .semibold),
            .foregroundColor: UIColor(result.primary.textColor).withAlphaComponent(0.85)
        ]
        let subtitleRect = subtitle.boundingRect(
            with: CGSize(width: size.width - 144, height: 60),
            options: [.usesLineFragmentOrigin],
            attributes: subtitleAttributes,
            context: nil)
        subtitle.draw(in: CGRect(x: 72, y: titleRect.maxY + 12, width: size.width - 144, height: subtitleRect.height), withAttributes: subtitleAttributes)
    }

    private static func drawDescription(result: EraResult, in ctx: UIGraphicsImageRendererContext, size: CGSize) {
        let description = NSString(string: result.description)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.9)
        ]
        let descriptionRect = CGRect(x: 72, y: size.height / 2, width: size.width - 144, height: size.height / 3)
        description.draw(with: descriptionRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: attributes, context: nil)
    }

    private static func drawFooter(in ctx: UIGraphicsImageRendererContext, size: CGSize) {
        let footerText = "What era are you? → eracheck.app"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        let footerRect = CGRect(x: 72, y: size.height - 120, width: size.width - 144, height: 36)
        NSString(string: footerText).draw(in: footerRect, withAttributes: attributes)
    }

    private static func drawDecorations(in context: CGContext, size: CGSize, color: UIColor) {
        context.setBlendMode(.overlay)
        let dotColor = color.withAlphaComponent(0.2)
        let circleRect = CGRect(x: size.width - 220, y: 120, width: 160, height: 160)
        context.setFillColor(dotColor.cgColor)
        context.fillEllipse(in: circleRect)
        context.setBlendMode(.normal)
    }
}
