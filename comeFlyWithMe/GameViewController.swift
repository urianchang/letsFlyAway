//
//  GameViewController.swift
//  comeFlyWithMe
//
//  Created by Urian Chang on 3/10/17.
//  Copyright © 2017 CodingDojo. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //: Set the scene
        let scene = StartMenu(size: view.bounds.size)
        let skView = self.view as! SKView
        skView.showsFPS = false  //Set to false for deployment
        skView.showsNodeCount = false    //Set to false for deployment
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
