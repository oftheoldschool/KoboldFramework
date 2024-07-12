import MetalKit

struct ExampleBasicUniforms {
    let time: Float
    let aspect: Float
}

class ExampleBasicRenderer: NSObject {
    static let maxFramesInFlight: Int = 3
    
    var sysLink: KSysLink
    var device: MTLDevice

    var applicationFinishedLaunching: Bool
    var bounds: (width: Float, height: Float)
    var commandQueue: MTLCommandQueue
    var library: MTLLibrary!
    var exampleBasicShader: ExampleBasicShader
    
    // MARK: - Renderer Variables
    let inflightSemaphore: DispatchSemaphore
    
    // MARK: - Renderer State
    var currentFrame: Int
    
    init(sysLink: KSysLink) {
        self.sysLink = sysLink
        self.currentFrame = 0

        self.applicationFinishedLaunching = false
        self.bounds = (width: .zero, height: .zero)
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = self.device.makeCommandQueue()!
        self.inflightSemaphore = DispatchSemaphore(value: ExampleBasicRenderer.maxFramesInFlight)
        do {
            self.library = try self.device.makeLibrary(
                source: ExampleBasicShader.getShader(includeHeader: true), 
                options: nil)
        } catch {
            fatalError(error.localizedDescription)
        }

        self.exampleBasicShader = ExampleBasicShader(device, library)
    }

    func draw(
        frameData: KFrameData
    ) {
        if inflightSemaphore.wait(timeout: DispatchTime.distantFuture) == .timedOut {
            fatalError("Unable to acquire semaphore for frame")
        }

        guard let view = sysLink.view else {
            fatalError("No MTKView available")
        }
        
        var uniforms = ExampleBasicUniforms(
            time: Float(frameData.elapsedTime),
            aspect: Float(bounds.width) / Float(bounds.height))
        
        currentFrame = (currentFrame + 1) % Self.maxFramesInFlight
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        guard let drawable = view.currentDrawable, let outputRenderPassDescriptor = view.currentRenderPassDescriptor
        else {
            return
        }
        
        if let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: outputRenderPassDescriptor) {
            
            commandEncoder.setCullMode(.none)
            commandEncoder.setFrontFacing(.clockwise)
            commandEncoder.setRenderPipelineState(exampleBasicShader.pipeline)
            commandEncoder.setVertexBytes(&uniforms, length: MemoryLayout<ExampleBasicUniforms>.stride, index: 0)
            commandEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<ExampleBasicUniforms>.stride, index: 0)

            commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            
            commandEncoder.endEncoding()
        }
        commandBuffer.present(drawable)
        
        let blockSemaphore = inflightSemaphore
        commandBuffer.addCompletedHandler { _ in
            blockSemaphore.signal()
        }
        commandBuffer.commit()
    }
}
