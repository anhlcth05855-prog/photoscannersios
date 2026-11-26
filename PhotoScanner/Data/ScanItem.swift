import Foundation
import CoreGraphics

public enum FilterType: String, Codable, CaseIterable {
    case original = "ORIGINAL"
    case colorRevive = "COLOR_REVIVE"
    case magicColor = "CAMSCANNER_MAGIC_COLOR"
    case vintageWarm = "VINTAGE_WARM"
    case polaroidRetro = "POLAROID_RETRO"
    case kodachrome = "KODACHROME"
    case blackAndWhite = "BLACK_AND_WHITE"
    case sepia = "SEPIA"
    case docHighContrast = "DOCUMENT_HIGH_CONTRAST"

    public var displayName: String {
        switch self {
        case .original: return "Gốc"
        case .colorRevive: return "Color Revive"
        case .magicColor: return "Magic Color"
        case .vintageWarm: return "Vintage Film"
        case .polaroidRetro: return "Polaroid"
        case .kodachrome: return "Kodachrome"
        case .blackAndWhite: return "B&W"
        case .sepia: return "Sepia"
        case .docHighContrast: return "Doc / Tài Liệu"
        }
    }
}

public struct ScanItem: Identifiable, Codable, Hashable {
    public var id: String
    public var originalImagePath: String
    public var croppedImagePath: String
    public var enhancedImagePath: String
    public var timestamp: Int64
    public var title: String
    public var quad: Quad?
    public var filterType: FilterType
    public var isGlareRemoved: Bool
    public var isShadowRemoved: Bool
    public var isColorRevived: Bool
    public var isSharpened: Bool
    public var isBWColorized: Bool
    public var rotationDegrees: Float
    
    // Photo story / metadata matching Photo Scanner Plus
    public var year: String
    public var location: String
    public var people: String
    public var story: String
    
    // Manual adjustments
    public var brightness: Float // -50 to +50
    public var contrast: Float   // 0.5 to 1.5
    public var saturation: Float // 0.0 to 2.0
    public var warmth: Float     // -30 to +30
    
    // Retro film effects
    public var dateStampText: String
    public var hasFilmGrain: Bool

    public init(
        id: String = UUID().uuidString,
        originalImagePath: String = "",
        croppedImagePath: String = "",
        enhancedImagePath: String = "",
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        title: String = "Photo Scan",
        quad: Quad? = nil,
        filterType: FilterType = .original,
        isGlareRemoved: Bool = false,
        isShadowRemoved: Bool = false,
        isColorRevived: Bool = false,
        isSharpened: Bool = false,
        isBWColorized: Bool = false,
        rotationDegrees: Float = 0,
        year: String = "",
        location: String = "",
        people: String = "",
        story: String = "",
        brightness: Float = 0,
        contrast: Float = 1.0,
        saturation: Float = 1.0,
        warmth: Float = 0,
        dateStampText: String = "",
        hasFilmGrain: Bool = false
    ) {
        self.id = id
        self.originalImagePath = originalImagePath
        self.croppedImagePath = croppedImagePath
        self.enhancedImagePath = enhancedImagePath
        self.timestamp = timestamp
        self.title = title
        self.quad = quad
        self.filterType = filterType
        self.isGlareRemoved = isGlareRemoved
        self.isShadowRemoved = isShadowRemoved
        self.isColorRevived = isColorRevived
        self.isSharpened = isSharpened
        self.isBWColorized = isBWColorized
        self.rotationDegrees = rotationDegrees
        self.year = year
        self.location = location
        self.people = people
        self.story = story
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.warmth = warmth
        self.dateStampText = dateStampText
        self.hasFilmGrain = hasFilmGrain
    }
}
