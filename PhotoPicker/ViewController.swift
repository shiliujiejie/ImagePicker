//
//  ViewController.swift
//  PhotoPicker
//
//  Created by liangqi on 16/3/4.
//  Copyright © 2016年 dailyios. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

class ViewController: UIViewController {
    
    var selectModel = [PhotoImageModel]()
    var containerView = UIView()
    
    var triggerRefresh = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.containerView)
        self.checkNeedAddButton()
    }
    
    private func checkNeedAddButton(){
        if self.selectModel.count < PhotoPickerController.imageMaxSelectedNum && !hasButton() {
            selectModel.append(PhotoImageModel(type: ModelType.Button, data: nil))
        }
    }

    private func hasButton() -> Bool{
        for item in self.selectModel {
            if item.type == ModelType.Button {
                return true
            }
        }
        return false
    }
    
    /**
     * 删除已选择图片数据 Model
     */
    func removeElement(element: PhotoImageModel?){
        if let current = element {
            self.selectModel = self.selectModel.filter({$0 != current})
            self.triggerRefresh = true // 删除数据事出发重绘界面逻辑
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .default
        self.navigationController?.navigationBar.barStyle = .default
        eventAddImage()
    }
    
   

    
    // MARK: - 按钮事件
    @objc func eventPreview(button:UIButton){
        let preview = SinglePhotoPreviewViewController()
        let data = self.getModelExceptButton()
        preview.selectImages = data
        preview.sourceDelegate = self
        preview.currentPage = button.tag
        self.show(preview, sender: nil)
    }
    
    // 页面底部 stylesheet
    @objc func eventAddImage() {
        let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // change the style sheet text color
        alert.view.tintColor = UIColor.black
        
        let actionCancel = UIAlertAction.init(title: "取消", style: .cancel, handler: nil)
        let actionCamera = UIAlertAction.init(title: "拍照", style: .default) { (UIAlertAction) -> Void in
            self.selectByCamera()
        }
        
        let actionPhoto = UIAlertAction.init(title: "从手机照片中选择", style: .default) { (UIAlertAction) -> Void in
            self.selectFromPhoto()
        }
        
        alert.addAction(actionCancel)
        alert.addAction(actionCamera)
        alert.addAction(actionPhoto)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // 拍照获取
    private func selectByCamera(){
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera // 调用摄像头
        imagePicker.cameraDevice = .rear // 后置摄像头拍照
        imagePicker.cameraCaptureMode = .photo // 拍照
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as String]
        
        imagePicker.modalPresentationStyle = .popover
        self.show(imagePicker, sender: nil)
    }
    
    /**
     * 从相册中选择图片
     */
    private func selectFromPhoto(){
        PHPhotoLibrary.requestAuthorization {[unowned self] (status) -> Void in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.showLocalPhotoGallery()
                    break
                default:
                    self.showNoPermissionDailog()
                    break
                }
            }
        }
    }
    
    /**
     * 用户相册未授权，Dialog提示
     */
    private func showNoPermissionDailog(){
        let alert = UIAlertController.init(title: nil, message: "没有打开相册的权限", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
  // MARK: -  打开本地相册列表
    private func showLocalPhotoGallery(){
        let picker = PhotoPickerController(type: PageType.RecentAlbum)
        picker.imageSelectDelegate = self
        picker.modalPresentationStyle = .popover
        PhotoPickerController.imageMaxSelectedNum = 4 // 允许选择的最大图片张数
        let realModel = self.getModelExceptButton() // 获取已经选择过的图片
        PhotoPickerController.alreadySelectedImageNum = realModel.count
        debugPrint(realModel.count)
        self.show(picker, sender: nil)
    }
    
    private func getModelExceptButton()->[PhotoImageModel]{
        var newModels = [PhotoImageModel]()
        for i in 0..<self.selectModel.count {
            let item = self.selectModel[i]
            if item.type != .Button {
                newModels.append(item)
            }
        }
        return newModels
    }
    
}

 // MARK: -  拍照 delegate相关方法
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // 完成拍照
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let mediaType = UIImagePickerController.InfoKey.mediaType
        var image: UIImage? = nil
        var localId: String? = ""
        if picker.isEditing { // 拍照图片运行编辑，则优先尝试从编辑后的类型中获取图片
            image = info[.editedImage] as? UIImage
        }else{
            image = info[.originalImage] as? UIImage
        }
        // 存入相册
        if image != nil {
            PHPhotoLibrary.shared().performChanges({
                let result = PHAssetChangeRequest.creationRequestForAsset(from: image!)
                let assetPlaceholder = result.placeholderForCreatedAsset
                localId = assetPlaceholder?.localIdentifier
            }, completionHandler: { (success, error) in
                if success && localId != nil {
                    let assetResult = PHAsset.fetchAssets(withLocalIdentifiers: [localId!], options: nil)
                    let asset = assetResult[0]
                    DispatchQueue.main.async {
                        self.renderSelectImages(images: [asset])
                    }
                }
            })
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - 相册选择  PhotoPickerControllerDelegate
extension ViewController: PhotoPickerControllerDelegate {
    
    func onImageSelectFinished(images: [PHAsset]) {
        self.renderSelectImages(images: images)
    }
    
    private func renderSelectImages(images: [PHAsset]){
        for item in images {
            self.selectModel.insert(PhotoImageModel(type: ModelType.Image, data: item), at: 0)
        }
        
        let total = self.selectModel.count;
        if total > PhotoPickerController.imageMaxSelectedNum {
            for i in 0 ..< total {
                let item = self.selectModel[i]
                if item.type == .Button {
                    self.selectModel.remove(at: i)
                }
            }
        }
    }
}
