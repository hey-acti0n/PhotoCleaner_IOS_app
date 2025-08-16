import SwiftUI
import Photos

struct PhotoSelectionView: View {
    @ObservedObject var photoManager: PhotoManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoIndex: Int?
    @State private var showingPhotoViewer = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if photoManager.isAuthorized {
                    VStack {
                        // Заголовок
                        HStack {
                            Text("Select start point")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("\(photoManager.photos.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                // Статистика по типам медиафайлов
                                let photoCount = photoManager.photos.filter { !photoManager.isVideo($0) }.count
                                let videoCount = photoManager.photos.filter { photoManager.isVideo($0) }.count
                                
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
                        
                        // Сетка медиафайлов
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(Array(photoManager.photos.enumerated()), id: \.element.localIdentifier) { index, photo in
                                    PhotoSelectionCell(
                                        photo: photo,
                                        index: index,
                                        isSelected: selectedPhotoIndex == index,
                                        photoManager: photoManager
                                    ) {
                                        selectedPhotoIndex = index
                                        photoManager.currentPhotoIndex = index
                                        showingPhotoViewer = true
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Кнопка возврата
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
//
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(25)
                        }
                        .padding()
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
                        
                        Text("Grant acess for selecting media")
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
            .navigationTitle("Select mediafiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .fullScreenCover(isPresented: $showingPhotoViewer) {
            PhotoViewer(photoManager: photoManager, canReturnToSelection: true)
        }
    }
}

struct PhotoSelectionCell: View {
    let photo: PHAsset
    let index: Int
    let isSelected: Bool
    let photoManager: PhotoManager
    let onTap: () -> Void
    @State private var image: UIImage?
    
    var body: some View {
        Button(action: onTap) {
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
                    }
                    .padding(5)
                    
                    Spacer()
                    
                    // Индикатор выбора
                    if isSelected {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding(5)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
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
