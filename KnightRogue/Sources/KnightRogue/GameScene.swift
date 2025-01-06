import Foundation
import UIKit
import SpriteKit
import GameplayKit

class GameScene: SKScene {
    private var knight: SKSpriteNode?
    private var lastUpdateTime: TimeInterval = 0
    private var idleFrames: [SKTexture] = []
    private var walkFrames: [SKTexture] = []
    private var isWalkingRight = false
    private var isWalkingLeft = false
    private var movementSpeed: CGFloat = 200.0
    
    // MARK: - Animation Setup
    func createIdleFrames() {
        print("Loading Idle texture...")
        let texture = SKTexture(imageNamed: "Idle")
        texture.filteringMode = .nearest // Add pixel-perfect rendering
        let totalFrames = 4
        
        // Frame bounding boxes (x, width) in pixels
        let frameBounds: [(leftPadding: CGFloat, width: CGFloat)] = [
            (24, 43), // Frame 0
            (19, 43), // Frame 1
            (14, 43), // Frame 2
            (9, 43)   // Frame 3
        ]
        
        idleFrames = createFrames(from: texture, totalFrames: totalFrames, frameBounds: frameBounds)
        print("Created \(idleFrames.count) idle frames")
    }
    
    func createWalkFrames() {
        print("Loading Run texture...")
        let texture = SKTexture(imageNamed: "Run")
        texture.filteringMode = .nearest // Add pixel-perfect rendering
        let totalFrames = 7
        
        // Assuming similar padding structure as idle frames
        let frameBounds: [(leftPadding: CGFloat, width: CGFloat)] = Array(repeating: (15, 43), count: totalFrames)
        walkFrames = createFrames(from: texture, totalFrames: totalFrames, frameBounds: frameBounds)
        print("Created \(walkFrames.count) walk frames")
    }
    
    private func createFrames(from texture: SKTexture, totalFrames: Int, frameBounds: [(leftPadding: CGFloat, width: CGFloat)]) -> [SKTexture] {
        return (0..<totalFrames).map { i in
            // Use the same texture instance instead of creating new ones
            let totalWidth = texture.size().width
            
            let startX = (CGFloat(i) * (totalWidth / CGFloat(totalFrames)) + frameBounds[i].leftPadding) / totalWidth
            let normalizedWidth = frameBounds[i].width / totalWidth
            
            let rect = CGRect(x: startX,
                            y: 0,
                            width: normalizedWidth,
                            height: 1.0)
            
            return SKTexture(rect: rect, in: texture)
        }
    }
    
    // MARK: - Character Setup
    func setupKnight() {
        createIdleFrames()
        createWalkFrames()
        
        // Ensure we have valid textures before creating the sprite
        guard !idleFrames.isEmpty else {
            print("Error: No idle frames available!")
            return
        }
        
        knight = SKSpriteNode(texture: idleFrames[0])
        
        guard let knight = knight else { return }
        
        // Set size preserving aspect ratio
        let scale: CGFloat = 1.5
        let spriteWidth = 43.0 * scale
        let spriteHeight = 86.0 * scale
        knight.size = CGSize(width: spriteWidth, height: spriteHeight)
        
        knight.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        knight.position = CGPoint(x: size.width * 0.2, y: size.height * 0.3)
        
        // Physics setup
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: spriteWidth * 0.7, height: spriteHeight * 0.9),
                                      center: CGPoint(x: 0, y: spriteHeight * 0.45))
        knight.physicsBody = physicsBody
        knight.physicsBody?.allowsRotation = false
        knight.physicsBody?.restitution = 0.0
        knight.physicsBody?.mass = 1.0
        knight.physicsBody?.friction = 1.0
        knight.physicsBody?.linearDamping = 1.0
        knight.zPosition = 2
        
        addChild(knight)
        startIdleAnimation()
    }
    
    // MARK: - Animations
    func startIdleAnimation() {
        guard let knight = knight else { return }
        knight.removeAllActions()
        
        let animateAction = SKAction.animate(with: idleFrames,
                                           timePerFrame: 0.3,
                                           resize: false,
                                           restore: true)
        
        let repeatAction = SKAction.repeatForever(animateAction)
        knight.run(repeatAction, withKey: "animation")
    }
    
    func startWalkingAnimation(direction: CGFloat) {
        guard let knight = knight else { return }
        knight.removeAllActions()
        
        knight.xScale = direction // Flip sprite based on direction
        
        let animateAction = SKAction.animate(with: walkFrames,
                                           timePerFrame: 0.07,
                                           resize: false,
                                           restore: true)
        
        let repeatAction = SKAction.repeatForever(animateAction)
        knight.run(repeatAction, withKey: "animation")
    }
    
    // MARK: - Level Design
    func createLevel() {
        // Ground
        createPlatform(size: CGSize(width: size.width, height: 40),
                      position: CGPoint(x: size.width / 2, y: size.height * 0.2))
        
        // Platforms
        createPlatform(size: CGSize(width: 200, height: 20),
                      position: CGPoint(x: size.width * 0.7, y: size.height * 0.4))
        
        createPlatform(size: CGSize(width: 200, height: 20),
                      position: CGPoint(x: size.width * 0.3, y: size.height * 0.6))
        
        // Obstacles
        createObstacle(size: CGSize(width: 40, height: 40),
                      position: CGPoint(x: size.width * 0.5, y: size.height * 0.3))
        
        createObstacle(size: CGSize(width: 40, height: 80),
                      position: CGPoint(x: size.width * 0.8, y: size.height * 0.3))
    }
    
    func createPlatform(size: CGSize, position: CGPoint) {
        let platform = SKSpriteNode(color: .brown, size: size)
        platform.position = position
        platform.physicsBody = SKPhysicsBody(rectangleOf: platform.size)
        platform.physicsBody?.isDynamic = false
        platform.physicsBody?.friction = 1.0
        platform.physicsBody?.restitution = 0.0
        platform.zPosition = 1
        addChild(platform)
    }
    
    func createObstacle(size: CGSize, position: CGPoint) {
        let obstacle = SKSpriteNode(color: .red, size: size)
        obstacle.position = position
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.isDynamic = false
        obstacle.physicsBody?.friction = 0.5
        obstacle.zPosition = 1
        addChild(obstacle)
    }
    
    // MARK: - Input Handling
    private var leftButton: SKSpriteNode?
    private var rightButton: SKSpriteNode?
    private var jumpButton: SKSpriteNode?
    
    private func setupControls() {
        // Left button
        leftButton = SKSpriteNode(color: .gray.withAlphaComponent(0.5), size: CGSize(width: 60, height: 60))
        if let leftButton = leftButton {
            leftButton.position = CGPoint(x: 50, y: 50)
            leftButton.zPosition = 10
            leftButton.name = "leftButton"
            addChild(leftButton)
        }
        
        // Right button
        rightButton = SKSpriteNode(color: .gray.withAlphaComponent(0.5), size: CGSize(width: 60, height: 60))
        if let rightButton = rightButton {
            rightButton.position = CGPoint(x: 120, y: 50)
            rightButton.zPosition = 10
            rightButton.name = "rightButton"
            addChild(rightButton)
        }
        
        // Jump button
        jumpButton = SKSpriteNode(color: .gray.withAlphaComponent(0.5), size: CGSize(width: 60, height: 60))
        if let jumpButton = jumpButton {
            jumpButton.position = CGPoint(x: size.width - 50, y: 50)
            jumpButton.zPosition = 10
            jumpButton.name = "jumpButton"
            addChild(jumpButton)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNodes = nodes(at: location)
            
            for node in touchedNodes {
                switch node.name {
                case "leftButton":
                    isWalkingLeft = true
                    isWalkingRight = false
                    startWalkingAnimation(direction: -1)
                case "rightButton":
                    isWalkingRight = true
                    isWalkingLeft = false
                    startWalkingAnimation(direction: 1)
                case "jumpButton":
                    jump()
                default:
                    break
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNodes = nodes(at: location)
            
            for node in touchedNodes {
                switch node.name {
                case "leftButton":
                    isWalkingLeft = false
                    if !isWalkingRight { startIdleAnimation() }
                case "rightButton":
                    isWalkingRight = false
                    if !isWalkingLeft { startIdleAnimation() }
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Game Loop
    override func didMove(to view: SKView) {
        backgroundColor = .darkGray
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        setupKnight()
        createLevel()
        setupControls()
    }
    
    func jump() {
        guard let knight = knight,
              let physics = knight.physicsBody,
              physics.velocity.dy < 0.1 && physics.velocity.dy > -0.1 else { return }
        
        knight.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 25))
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        let dt = currentTime - lastUpdateTime
        
        // Update character movement
        if let knight = knight {
            var velocityX: CGFloat = 0
            
            if isWalkingLeft {
                velocityX = -movementSpeed
            } else if isWalkingRight {
                velocityX = movementSpeed
            }
            
            knight.physicsBody?.velocity.dx = velocityX
        }
        
        lastUpdateTime = currentTime
    }
}