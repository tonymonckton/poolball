//
//  Sphere.swift
//  HelloMetal
//
//  Created by Tony Monckton on 28/12/2017.
//
//

import UIKit
import MetalKit

class Sphere: Node {
  
  init(device: MTLDevice, commandQ: MTLCommandQueue, textureLoader :MTKTextureLoader) {

    // create sphere vertices
    let layer_size:Int  = 128
    let circum_size:Int = 128
    let radius          = 1.6
    let circCnt:Int     = circum_size;
    let circCnt_2:Int   = circCnt / 2;
    let layerCount:Int  = layer_size;

    var vArray:Array<Vertex> = []
    var verticesArray:Array<Vertex> = []
  
    var tbInx = 0
    while tbInx <= layerCount {
      let v:Double         = ( 1.0 - (Double(tbInx) / Double(layerCount)) )
      let a:Double         = ( 1.0 - 2.0 * Double(tbInx) / Double(layerCount) )
      let heightFac:Double = sin(a * (M_PI/2.0))
      let cosUp:Double     = sqrt( 1.0 - heightFac * heightFac )
      let z:Double        = heightFac
      
      var i:Int = 0
      while i <= circCnt_2 {
        let u:Double     = Double(i)/Double(circCnt_2)
        let a:Double     = M_PI * Double(u)
        let x:Double     = cos(a) * cosUp
        let y:Double     = sin(a) * cosUp
        vArray.append( Vertex(x: Float(x*radius), y: Float(y*radius), z: Float(z*radius), r: 1.0, g: 1.0, b: 1.0, a: 1.0, s: Float(u), t: Float(v), nX: Float(x), nY: Float(y), nZ: Float(z)  ) )
        i += 1
      }
      
      i = 0
      while i <= circCnt_2 {
        let u:Double = Double(i)/Double(circCnt_2)
        let a:Double = M_PI * u + M_PI
        let x:Double = cos(a) * cosUp
        let y:Double = sin(a) * cosUp
        vArray.append( Vertex(x: Float(x*radius), y: Float(y*radius), z: Float(z*radius), r: 1.0, g: 1.0, b: 1.0, a: 1.0, s: Float(u), t: Float(v), nX: Float(x), nY: Float(y), nZ: Float(z)  ) )
        i += 1
      }
      tbInx += 1
    }
    // south pole
    let circSize_2  = circCnt_2 + 1
    let circSize    = circSize_2 * 2
    
    for i in 0 ..< circCnt_2 {
//      AddFace( circSize + i, circSize + i + 1, i )
        verticesArray.append( vArray[circSize + i] )
        verticesArray.append( vArray[circSize + i + 1] )
        verticesArray.append( vArray[i] )
    }
    for i in (circCnt_2+1) ..< (2*circCnt_2+1) {
//      AddFace( circSize + i, circSize + i + 1, i )
        verticesArray.append( vArray[circSize + i] )
        verticesArray.append( vArray[circSize + i + 1] )
        verticesArray.append( vArray[i] )
    }
    
    // front hemisphere
    for tbInx2 in 1 ..< (layerCount - 1) {
      var ringStart     = tbInx2 * circSize
      var nextRingStart = (tbInx2+1) * circSize
      for i in 0 ..< circCnt_2 {
        verticesArray.append( vArray[ringStart + i] )
        verticesArray.append( vArray[nextRingStart + i] )
        verticesArray.append( vArray[nextRingStart + i + 1] )
        
        verticesArray.append( vArray[ringStart + i] )
        verticesArray.append( vArray[nextRingStart + i + 1] )
        verticesArray.append( vArray[ringStart + i + 1] )
      }

      // back hemisphere
      ringStart += circSize_2
      nextRingStart += circSize_2
      for i in 0 ..< circCnt_2 {
          verticesArray.append( vArray[ringStart + i] )
          verticesArray.append( vArray[nextRingStart + i] )
          verticesArray.append( vArray[nextRingStart + i + 1] )

          verticesArray.append( vArray[ringStart + i] )
          verticesArray.append( vArray[nextRingStart + i + 1] )
          verticesArray.append( vArray[ringStart + i + 1] )
      }
    }

    // north pole
    let start:Int = (layerCount-1) * circSize;
    for i in 0 ..< circCnt_2 {
        verticesArray.append( vArray[start + i + 1] )
        verticesArray.append( vArray[start + i] )
        verticesArray.append( vArray[start + i + circSize] )
    }
    for i in circCnt_2+1 ..< 2*circCnt_2+1 {
        verticesArray.append( vArray[start + i + 1] )
        verticesArray.append( vArray[start + i] )
        verticesArray.append( vArray[start + i + circSize] )
    }
    
    print ( "vArray vertices:", vArray.count )
    print ( "vArray: tris", vArray.count/3 )
    
    let path    = Bundle.main.path(forResource: "10ball", ofType: "png")!
    let data    = NSData(contentsOfFile: path) as! Data
    let texture = try! textureLoader.newTexture(with: data, options: [MTKTextureLoaderOptionSRGB : (false as NSNumber)])
    
    super.init(name: "Sphere", vertices: verticesArray, device: device, texture: texture)
  }
  
  override func updateWithDelta(_ delta: CFTimeInterval) {
    
    super.updateWithDelta(delta)
    
    let secsPerMove: Float = 6.0
    rotationY = sinf( Float(time) * 2.0 * Float(M_PI) / secsPerMove)
    rotationX = sinf( Float(time) * 2.0 * Float(M_PI) / secsPerMove)
  }
  
  
}
