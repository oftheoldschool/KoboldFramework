import Metal
@_implementationOnly import KoboldLogging

class ExampleBasicShader {
    private static let shaderCode = """
        struct ExampleBasicVertexInput {
            float2 pos;
            float2 st;
        };
    
        struct ExampleBasicFragmentInput {
            float4 pos [[ position ]];
            float2 st;
        };
    
        struct ExampleBasicUniforms {
            float time;
            float aspect;
        };
    
        constant ExampleBasicVertexInput exampleVertices[4] = {
            { {-1, -1}, { 0, 0} },
            { {-1, 1}, {0, 1} },
            { {1, 1}, {1, 1} },
            { {1, -1}, {1, 0} },
        };
    
        constant int exampleIndices[6] = {
            0, 1, 2, 0, 2, 3,
        };
    
        vertex ExampleBasicFragmentInput example_basic_shader_vertex(
            uint vertexID                            [[vertex_id]],
            constant ExampleBasicUniforms & uniforms [[buffer(0)]]
        ) {
            ExampleBasicVertexInput vIn = exampleVertices[exampleIndices[vertexID]];
            return { float4(vIn.pos, 0, 1), vIn.st };
        }
    
        fragment float4 example_basic_shader_fragment(
            ExampleBasicFragmentInput fIn            [[stage_in]],
            constant ExampleBasicUniforms & uniforms [[buffer(0)]]
        ) {
            return float4((sin(uniforms.time) + 1) / 2, fIn.st.x, fIn.st.y, 1.f);
        }
    """

    var pipeline: MTLRenderPipelineState!

    init(
        _ device: MTLDevice,
        _ library: MTLLibrary
    ) {
        self.pipeline = Self.createPipeline(device, library)
    }

    static func getShader(includeHeader: Bool = false) -> String {
        let header = """
            #include <metal_stdlib>
            using namespace metal;
        """
        return """
            \(includeHeader ? header : "")
        
            \(Self.shaderCode)
        
        """
    }

    static func createPipeline(
        _ device: MTLDevice,
        _ library: MTLLibrary
    ) -> MTLRenderPipelineState {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Example Basic Pipeline"
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "example_basic_shader_vertex")!
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "example_basic_shader_fragment")!

        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        var pipelineState: MTLRenderPipelineState
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            kfatal("Error creating Example Basic pipeline", error)
        }
        return pipelineState
    }
}
