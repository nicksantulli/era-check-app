import SwiftUI
import UIKit

final class EraShareCardRenderer {
    private static let logicalSize = CGSize(width: 360, height: 360)
    private static let scale: CGFloat = 3

    static func render(result: EraResult) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: logicalSize, format: format)
        let theme = theme(for: result.primary.id)

        return renderer.image { ctx in
            let context = ctx.cgContext
            drawBackground(theme: theme, in: context)
            drawDecorations(theme: theme, in: context)
            drawContent(result: result, theme: theme, in: ctx)
        }
    }

    private static func drawContent(result: EraResult, theme: ShareCardTheme, in ctx: UIGraphicsImageRendererContext) {
        drawWordmark(theme: theme, in: ctx)
        drawTopRule(theme: theme, in: ctx)
        drawYearsBadge(theme: theme, in: ctx)
        drawEraName(result: result, theme: theme, in: ctx)
        drawTagline(result: result, theme: theme, in: ctx)
        drawBlurb(result: result, theme: theme, in: ctx)
        drawBottomRule(theme: theme, in: ctx)
        drawFooter(theme: theme, in: ctx)
    }

    private static func drawBackground(theme: ShareCardTheme, in context: CGContext) {
        if let blocks = theme.chaosBlocks {
            context.setFillColor(theme.backgroundTop.cgColor)
            context.fill(CGRect(origin: .zero, size: logicalSize))
            for block in blocks {
                context.setFillColor(block.color.cgColor)
                context.fill(block.rect)
            }
            return
        }

        let colors = [theme.backgroundTop.cgColor, theme.backgroundMid.cgColor, theme.backgroundBottom.cgColor] as CFArray
        let locations: [CGFloat] = [0, 0.5, 1]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: 180, y: 0),
                end: CGPoint(x: 180, y: logicalSize.height),
                options: [])
        }
    }

    private static func drawDecorations(theme: ShareCardTheme, in context: CGContext) {
        switch theme.id {
        case .tumblrRomantic:
            drawTumblrDecorations(theme: theme, in: context)
        case .vineChaosAgent:
            drawVineDecorations(theme: theme, in: context)
        case .vscoNaturalist:
            drawVSCOFade(theme: theme, in: context)
            drawGrainOverlay(in: context, alpha: 0.08)
            drawVSCODecorations(theme: theme, in: context)
        case .darkAesthetic:
            drawDarkAestheticDecorations(theme: theme, in: context)
        case .quietLuxury:
            drawQuietLuxuryDecorations(theme: theme, in: context)
        }
    }

    private static func drawWordmark(theme: ShareCardTheme, in ctx: UIGraphicsImageRendererContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.wordmarkFont,
            .foregroundColor: theme.primaryText.withAlphaComponent(0.45)
        ]
        let text = NSString(string: "ERA CHECK")
        let textRect = CGRect(x: 28, y: 28, width: 304, height: 14)
        text.draw(in: textRect, withAttributes: attributes)
    }

    private static func drawTopRule(theme: ShareCardTheme, in ctx: UIGraphicsImageRendererContext) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 28, y: 46))
        path.addLine(to: CGPoint(x: 332, y: 46))
        theme.ruleColor.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    private static func drawYearsBadge(theme: ShareCardTheme, in ctx: UIGraphicsImageRendererContext) {
        let badgeRect = CGRect(x: 36, y: 188, width: 96, height: 26)
        let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: 13)
        theme.yearsBadgeBackground.setFill()
        badgePath.fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.yearsFont,
            .foregroundColor: theme.yearsBadgeText,
            .paragraphStyle: paragraph
        ]
        NSString(string: theme.yearsLabel).draw(
            in: badgeRect.insetBy(dx: 4, dy: 6),
            withAttributes: attributes)
    }

    private static func drawEraName(result: EraResult, theme: ShareCardTheme, in ctx: UIGraphicsImageRendererContext) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byWordWrapping

        let nameRect = CGRect(x: 30, y: 218, width: 300, height: 60)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.titleFont,
            .foregroundColor: theme.primaryText,
            .paragraphStyle: paragraph
        ]

        if theme.id == .vineChaosAgent {
            let context = ctx.cgContext
            context.saveGState()
            let center = CGPoint(x: nameRect.midX, y: nameRect.midY)
            context.translateBy(x: center.x, y: center.y)
            context.rotate(by: CGFloat(-2.0 * .pi / 180))
            context.translateBy(x: -center.x, y: -center.y)
            NSString(string: result.primary.name.uppercased()).draw(in: nameRect, withAttributes: attributes)
            context.restoreGState()
            return
        }

        NSString(string: result.primary.name).draw(in: nameRect, withAttributes: attributes)
    }

    private static func drawTagline(result: EraResult, theme: ShareCardTheme, in ctx: UIGraphicsImageRendererContext) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.taglineFont,
            .foregroundColor: theme.primaryText.withAlphaComponent(0.65),
            .paragraphStyle: paragraph,
            .kern: theme.taglineKern
        ]
        NSString(string: theme.taglineTransform(result.primary.tagline)).draw(
            in: CGRect(x: 30, y: 276, width: 300, height: 20),
            withAttributes: attributes)
    }

    private static func drawBlurb(result: EraResult, theme: ShareCardTheme, in ctx: UIGraphicsImageRendererContext) {
        let description = NSString(string: excerpt(for: result.primary.blurb))
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.blurbFont,
            .foregroundColor: theme.secondaryText,
            .paragraphStyle: paragraph
        ]
        let descriptionRect = CGRect(x: 30, y: 304, width: 300, height: 26)
        description.draw(with: descriptionRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: attributes, context: nil)
    }

    private static func drawBottomRule(theme: ShareCardTheme, in ctx: UIGraphicsImageRendererContext) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 28, y: 315))
        path.addLine(to: CGPoint(x: 332, y: 315))
        theme.ruleColor.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    private static func drawFooter(theme: ShareCardTheme, in ctx: UIGraphicsImageRendererContext) {
        let footerText = "What era are you?\neracheck.app"
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        let attributes: [NSAttributedString.Key: Any] = [
            .font: theme.footerFont,
            .foregroundColor: theme.primaryText.withAlphaComponent(0.40),
            .paragraphStyle: paragraph
        ]
        let footerRect = CGRect(x: 30, y: 324, width: 300, height: 28)
        NSString(string: footerText).draw(with: footerRect, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
    }

    private static func drawTumblrDecorations(theme: ShareCardTheme, in context: CGContext) {
        // Crescent moon
        let moonRect = CGRect(x: 286, y: 52, width: 28, height: 28)
        context.setFillColor(theme.primaryText.withAlphaComponent(0.18).cgColor)
        context.fillEllipse(in: moonRect)
        context.setFillColor(theme.backgroundMid.cgColor)
        context.fillEllipse(in: moonRect.offsetBy(dx: 10, dy: 2))

        let stars: [CGPoint] = [
            CGPoint(x: 58, y: 72), CGPoint(x: 280, y: 48), CGPoint(x: 120, y: 108), CGPoint(x: 310, y: 130),
            CGPoint(x: 40, y: 180), CGPoint(x: 320, y: 90), CGPoint(x: 195, y: 60)
        ]
        context.setFillColor(theme.primaryText.withAlphaComponent(0.12).cgColor)
        for star in stars {
            context.fillEllipse(in: CGRect(x: star.x, y: star.y, width: 3, height: 3))
        }
    }

    private static func drawVineDecorations(theme: ShareCardTheme, in context: CGContext) {
        let borderRect = CGRect(x: 8, y: 8, width: 344, height: 344)
        context.setStrokeColor(theme.primaryText.withAlphaComponent(0.25).cgColor)
        context.setLineWidth(0.8)
        context.stroke(borderRect)
    }

    private static func drawVSCOFade(theme: ShareCardTheme, in context: CGContext) {
        let bloomCenter = CGPoint(x: 310, y: 40)
        let colors = [UIColor.white.withAlphaComponent(0.12).cgColor, UIColor.clear.cgColor] as CFArray
        let locations: [CGFloat] = [0, 1]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
            context.drawRadialGradient(
                gradient,
                startCenter: bloomCenter,
                startRadius: 0,
                endCenter: bloomCenter,
                endRadius: 80,
                options: [])
        }
    }

    private static func drawVSCODecorations(theme: ShareCardTheme, in context: CGContext) {
        let leafConfig = UIImage.SymbolConfiguration(pointSize: 56, weight: .regular)
        if let leaf = UIImage(systemName: "leaf", withConfiguration: leafConfig)?.withTintColor(theme.primaryText.withAlphaComponent(0.10), renderingMode: .alwaysOriginal) {
            leaf.draw(in: CGRect(x: 24, y: 256, width: 72, height: 72))
        }
    }

    private static func drawDarkAestheticDecorations(theme: ShareCardTheme, in context: CGContext) {
        let red = UIColor(hex: "#8B1A1A").withAlphaComponent(0.60)
        let colors = [red.cgColor, UIColor.clear.cgColor] as CFArray
        let locations: [CGFloat] = [0, 1]
        let origin = CGPoint(x: 0, y: 360)
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
            context.drawRadialGradient(
                gradient,
                startCenter: origin,
                startRadius: 0,
                endCenter: origin,
                endRadius: 180,
                options: [])
        }

        context.setStrokeColor(theme.primaryText.withAlphaComponent(0.07).cgColor)
        context.setLineWidth(0.4)
        context.beginPath()
        context.move(to: CGPoint(x: 60, y: 40))
        context.addLine(to: CGPoint(x: 300, y: 80))
        context.addLine(to: CGPoint(x: 180, y: 180))
        context.closePath()
        context.strokePath()

        context.beginPath()
        context.move(to: CGPoint(x: 80, y: 20))
        context.addLine(to: CGPoint(x: 320, y: 100))
        context.addLine(to: CGPoint(x: 200, y: 200))
        context.closePath()
        context.strokePath()
    }

    private static func drawQuietLuxuryDecorations(theme: ShareCardTheme, in context: CGContext) {
        let borderRect = CGRect(x: 14, y: 14, width: 332, height: 332)
        context.setStrokeColor(theme.primaryText.withAlphaComponent(0.18).cgColor)
        context.setLineWidth(0.5)
        context.stroke(borderRect)
    }

    private static func drawGrainOverlay(in context: CGContext, alpha: CGFloat) {
        guard let random = CIFilter(name: "CIRandomGenerator")?.outputImage else { return }
        let rect = CGRect(origin: .zero, size: logicalSize)
        let crop = random.cropped(to: rect)
        let ciContext = CIContext(options: [.workingColorSpace: NSNull()])
        guard let cg = ciContext.createCGImage(crop, from: rect) else { return }
        context.saveGState()
        context.setAlpha(alpha)
        context.draw(cg, in: rect)
        context.restoreGState()
    }

    private static func excerpt(for blurb: String) -> String {
        let components = blurb.split(separator: ".")
        if components.isEmpty { return blurb }
        let joined = components.prefix(2).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.joined(separator: ". ")
        return joined + "."
    }

    private static func theme(for era: EraID) -> ShareCardTheme {
        switch era {
        case .tumblrRomantic:
            return ShareCardTheme(
                id: era,
                yearsLabel: "2011–2014",
                backgroundTop: UIColor(hex: "#4A1942"),
                backgroundMid: UIColor(hex: "#321230"),
                backgroundBottom: UIColor(hex: "#1A0818"),
                primaryText: UIColor(hex: "#F0EAF5"),
                secondaryText: UIColor(hex: "#BFA7D8"),
                yearsBadgeBackground: UIColor.white.withAlphaComponent(0.10),
                yearsBadgeText: UIColor(hex: "#F0EAF5"),
                ruleColor: UIColor(hex: "#BFA7D8").withAlphaComponent(0.20),
                titleFont: .systemFont(ofSize: 48, weight: .ultraLight).withDesign(.serif),
                taglineFont: .systemFont(ofSize: 13, weight: .light).withDesign(.serif),
                blurbFont: .systemFont(ofSize: 11.5, weight: .light).withDesign(.serif),
                yearsFont: .systemFont(ofSize: 10, weight: .light).withDesign(.serif),
                wordmarkFont: .monospacedSystemFont(ofSize: 10, weight: .medium),
                footerFont: .monospacedSystemFont(ofSize: 9, weight: .light),
                taglineKern: 1.5,
                taglineTransform: { $0.lowercased() },
                chaosBlocks: nil)
        case .vineChaosAgent:
            return ShareCardTheme(
                id: era,
                yearsLabel: "2014–2017",
                backgroundTop: UIColor(hex: "#FF5722"),
                backgroundMid: UIColor(hex: "#FF5722"),
                backgroundBottom: UIColor(hex: "#FF5722"),
                primaryText: UIColor(hex: "#111111"),
                secondaryText: UIColor(hex: "#333333"),
                yearsBadgeBackground: UIColor(hex: "#111111"),
                yearsBadgeText: .white,
                ruleColor: UIColor(hex: "#111111").withAlphaComponent(0.25),
                titleFont: .systemFont(ofSize: 44, weight: .black),
                taglineFont: .systemFont(ofSize: 13, weight: .heavy),
                blurbFont: .systemFont(ofSize: 11, weight: .medium),
                yearsFont: .systemFont(ofSize: 10, weight: .black),
                wordmarkFont: .monospacedSystemFont(ofSize: 10, weight: .medium),
                footerFont: .monospacedSystemFont(ofSize: 9, weight: .light),
                taglineKern: 1.8,
                taglineTransform: { $0.uppercased() },
                chaosBlocks: [
                    ColorBlock(rect: CGRect(x: 0, y: 0, width: 130, height: 100), color: UIColor(hex: "#FFC107")),
                    ColorBlock(rect: CGRect(x: 240, y: 280, width: 120, height: 80), color: UIColor(hex: "#1565C0")),
                    ColorBlock(rect: CGRect(x: 0, y: 160, width: 60, height: 70), color: UIColor(hex: "#43A047")),
                    ColorBlock(rect: CGRect(x: 310, y: 40, width: 50, height: 100), color: UIColor(hex: "#E91E63"))
                ])
        case .vscoNaturalist:
            return ShareCardTheme(
                id: era,
                yearsLabel: "2017–2020",
                backgroundTop: UIColor(hex: "#F0E4CC"),
                backgroundMid: UIColor(hex: "#D4B88A"),
                backgroundBottom: UIColor(hex: "#A0784A"),
                primaryText: UIColor(hex: "#2C1A0E"),
                secondaryText: UIColor(hex: "#5C3D22"),
                yearsBadgeBackground: UIColor(hex: "#2C1A0E").withAlphaComponent(0.10),
                yearsBadgeText: UIColor(hex: "#2C1A0E"),
                ruleColor: UIColor(hex: "#2C1A0E").withAlphaComponent(0.14),
                titleFont: .systemFont(ofSize: 44, weight: .semibold).withDesign(.rounded),
                taglineFont: .systemFont(ofSize: 13, weight: .medium).withDesign(.rounded),
                blurbFont: .systemFont(ofSize: 11.5, weight: .regular).withDesign(.rounded),
                yearsFont: .systemFont(ofSize: 10, weight: .medium).withDesign(.rounded),
                wordmarkFont: .monospacedSystemFont(ofSize: 10, weight: .medium),
                footerFont: .monospacedSystemFont(ofSize: 9, weight: .light),
                taglineKern: 0.8,
                taglineTransform: { $0.lowercased() },
                chaosBlocks: nil)
        case .darkAesthetic:
            return ShareCardTheme(
                id: era,
                yearsLabel: "2019–2022",
                backgroundTop: UIColor(hex: "#2C1B18"),
                backgroundMid: UIColor(hex: "#1E1311"),
                backgroundBottom: UIColor(hex: "#120B09"),
                primaryText: UIColor(hex: "#E8E0D8"),
                secondaryText: UIColor(hex: "#9A9090"),
                yearsBadgeBackground: UIColor(hex: "#8B1A1A"),
                yearsBadgeText: UIColor(hex: "#E8E0D8"),
                ruleColor: UIColor(hex: "#C43C3C").withAlphaComponent(0.35),
                titleFont: .systemFont(ofSize: 50, weight: .light).withDesign(.serif),
                taglineFont: .systemFont(ofSize: 13, weight: .light).withDesign(.serif),
                blurbFont: .systemFont(ofSize: 11.5, weight: .light).withDesign(.serif),
                yearsFont: .systemFont(ofSize: 10, weight: .medium),
                wordmarkFont: .monospacedSystemFont(ofSize: 10, weight: .medium),
                footerFont: .monospacedSystemFont(ofSize: 9, weight: .light),
                taglineKern: 3,
                taglineTransform: { $0.uppercased() },
                chaosBlocks: nil)
        case .quietLuxury:
            return ShareCardTheme(
                id: era,
                yearsLabel: "2022–present",
                backgroundTop: UIColor(hex: "#F5F0E8"),
                backgroundMid: UIColor(hex: "#EDE7DC"),
                backgroundBottom: UIColor(hex: "#D4C5B0"),
                primaryText: UIColor(hex: "#1A1612"),
                secondaryText: UIColor(hex: "#6B6058"),
                yearsBadgeBackground: UIColor(hex: "#1A1612").withAlphaComponent(0.07),
                yearsBadgeText: UIColor(hex: "#1A1612"),
                ruleColor: UIColor(hex: "#1A1612").withAlphaComponent(0.12),
                titleFont: .systemFont(ofSize: 42, weight: .ultraLight),
                taglineFont: .systemFont(ofSize: 12, weight: .ultraLight),
                blurbFont: .systemFont(ofSize: 11.5, weight: .light),
                yearsFont: .systemFont(ofSize: 10, weight: .light),
                wordmarkFont: .monospacedSystemFont(ofSize: 10, weight: .ultraLight),
                footerFont: .monospacedSystemFont(ofSize: 9, weight: .light),
                taglineKern: 3.2,
                taglineTransform: { $0.uppercased() },
                chaosBlocks: nil)
        }
    }
}

private struct ColorBlock {
    let rect: CGRect
    let color: UIColor
}

private struct ShareCardTheme {
    let id: EraID
    let yearsLabel: String
    let backgroundTop: UIColor
    let backgroundMid: UIColor
    let backgroundBottom: UIColor
    let primaryText: UIColor
    let secondaryText: UIColor
    let yearsBadgeBackground: UIColor
    let yearsBadgeText: UIColor
    let ruleColor: UIColor
    let titleFont: UIFont
    let taglineFont: UIFont
    let blurbFont: UIFont
    let yearsFont: UIFont
    let wordmarkFont: UIFont
    let footerFont: UIFont
    let taglineKern: CGFloat
    let taglineTransform: (String) -> String
    let chaosBlocks: [ColorBlock]?
}

private extension UIColor {
    convenience init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: value).scanHexInt64(&int)
        self.init(
            red: CGFloat((int >> 16) & 0xFF) / 255.0,
            green: CGFloat((int >> 8) & 0xFF) / 255.0,
            blue: CGFloat(int & 0xFF) / 255.0,
            alpha: 1)
    }
}

private extension UIFont {
    func withDesign(_ design: UIFontDescriptor.SystemDesign) -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(design) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
