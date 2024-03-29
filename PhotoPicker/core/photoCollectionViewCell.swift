
//
//  photoCollectionViewCell.swift
//  PhotoPicker
//
//  Created by liangqi on 16/3/6.
//  Copyright © 2016年 dailyios. All rights reserved.
//

import UIKit
import Photos
protocol PhotoCollectionViewCellDelegate: class {
    func eventSelectNumberChange(number: Int);
    
}
class photoCollectionViewCell: UICollectionViewCell {
	
	@IBOutlet weak var thumbnail: UIImageView!
	@IBOutlet weak var imageSelect: UIImageView!
    @IBOutlet weak var selectButton: UIButton!
    
	weak var delegate: PhotoCollectionViewController?
    weak var eventDelegate: PhotoCollectionViewCellDelegate?
	
	var representedAssetIdentifier: String?
	var model : PHAsset?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		self.thumbnail.contentMode = .scaleAspectFill
		self.thumbnail.clipsToBounds = true
	}
    
    func updateSelected(select:Bool){
        self.selectButton.isSelected = select
        self.imageSelect.isHidden = !select
        
        if select {
            self.selectButton.setImage(nil, for: UIControl.State.normal)
        } else {
            self.selectButton.setImage(UIImage(named: "picture_unselect"), for: .normal)
        }
    }
	
	@IBAction func eventImageSelect(sender: UIButton) {
		if sender.isSelected {
			sender.isSelected = false
			self.imageSelect.isHidden = true
			sender.setImage(UIImage(named: "picture_unselect"), for: .normal)
			if delegate != nil {
				if let index = PhotoImage.instance.selectedImage.index(of: self.model!) {
					PhotoImage.instance.selectedImage.remove(at: index)
				}
                
                if self.eventDelegate != nil {
                    self.eventDelegate!.eventSelectNumberChange(number: PhotoImage.instance.selectedImage.count)
                }
			}
		} else {
			
			if delegate != nil {
				if PhotoImage.instance.selectedImage.count >= PhotoPickerController.imageMaxSelectedNum - PhotoPickerController.alreadySelectedImageNum {
					self.showSelectErrorDialog() ;
					return;
				} else {
					PhotoImage.instance.selectedImage.append(self.model!)
                    
                    if self.eventDelegate != nil {
                        self.eventDelegate!.eventSelectNumberChange(number: PhotoImage.instance.selectedImage.count)
                    }
				}
			}
			
			sender.isSelected = true
            self.imageSelect.isHidden = false
			sender.setImage(nil, for: .normal)
			self.imageSelect.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 6, options: [.curveEaseIn], animations: { () -> Void in
					self.imageSelect.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
				}, completion: nil)
		}
	}
	
	private func showSelectErrorDialog() {
		if self.delegate != nil {
            let less = PhotoPickerController.imageMaxSelectedNum - PhotoPickerController.alreadySelectedImageNum
            
            let range = PhotoPickerConfig.ErrorImageMaxSelect.range(of:"#")
            var error = PhotoPickerConfig.ErrorImageMaxSelect
            error.replaceSubrange(range!, with: String(less))
            
			let alert = UIAlertController.init(title: nil, message: error, preferredStyle: .alert)
			let confirmAction = UIAlertAction(title: PhotoPickerConfig.ButtonConfirmTitle, style: .default, handler: nil)
			alert.addAction(confirmAction)
			self.delegate?.present(alert, animated: true, completion: nil)
		}
	}
}
