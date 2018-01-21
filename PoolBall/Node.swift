/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import Metal
import QuartzCore
import simd

struct Vertex {
  
  var x,y,z: Float     // position data
  var r,g,b,a: Float   // color data
  var s,t: Float       // texture coordinates
  var nX,nY,nZ: Float  // normal
  
  func floatBuffer() -> [Float] {
    return [x,y,z,r,g,b,a,s,t,nX,nY,nZ]
  }
  
};




class Node {
  
  var time:CFTimeInterval = 0.0
  
  let name: String
  let light = Light(color: (1.0,1.0,1.0), ambientIntensity: 0.1, direction: (0.0, 0.0, 1.0), diffuseIntensity: 0.8, shininess: 10, specularIntensity: 2)
  
  var vertexCount: Int
  var vertexBuffer: MTLBuffer
  var device: MTLDevice
  
  var positionX:Float = 0.0
  var positionY:Float = 0.0
  var positionZ:Float = 0.0
  
  var rotationX:Float = 0.0
  var rotationY:Float = 0.0
  var rotationZ:Float = 0.0
  var scale:Float     = 1.0
  
  var bufferProvider: BufferProvider
  var texture: MTLTexture! = nil
  lazy var samplerState: MTLSamplerState? = Node.defaultSampler(self.device)
  
  init(name: String, vertices: Array<Vertex>, device: MTLDevice, texture: MTLTexture) {
    
    var vertexData = Array<Float>()
    for vertex in vertices{
      vertexData += vertex.floatBuffer()
    }
  
    let dataSize = vertexData.count * MemoryLayout<Float>.size
    vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: MTLResourceOptions())
    
    self.name = name
    self.device = device
    vertexCount = vertices.count
    self.texture = texture
    
    self.bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3)
  }
  
  init(name: String, vertices: Array<Vertex>, device: MTLDevice){
        var vertexData = Array<Float>()
        for vertex in vertices{
            vertexData += vertex.floatBuffer()
        }
        
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
        
        self.name     = name
        self.device   = device
        vertexCount   = vertices.count
        self.texture  = nil
    
    self.bufferProvider = BufferProvider(device: device, inflightBuffersCount: 3)
    }
    
    
  func render(_ commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: float4x4, projectionMatrix: float4x4, clearColor: MTLClearColor?) {
    
    let _ = bufferProvider.avaliableResourcesSemaphore.wait(timeout: DispatchTime.distantFuture)
    
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    renderPassDescriptor.colorAttachments[0].storeAction = .store
    
    let commandBuffer = commandQueue.makeCommandBuffer()
    commandBuffer.addCompletedHandler { (commandBuffer) -> Void in
      self.bufferProvider.avaliableResourcesSemaphore.signal()
    }
    
    let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    renderEncoder.setCullMode(MTLCullMode.front)
    
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
    renderEncoder.setFragmentTexture(texture, at: 0)
    if let samplerState = samplerState {
      renderEncoder.setFragmentSamplerState(samplerState, at: 0)
    }
    
    var nodeModelMatrix = self.modelMatrix()
    nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
    
    let uniformBuffer = bufferProvider.nextUniformsBuffer(projectionMatrix, modelViewMatrix: nodeModelMatrix, light: light)
    
    renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
    renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, at: 1)
    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    renderEncoder.endEncoding()
    
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  func modelMatrix() -> float4x4 {
    var matrix = float4x4()
    matrix.translate(positionX, y: positionY, z: positionZ)
    matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
    matrix.scale(scale, y: scale, z: scale)
    return matrix
  }
  
  func updateWithDelta(_ delta: CFTimeInterval) {
    time += delta
  }
  
  class func defaultSampler(_ device: MTLDevice) -> MTLSamplerState {
    let pSamplerDescriptor:MTLSamplerDescriptor? = MTLSamplerDescriptor();
    
    if let sampler = pSamplerDescriptor {
      sampler.minFilter             = MTLSamplerMinMagFilter.nearest
      sampler.magFilter             = MTLSamplerMinMagFilter.nearest
      sampler.mipFilter             = MTLSamplerMipFilter.nearest
      sampler.maxAnisotropy         = 1
      sampler.sAddressMode          = MTLSamplerAddressMode.clampToEdge
      sampler.tAddressMode          = MTLSamplerAddressMode.clampToEdge
      sampler.rAddressMode          = MTLSamplerAddressMode.clampToEdge
      sampler.normalizedCoordinates = true
      sampler.lodMinClamp           = 0
      sampler.lodMaxClamp           = FLT_MAX
    }
    else {
      print(">> ERROR: Failed creating a sampler descriptor!")
    }
    return device.makeSamplerState(descriptor: pSamplerDescriptor!)
  }
  
  
}
