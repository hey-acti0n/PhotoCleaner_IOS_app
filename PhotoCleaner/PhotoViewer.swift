import SwiftUI
import Photos
import AVKit

struct PhotoViewer: View {
    @ObservedObject var photoManager: PhotoManager
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset = CGSize.zero
    @State private var currentImage: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    
    let canReturnToSelection: Bool
    
    init(photoManager: PhotoManager, canReturnToSelection: Bool = false) {
        self.photoManager = photoManager
        self.canReturnToSelection = canReturnToSelection
    }
    
    private let screenWidth = UIScreen.main.bounds.width
    private let swipeThreshold: CGFloat = UIScreen.main.bounds.width * Constants.SwipeThresholds.percentage
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Фон
                Color.black.ignoresSafeArea()
                
                if photoManager.isAuthorized {
                    // Верхняя панель с информацией
                    VStack {
                        HStack {
                            Spacer()
                            
                            // Индикатор корзины
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                                Text("\(photoManager.photosToDelete.count)")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(25)
                            
                            // Индикатор прогресса
                            HStack {
                                Text("\(photoManager.currentPhotoIndex + 1) из \(photoManager.photos.count)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    
                    if let currentPhoto = photoManager.getCurrentPhoto() {
                        // Основное содержимое (фото или видео)
                        if photoManager.isVideo(currentPhoto) {
                            // Отображение видео
                            VideoPlayerView(asset: currentPhoto, photoManager: photoManager)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .gesture(
                                    // Жест свайпа для навигации по видео
                                    DragGesture()
                                        .onChanged { value in
                                            dragOffset = value.translation
                                        }
                                        .onEnded { value in
                                            handleSwipe(value: value)
                                        }
                                )
                                .onDisappear {
                                    // Сбрасываем состояние при исчезновении видео
                                    dragOffset = .zero
                                }
                        } else {
                            // Отображение фото (существующая логика)
                            if let image = currentImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .scaleEffect(scale)
                                    .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
                                    .gesture(
                                        // Жест свайпа для навигации
                                        DragGesture()
                                            .onChanged { value in
                                                // Если изображение не увеличено, обрабатываем свайп для навигации
                                                if scale <= 1.0 {
                                                    dragOffset = value.translation
                                                } else {
                                                    // Если увеличено, перемещаем изображение
                                                    offset = CGSize(
                                                        width: lastOffset.width + value.translation.width,
                                                        height: lastOffset.height + value.translation.height
                                                    )
                                                }
                                            }
                                            .onEnded { value in
                                                if scale <= 1.0 {
                                                    handleSwipe(value: value)
                                                } else {
                                                    // Сохраняем позицию для следующего жеста
                                                    lastOffset = offset
                                                }
                                            }
                                    )
                                    .gesture(
                                        // Жест масштабирования
                                        MagnificationGesture()
                                            .onChanged { value in
                                                let delta = value / lastScale
                                                lastScale = value
                                                scale = min(max(scale * delta, 1.0), 4.0)
                                                
                                                // Сбрасываем смещение при возврате к нормальному размеру
                                                if scale <= 1.0 {
                                                    withAnimation(.spring()) {
                                                        offset = .zero
                                                        lastOffset = .zero
                                                    }
                                                }
                                            }
                                            .onEnded { _ in
                                                lastScale = 1.0
                                                
                                                // Возвращаем к нормальному размеру, если слишком маленький
                                                if scale < 1.0 {
                                                    withAnimation(.spring()) {
                                                        scale = 1.0
                                                        offset = .zero
                                                        lastOffset = .zero
                                                    }
                                                }
                                            }
                                    )
                                    .gesture(
                                        // Двойной тап для сброса масштаба
                                        TapGesture(count: 2)
                                            .onEnded {
                                                withAnimation(.spring()) {
                                                    scale = 1.0
                                                    offset = .zero
                                                    lastOffset = .zero
                                                    dragOffset = .zero
                                                }
                                            }
                                    )
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scale)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: offset)
                            } else {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Кнопка выхода поверх медиафайла
                        VStack {
                            HStack {
                                Button(action: {
                                    dismiss()
                                }) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                            .font(.title2)
                                        Text(canReturnToSelection ? "Gallery" : "Main menu")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(25)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            Spacer()
                        }
                        
                        // Кнопки действий
                        VStack {
                            Spacer()
                            HStack(spacing: 20) {
                                // Кнопка удаления
                                Button(action: {
                                    withAnimation {
                                        photoManager.markPhotoForDeletion()
                                        if !photoManager.isVideo(currentPhoto) {
                                            loadCurrentImage()
                                        }
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 60, height: 60)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                }
                                
                                // Кнопка сохранения
                                Button(action: {
                                    withAnimation {
                                        photoManager.keepCurrentPhoto()
                                        if !photoManager.isVideo(currentPhoto) {
                                            loadCurrentImage()
                                        }
                                    }
                                }) {
                                    Image(systemName: "checkmark")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 60, height: 60)
                                        .background(Color.green)
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.trailing)
                        }
                        .padding(.bottom, 50)
                        
                        // Подсказки по свайпу
                        VStack {
                            HStack {
                                VStack {
                                    Image(systemName: "arrow.left")
                                        .font(.title)
                                        .foregroundColor(.red)
                                    Text("Delete")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .padding()
                                .cornerRadius(15)
                                
                                Spacer()
                                
                                VStack {
                                    Image(systemName: "arrow.right")
                                        .font(.title)
                                        .foregroundColor(.green)
                                    Text("Keep")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                .padding()
                                .cornerRadius(15)
                            }
                            .padding(.horizontal, 40)
                            
                            Spacer()
                        }
                        .padding(.top, 60)
                    } else {
                        // Нет медиафайлов
                        VStack(spacing: 20) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                            
                            Text("Empty gallery")
                                .font(.title)
                                .foregroundColor(.white)
                            
                            Text(Constants.UserMessages.emptyGallery)
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                } else {
                    // Запрос разрешения
                    VStack(spacing: 30) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("Acess to mediafiles")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Text(Constants.UserMessages.photoAccessRequired)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Grant acess") {
                            photoManager.requestPhotoLibraryAccess()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(25)
                    }
                }
            }
        }
        .onAppear {
            if let currentPhoto = photoManager.getCurrentPhoto(), !photoManager.isVideo(currentPhoto) {
                loadCurrentImage()
            }
        }
        .onChange(of: photoManager.currentPhotoIndex) { _ in
            // Сбрасываем масштаб и позицию при смене медиафайла
            withAnimation(.spring()) {
                scale = 1.0
                offset = .zero
                lastOffset = .zero
                dragOffset = .zero
            }
            
            if let currentPhoto = photoManager.getCurrentPhoto(), !photoManager.isVideo(currentPhoto) {
                loadCurrentImage()
            }
        }
        .onDisappear {
            // Очищаем изображение при закрытии экрана
            currentImage = nil
        }
        .onChange(of: photoManager.photos.count) { _ in
            if let currentPhoto = photoManager.getCurrentPhoto(), !photoManager.isVideo(currentPhoto) {
                loadCurrentImage()
            }
        }
    }
    
    private func loadCurrentImage() {
        guard let currentPhoto = photoManager.getCurrentPhoto() else {
            currentImage = nil
            return
        }
        
        // Загружаем изображение только для фото
        guard !photoManager.isVideo(currentPhoto) else { return }
        
        // Сбрасываем текущее изображение перед загрузкой нового
        currentImage = nil
        
        // Сбрасываем состояние масштабирования
        scale = 1.0
        offset = .zero
        lastOffset = .zero
        dragOffset = .zero
        
        let size = Constants.ImageSizes.preview
        photoManager.getPhotoImage(for: currentPhoto, size: size) { image in
            DispatchQueue.main.async {
                self.currentImage = image
            }
        }
    }
    
    private func handleSwipe(value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height
        
        // Проверяем, что свайп преимущественно горизонтальный
        if abs(horizontalAmount) > abs(verticalAmount) {
            if horizontalAmount > swipeThreshold {
                // Свайп вправо - оставить медиафайл
                withAnimation {
                    photoManager.keepCurrentPhoto()
                    if let currentPhoto = photoManager.getCurrentPhoto(), !photoManager.isVideo(currentPhoto) {
                        loadCurrentImage()
                    }
                }
            } else if horizontalAmount < -swipeThreshold {
                // Свайп влево - отметить для удаления
                withAnimation {
                    photoManager.markPhotoForDeletion()
                    if let currentPhoto = photoManager.getCurrentPhoto(), !photoManager.isVideo(currentPhoto) {
                        loadCurrentImage()
                    }
                }
            }
        }
        
        // Возвращаем медиафайл в исходное положение
        dragOffset = .zero
    }
}
