import SwiftUI
import Combine

struct PersonNameCarousel: View {
    private let names: [String]
    private let animationDuration: Double
    @State private var currentIndex = 0
    @State private var timer: AnyCancellable?
    
    init(names: [String], animationDuration: Double = 1) {
        self.names = names.isEmpty ? ["加载中..."] : names
        self.animationDuration = animationDuration
    }
    
    var body: some View {
        ZStack {
            // 黑色背景
            Rectangle()
                .fill(Color.black)
                .frame(height: 40)
            
            // 当前名称
            if !names.isEmpty {
                Text(names[currentIndex])
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                    .lineLimit(1)
            } else {
                Text("加载中...")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // 左右两侧指示器
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 12, weight: .bold))
                    .padding(.leading, 10)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 12, weight: .bold))
                    .padding(.trailing, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            // 确保只有一个名字以上才开始轮播
            if names.count > 1 {
                startCarousel()
            }
        }
        .onDisappear {
            // 清理计时器
            timer?.cancel()
        }
        // 当names变化时重新启动轮播
        .onChange(of: names) { _, newNames in
            timer?.cancel()
            
            if newNames.count > 1 {
                // 重置状态
                currentIndex = 0
                
                // 启动轮播
                startCarousel()
            }
        }
    }
    
    private func startCarousel() {
        // 使用Combine的计时器
        timer = Timer.publish(every: animationDuration, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                // 简单地更新索引，无需动画
                currentIndex = (currentIndex + 1) % names.count
            }
    }
} 