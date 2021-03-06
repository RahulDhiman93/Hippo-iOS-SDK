//
//  FileUploader.swift
//  SDKDemo1
//
//  Created by cl-macmini-117 on 13/12/17.
//  Copyright © 2017 CL-macmini-88. All rights reserved.
//

import Foundation


struct FileUploader {
    struct Result {
        let isSuccessful: Bool
        let error: Error?
        let imageUrl: String?
        let imageThumbnailUrl: String?
        let fileUrl: String?
    }
    struct RequestParams {
        public let path: String
        public let mimeType: String
        public let fileName: String
        
        public init(path: String, mimeType: String, fileName: String = "") {
            self.path = path
            self.mimeType = mimeType
            
            if fileName.isEmpty {
                self.fileName = URL.init(fileURLWithPath: path).lastPathComponent
            } else {
                self.fileName = fileName
            }
        }
    }
    
    static func uploadFileWith(request: RequestParams, completion: @escaping (FileUploader.Result) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            let pathURL = URL.init(fileURLWithPath: request.path)
            
            guard let dataOfFile = try? Data.init(contentsOf: pathURL, options: []) else {
                let result = Result(isSuccessful: false, error: nil, imageUrl: nil, imageThumbnailUrl: nil, fileUrl: nil)
                DispatchQueue.main.async {
                    completion(result)
                }
                return
            }
            let parameters = getParamsToUploadImageWith(for: request)
            guard let file = HippoFile(data: dataOfFile as Data, name: request.fileName, fileName: request.fileName, mimeType: request.mimeType) else {
                let result = Result(isSuccessful: false, error: nil, imageUrl: nil, imageThumbnailUrl: nil, fileUrl: nil)
                DispatchQueue.main.async {
                    completion(result)
                }
                return
            }
                        
            let endPoint = FuguEndPoints.API_UPLOAD_FILE.rawValue
            HTTPClient.makeMultiPartRequestWith(method: .POST, para: parameters, extendedUrl: endPoint, fileList: [file]) { (responseObject, error, _, _) in
                
                let failureResult = Result(isSuccessful: false, error: error, imageUrl: nil, imageThumbnailUrl: nil, fileUrl: nil)
                
                guard error == nil, let value = responseObject as? [String: Any], let data = value["data"] as? [String: Any] else {
                    DispatchQueue.main.async {
                        completion(failureResult)
                    }
                    return
                }
                let imageUrl = data["image_url"] as? String
                var thumbnailUrl = data["thumbnail_url"] as? String
                let url = data["url"] as? String
                
                
                // Compression on gif on backend side is resulting in single frame, so sending orignal url in thumbnailURL
                if let imageURLExtention = URL(string: imageUrl ?? "")?.pathExtension, imageURLExtention.lowercased() == "gif" {
                    thumbnailUrl = imageUrl
                }
                
                let result = Result(isSuccessful: true, error: nil, imageUrl: imageUrl, imageThumbnailUrl: thumbnailUrl, fileUrl: url)
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
    }
    
    private static func getParamsToUploadImageWith(for request: RequestParams) -> [String: Any] {
        
        var params: [String: Any] = ["file_name": request.fileName]
        
        if HippoConfig.shared.appUserType == .customer {
            params["app_secret_key"] = HippoConfig.shared.appSecretKey
        } else if let token = HippoConfig.shared.agentDetail?.fuguToken {
            params["access_token"] = token
        }
        params["allow_all_mime_type"] = true
        params["file_type"] = request.mimeType
        return params
    }
    static func saveImageInKingfisherCacheFor(thumbnailUrl: String, originalUrl: String, localPath: String) {
        let _ = URL.init(fileURLWithPath: localPath)
        
//        guard let cachedImageData = try? Data.init(contentsOf: pathURL, options: []) else {
//            return
//        }
//        let options = ImageCreatingOptions(scale: 1, duration: 1, preloadAll: true, onlyFirstFrame: false)
//
//        if cachedImageData.kf.imageFormat == .GIF, let cachedImage = KingfisherWrapper<Image>.animatedImage(data: cachedImageData, options: options) {
//            ImageCache.default.store(cachedImage, original: cachedImageData, forKey: thumbnailUrl)
//            ImageCache.default.store(cachedImage, original: cachedImageData, forKey: originalUrl)
//        } else if let cachedImage = UIImage(data: cachedImageData) {
//            ImageCache.default.store(cachedImage, forKey: thumbnailUrl)
//            ImageCache.default.store(cachedImage, forKey: originalUrl)
//        }
    }
}
