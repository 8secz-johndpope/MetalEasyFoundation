import Foundation
import Metal

// OpenGL uses a bottom-left origin while Metal uses a top-left origin.
public let standardImageVertices:[Float] = [-1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 1.0, -1.0]

extension MTLCommandBuffer {
    func renderQuad(pipelineState:MTLRenderPipelineState, uniformSettings:ShaderUniformSettings? = nil, vertexUniformSettings: ShaderUniformSettings? = nil, inputTextures:[UInt:Texture], useNormalizedTextureCoordinates:Bool = true, imageVertices:[Float] = standardImageVertices, outputTexture:Texture, outputOrientation:ImageOrientation = .portrait, textureCoordinates: [Float] = standardImageVertices) {
        let vertexBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: imageVertices,
                                                                        length: imageVertices.count * MemoryLayout<Float>.size,
                                                                        options: [])!
        vertexBuffer.label = "Vertices"
        
        
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = outputTexture.texture
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(240.0/255.0, 240.0/255.0, 240.0/255.0, 1)
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].loadAction = .clear
        
        guard let renderEncoder = self.makeRenderCommandEncoder(descriptor: renderPass) else {
            fatalError("Could not create render encoder")
        }
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        for textureIndex in 0..<inputTextures.count {
            let currentTexture = inputTextures[UInt(textureIndex)]!
            
            let inputTextureCoordinates = currentTexture.textureCoordinates(for:outputOrientation, normalized:useNormalizedTextureCoordinates)
            let textureBuffer = sharedMetalRenderingDevice.device.makeBuffer(bytes: textureCoordinates == standardImageVertices ? inputTextureCoordinates : textureCoordinates,
                                                                             length: (textureCoordinates == standardImageVertices ? inputTextureCoordinates : textureCoordinates).count * MemoryLayout<Float>.size,
                                                                             options: [])!
            textureBuffer.label = "Texture Coordinates"

            renderEncoder.setVertexBuffer(textureBuffer, offset: 0, index: 1 + textureIndex)
            renderEncoder.setFragmentTexture(currentTexture.texture, index: textureIndex)
        }
        uniformSettings?.restoreShaderSettings(renderEncoder: renderEncoder)
        vertexUniformSettings?.restoreVertexShaderSettings(renderEncoder: renderEncoder)
//        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: imageVertices.count / 2)
        renderEncoder.endEncoding()
    }
}

func generateRenderPipelineState(device:MetalRenderingDevice, vertexFunctionName:String, fragmentFunctionName:String, operationName:String) -> (MTLRenderPipelineState, [String:(Int, MTLDataType)], [String:(Int, MTLDataType)]) {
    guard let vertexFunction = device.shaderLibrary.makeFunction(name: vertexFunctionName) else {
        fatalError("\(operationName): could not compile vertex function \(vertexFunctionName)")
    }
    
    guard let fragmentFunction = device.shaderLibrary.makeFunction(name: fragmentFunctionName) else {
        fatalError("\(operationName): could not compile fragment function \(fragmentFunctionName)")
    }
    
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
    descriptor.rasterSampleCount = 1
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    
    do {
        var reflection:MTLAutoreleasedRenderPipelineReflection?
        let pipelineState = try device.device.makeRenderPipelineState(descriptor: descriptor, options: [.bufferTypeInfo, .argumentInfo], reflection: &reflection)

        var uniformLookupTable:[String:(Int, MTLDataType)] = [:]
        if let fragmentArguments = reflection?.fragmentArguments {
            for fragmentArgument in fragmentArguments where fragmentArgument.type == .buffer {
                if (fragmentArgument.bufferDataType == .struct) {
                    for (index, uniform) in (fragmentArgument.bufferStructType?.members ?? []).enumerated() {
                        uniformLookupTable[uniform.name] = (index, uniform.dataType)
                    }
                }
            }
        }
        
        var vertexUniformLookupTable:[String:(Int, MTLDataType)] = [:]
        if let vertexArguments = reflection?.vertexArguments {
            for vertexArgument in vertexArguments where vertexArgument.type == .buffer {
                if (vertexArgument.bufferDataType == .struct) {
                    for (index, uniform) in (vertexArgument.bufferStructType?.members ?? []).enumerated() {
                        vertexUniformLookupTable[uniform.name] = (index, uniform.dataType)
                    }
                }
            }
        }
        
        return (pipelineState, uniformLookupTable, vertexUniformLookupTable)
    } catch {
        fatalError("Could not create render pipeline state for vertex:\(vertexFunctionName), fragment:\(fragmentFunctionName), error:\(error)")
    }
}
