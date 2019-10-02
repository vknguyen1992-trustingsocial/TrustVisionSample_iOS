//
//  ViewController.swift
//  TrustVisionSample
//
//  Created by Nguyen Vu on 10/1/19.
//  Copyright © 2019 MACBOOK. All rights reserved.
//

import UIKit
import TrustVisionSDK
import TrustVisionAPI

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        
        // testing server - enable sanity
        let accessKeyId = "ddac2562-3bd0-41ef-93a4-e527fc167c5a"
        let accessKeySecret = "97dc8a54-8bb7-476f-8636-9c4d0c403c23"

        TrustVisionSdk.initialize(
            accessKeyId: accessKeyId,
            accessKeySecret: accessKeySecret,
            isForced: true,
            success: {
                
                do {
                    let cardTypes = try TrustVisionSdk.getCardTypes()
                    let config = TSFaceSDKConfig.defaultConfig()
                    config.isEnableSound = true
                    config.livenessMode = TVLivenessOption.passive
                    config.actionMode = TSFaceSDKConfig.ActionMode.faceMatching
                    config.cardType = cardTypes.first!
                    
                    DispatchQueue.main.async {
                        self.startFlow(config: config)
                    }
                } catch _ {
                    print("[SDK ERROR] [get card types] SDK is not initialised")
                }
                
        }) { (error) in
            print("[SDK ERROR] [Initialize]: \(String(describing: error.description))")
        }
    }
    
    func startFlow(config: TSFaceSDKConfig) {
        do {
            let vc = try TrustVisionSdk.newCameraViewController(
                screenOrientation: UIApplication.shared.delegate as? TSScreenOrientationProtocol,
                config: config
            ) {(result, error) in
                if let result = result {
                    print("[RESULT] \(result)")
                }
            }
            self.present(vc, animated: true, completion: nil);
        } catch _ {
            print("[SDK ERROR] [start SDK flow] SDK is not initialised")
        }
    }
}

