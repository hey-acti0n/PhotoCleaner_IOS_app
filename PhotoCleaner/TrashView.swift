import SwiftUI
import Photos

struct TrashView: View {
    @ObservedObject var photoManager: PhotoManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotos: Set<String> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if photoManager.photosToDelete.isEmpty {
                    // Пустая корзина
                    VStack(spacing: 30) {
                        Image(systemName: "trash")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("Bin empty")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Text(Constants.UserMessages.emptyTrash)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    // Список медиафайлов в корзине
                    VStack {
                        // Заголовок с количеством
                        HStack {
                            Text("For cleaning")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("\(photoManager.photosToDelete.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                
                                // Статистика по типам в корзине
                                let photoIds = photoManager.photosToDelete
                                let photoCount = photoManager.photos.filter { photoIds.contains($0.localIdentifier) && !photoManager.isVideo($0) }.count
                                let videoCount = photoManager.photos.filter { photoIds.contains($0.localIdentifier) && photoManager.isVideo($0) }.count
                                
                                HStack(spacing: 8) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "photo.fill")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                        Text("\(photoCount)")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "video.fill")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Text("\(videoCount)")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Список медиафайлов
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 2) {
                                ForEach(Array(photoManager.photosToDelete), id: \.self) { photoId in
                                    if let photo = photoManager.getPhotoById(photoId) {
                                        TrashPhotoCell(
                                            photo: photo,
                                            photoManager: photoManager,
                                            isSelected: selectedPhotos.contains(photoId),
                                            onToggle: {
                                                if selectedPhotos.contains(photoId) {
                                                    selectedPhotos.remove(photoId)
                                                } else {
                                                    selectedPhotos.insert(photoId)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Кнопки действий
                        VStack(spacing: 15) {
                            HStack(spacing: 15) {
                                // Кнопка выбора всех
                                Button(action: {
                                    if selectedPhotos.count == photoManager.photosToDelete.count {
                                        selectedPhotos.removeAll()
                                    } else {
                                        selectedPhotos = Set(photoManager.photosToDelete)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: selectedPhotos.count == photoManager.photosToDelete.count ? "checkmark.square.fill" : "square")
                                            .font(.title2)
                                        Text(selectedPhotos.count == photoManager.photosToDelete.count ? "Remove selection" : "Select all")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.blue)
                                    .cornerRadius(25)
                                }
                                
                                // Кнопка восстановления выбранных
                                Button(action: {
                                    photoManager.restoreMultipleFromTrash(selectedPhotos)
                                    selectedPhotos.removeAll()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.uturn.backward")
                                            .font(.title2)
                                        Text("Restore")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.green)
                                    .cornerRadius(25)
                                }
                                .disabled(selectedPhotos.isEmpty)
                                .opacity(selectedPhotos.isEmpty ? 0.6 : 1.0)
                            }
                            
                            HStack(spacing: 15) {
                                // Кнопка удаления выбранных
                                Button(action: {
                                    photoManager.deleteSelectedPhotos(selectedPhotos)
                                    selectedPhotos.removeAll()
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                            .font(.title2)
                                        Text("Delete selected")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.red)
                                    .cornerRadius(25)
                                }
                                .disabled(selectedPhotos.isEmpty)
                                .opacity(selectedPhotos.isEmpty ? 0.6 : 1.0)
                                
                                // Кнопка восстановления всех
                                Button(action: {
                                    photoManager.restoreAllFromTrash()
                                    selectedPhotos.removeAll()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.uturn.backward.circle")
                                            .font(.title2)
                                        Text("Restore all")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.green)
                                    .cornerRadius(25)
                                }
                            }
                            
                            // Кнопка очистки корзины
                            Button(action: {
                                photoManager.deleteMarkedPhotos()
                                selectedPhotos.removeAll()
                            }) {
                                HStack {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.title2)
                                    Text("Delete all")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.red)
                                .cornerRadius(25)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Bin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 15) {
                        if !photoManager.photosToDelete.isEmpty {
                            Button("Restore all") {
                                photoManager.restoreAllFromTrash()
                                selectedPhotos.removeAll()
                            }
                            .foregroundColor(.green)
                        }
                        
                        if !photoManager.photosToDelete.isEmpty {
                            Button("Clean") {
                                photoManager.deleteMarkedPhotos()
                                selectedPhotos.removeAll()
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }
}

struct TrashPhotoCell: View {
    let photo: PHAsset
    let photoManager: PhotoManager
    let isSelected: Bool
    let onToggle: () -> Void
    @State private var image: UIImage?
    @State private var showingRestoreAlert = false
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 90)
                    .clipped()
                    .cornerRadius(10)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 90, height: 90)
                    .cornerRadius(10)
            }
            
            // Индикатор типа медиафайла
            VStack {
                HStack {
                    if photoManager.isVideo(photo) {
                        HStack(spacing: 4) {
                            Image(systemName: "video.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text(photoManager.getVideoDuration(photo))
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    // Индикатор выбора
                    Button(action: onToggle) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(isSelected ? .green : .white)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding(5)
                
                Spacer()
            }
        }
        .onAppear {
            loadImage()
        }
        .onDisappear {
            // Очищаем изображение при исчезновении ячейки
            image = nil
        }
        .onLongPressGesture {
            showingRestoreAlert = true
        }
        .alert("Restore mediafile?", isPresented: $showingRestoreAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) {
                photoManager.restoreFromTrash(photo.localIdentifier)
            }
        } message: {
            Text("Media will be restored")
        }
    }
    
    private func loadImage() {
        let size = CGSize(width: 180, height: 180)
        
        PHImageManager.default().requestImage(
            for: photo,
            targetSize: size,
            contentMode: .aspectFill,
            options: nil
        ) { image, info in
            DispatchQueue.main.async {
                if let image = image {
                    self.image = image
                } else {
                    // Если изображение не загрузилось, попробуем загрузить еще раз
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.loadImage()
                    }
                }
            }
        }
    }
}
