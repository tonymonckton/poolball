/**
 * Copyright (c)
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

import UIKit
import simd

class MySceneViewController: MetalViewController, MetalViewControllerDelegate {
  
  var worldModelMatrix:float4x4! = nil
  var mSphere:Sphere! = nil
  let panSensivity:Float = 5.0
  var lastPanLocation: CGPoint!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    worldModelMatrix = float4x4()
    worldModelMatrix.translate(0.0, y: 0.0, z: -4)
    worldModelMatrix.rotateAroundX(float4x4.degrees(toRad: 0), y: 0.0, z: 0.0)
    
    mSphere = Sphere(device: device, commandQ: commandQueue, textureLoader: textureLoader)
    
    self.metalViewControllerDelegate = self
    
    setupGestures()
  }
  
  //MARK: - MetalViewControllerDelegate
  func renderObjects(_ drawable:CAMetalDrawable) {
      mSphere.render(commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil)
  }
  
  func updateLogic(_ timeSinceLastUpdate: CFTimeInterval) {
      mSphere.updateWithDelta(timeSinceLastUpdate)
  }

  //MARK: - Gesture related

  func setupGestures() {
    let pan = UIPanGestureRecognizer(target: self, action: #selector(MySceneViewController.pan(_:)))
    self.view.addGestureRecognizer(pan)
  }
  
  func pan(_ panGesture: UIPanGestureRecognizer) {
    if panGesture.state == UIGestureRecognizerState.changed {
      let pointInView = panGesture.location(in: self.view)
      let xDelta = Float((lastPanLocation.x - pointInView.x)/self.view.bounds.width) * panSensivity
      let yDelta = Float((lastPanLocation.y - pointInView.y)/self.view.bounds.height) * panSensivity

        mSphere.rotationY -= xDelta
        mSphere.rotationX -= yDelta

        lastPanLocation = pointInView
    } else if panGesture.state == UIGestureRecognizerState.began {
      lastPanLocation = panGesture.location(in: self.view)
    } 
  }
  
}
