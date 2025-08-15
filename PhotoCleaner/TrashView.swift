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
                        
                        Text("Корзина пуста")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Text(Constants.UserMessages.emptyTrash)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    // Список фотографий в корзине
                    VStack {
                        // Заголовок с количеством
                        HStack {
                            Text("Фотографии для удаления")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(photoManager.photosToDelete.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // Список фотографий
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
                                        Text(selectedPhotos.count == photoManager.photosToDelete.count ? "Снять выбор" : "Выбрать все")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.blue)
                                    .cornerRadius(25)
                                }
                                
                                // Кнопка удаления выбранных
                                Button(action: {
                                    photoManager.deleteSelectedPhotos(selectedPhotos)
                                    selectedPhotos.removeAll()
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                            .font(.title2)
                                        Text("Удалить выбранные")
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
                            }
                            
                            // Кнопка очистки корзины
                            Button(action: {
                                photoManager.deleteMarkedPhotos()
                                selectedPhotos.removeAll()
                            }) {
                                HStack {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.title2)
                                    Text("Очистить всю корзину")
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
            .navigationTitle("Корзина")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !photoManager.photosToDelete.isEmpty {
                        Button("Очистить") {
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

struct TrashPhotoCell: View {
    let photo: PHAsset
    let isSelected: Bool
    let onToggle: () -> Void
    @State private var image: UIImage?
    
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
            
            // Индикатор выбора
            VStack {
                HStack {
                    Spacer()
                    Button(action: onToggle) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(isSelected ? .green : .white)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .padding(5)
        }
        .onAppear {
            loadImage()
        }
        .onDisappear {
            // Очищаем изображение при исчезновении ячейки
            image = nil
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
