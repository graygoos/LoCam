
/*
 V1:
 Place date & location labels in PhotoView✅
 Place flipCameraButton centered with cameraButton ✅
 Save photos and video with date and location data - metadata and visible when viewing files
 Have the date update in real time as the camera feed is showing and save the exact time a photo is taken in metadata
 Make  date and location labels adapt to  all iPhone sizes
 Add flipCamera functionality to video view
 Fix threading issues in VideoViewController and save to photo album
 Fix captureSession issues and be able to switch segmented control smoothly
 Add location and date labels to VideoViewController
 View to show recordings and/photos in both photo and video views
 Add settings button to top of both views
 Add Flash button/functionality to both video and photo
 Flip selfie photos
 Make app as bright as stock Apple photos app
 Errors/ Alerts
 Light and dark mode support
    -
    -
    -
 Polish App design
 Push to Test Flight and get users
 
 
 Start planning V2 features after above
 
 
 V2:
 Design
 Include pin emoji in location text and clock emoji in date text?
 Landscape support
 Settings functionality
 Live streaming/broadcasting
 Hide location
 Blur faces
 Obscure voice
 Blur background
 Front and rear camera simultaneous video/photo
 Implement APIs form WWDC 2023
 
 blur/obscure faces, change voice, include location pin 📍 so a person viewing the photo or video can locate the place where the photo was taken - include the map/location functionality in the app, open photos taken with the app - be able to track
 
 advanced features from discussion with Grant, stream video
 
 check to ensure airdrop does not strip date and location data from exported photos/videos
 */



/*
 PROMPT: I want the date and location visible on the saved photo, not just as metadata
 
 Sure, you can also make the date and location visible on the saved photo as a watermark. Here are the steps on how to do it:

 Import the CoreLocation and Photos frameworks.
 Get the user's current location using the CLLocationManager class.
 Get the current date using the Date class.
 Create a PHAssetChangeRequest object.
 Set the location and date on the PHAssetChangeRequest object.
 Save the PHAssetChangeRequest object.
 Get the asset for the saved photo.
 Get the image for the asset.
 Create a watermark with the location and date.
 Add the watermark to the image.
 Save the image.
 Here is an example code:
 
 
 import CoreLocation
 import Photos

 func savePhotoWithLocationAndDate(image: UIImage) {
     let locationManager = CLLocationManager()
     let location = locationManager.location
     let date = Date()

     let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
     assetChangeRequest.location = location
     assetChangeRequest.dateCreated = date

     PHPhotoLibrary.shared().performChanges(
         {
             PHAssetChangeRequest.save(assetChangeRequest)
         },
         completionHandler: { success, error in
             if success {
                 print("Photo saved with location and date")
                 let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetChangeRequest.asset.localIdentifier], options: nil).firstObject
                 let image = asset?.image
                 let watermark = watermark(location: location, date: date)
                 let watermarkedImage = watermarkImage(image: image, watermark: watermark)
                 PHPhotoLibrary.shared().performChanges(
                     {
                         PHAssetChangeRequest.updateAsset(asset, image: watermarkedImage)
                     },
                     completionHandler: { success, error in
                         if success {
                             print("Watermarked photo saved")
                         } else {
                             print("Error saving watermarked photo: \(error)")
                         }
                     }
                 )
             } else {
                 print("Error saving photo: \(error)")
             }
         }
     )
 }

 func watermark(location: CLLocation?, date: Date) -> UIImage {
     let locationString = location?.coordinate.description ?? ""
     let dateString = date.description
     let text = locationString + "\n" + dateString
     let attributes: [NSAttributedString.Key: Any] = [
         .font: UIFont.systemFont(ofSize: 12),
         .foregroundColor: UIColor.white,
         .backgroundColor: UIColor.black,
     ]
     let watermarkImage = NSAttributedString(string: text, attributes: attributes).image()
     return watermarkImage
 }

 func watermarkImage(image: UIImage, watermark: UIImage) -> UIImage {
     let size = image.size
     let watermarkSize = watermark.size
     let x = (size.width - watermarkSize.width) / 2
     let y = (size.height - watermarkSize.height) / 2

     let watermarkedImage = UIGraphicsImageRenderer(size: size).image { _ in
         image.draw(in: CGRect(origin: .zero, size: size))
         watermark.draw(in: CGRect(origin: CGPoint(x: x, y: y), size: watermarkSize))
     }

     return watermarkedImage
 }

 This code will save the photo to the photo library with the location and date set. You can then view the location and date when you view the photo in the photo album. The location and date will be visible as a watermark on the photo.

 I hope this helps! Let me know if you have any other questions.
 
 */






/*
private func savePhotoWithDateAndLocation(image: UIImage) {
    let locationManager = CLLocationManager()
    let location = locationManager.location
    let date = Date()
    
    let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
    assetChangeRequest.location = location
    assetChangeRequest.creationDate = date
    
//        PHPhotoLibrary.shared().performChanges
}


func watermark(location: CLLocation?, date: Date) -> UIImage {
    let locationString = location?.debugDescription ?? ""
    let dateString = date.description
    let text = locationString + "\n" + dateString
    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 12),
        .foregroundColor: UIColor.white,
        .backgroundColor: UIColor.black
    ]
//        let watermarkImage = NSAttributedString(string: text, attributes: attributes).image()
    let size = CGSize(width: 200, height: 200)
    let attributedString = NSAttributedString(string: text, attributes: attributes)
    let image = UIGraphicsImageRenderer(size: size).image { _ in
        attributedString.draw(in: CGRect(origin: .zero, size: size))
    }
    
//        return watermarkImage
    return image
}

func watermarkImage(image: UIImage, watermark: UIImage) -> UIImage {
    let size = image.size
    let waterMarkSize = watermark.size
    let x = (size.width - waterMarkSize.width) / 2
    let y = (size.height - waterMarkSize.height) / 2
    
    let watermarkImage = UIGraphicsImageRenderer(size: size).image { _ in
        image.draw(in: CGRect(origin: .zero, size: size))
        watermark.draw(in: CGRect(origin: CGPoint(x: x, y: y), size: waterMarkSize))
    }
    
    return watermarkImage
}
*/

/*
func addDateAndLocationToPhotos(image: UIImage, text: String, location: String, textColor: UIColor, textFont: UIFont) -> UIImage? {
    // create a copy of the image
    UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
    image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    
    // Define the attributes for the text
    let textAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: textColor,
        .font: textFont
    ]
    
    // Calculate the size of the text
    let textSize = (text as NSString).size(withAttributes: textAttributes)
    
    // Calculate the position to draw the text
    let textRect = CGRect(
        x: (image.size.width - textSize.width) / 2,
        y: (image.size.height - textSize.height) / 2,
        width: textSize.width,
        height: textSize.height
    )
    
    // Draw the text on the image
    text.draw(in: textRect, withAttributes: textAttributes)
    
    // Get the final image with the added text
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
}
 */

/*
// Usage example
let originalImage = UIImage(named: "original_image")
let text = "Hello World"
let textColor = UIColor.white
let textFont = UIFont.boldSystemFont(ofSize: 24.0)

if let imageWithText = addTextToImage(image: originalImage, text: text, textColor: textColor, textFont: textFont) {
    // Do something with the image that has the added text
    // For example, you can display it an image view
    let imageView = UIImageView(image: imageWithText)
    // ... Add the image view to your view hierarchy or perform any other actiond
}
*/
