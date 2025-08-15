import Foundation
import UIKit

// Константы для безопасности и конфигурации
struct Constants {
    
    // Размеры изображений
    struct ImageSizes {
        static let thumbnail = CGSize(width: 200, height: 200)
        static let preview = CGSize(width: 1000, height: 1000)
        static let fullScreen = CGSize(width: 2000, height: 2000)
    }
    
    // Пороги для свайпов
    struct SwipeThresholds {
        static let percentage: CGFloat = 0.3 // 30% от ширины экрана
        static let minimumDistance: CGFloat = 50 // Минимальное расстояние в пикселях
    }
    
    // Таймауты и задержки
    struct Timeouts {
        static let imageLoadTimeout: TimeInterval = 30.0
        static let animationDuration: Double = 0.3
    }
    
    // Максимальные значения
    struct Limits {
        static let maxPhotosInTrash = 1000
        static let maxPhotosToKeep = 10000
    }
    
    // Сообщения об ошибках
    struct ErrorMessages {
        static let noPhotoAccess = "Нет доступа к фотографиям"
        static let noDeletePermission = "Нет прав на удаление фотографий"
        static let photoLoadFailed = "Не удалось загрузить фотографию"
        static let deleteFailed = "Не удалось удалить фотографию"
        static let networkError = "Ошибка сети при загрузке фотографии"
    }
    
    // Сообщения для пользователя
    struct UserMessages {
        static let photoAccessRequired = "Приложению необходим доступ к вашей галерее для очистки фотографий"
        static let emptyGallery = "В вашей галерее нет фотографий для очистки"
        static let emptyTrash = "Фотографии для удаления появятся здесь после свайпа влево"
    }
}
