import Foundation
import UIKit
import SpriteKit
import GameplayKit

class GameScene: SKScene {
    private var knight: SKSpriteNode?
    private var lastUpdateTime: TimeInterval = 0
    private var idleFrames: [SKTexture] = []

    func createIdleFrames() {
        let texture = SKTexture(imageNamed: "Idle")
        let totalFrames = 4
        
        // Frame bounding boxes (x, width) in pixels
        let frameBounds: [(leftPadding: CGFloat, width: CGFloat)] = [
            (24, 43), // Frame 0
            (19, 43), // Frame 1
            (14, 43), // Frame 2
            (9, 43)   // Frame 3
        ]
        
        // Create frames with corrected positions
        idleFrames = (0..<totalFrames).map { i in
            let frameTexture = SKTexture(imageNamed: "Idle")
            let totalWidth = texture.size().width
            
            // Calculate normalized coordinates accounting for padding
            let startX = (CGFloat(i) * (totalWidth / CGFloat(totalFrames)) + frameBounds[i].leftPadding) / totalWidth
            let normalizedWidth = frameBounds[i].width / totalWidth
            
            let rect = CGRect(x: startX,
                            y: 0, // Start from top of sprite sheet
                            width: normalizedWidth,
                            height: 1.0) // Use full height
            
            return SKTexture(rect: rect, in: frameTexture)
        }
        
        // Create knight sprite if it doesn't exist
        if knight == nil {
            knight = SKSpriteNode(texture: idleFrames[0])
            
            // Set size preserving aspect ratio
            let scale: CGFloat = 1.5
            let spriteWidth = 43.0 * scale
            let spriteHeight = 86.0 * scale // Full height of sprite sheet
            knight?.size = CGSize(width: spriteWidth, height: spriteHeight)
            
            // Set anchor point to bottom center
            knight?.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            
            // Position above platform
            let platformHeight = size.height * 0.2
            knight?.position = CGPoint(x: size.width / 2, y: platformHeight + 20)
            
            // Add physics body
            let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: spriteWidth * 0.7, height: spriteHeight * 0.9),
                                          center: CGPoint(x: 0, y: spriteHeight * 0.45)) // Offset to match visual
            knight?.physicsBody = physicsBody
            knight?.physicsBody?.allowsRotation = false
            knight?.physicsBody?.restitution = 0.0
            knight?.physicsBody?.mass = 1.0
            knight?.physicsBody?.friction = 1.0
            knight?.zPosition = 2
            
            if let knight = knight {
                addChild(knight)
            }
        }
        
        startIdleAnimation()
    }

    func startIdleAnimation() {
        guard let knight = knight else { return }
        knight.removeAllActions()
        
        let animateAction = SKAction.animate(with: idleFrames, 
                                           timePerFrame: 0.2,
                                           resize: false,
                                           restore: true)
        
        let repeatAction = SKAction.repeatForever(animateAction)
        knight.run(repeatAction)
    }

    func createPlatform() {
        let platform = SKSpriteNode(color: .brown, size: CGSize(width: size.width * 0.8, height: 20))
        platform.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
        platform.physicsBody = SKPhysicsBody(rectangleOf: platform.size)
        platform.physicsBody?.isDynamic = false
        platform.physicsBody?.friction = 1.0
        platform.physicsBody?.restitution = 0.0
        platform.zPosition = 1
        addChild(platform)
    }

    override func didMove(to view: SKView) {
        backgroundColor = .darkGray

        // Create frames and knight
        createIdleFrames()

        // Add platform
        createPlatform()

        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let knight = knight,
              let physics = knight.physicsBody,
              physics.velocity.dy < 0.1 && physics.velocity.dy > -0.1 else { return }
        
        knight.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 25))
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        if let knight = knight {
            // Log position every frame
            print("⏱ Update frame - Knight position: \(knight.position)")
        }
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
    }
}