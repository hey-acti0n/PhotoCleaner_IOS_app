import SwiftUI

struct MainMenuView: View {
    @ObservedObject var photoManager: PhotoManager
    @State private var showingPhotoSelection = false
    @State private var showingTrashView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Градиентный фон
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Заголовок
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("PhotoCleaner")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Clear your gallery")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Основные кнопки
                    VStack(spacing: 25) {
                        // Кнопка начала работы
                        Button(action: {
                            showingPhotoSelection = true
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.title2)
                                Text("Start selecting")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.green)
                            .cornerRadius(30)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        
                        // Кнопка просмотра корзины
                        Button(action: {
                            showingTrashView = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.title2)
                                Text("Bin")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.orange)
                            .cornerRadius(30)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(photoManager.photosToDelete.isEmpty)
                        .opacity(photoManager.photosToDelete.isEmpty ? 0.6 : 1.0)
                        
                        // Кнопка очистки корзины
                        Button(action: {
                            photoManager.deleteMarkedPhotos()
                        }) {
                            HStack {
                                Image(systemName: "trash.circle.fill")
                                    .font(.title2)
                                Text("Clear the bin")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.red)
                            .cornerRadius(30)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(photoManager.photosToDelete.isEmpty)
                        .opacity(photoManager.photosToDelete.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 40)
                    
                    // Статистика
                    VStack(spacing: 15) {
                        HStack {
                            VStack {
                                Text("\(photoManager.photos.count)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Total files")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("\(photoManager.photosToDelete.count)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                Text("Bin")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("\(photoManager.photosToKeep.count)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("Marked")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(20)
                        
                        // Детальная статистика по типам
                        if !photoManager.photos.isEmpty {
                            HStack(spacing: 20) {
                                let photoCount = photoManager.photos.filter { !photoManager.isVideo($0) }.count
                                let videoCount = photoManager.photos.filter { photoManager.isVideo($0) }.count
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "photo.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text("\(photoCount)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text("photo")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "video.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text("\(videoCount)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text("video")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .padding(.top, 60)
            }
        }
        .fullScreenCover(isPresented: $showingPhotoSelection) {
            PhotoSelectionView(photoManager: photoManager)
        }
        .sheet(isPresented: $showingTrashView) {
            TrashView(photoManager: photoManager)
        }
        .onDisappear {
            // Очищаем состояние при закрытии главного экрана
            showingPhotoSelection = false
            showingTrashView = false
        }
    }
}
