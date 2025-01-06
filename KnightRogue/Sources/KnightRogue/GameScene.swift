import Foundation
import UIKit
import SpriteKit
import GameplayKit

class GameScene: SKScene {
    private var knight: SKSpriteNode?
    private var lastUpdateTime: TimeInterval = 0
    private var idleFrames: [SKTexture] = []
    private var walkFrames: [SKTexture] = []
    private var jumpFrames: [SKTexture] = []
    private var isWalkingRight = false
    private var isWalkingLeft = false
    private var isJumping = false
    private var movementSpeed: CGFloat = 200.0
    
    // Track touches for each button
    private var leftButtonTouch: UITouch?
    private var rightButtonTouch: UITouch?
    private var jumpButtonTouch: UITouch?
    
    private var leftButton: SKNode?
    private var rightButton: SKNode?
    private var jumpButton: SKNode?
    
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
    
    func createJumpFrames() {
        print("Loading Jump texture...")
        let texture = SKTexture(imageNamed: "Jump")
        texture.filteringMode = .nearest
        let totalFrames = 6
        
        // Adjusted padding for jump frames
        let frameBounds: [(leftPadding: CGFloat, width: CGFloat)] = [
            (24, 43), // Frame 0
            (24, 43), // Frame 1
            (24, 43), // Frame 2
            (24, 43), // Frame 3
            (24, 43), // Frame 4
            (24, 43)  // Frame 5
        ]
        jumpFrames = createFrames(from: texture, totalFrames: totalFrames, frameBounds: frameBounds)
        print("Created \(jumpFrames.count) jump frames")
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
        createJumpFrames()
        
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
    
    func startJumpAnimation() {
        guard let knight = knight else { return }
        knight.removeAllActions()
        
        let animateAction = SKAction.animate(with: jumpFrames,
                                           timePerFrame: 0.08,
                                           resize: false,
                                           restore: true)
        
        let completionAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isJumping = false
            if self.isWalkingLeft || self.isWalkingRight {
                self.startWalkingAnimation(direction: self.isWalkingLeft ? -1 : 1)
            } else {
                self.startIdleAnimation()
            }
        }
        
        let sequence = SKAction.sequence([animateAction, completionAction])
        knight.run(sequence, withKey: "animation")
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
    private func setupControls() {
        // Enable multitouch
        view?.isMultipleTouchEnabled = true
        
        // Create buttons
        let buttonSize = CGSize(width: 60, height: 60)
        
        // Left button
        let leftButton = SKShapeNode(rectOf: buttonSize, cornerRadius: 10)
        leftButton.fillColor = .gray.withAlphaComponent(0.5)
        leftButton.strokeColor = .white.withAlphaComponent(0.3)
        leftButton.position = CGPoint(x: 50, y: 50)
        leftButton.name = "leftButton"
        leftButton.zPosition = 10
        addChild(leftButton)
        self.leftButton = leftButton
        
        // Right button
        let rightButton = SKShapeNode(rectOf: buttonSize, cornerRadius: 10)
        rightButton.fillColor = .gray.withAlphaComponent(0.5)
        rightButton.strokeColor = .white.withAlphaComponent(0.3)
        rightButton.position = CGPoint(x: 120, y: 50)
        rightButton.name = "rightButton"
        rightButton.zPosition = 10
        addChild(rightButton)
        self.rightButton = rightButton
        
        // Jump button
        let jumpButton = SKShapeNode(rectOf: buttonSize, cornerRadius: 10)
        jumpButton.fillColor = .gray.withAlphaComponent(0.5)
        jumpButton.strokeColor = .white.withAlphaComponent(0.3)
        jumpButton.position = CGPoint(x: size.width - 50, y: 50)
        jumpButton.name = "jumpButton"
        jumpButton.zPosition = 10
        addChild(jumpButton)
        self.jumpButton = jumpButton
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            if leftButton?.contains(location) ?? false {
                isWalkingLeft = true
                if !isJumping {
                    startWalkingAnimation(direction: -1)
                }
            }
            
            if rightButton?.contains(location) ?? false {
                isWalkingRight = true
                if !isJumping {
                    startWalkingAnimation(direction: 1)
                }
            }
            
            if jumpButton?.contains(location) ?? false {
                jump()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            if leftButton?.contains(location) ?? false {
                isWalkingLeft = false
                if !isWalkingRight && !isJumping {
                    startIdleAnimation()
                }
            }
            
            if rightButton?.contains(location) ?? false {
                isWalkingRight = false
                if !isWalkingLeft && !isJumping {
                    startIdleAnimation()
                }
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
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
              (isWalkingLeft || isWalkingRight), // Only jump if moving
              !isJumping, // Prevent double jumping
              abs(physics.velocity.dy) < 1.0 else { return }
        
        isJumping = true
        physics.applyImpulse(CGVector(dx: 0, dy: 400))
        startJumpAnimation()
        print("Jump applied with velocity: \(physics.velocity)")
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        guard let knight = knight else { return }
        
        // Apply horizontal movement even during jumps
        var dx: CGFloat = 0
        if isWalkingRight {
            dx = movementSpeed
        } else if isWalkingLeft {
            dx = -movementSpeed
        }
        
        if dx != 0 {
            knight.physicsBody?.velocity.dx = dx
        } else {
            // Slow down horizontal movement when not pressing buttons
            knight.physicsBody?.velocity.dx *= 0.9
        }
    }
}