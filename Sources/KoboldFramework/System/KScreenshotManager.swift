import SwiftUI
import MetalKit
import Metal
import UIKit
import Photos
import UniformTypeIdentifiers

@MainActor
public class KScreenshotManager: ObservableObject {
    private weak var sysLink: KSysLink?

    public func configure(sysLink: KSysLink) {
        self.sysLink = sysLink
    }
    
    public func captureScreenshot() -> UIImage? {
        guard let sysLink = sysLink else { return nil }
        guard let metalView = sysLink.getMtkView() else { return nil }
        return captureMetalKitView(metalView)
    }
    
    private func captureMetalKitView(_ metalKitView: MTKView) -> UIImage? {
        if metalKitView.bounds.width <= 0 || metalKitView.bounds.height <= 0 {
            return nil
        }
        
        if metalKitView.framebufferOnly {
            return nil
        }
        
        metalKitView.setNeedsDisplay()
        metalKitView.draw()
        
        guard let drawable = metalKitView.currentDrawable else { return nil }
        return captureDrawableTexture(drawable.texture)
    }
    
    private func captureDrawableTexture(_ texture: MTLTexture) -> UIImage? {
        let width = texture.width
        let height = texture.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bufferSize = height * bytesPerRow
        
        guard width > 0 && height > 0 else { return nil }
        
        guard let buffer = malloc(bufferSize) else { return nil }
        defer { free(buffer) }
        
        texture.getBytes(buffer,
                        bytesPerRow: bytesPerRow,
                        from: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                                      size: MTLSize(width: width, height: height, depth: 1)),
                        mipmapLevel: 0)

        let colorSpace: CGColorSpace
        let bitmapInfo: CGBitmapInfo
        
        switch texture.pixelFormat {
        case .bgra8Unorm, .bgra8Unorm_srgb:
            colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
            
        case .rgba8Unorm, .rgba8Unorm_srgb:
            colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            
        case .rgba16Float, .rgb10a2Unorm, .bgra10_xr, .bgr10_xr:
            colorSpace = CGColorSpace(name: CGColorSpace.displayP3) ??
                        CGColorSpace(name: CGColorSpace.sRGB)!
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
            
        default:
            colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        }
        
        guard let context = CGContext(data: buffer,
                                     width: width,
                                     height: height,
                                     bitsPerComponent: 8,
                                     bytesPerRow: bytesPerRow,
                                     space: colorSpace,
                                     bitmapInfo: bitmapInfo.rawValue) else { return nil }
        
        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    public func saveScreenshot(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        #if targetEnvironment(macCatalyst)
        saveToFile(image: image, completion: completion)
        #else
        saveToPhotos(image: image, completion: completion)
        #endif
    }
    
    private func saveToPhotos(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            performSave(image: image, completion: completion)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.performSave(image: image, completion: completion)
                    } else {
                        completion(false, PhotoSaveError.accessDenied)
                    }
                }
            }
        case .denied, .restricted:
            completion(false, PhotoSaveError.accessDenied)
        @unknown default:
            completion(false, PhotoSaveError.unknown)
        }
    }
    
    #if targetEnvironment(macCatalyst)
    private func saveToFile(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let timestamp = formatter.string(from: Date())
        let fileName = "Screenshot \(timestamp).png"
        
        let fileManager = FileManager.default
        var saveURL: URL?
        
        if let picturesURL = fileManager.urls(for: .picturesDirectory, in: .userDomainMask).first {
            saveURL = picturesURL.appendingPathComponent(fileName)
        }
        
        guard let finalURL = saveURL else {
            completion(false, PhotoSaveError.noValidSaveLocation)
            return
        }
        
        do {
            if let data = image.pngData() {
                try data.write(to: finalURL)
                completion(true, nil)
            } else {
                completion(false, PhotoSaveError.imageConversionFailed)
            }
        } catch {
            completion(false, error)
        }
    }
    #endif
    
    private func performSave(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCreationRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
}

private enum PhotoSaveError: Error, LocalizedError {
    case accessDenied
    case noValidSaveLocation
    case imageConversionFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to Photos library was denied"
        case .noValidSaveLocation:
            return "Could not find a valid location to save the screenshot"
        case .imageConversionFailed:
            return "Failed to convert image to PNG format"
        case .unknown:
            return "An unknown error occurred while saving"
        }
    }
}

public struct KScreenshotButtonConfig {
    public let customAction: ((UIImage) -> Void)?
    
    public init(customAction: ((UIImage) -> Void)? = nil) {
        self.customAction = customAction
    }
}
