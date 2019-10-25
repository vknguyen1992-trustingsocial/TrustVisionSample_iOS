//
//  CaptureImageViewController.swift
//  TrustVisionSample
//
//  Created by Nguyen Vu on 10/24/19.
//  Copyright © 2019 MACBOOK. All rights reserved.
//

import Foundation

class CaptureImageViewController: UIViewController {
    
    @IBOutlet weak var frontIdCardImageView: UIImageView!
    @IBOutlet weak var backIdCardImageView: UIImageView!
    @IBOutlet weak var customerImageView: UIImageView!
    @IBOutlet weak var agentImageView: UIImageView!
    @IBOutlet weak var idCardInfoTableView: UITableView!
    
    @IBAction func matchCardAndCustomerButtonPressed(_ sender: Any) {
        self.matchImage(image1Id: frontCardImageId, image2Id: customerImageId)
    }
    
    @IBAction func matchCustomerAndAgentButtonPressed(_ sender: Any) {
        self.matchImage(image1Id: customerImageId, image2Id: agentImageId)
    }
    
    fileprivate var cardTypes: [TrustVisionSDK.TVCardType] = []
    fileprivate var frontCardImageId: String?
    fileprivate var backCardImageId: String?
    fileprivate var customerImageId: String?
    fileprivate var agentImageId: String?
    fileprivate var cardInfos: [(String, String)] = []
    
    fileprivate let CellIdentifier = "IdCardCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.idCardInfoTableView.dataSource = self
        
        let imageViews = [
            self.frontIdCardImageView,
            self.backIdCardImageView,
            self.customerImageView,
            self.agentImageView
        ]
        for imageView in imageViews {
            imageView?.layer.borderWidth = 1
            imageView?.layer.borderColor = UIColor.gray.cgColor
        }
        
        let selectors = [
            (self.frontIdCardImageView, #selector(didTapFrontIdCardImageView)),
            (self.backIdCardImageView, #selector(didTapBackIdCardImageView)),
            (self.customerImageView, #selector(didTapCustomImageView)),
            (self.agentImageView, #selector(didTapAgentImageView))
        ]
        
        for (imageView, selector) in selectors {
            let tapGesture = UITapGestureRecognizer(target: self, action: selector)
            imageView?.addGestureRecognizer(tapGesture)
        }
        
        do {
            self.cardTypes = try TrustVisionSdk.getCardTypes()
        } catch _ {
            print("[SDK ERROR] [get card types] SDK is not initialised")
        }
    }
    
    @objc func didTapFrontIdCardImageView() {
        self.showCardSide(
            .front,
            callback: { (result) -> Void in
                DispatchQueue.main.async {
                    self.frontIdCardImageView.image = result.frontIdImage
                    self.frontCardImageId = result.frontIdImageId
                    self.updateCardInfos(result: result)
                }
        })
    }
    @objc func didTapBackIdCardImageView() {
        self.showCardSide(
            .back,
            callback: { (result) -> Void in
                DispatchQueue.main.async {
                    self.backIdCardImageView.image = result.backIdImage
                    self.backCardImageId = result.backIdImageId
                    self.updateCardInfos(result: result)
                }
        })
    }
    @objc func didTapCustomImageView() {
        self.showCaptureSelfie(
            callback: { (result) -> Void in
                DispatchQueue.main.async {
                    self.customerImageView.image = result.selfieImage
                    self.customerImageId = result.selfieImageId
                }
        })
    }
    @objc func didTapAgentImageView() {
        self.showCaptureSelfie(
            callback: { (result) -> Void in
                DispatchQueue.main.async {
                    self.agentImageView.image = result.selfieImage
                    self.agentImageId = result.selfieImageId
                }
        })
    }
    
    fileprivate func updateCardInfos(result: TVDetectionResult) {
        if let infos = result.cardInfoResult?.infos {
            for info in infos {
                if let key = info.field, let value = info.value {
                    if let index = self.cardInfos.firstIndex(where: { (infoTuple) -> Bool in
                        return infoTuple.0 == key
                    }) {
                        self.cardInfos[index] = (key, value)
                    } else {
                        self.cardInfos.append((key, value))
                    }
                }
            }
        }
        
        self.idCardInfoTableView.reloadData()
    }
    
    fileprivate func showCardSide(
        _ cardSide: TVIdCardConfiguration.TVCardSide,
        callback: @escaping (TVDetectionResult) -> Void
        ) {
        
        guard let cardType = self.cardTypes.first else {
            return;
        }
        
        cardType.orientation = .portrait
        
        let config = TVIdCardConfiguration(
            cardType: cardType,
            cardSide: cardSide,
            isSoundEnable: true,
            isSanityRequired: false)
        let vc = TrustVisionSdk.startIdCapturing(
            configuration: config,
            success: callback
        ) { [weak self] (error) in
            guard let strongSelf = self else { return; }
            DispatchQueue.main.async {
                strongSelf.showError(error: error.description)
            }
        }
        
        self.present(vc, animated: true, completion: nil)
    }
    
    fileprivate func showCaptureSelfie(callback: @escaping (TVDetectionResult) -> Void) {
        
        let config = TVSelfieConfiguration(
            cameraOption: .front,
            isSoundEnable: true,
            isSanityRequired: false,
            livenessMode: .passive)
        let vc = TrustVisionSdk.startSelfieCapturing(
            configuration: config,
            success: callback
        ) { [weak self] (error) in
            guard let strongSelf = self else { return; }
            DispatchQueue.main.async {
                strongSelf.showError(error: error.description)
            }
        }
        
        self.present(vc, animated: true, completion: nil)
    }
    
    fileprivate func matchImage(image1Id: String?, image2Id: String?) {
        
        guard let image1Id = image1Id, let image2Id = image2Id else {
            return;
        }
        
        TrustVisionSdk.matchFace(
            image1Id: image1Id,
            image2Id: image2Id,
            success: { [weak self] (result) in
                guard let strongSelf = self else { return; }
                DispatchQueue.main.async {
                    strongSelf.showMatchingResult(result.matchResult)
                }
        }) { [weak self] (error) in
            guard let strongSelf = self else { return; }
            DispatchQueue.main.async {
                strongSelf.showError(error: error.description)
            }
        }
    }
    
    fileprivate func showMatchingResult(_ matchingResult: TrustVisionSDK.TVCompareFacesResult.MatchResult) {
        
        var matchingResultString = "";
        switch matchingResult {
        case .matched:
            matchingResultString = "Matched"
        case .unmatched:
            matchingResultString = "Not Matched"
        case .unsure:
            matchingResultString = "Not Sure"
        }
        
        let alertViewController = UIAlertController(title: matchingResultString, message: "", preferredStyle: .alert)
        alertViewController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    fileprivate func showError(error: String) {
        let alertViewController = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        alertViewController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertViewController, animated: true, completion: nil)
    }
}

extension CaptureImageViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cardInfos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        
        if (cell == nil) {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: CellIdentifier)
        }
        
        let info = self.cardInfos[indexPath.row]
        cell!.textLabel?.text = info.0
        cell!.detailTextLabel?.numberOfLines = 0
        cell!.detailTextLabel?.text = info.1
        return cell!
    }
}
