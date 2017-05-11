//
//  GameScene.swift
//  comeFlyWithMe
//
//  Created by Urian Chang on 3/10/17.
//  Copyright © 2017 CodingDojo. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

let sounds = true  //: Variable to enable/disable sounds
var userShip : Int = 0 //: Variable to keep track of which ship the user has selected ('0' means no ship has been selected)

//: Start menu
class StartMenu: SKScene {
    var welcomeText = SKLabelNode(fontNamed: "Zapfino")
    var startText = SKLabelNode(fontNamed: "Chalkduster")
    var shipSelect1 = SKSpriteNode(imageNamed: "myShip")
    var shipSelect2 = SKSpriteNode(imageNamed: "myKite")

    override init (size: CGSize) {
        userShip = 0
        let bg = SKSpriteNode(imageNamed: "daySky")
        bg.size = size
        bg.position = CGPoint(x: size.width/2, y: size.height/2)
        super.init(size: size)
        addChild(bg)
        
        if sounds {
            let backgroundMusic = SKAudioNode(fileNamed: "acousticbreeze.caf")
            backgroundMusic.autoplayLooped = true
            addChild(backgroundMusic)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        //: Create welcome text
        welcomeText.text = "Let's fly away"
        welcomeText.fontSize = 40
        welcomeText.fontColor = UIColor.black
        welcomeText.position = CGPoint(x: frame.midX, y: frame.height - welcomeText.frame.maxY)
        
        //: Create ship selectors
            //: 1. Dirigible
        shipSelect1.setScale(0.20)
        shipSelect1.position = CGPoint(x: frame.midX - shipSelect1.frame.maxX-10, y: frame.midY)

            //: 2. Kite
        shipSelect2.setScale(0.20)
        shipSelect2.position = CGPoint(x: frame.midX + shipSelect2.frame.maxX+10, y: frame.midY)
        
        //: Create start text
        startText.text = "Please choose"
        startText.fontSize = 40
        startText.fontColor = UIColor.red
        startText.position = CGPoint(x: frame.midX, y: startText.frame.height)
        
        self.addChild(welcomeText)
        self.addChild(shipSelect1)
        self.addChild(shipSelect2)
        self.addChild(startText)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //: Flashing animation
        let fadeSeq = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.5)
            ])
        let flash = SKAction.repeatForever(fadeSeq)
        
        //: Shaking animation
        let rotate1 = SKAction.rotate(byAngle: -0.07, duration: 0.1)
        let rotate2 = SKAction.rotate(byAngle: 0.0, duration: 0.1)
        let rotate3 = SKAction.rotate(byAngle: 0.07, duration: 0.1)
        let shake_seq = SKAction.sequence([rotate1, rotate2, rotate3])
        let shake = SKAction.repeatForever(shake_seq)

        //: Only want to detect the first touch
        guard let touch = touches.first else {
            return
        }
        let location = touch.location(in: self)
        
        //: When user selects dirigible
        if self.atPoint(location) == self.shipSelect1 {
            userShip = 1
            shipSelect1.removeAllActions()
            shipSelect2.removeAllActions()
            shipSelect1.run(shake)
        }
        
        //: When user selects paper airplane
        if self.atPoint(location) == self.shipSelect2 {
            userShip = 2
            shipSelect2.removeAllActions()
            shipSelect1.removeAllActions()
            shipSelect2.run(shake)
        }
        
        //: When user makes any selection
        if self.atPoint(location) == self.shipSelect1 || self.atPoint(location) == self.shipSelect2 {
            startText.removeFromParent()
            startText.text = "Tap to Play"
            startText.run(flash)
            addChild(startText)
        }

        //: When user selects the start text
        if self.atPoint(location) == self.startText {
            //print ("Start button pressed")
            if userShip != 0 {
                //print ("User selected ship \(userShip)")
                if userShip == 1 {
                    let reveal = SKTransition.flipHorizontal(withDuration: 0.3)
                    let letsPlay = GameScene1(size: self.size)
                    self.view?.presentScene(letsPlay, transition: reveal)
                } else {
                    let reveal = SKTransition.flipHorizontal(withDuration: 0.3)
                    let letsPlay = GameScene2(size: self.size)
                    self.view?.presentScene(letsPlay, transition: reveal)
                }
            }
        }
    }

    override func update(_ currentTime: CFTimeInterval) {
    }
}

//: Game Scene for Kite
class GameScene2: SKScene, SKPhysicsContactDelegate {
    //: Variables that will be used
    var skyNode : SKSpriteNode      // Sky shown
    var skyNodeNext : SKSpriteNode  // Sky queued
    var cloudsNode : SKSpriteNode   // Clouds shown
    var cloudsNodeNext : SKSpriteNode   // Clouds queued
    var groundNode : SKSpriteNode       // Ground shown
    var groundNodeNext : SKSpriteNode   // Ground queued
    var kite : SKSpriteNode!     // Kite
    var lastFrameTime : TimeInterval = 0    // Time of last frame
    var deltaTime : TimeInterval = 0    // Time since last frame
    let shipCategory : UInt32 = 1 << 0  // Physics body category for ship
    let balloonCategory : UInt32 = 1 << 1   // Physics body category for balloon
    var gravityVectorY = SKFieldNode.linearGravityField(withVector: vector_float3(0, 0, 0)) // Vertical gravity vector
    var totalScore = 0  // Total score tracker
    var scoreLabelNode : SKLabelNode! // Score label
    var totalHighFives = 0  // Total high-fives tracker
    var highFiveLabelNode : SKLabelNode! // High-five counter label
    var totalBalloons = 0   // Total balloons saved
    var balloonsLabelNode : SKLabelNode! // Balloon counter label
    let motionTracker = CMMotionManager() //Tracker for motion
    var angleY : CGFloat = 0.0 //Y-position based off of accelerometer
    var exitLabelNode : SKSpriteNode! // Label for exiting the game
    
    override init(size: CGSize) {
        //: Check for current time
        let current = NSDate()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        let currentHour = formatter.string(from: current as Date)
        //let currentHour = "20"     //Use for QA
        //print ("Current hour is \(currentHour)")
        
        //: Display appropriate sky background based on time
        var bgname = String()
        var bgmusic = String()
        if Int(currentHour)! > 7 && Int(currentHour)! < 18 {
            bgname = "daySky.png"
            bgmusic = "warm_breeze.caf"
        } else {
            bgname = "nightSky.png"
            bgmusic = "night_sky.caf"
        }
        
        //: Prep sky layer
        skyNode = SKSpriteNode(imageNamed: bgname)
        skyNode.size = size
        skyNode.position = CGPoint(x: size.width/2, y: size.height/2)
        skyNodeNext = skyNode.copy() as! SKSpriteNode
        skyNodeNext.position = CGPoint(x: skyNode.position.x + skyNode.size.width, y: skyNode.position.y)
        
        //: Prep cloud layer
        cloudsNode = SKSpriteNode(imageNamed: "clouds.png")
        cloudsNode.size = size
        cloudsNode.position = CGPoint(x: size.width/2, y: size.height/2)
        cloudsNodeNext = cloudsNode.copy() as! SKSpriteNode
        cloudsNodeNext.position = CGPoint(x: cloudsNode.position.x + cloudsNode.size.width, y: cloudsNode.position.y)
        
        //: Prep ground layer
        groundNode = SKSpriteNode(imageNamed: "ground.png")
        groundNode.size = size
        groundNode.position = CGPoint(x: size.width/2, y: size.height/2)
        groundNodeNext = groundNode.copy() as! SKSpriteNode
        groundNodeNext.position = CGPoint(x: groundNode.position.x + groundNode.size.width, y: groundNode.position.y)
        
        //: IMPORTANT
        super.init(size: size)
        
        //: Add background layers to the scene
        self.addChild(skyNode)
        self.addChild(skyNodeNext)
        
        self.addChild(cloudsNode)
        self.addChild(cloudsNodeNext)
        
        self.addChild(groundNode)
        self.addChild(groundNodeNext)
        
        //: Add background music
        if sounds {
            let backgroundMusic = SKAudioNode(fileNamed: bgmusic)
            backgroundMusic.autoplayLooped = true
            addChild(backgroundMusic)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    //: Helper function to move the background layers
    func moveSprite(sprite : SKSpriteNode,
                    nextSprite : SKSpriteNode, speed : Float) -> Void {
        var newPosition = CGPoint.zero
        
        // For both the layer and its duplicate:
        for spriteToMove in [sprite, nextSprite] {
            
            // Shift the layer leftward based on the speed
            newPosition = spriteToMove.position
            newPosition.x -= CGFloat(speed * Float(deltaTime))
            spriteToMove.position = newPosition
            
            // If this layer is offscreen:
            if spriteToMove.frame.maxX < self.frame.minX {
                // Shift it over so that it's now to the immediate right of the current layer
                spriteToMove.position =
                    CGPoint(x: spriteToMove.position.x +
                        spriteToMove.size.width * 2,
                            y: spriteToMove.position.y)
            }
        }
    }
    
    override func didMove(to view: SKView) {
        print ("Game started with ship \(userShip)")
        //: Setup physics p.I
        self.physicsWorld.gravity = CGVector(dx: -2.0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        //: Add kite
        kite = SKSpriteNode(imageNamed: "myKite")
        kite.setScale(0.12)
        kite.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        kite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: kite.size.width, height: kite.size.height))
        kite.physicsBody?.isDynamic = true
        kite.physicsBody?.allowsRotation = false
        kite.physicsBody?.categoryBitMask = shipCategory
        kite.physicsBody?.linearDamping = 0.5
        addChild(kite)
        
        //: Setup physics p.II
        gravityVectorY.strength = 1.0
        addChild(gravityVectorY)
        
        //: Screen borders
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.friction = 0
        self.physicsBody = borderBody
        
        //: Create balloons indefinitely
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addBalloons),
                SKAction.wait(forDuration: 2.0)])
        ))
        
        //: Create the labels
        scoreLabelNode = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabelNode.fontSize = 18.0
        scoreLabelNode.text = "Score: \(totalScore)"
        scoreLabelNode.position = CGPoint(x: scoreLabelNode.frame.maxX, y: 8)
        
        balloonsLabelNode = SKLabelNode(fontNamed: "Chalkduster")
        balloonsLabelNode.text = "Balloons: \(totalBalloons)"
        balloonsLabelNode.fontSize = 18.0
        balloonsLabelNode.position = CGPoint(x: self.frame.midX, y: 8)
        
        highFiveLabelNode = SKLabelNode(fontNamed: "Chalkduster")
        highFiveLabelNode.text = "High-fives: \(totalHighFives)"
        highFiveLabelNode.fontSize = 18.0
        highFiveLabelNode.position = CGPoint(x: self.frame.width - highFiveLabelNode.frame.maxX, y: 8)
        
        exitLabelNode = SKSpriteNode(imageNamed: "close_btn")
        exitLabelNode.setScale(0.10)
        exitLabelNode.position = CGPoint(x: exitLabelNode.frame.maxX, y: self.frame.height-exitLabelNode.frame.maxY)
        
        //: Add the labels
        addChild(scoreLabelNode)
        addChild(balloonsLabelNode)
        addChild(highFiveLabelNode)
        addChild(exitLabelNode)
        
        //: Initialize motion tracker
        self.motionTracker.startAccelerometerUpdates()
        
        //: Add particles to kite
        if let shipTrail = SKEmitterNode(fileNamed: "shipTrail") {
            kite.zPosition = 10
            shipTrail.particleZPosition = 1
            shipTrail.targetNode = self
            kite.addChild(shipTrail)
        }
        
    }
    
    //: Action when user touches the screen (gives the kite a push)
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchPoint = touches.first?.location(in: self)
        if self.atPoint(touchPoint!) == exitLabelNode {
            print ("Exit button pressed")
            let reveal = SKTransition.flipHorizontal(withDuration: 0.3)
            let startMenu = StartMenu(size: self.size)
            self.view?.presentScene(startMenu, transition: reveal)
        } else {
            let ypos = angleY
            kite.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            kite.physicsBody?.applyImpulse(CGVector(dx: 15, dy: ypos))
        }
    }
    
    //: Helper functions for generating random floats
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addBalloons() {
        //: Call random function to determine what type of balloon to add
        let randBall = Int(arc4random_uniform(10))
        var balloon = SKSpriteNode()
        
        if randBall == 0 {
            balloon = SKSpriteNode(imageNamed: "hotAir")
            balloon.setScale(0.28)
            balloon.name = "friend"
        } else if randBall >= 1 && randBall < 3 {
            balloon = SKSpriteNode(imageNamed: "pinkBalloon")
            balloon.setScale(0.15)
            balloon.name = "pink"
        } else if randBall >= 3 && randBall < 6 {
            balloon = SKSpriteNode(imageNamed: "yellowBalloon")
            balloon.setScale(0.15)
            balloon.name = "yellow"
        } else {
            balloon = SKSpriteNode(imageNamed: "redBalloon")
            balloon.setScale(0.15)
            balloon.name = "red"
        }
        
        //: Determine where to put the balloon on the Y-axis
        let yPosition = random(min: balloon.size.height/2, max: size.height - balloon.size.height/2)
        
        //: Place balloon off-screen when it is first rendered
        balloon.position = CGPoint(x: size.width + balloon.size.width/2, y: yPosition)
        
        //: Add the balloon
        addChild(balloon)
        
        //: Determine the horizontal speed of the balloon (duration)
        let balloonSpeed = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        //: Balloon actions
        //: Move from right to left
        let balloonMove = SKAction.move(to: CGPoint(x: -balloon.size.width/2, y: yPosition), duration: TimeInterval(balloonSpeed))
        //: Remove balloon at the end of its lifecycle
        let balloonPop = SKAction.removeFromParent()
        
        //: Queue up the balloon actions and execute
        balloon.run(SKAction.sequence([balloonMove, balloonPop]))
        
        //: Give balloon a physics body to detect collisions
        balloon.physicsBody = SKPhysicsBody(rectangleOf: balloon.size)
        balloon.physicsBody?.isDynamic = false
        balloon.physicsBody?.categoryBitMask = balloonCategory
        balloon.physicsBody?.contactTestBitMask = shipCategory
    }
    
    //: Helper function for when collision is detected between ship and balloon
    func shipHitBalloon(balloon: SKSpriteNode) {
        if let ballKind = balloon.name {
            if ballKind == "friend" {
                if sounds {run(SKAction.playSoundFileNamed("yay.caf", waitForCompletion: false))}
                totalHighFives += 1
                totalScore += 10
            } else {
                if ballKind == "pink" {
                    totalScore += 5
                } else if ballKind == "yellow" {
                    totalScore += 3
                } else {
                    totalScore += 1
                }
                if sounds {run(SKAction.playSoundFileNamed("bell.caf", waitForCompletion: false))}
                totalBalloons += 1
            }
        }
        
        //: Recreate the labels
        //: 1. Remove labels
        scoreLabelNode.removeFromParent()
        balloonsLabelNode.removeFromParent()
        highFiveLabelNode.removeFromParent()
        
        //: 2. Create labels
        scoreLabelNode = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabelNode.fontSize = 18.0
        scoreLabelNode.text = "Score: \(totalScore)"
        scoreLabelNode.position = CGPoint(x: scoreLabelNode.frame.maxX, y: 8)
        
        balloonsLabelNode = SKLabelNode(fontNamed: "Chalkduster")
        balloonsLabelNode.text = "Balloons: \(totalBalloons)"
        balloonsLabelNode.fontSize = 18.0
        balloonsLabelNode.position = CGPoint(x: self.frame.midX, y: 8)
        
        highFiveLabelNode = SKLabelNode(fontNamed: "Chalkduster")
        highFiveLabelNode.text = "High-fives: \(totalHighFives)"
        highFiveLabelNode.fontSize = 18.0
        highFiveLabelNode.position = CGPoint(x: self.frame.width - highFiveLabelNode.frame.maxX, y: 8)
        
        //: 3. Add labels
        addChild(scoreLabelNode)
        addChild(balloonsLabelNode)
        addChild(highFiveLabelNode)
        
        balloon.removeFromParent()
    }
    
    //: Contact delegate method
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if ((firstBody.categoryBitMask & shipCategory != 0) &&
            (secondBody.categoryBitMask & balloonCategory != 0)) {
            if let _ = firstBody.node as? SKSpriteNode, let
                balloon = secondBody.node as? SKSpriteNode {
                shipHitBalloon(balloon: balloon)
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // First, update the delta time values:
        // If we don't have a last frame time value, this is the first frame,
        // so delta time will be zero.
        if lastFrameTime <= 0 {
            lastFrameTime = currentTime
        }
        
        // Update delta time
        deltaTime = currentTime - lastFrameTime
        
        // Set last frame time to current time
        lastFrameTime = currentTime
        
        //: Let's see the accelerometer data...
        if let accelerometer_data = self.motionTracker.accelerometerData {
            //print ("Accel data: \(accelerometer_data)")
            angleY = CGFloat(accelerometer_data.acceleration.y * (-50))
        }
        
        // Check position of the airship and modify the vertical gravity vector as needed
        if Int(kite.position.y) > Int(size.height*0.55) {
            gravityVectorY.removeFromParent()
            gravityVectorY = SKFieldNode.linearGravityField(withVector: vector_float3(0, -1, 0))
        } else if Int(kite.position.y) < Int(size.height*0.45) {
            gravityVectorY.removeFromParent()
            gravityVectorY = SKFieldNode.linearGravityField(withVector: vector_float3(0, 1, 0))
        } else {
            gravityVectorY.removeFromParent()
            gravityVectorY = SKFieldNode.linearGravityField(withVector: vector_float3(0, 0, 0))
        }
        gravityVectorY.strength = 1.0
        addChild(gravityVectorY)
        
        // Next, move each of the layers.
        // Objects that should appear move slower than foreground objects.
        self.moveSprite(sprite: skyNode, nextSprite:skyNodeNext, speed:25.0)
        self.moveSprite(sprite: cloudsNode, nextSprite:cloudsNodeNext,
                        speed:50.0)
        self.moveSprite(sprite: groundNode, nextSprite:groundNodeNext, speed:75.0)
    }
}

//: Game Scene for Dirigible
class GameScene1: SKScene, SKPhysicsContactDelegate {
    
    //: Variables that will be used
    var skyNode : SKSpriteNode      // Sky shown
    var skyNodeNext : SKSpriteNode  // Sky queued
    var cloudsNode : SKSpriteNode   // Clouds shown
    var cloudsNodeNext : SKSpriteNode   // Clouds queued
    var groundNode : SKSpriteNode       // Ground shown
    var groundNodeNext : SKSpriteNode   // Ground queued
    var airship : SKSpriteNode!     // Airship
    var lastFrameTime : TimeInterval = 0    // Time of last frame
    var deltaTime : TimeInterval = 0    // Time since last frame
    let shipCategory : UInt32 = 1 << 0  // Physics body category for airship
    let balloonCategory : UInt32 = 1 << 1   // Physics body category for balloon
    var gravityVectorY = SKFieldNode.linearGravityField(withVector: vector_float3(0, 0, 0)) // Vertical gravity vector
    var totalScore = 0  // Total score tracker
    var scoreLabelNode : SKLabelNode! // Score label
    var totalHighFives = 0  // Total high-fives tracker
    var highFiveLabelNode : SKLabelNode! // High-five counter label
    var totalBalloons = 0   // Total balloons saved
    var balloonsLabelNode : SKLabelNode! // Balloon counter label
    var exitLabelNode : SKSpriteNode! // Label for exiting the game
    
    override init(size: CGSize) {
        //: Check for current time
        let current = NSDate()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        let currentHour = formatter.string(from: current as Date)
        //let currentHour = "20"     //Use for QA
        //print ("Current hour is \(currentHour)")
        
        //: Display appropriate sky background based on time
        var bgname = String()
        var bgmusic = String()
        if Int(currentHour)! > 7 && Int(currentHour)! < 18 {
            bgname = "daySky.png"
            bgmusic = "warm_breeze.caf"
        } else {
            bgname = "nightSky.png"
            bgmusic = "night_sky.caf"
        }
        
        //: Prep sky layer
        skyNode = SKSpriteNode(imageNamed: bgname)
        skyNode.size = size
        skyNode.position = CGPoint(x: size.width/2, y: size.height/2)
        skyNodeNext = skyNode.copy() as! SKSpriteNode
        skyNodeNext.position = CGPoint(x: skyNode.position.x + skyNode.size.width, y: skyNode.position.y)
        
        //: Prep cloud layer
        cloudsNode = SKSpriteNode(imageNamed: "clouds.png")
        cloudsNode.size = size
        cloudsNode.position = CGPoint(x: size.width/2, y: size.height/2)
        cloudsNodeNext = cloudsNode.copy() as! SKSpriteNode
        cloudsNodeNext.position = CGPoint(x: cloudsNode.position.x + cloudsNode.size.width, y: cloudsNode.position.y)
        
        //: Prep ground layer
        groundNode = SKSpriteNode(imageNamed: "ground.png")
        groundNode.size = size
        groundNode.position = CGPoint(x: size.width/2, y: size.height/2)
        groundNodeNext = groundNode.copy() as! SKSpriteNode
        groundNodeNext.position = CGPoint(x: groundNode.position.x + groundNode.size.width, y: groundNode.position.y)
        
        //: IMPORTANT
        super.init(size: size)
        
        //: Add background layers to the scene
        self.addChild(skyNode)
        self.addChild(skyNodeNext)
        
        self.addChild(cloudsNode)
        self.addChild(cloudsNodeNext)
        
        self.addChild(groundNode)
        self.addChild(groundNodeNext)
        
        //: Add background music
        if sounds {
            let backgroundMusic = SKAudioNode(fileNamed: bgmusic)
            backgroundMusic.autoplayLooped = true
            addChild(backgroundMusic)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    //: Helper function to move the background layers
    func moveSprite(sprite : SKSpriteNode,
                    nextSprite : SKSpriteNode, speed : Float) -> Void {
        var newPosition = CGPoint.zero
        
        // For both the layer and its duplicate:
        for spriteToMove in [sprite, nextSprite] {
            
            // Shift the layer leftward based on the speed
            newPosition = spriteToMove.position
            newPosition.x -= CGFloat(speed * Float(deltaTime))
            spriteToMove.position = newPosition
            
            // If this layer is offscreen:
            if spriteToMove.frame.maxX < self.frame.minX {
                // Shift it over so that it's now to the immediate right of the current layer
                spriteToMove.position =
                    CGPoint(x: spriteToMove.position.x +
                        spriteToMove.size.width * 2,
                            y: spriteToMove.position.y)
            }
        }
    }
    
    override func didMove(to view: SKView) {
        print ("Game started with ship \(userShip)")
        //: Setup physics p.I
        self.physicsWorld.gravity = CGVector(dx: -5.0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        //: Add player's airship
        let airshipTexture1 = SKTexture(imageNamed: "myShip")
        let airshipTexture2 = SKTexture(imageNamed: "myShip2")
        let animation = SKAction.animate(with: [airshipTexture1, airshipTexture2], timePerFrame: 0.06)
        let propeller = SKAction.repeatForever(animation)
        airship = SKSpriteNode(texture: airshipTexture1)
        airship.setScale(0.20)
        airship.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        airship.run(propeller)
        airship.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: airship.size.width, height: airship.size.height))
        airship.physicsBody?.isDynamic = true
        airship.physicsBody?.allowsRotation = false
        airship.physicsBody?.categoryBitMask = shipCategory
        airship.physicsBody?.linearDamping = 1.0
        addChild(airship)
        
        //: Setup physics p.II
        gravityVectorY.strength = 1.0
        addChild(gravityVectorY)
        
        //: Screen borders
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.friction = 0
        self.physicsBody = borderBody
        
        //: Create balloons indefinitely
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addBalloons),
                SKAction.wait(forDuration: 2.0)])
        ))
        
        //: Create the labels
        scoreLabelNode = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabelNode.fontSize = 18.0
        scoreLabelNode.text = "Score: \(totalScore)"
        scoreLabelNode.position = CGPoint(x: scoreLabelNode.frame.maxX, y: 8)
        
        balloonsLabelNode = SKLabelNode(fontNamed: "Chalkduster")
        balloonsLabelNode.text = "Balloons: \(totalBalloons)"
        balloonsLabelNode.fontSize = 18.0
        balloonsLabelNode.position = CGPoint(x: self.frame.midX, y: 8)
        
        highFiveLabelNode = SKLabelNode(fontNamed: "Chalkduster")
        highFiveLabelNode.text = "High-fives: \(totalHighFives)"
        highFiveLabelNode.fontSize = 18.0
        highFiveLabelNode.position = CGPoint(x: self.frame.width - highFiveLabelNode.frame.maxX, y: 8)
        
        exitLabelNode = SKSpriteNode(imageNamed: "close_btn")
        exitLabelNode.setScale(0.10)
        exitLabelNode.position = CGPoint(x: exitLabelNode.frame.maxX, y: self.frame.height-exitLabelNode.frame.maxY)
        
        //: Add the labels
        addChild(scoreLabelNode)
        addChild(balloonsLabelNode)
        addChild(highFiveLabelNode)
        addChild(exitLabelNode)
        
        //: Add particles to ship
        if let shipTrail = SKEmitterNode(fileNamed: "shipTrail") {
            airship.zPosition = 10
            shipTrail.particleZPosition = 1
            shipTrail.targetNode = self
            airship.addChild(shipTrail)
        }
    }
    
    //: Action when user touches the screen (moves the airship)
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //: Use only one touch point
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        if self.atPoint(touchLocation) == exitLabelNode {
            print ("Exit button pressed")
            let reveal = SKTransition.flipHorizontal(withDuration: 0.3)
            let startMenu = StartMenu(size: self.size)
            self.view?.presentScene(startMenu, transition: reveal)
        } else {
            airship.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            let offset = touchLocation - airship.position
            airship.physicsBody?.applyImpulse(CGVector(dx: offset.x, dy: offset.y))
        }
    }
    
    //: Helper functions for generating random floats
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addBalloons() {
        //: Call random function to determine what type of balloon to add
        let randBall = Int(arc4random_uniform(10))
        var balloon = SKSpriteNode()
        
        if randBall == 0 {
            balloon = SKSpriteNode(imageNamed: "hotAir")
            balloon.setScale(0.28)
            balloon.name = "friend"
        } else if randBall >= 1 && randBall < 3 {
            balloon = SKSpriteNode(imageNamed: "pinkBalloon")
            balloon.setScale(0.15)
            balloon.name = "pink"
        } else if randBall >= 3 && randBall < 6 {
            balloon = SKSpriteNode(imageNamed: "yellowBalloon")
            balloon.setScale(0.15)
            balloon.name = "yellow"
        } else {
            balloon = SKSpriteNode(imageNamed: "redBalloon")
            balloon.setScale(0.15)
            balloon.name = "red"
        }
        
        //: Determine where to put the balloon on the Y-axis
        let yPosition = random(min: balloon.size.height/2, max: size.height - balloon.size.height/2)
        
        //: Place balloon off-screen when it is first rendered
        balloon.position = CGPoint(x: size.width + balloon.size.width/2, y: yPosition)
        
        //: Add the balloon
        addChild(balloon)
        
        //: Determine the horizontal speed of the balloon (duration)
        let balloonSpeed = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        //: Balloon actions
            //: Move from right to left
        let balloonMove = SKAction.move(to: CGPoint(x: -balloon.size.width/2, y: yPosition), duration: TimeInterval(balloonSpeed))
            //: Remove balloon at the end of its lifecycle
        let balloonPop = SKAction.removeFromParent()
        
            //: Queue up the balloon actions and execute
        balloon.run(SKAction.sequence([balloonMove, balloonPop]))
        
        //: Give balloon a physics body to detect collisions
        balloon.physicsBody = SKPhysicsBody(rectangleOf: balloon.size)
        balloon.physicsBody?.isDynamic = false
        balloon.physicsBody?.categoryBitMask = balloonCategory
        balloon.physicsBody?.contactTestBitMask = shipCategory
    }
    
    //: Helper function for when collision is detected between ship and balloon
    func shipHitBalloon(balloon: SKSpriteNode) {
        if let ballKind = balloon.name {
            if ballKind == "friend" {
                if sounds {run(SKAction.playSoundFileNamed("yay.caf", waitForCompletion: false))}
                totalHighFives += 1
                totalScore += 10
            } else {
                if ballKind == "pink" {
                    totalScore += 5
                } else if ballKind == "yellow" {
                    totalScore += 3
                } else {
                    totalScore += 1
                }
                if sounds {run(SKAction.playSoundFileNamed("bell.caf", waitForCompletion: false))}
                totalBalloons += 1
            }
        }
        
        //: Recreate the labels
            //: 1. Remove labels
        scoreLabelNode.removeFromParent()
        balloonsLabelNode.removeFromParent()
        highFiveLabelNode.removeFromParent()
        
            //: 2. Create labels
        scoreLabelNode = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabelNode.fontSize = 18.0
        scoreLabelNode.text = "Score: \(totalScore)"
        scoreLabelNode.position = CGPoint(x: scoreLabelNode.frame.maxX, y: 8)
        
        balloonsLabelNode = SKLabelNode(fontNamed: "Chalkduster")
        balloonsLabelNode.text = "Balloons: \(totalBalloons)"
        balloonsLabelNode.fontSize = 18.0
        balloonsLabelNode.position = CGPoint(x: self.frame.midX, y: 8)
        
        highFiveLabelNode = SKLabelNode(fontNamed: "Chalkduster")
        highFiveLabelNode.text = "High-fives: \(totalHighFives)"
        highFiveLabelNode.fontSize = 18.0
        highFiveLabelNode.position = CGPoint(x: self.frame.width - highFiveLabelNode.frame.maxX, y: 8)
        
            //: 3. Add labels
        addChild(scoreLabelNode)
        addChild(balloonsLabelNode)
        addChild(highFiveLabelNode)
        
        balloon.removeFromParent()
    }
    
    //: Contact delegate method
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if ((firstBody.categoryBitMask & shipCategory != 0) &&
            (secondBody.categoryBitMask & balloonCategory != 0)) {
            if let _ = firstBody.node as? SKSpriteNode, let
                balloon = secondBody.node as? SKSpriteNode {
                shipHitBalloon(balloon: balloon)
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // First, update the delta time values:
        // If we don't have a last frame time value, this is the first frame,
        // so delta time will be zero.
        if lastFrameTime <= 0 {
            lastFrameTime = currentTime
        }
        
        // Update delta time
        deltaTime = currentTime - lastFrameTime
        
        // Set last frame time to current time
        lastFrameTime = currentTime
        
        // Check position of the airship and modify the vertical gravity vector as needed
        if Int(airship.position.y) > Int(size.height*0.55) {
            gravityVectorY.removeFromParent()
            gravityVectorY = SKFieldNode.linearGravityField(withVector: vector_float3(0, -1, 0))
        } else if Int(airship.position.y) < Int(size.height*0.45) {
            gravityVectorY.removeFromParent()
            gravityVectorY = SKFieldNode.linearGravityField(withVector: vector_float3(0, 1, 0))
        } else {
            gravityVectorY.removeFromParent()
            gravityVectorY = SKFieldNode.linearGravityField(withVector: vector_float3(0, 0, 0))
        }
        gravityVectorY.strength = 1.0
        addChild(gravityVectorY)
        
        // Next, move each of the layers.
        // Objects that should appear move slower than foreground objects.
        self.moveSprite(sprite: skyNode, nextSprite:skyNodeNext, speed:25.0)
        self.moveSprite(sprite: cloudsNode, nextSprite:cloudsNodeNext,
                        speed:50.0)
        self.moveSprite(sprite: groundNode, nextSprite:groundNodeNext, speed:75.0)
    }
}

//: Helper functions: Vector math (extending the basic ones)
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}
