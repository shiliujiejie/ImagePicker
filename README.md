# ImagePicker
image Picker      image shower


    let picker = PhotoPickerController(type: PageType.RecentAlbum)
    picker.imageSelectDelegate = self
    picker.modalPresentationStyle = .Popover

    // max select number
     PhotoPickerController.imageMaxSelectedNum = 4

     self.showViewController(picker, sender: nil)
    ``
    图片选择器默认打开最近添加相册列表，如果需要打开其他相册，或者首先打开相册列表，请直接设置`PageType`枚举具体类型即可：
    ```
     enum PageType{
       case List      // 打开相册列表
       case RecentAlbum // 直接打开最近添加相册
       case AllAlbum // 直接打开所有相册列表
    }
