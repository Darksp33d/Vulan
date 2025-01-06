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
        let textureSize = texture.size()
        print("Original texture size: \(textureSize)")
        
        // Using normalized coordinates (0 to 1)
        let frameWidth = 1.0 / 4.0  // Width of each frame in normalized coordinates
        
        // Create frames
        for i in 0..<4 {
            let frame = CGRect(
                x: frameWidth * CGFloat(i),
                y: 0,
                width: frameWidth,
                height: 1.0
            )
            print("Creating frame \(i) at x: \(frame.origin.x), width: \(frame.width)")
            let frameTexture = SKTexture(rect: frame, in: texture)
            idleFrames.append(frameTexture)
        }
        
        print("Created \(idleFrames.count) frames")
    }
    
    func startIdleAnimation() {
        guard let knight = knight else { return }
        let animation = SKAction.animate(with: idleFrames, timePerFrame: 0.15)
        knight.run(SKAction.repeatForever(animation), withKey: "idleAnimation")
    }
    
    override func didMove(to view: SKView) {
        // Set up the scene
        backgroundColor = .darkGray
        
        // Create animation frames
        createIdleFrames()
        
        // Create a visible platform
        let platform = SKSpriteNode(color: .green, size: CGSize(width: frame.width, height: 50))
        platform.position = CGPoint(x: frame.midX, y: 100)
        platform.physicsBody = SKPhysicsBody(rectangleOf: platform.size)
        platform.physicsBody?.isDynamic = false
        addChild(platform)
        
        // Create the knight sprite
        guard let firstFrame = idleFrames.first else { return }
        let tempKnight = SKSpriteNode(texture: firstFrame)
        
        // Calculate size to maintain aspect ratio
        let desiredHeight: CGFloat = 80
        let aspectRatio = firstFrame.size().width / firstFrame.size().height
        let desiredWidth = desiredHeight * aspectRatio
        
        tempKnight.size = CGSize(width: desiredWidth, height: desiredHeight)
        tempKnight.position = CGPoint(x: frame.midX, y: frame.midY)
        
        // Add debug coloring
        tempKnight.color = .red
        tempKnight.colorBlendFactor = 0.3 // Made more transparent to see sprite better
        
        // Add physics after setting size
        tempKnight.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: desiredWidth * 0.6, height: desiredHeight * 0.9))
        tempKnight.physicsBody?.allowsRotation = false
        tempKnight.physicsBody?.restitution = 0
        addChild(tempKnight)
        knight = tempKnight
        
        // Start idle animation after a short delay to ensure texture is loaded
        let waitAction = SKAction.wait(forDuration: 0.1)
        let startAnimation = SKAction.run { [weak self] in
            self?.startIdleAnimation()
        }
        tempKnight.run(SKAction.sequence([waitAction, startAnimation]))
        
        // Set up physics
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let knight = knight else { return }
        knight.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 200))
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
    }
}
