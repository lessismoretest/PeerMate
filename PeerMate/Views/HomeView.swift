import SwiftUI

struct HomeView: View {
    @StateObject private var userSettings = UserSettings()
    @StateObject private var viewModel = HomeViewModel()
    @AppStorage("birthDate") private var birthDate = Date()
    @State private var isRefreshing = false
    @State private var scrollViewHeight: CGFloat = 0
    @State private var contentOffset: CGFloat = 0
    @State private var isHovered = false
    
    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M 月 d 日"
        return formatter.string(from: Date())
    }
    
    private var userAge: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }
    
    init() {
        // 检查图片是否存在
        let image = NSImage(named: "calligraphy")
        print("Calligraphy image loaded:", image != nil)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(currentDate)，ta 在...")
                                .font(.title)
                                .bold()
                            
                            Text("💪 此时，ta 与你相同的 \(userAge) 岁，你在做什么？")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 10)
                        
                        if userSettings.people.isEmpty {
                            Text("请在设置中添加人物")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(userSettings.people) { person in
                                PersonCardView(
                                    person: person,
                                    response: viewModel.responses[person.id],
                                    isLoading: viewModel.isLoading[person.id] ?? false,
                                    error: viewModel.errors[person.id]
                                )
                            }
                        }
                        
                        GeometryReader { proxy in
                            Color.clear
                                .preference(
                                    key: ContentOffsetPreferenceKey.self,
                                    value: proxy.frame(in: .named("scrollView")).maxY
                                )
                        }
                        .frame(height: 0)
                        
                        Spacer(minLength: 60)
                    }
                    .padding()
                }
                .coordinateSpace(name: "scrollView")
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                scrollViewHeight = proxy.size.height
                            }
                            .onChange(of: proxy.size.height) { _, newHeight in
                                scrollViewHeight = newHeight
                            }
                    }
                )
                .onPreferenceChange(ContentOffsetPreferenceKey.self) { offset in
                    contentOffset = offset
                    print("Content offset:", offset)
                    print("ScrollView height:", scrollViewHeight)
                    print("Show bottom text:", showBottomText)
                }
                
                if showBottomText {
                    Image("calligraphy")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                        .padding(.bottom, 20)
                        .opacity(isHovered ? 1 : 0.3)
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isHovered = hovering
                            }
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showBottomText)
        .onAppear {
            viewModel.fetchResponses(for: userSettings.people, using: userSettings.aiConfig)
        }
        .toolbar {
            Button {
                isRefreshing = true
                viewModel.refreshAll(people: userSettings.people, using: userSettings.aiConfig)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isRefreshing = false
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(isRefreshing ? .linear(duration: 0.5) : .none, value: isRefreshing)
            }
        }
    }
    
    private var showBottomText: Bool {
        guard scrollViewHeight > 0 else { return false }
        // 当内容偏移量小于滚动视图高度的5%时显示
        return contentOffset - scrollViewHeight < scrollViewHeight * 0.05
    }
}

// 用于跟踪内容偏移量的 PreferenceKey
private struct ContentOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct PersonCardView: View {
    let person: Person
    let response: String?
    let isLoading: Bool
    let error: Error?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                person.avatar
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                
                Text(person.name)
                    .font(.headline)
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
            } else if let response = response {
                Text(response)
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
} 