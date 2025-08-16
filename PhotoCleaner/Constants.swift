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
        static let videoLoadTimeout: TimeInterval = 45.0
        static let animationDuration: Double = 0.3
    }
    
    // Максимальные значения
    struct Limits {
        static let maxPhotosInTrash = 1000
        static let maxPhotosToKeep = 10000
        static let maxVideoDuration: TimeInterval = 300.0 // 5 минут
    }
    
    // Сообщения об ошибках
    struct ErrorMessages {
        static let noPhotoAccess = "Нет доступа к медиафайлам"
        static let noDeletePermission = "Нет прав на удаление медиафайлов"
        static let photoLoadFailed = "Не удалось загрузить изображение"
        static let videoLoadFailed = "Не удалось загрузить видео"
        static let deleteFailed = "Не удалось удалить медиафайл"
        static let networkError = "Ошибка сети при загрузке медиафайла"
    }
    
    // Сообщения для пользователя
    struct UserMessages {
        static let photoAccessRequired = "Приложению необходим доступ к вашей галерее для очистки медиафайлов"
        static let emptyGallery = "В вашей галерее нет медиафайлов для очистки"
        static let emptyTrash = "Deleted files will appear here after swiping left"
        static let videoPlaying = "Воспроизведение видео"
        static let videoLoadError = "Ошибка загрузки видео"
    }
    
    // Настройки видео
    struct VideoSettings {
        static let autoPlay = true
        static let loopPlayback = false
        static let showControls = true
        static let quality = "high"
    }
}
