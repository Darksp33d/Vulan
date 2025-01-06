import Foundation
import UIKit
import SpriteKit
import GameplayKit

class GameScene: SKScene {
    private var knight: SKSpriteNode?
    private var lastUpdateTime: TimeInterval = 0
    
    override func didMove(to view: SKView) {
        // Set up the scene
        backgroundColor = .darkGray
        
        // Create a visible platform
        let platform = SKSpriteNode(color: .green, size: CGSize(width: frame.width, height: 50))
        platform.position = CGPoint(x: frame.midX, y: 100)
        platform.physicsBody = SKPhysicsBody(rectangleOf: platform.size)
        platform.physicsBody?.isDynamic = false
        addChild(platform)
        
        // Create the knight sprite using the Idle sprite
        let knightTexture = SKTexture(imageNamed: "Idle")
        let tempKnight = SKSpriteNode(texture: knightTexture, size: CGSize(width: 100, height: 100))
        tempKnight.position = CGPoint(x: frame.midX, y: frame.midY)
        tempKnight.physicsBody = SKPhysicsBody(rectangleOf: tempKnight.size)
        tempKnight.physicsBody?.allowsRotation = false
        tempKnight.physicsBody?.restitution = 0
        addChild(tempKnight)
        knight = tempKnight
        
        // Set up physics
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let knight = knight else { return }
        
        // Simple jump mechanic
        knight.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 200))
        
        // Change texture to jump
        knight.texture = SKTexture(imageNamed: "Jump")
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Check if knight is moving and update texture accordingly
        if let knight = knight, let body = knight.physicsBody {
            if abs(body.velocity.dy) < 0.1 {
                knight.texture = SKTexture(imageNamed: "Idle")
            }
        }
    }
}
