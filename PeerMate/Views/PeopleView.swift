import SwiftUI
import UniformTypeIdentifiers

struct PeopleView: View {
    @StateObject private var userSettings = UserSettings()
    @State private var isAddingPerson = false
    @State private var editingPerson: Person?
    @State private var isEditing = false
    @State private var famousPersons: [String] = []
    @State private var isLoadingPersons = false
    @State private var loadError: Error?
    
    var body: some View {
        VStack(spacing: 0) {
            // 人物名称轮播区域
            PersonNameCarousel(names: famousPersons)
                .frame(maxWidth: .infinity)
            
            Divider()
                .background(Color.gray.opacity(0.5))
            
            VStack(spacing: 16) {
                List {
                    ForEach(Array(userSettings.people.enumerated()), id: \.element.id) { index, person in
                        PersonRow(
                            person: Person(
                                id: person.id,
                                name: person.name,
                                avatarData: person.avatarData,
                                index: index
                            ),
                            isEditing: isEditing,
                            onEdit: { editingPerson = person },
                            onDelete: { deletePerson(at: IndexSet([index])) },
                            userSettings: userSettings
                        )
                    }
                    .onDelete(perform: deletePerson)
                    .onMove(perform: movePeople)
                }
                
                Button("添加人物") {
                    isAddingPerson = true
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 10)
            }
            .padding([.horizontal, .top])
        }
        .sheet(isPresented: $isAddingPerson) {
            PersonFormSheet(userSettings: userSettings)
        }
        .sheet(item: $editingPerson) { person in
            PersonFormSheet(userSettings: userSettings, editingPerson: person)
        }
        .navigationTitle("人类群星闪耀时 🌟")
        .toolbar {
            Button(isEditing ? "完成" : "编辑") {
                isEditing.toggle()
            }
        }
        .onAppear {
            loadFamousPersons()
        }
        .alert(isPresented: Binding<Bool>(
            get: { loadError != nil },
            set: { if !$0 { loadError = nil } }
        )) {
            Alert(
                title: Text("加载失败"),
                message: Text(loadError?.localizedDescription ?? "未知错误"),
                dismissButton: .default(Text("重试")) {
                    loadFamousPersons()
                }
            )
        }
    }
    
    private func loadFamousPersons() {
        guard famousPersons.isEmpty, !isLoadingPersons else { return }
        
        isLoadingPersons = true
        loadError = nil
        
        Task {
            do {
                let persons = try await AIService.shared.fetchFamousPersons(using: userSettings.aiConfig)
                await MainActor.run {
                    print("获取到\(persons.count)位历史人物: \(persons)")
                    if !persons.isEmpty {
                        famousPersons = persons.shuffled() // 随机打乱顺序
                    } else {
                        // 如果返回空列表，使用默认人物
                        famousPersons = ["爱因斯坦", "牛顿", "达芬奇", "莎士比亚", "孔子", 
                                       "苏格拉底", "居里夫人", "拿破仑", "贝多芬", "爱迪生"]
                    }
                    isLoadingPersons = false
                }
            } catch {
                print("加载历史人物失败: \(error)")
                await MainActor.run {
                    loadError = error
                    isLoadingPersons = false
                    
                    // 加载失败时使用一些默认名人
                    if famousPersons.isEmpty {
                        famousPersons = ["爱因斯坦", "牛顿", "达芬奇", "莎士比亚", "孔子", 
                                       "苏格拉底", "居里夫人", "拿破仑", "贝多芬", "爱迪生"]
                    }
                }
            }
        }
    }
    
    private func deletePerson(at offsets: IndexSet) {
        userSettings.people.remove(atOffsets: offsets)
    }
    
    private func movePeople(from source: IndexSet, to destination: Int) {
        userSettings.people.move(fromOffsets: source, toOffset: destination)
    }
}

private struct PersonRow: View {
    let person: Person
    let isEditing: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    @ObservedObject var userSettings: UserSettings
    
    @State private var isDragging = false
    
    var body: some View {
        HStack {
            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.gray)
                    .imageScale(.large)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.dragLink.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .imageScale(.large)
            }
            
            person.avatar
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(person.name)
                    .font(.headline)
            }
            
            Spacer()
            
            if !isEditing {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .background(isDragging ? Color.accentColor.opacity(0.1) : Color.clear)
        .onDrag {
            isDragging = true
            return NSItemProvider(object: person.id.uuidString as NSString)
        }
        .onDrop(of: [.text], delegate: PersonDropDelegate(
            item: person,
            items: userSettings.people,
            isDragging: $isDragging,
            userSettings: userSettings
        ))
    }
}

struct PersonDropDelegate: DropDelegate {
    let item: Person
    let items: [Person]
    @Binding var isDragging: Bool
    @ObservedObject var userSettings: UserSettings
    
    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let fromIndex = items.firstIndex(where: { $0.id == item.id }),
              let itemProvider = info.itemProviders(for: [.text]).first else { return }
        
        itemProvider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (data, error) in
            guard let data = data as? Data,
                  let id = String(data: data, encoding: .utf8),
                  let toIndex = items.firstIndex(where: { $0.id.uuidString == id }) else { return }
            
            if fromIndex != toIndex {
                DispatchQueue.main.async {
                    withAnimation {
                        let fromOffset = IndexSet(integer: fromIndex)
                        let toOffset = toIndex > fromIndex ? toIndex + 1 : toIndex
                        userSettings.people.move(fromOffsets: fromOffset, toOffset: toOffset)
                    }
                }
            }
        }
    }
    
    func dropExited(info: DropInfo) {
        isDragging = false
    }
    
    func performDrop(info: DropInfo) -> Bool {
        isDragging = false
        return true
    }
}

private struct PersonFormSheet: View {
    @ObservedObject var userSettings: UserSettings
    @Environment(\.dismiss) private var dismiss
    
    var editingPerson: Person?
    
    @State private var name: String
    @State private var avatarImage: NSImage?
    @State private var isShowingImagePicker = false
    
    init(userSettings: UserSettings, editingPerson: Person? = nil) {
        self.userSettings = userSettings
        self.editingPerson = editingPerson
        _name = State(initialValue: editingPerson?.name ?? "")
        if let data = editingPerson?.avatarData, let image = NSImage(data: data) {
            _avatarImage = State(initialValue: image)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Text(editingPerson == nil ? "添加人物" : "编辑人物")
                    .font(.headline)
                Spacer()
            }
            .padding(.top)
            
            VStack(spacing: 16) {
                // 头像部分
                VStack(spacing: 12) {
                    if let image = avatarImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                    
                    Button("选择头像") {
                        isShowingImagePicker = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.bottom, 8)
                
                // 姓名输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("姓名")
                        .foregroundColor(.secondary)
                    TextField("请输入姓名", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                Spacer()
                
                // 底部按钮
                HStack(spacing: 16) {
                    Button("取消") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button(editingPerson == nil ? "添加" : "保存") {
                        savePerson()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty)
                }
            }
            .padding()
        }
        .frame(width: 300, height: 400)
        .fileImporter(
            isPresented: $isShowingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                if let url = files.first {
                    loadImage(from: url)
                }
            case .failure(let error):
                print("Error selecting image:", error)
            }
        }
    }
    
    private func loadImage(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        if let image = NSImage(contentsOf: url) {
            avatarImage = image
        }
    }
    
    private func savePerson() {
        var avatarData: Data?
        if let image = avatarImage {
            avatarData = image.tiffRepresentation
        }
        
        if let editingPerson = editingPerson {
            // 更新现有人物
            if let index = userSettings.people.firstIndex(where: { $0.id == editingPerson.id }) {
                userSettings.people[index] = Person(
                    id: editingPerson.id,
                    name: name,
                    avatarData: avatarData
                )
            }
        } else {
            // 添加新人物
            let person = Person(name: name, avatarData: avatarData)
            userSettings.people.append(person)
        }
        
        dismiss()
    }
} 