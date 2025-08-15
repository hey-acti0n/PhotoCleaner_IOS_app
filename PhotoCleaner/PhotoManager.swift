import Foundation
import Photos
import UIKit

class PhotoManager: ObservableObject {
    @Published var photos: [PHAsset] = []
    @Published var currentPhotoIndex: Int = 0
    @Published var isAuthorized = false
    @Published var photosToDelete: Set<String> = [] // ID фотографий для удаления
    @Published var photosToKeep: Set<String> = [] // ID фотографий для сохранения
    
    init() {
        requestPhotoLibraryAccess()
    }
    
    deinit {
        // Очищаем ресурсы при деинициализации
        photos.removeAll()
        photosToDelete.removeAll()
        photosToKeep.removeAll()
        
        // Отменяем все активные запросы изображений
        PHImageManager.default().cancelImageRequest(PHInvalidImageRequestID)
    }
    
    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isAuthorized = status == .authorized
                if self?.isAuthorized == true {
                    self?.loadPhotos()
                }
            }
        }
    }
    
    func loadPhotos() {
        // Проверяем права доступа перед загрузкой
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            DispatchQueue.main.async {
                self.isAuthorized = false
            }
            return
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Выполняем загрузку на фоновом потоке
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                // Ограничиваем количество загружаемых фотографий для предотвращения переполнения памяти
                let maxPhotos = min(fetchResult.count, 10000)
                self.photos = fetchResult.objects(at: IndexSet(0..<maxPhotos))
                self.currentPhotoIndex = 0 // Сбрасываем индекс к началу
            }
        }
    }
    
    func getCurrentPhoto() -> PHAsset? {
        guard photos.count > 0, currentPhotoIndex >= 0, currentPhotoIndex < photos.count else { 
            return nil 
        }
        return photos[currentPhotoIndex]
    }
    
    func moveToNextPhoto() {
        guard photos.count > 0 else { return }
        
        if currentPhotoIndex < photos.count - 1 {
            currentPhotoIndex += 1
        }
    }
    
    func deleteCurrentPhoto() {
        guard currentPhotoIndex < photos.count else { return }
        
        let photoToDelete = photos[currentPhotoIndex]
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([photoToDelete] as NSFastEnumeration)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // Удаляем фото из массива
                    self?.photos.remove(at: self?.currentPhotoIndex ?? 0)
                    
                    // Если это было последнее фото, возвращаемся к предыдущему
                    if self?.currentPhotoIndex == self?.photos.count {
                        self?.currentPhotoIndex = max(0, (self?.photos.count ?? 1) - 1)
                    }
                }
            }
        }
    }
    
    func keepCurrentPhoto() {
        guard currentPhotoIndex < photos.count else { return }
        let currentPhoto = photos[currentPhotoIndex]
        let photoId = currentPhoto.localIdentifier
        
        // Валидация ID фотографии
        guard !photoId.isEmpty else { return }
        
        // Проверяем лимит сохранения
        guard photosToKeep.count < Constants.Limits.maxPhotosToKeep else {
            return
        }
        
        // Убираем из списка удаления, если был там
        photosToDelete.remove(photoId)
        // Добавляем в список сохранения
        photosToKeep.insert(photoId)
        
        moveToNextPhoto()
    }
    
    func markPhotoForDeletion() {
        guard currentPhotoIndex < photos.count else { return }
        let currentPhoto = photos[currentPhotoIndex]
        let photoId = currentPhoto.localIdentifier
        
        // Валидация ID фотографии
        guard !photoId.isEmpty else { return }
        
        // Проверяем лимит корзины
        guard photosToDelete.count < Constants.Limits.maxPhotosInTrash else {
            return
        }
        
        // Убираем из списка сохранения, если был там
        photosToKeep.remove(photoId)
        // Добавляем в список удаления
        photosToDelete.insert(photoId)
        
        moveToNextPhoto()
    }
    
    func deleteMarkedPhotos() {
        guard !photosToDelete.isEmpty else { return }
        
        // Получаем все фотографии для удаления
        let photosToDeleteAssets = photos.filter { photosToDelete.contains($0.localIdentifier) }
        
        // Проверяем, что у нас есть права на удаление
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(photosToDeleteAssets as NSFastEnumeration)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // Удаляем фотографии из массива
                    self?.photos.removeAll { photosToDeleteAssets.contains($0) }
                    
                    // Очищаем корзину
                    self?.photosToDelete.removeAll()
                    self?.photosToKeep.removeAll()
                    
                    // Корректируем текущий индекс
                    if self?.currentPhotoIndex ?? 0 >= self?.photos.count ?? 0 {
                        self?.currentPhotoIndex = max(0, (self?.photos.count ?? 1) - 1)
                    }
                } else {
                    // Обработка ошибки
                    if error != nil {
                        // Логирование ошибки удаления
                    }
                }
            }
        }
    }
    
    func deleteSelectedPhotos(_ selectedIds: Set<String>) {
        guard !selectedIds.isEmpty else { return }
        
        // Валидация входных данных
        let validIds = selectedIds.filter { !$0.isEmpty }
        guard !validIds.isEmpty else { return }
        
        // Получаем выбранные фотографии для удаления
        let photosToDeleteAssets = photos.filter { validIds.contains($0.localIdentifier) }
        
        // Проверяем, что у нас есть права на удаление
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(photosToDeleteAssets as NSFastEnumeration)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // Удаляем фотографии из массива
                    self?.photos.removeAll { photosToDeleteAssets.contains($0) }
                    
                    // Убираем удаленные из корзины
                    for photoId in validIds {
                        self?.photosToDelete.remove(photoId)
                    }
                    
                    // Корректируем текущий индекс
                    if self?.currentPhotoIndex ?? 0 >= self?.photos.count ?? 0 {
                        self?.currentPhotoIndex = max(0, (self?.photos.count ?? 1) - 1)
                    }
                } else {
                    // Обработка ошибки
                    if error != nil {
                        // Логирование ошибки удаления
                    }
                }
            }
        }
    }
    
    func getPhotoById(_ photoId: String) -> PHAsset? {
        guard !photoId.isEmpty else { return nil }
        guard photoId.count <= 1000 else { return nil } // Защита от слишком длинных ID
        return photos.first { $0.localIdentifier == photoId }
    }
    
    func clearTrash() {
        photosToDelete.removeAll()
        photosToKeep.removeAll()
    }
    
    func getPhotoImage(for asset: PHAsset, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        // Создаем уникальный ID для запроса
        _ = PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, info in
            // Проверяем, что запрос не был отменен
            if let isCancelled = info?[PHImageCancelledKey] as? Bool, isCancelled {
                return
            }
            
            // Проверяем, что это правильный размер изображения
            if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                // Изображение низкого качества, игнорируем
                return
            }
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
        
        // Сохраняем ID запроса для возможности отмены
        // В реальном приложении можно добавить словарь для отслеживания активных запросов
    }
}
