import SwiftUI
import UserNotifications
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var searchText = ""
    @State private var items: [ItemModel] = [
        ItemModel(title: "Türkiye wikipedia", content: "Keyword Description"),
        ItemModel(title: "Moldova stiri", content: "Second Keyword Description"),
        ItemModel(title: "999 apartament", content: "Third Keyword Description")
    ]
    @State private var selectAll = false
    @State private var showingDocumentPicker = false
    @State private var selectedItem: ItemModel?
    @State private var showingDetailView = false
    @State private var showingDuplicateAlert = false
    @State private var duplicateTitle = ""
    @State private var isViewLoaded = false
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 15) {
                    // Search field and buttons
                    HStack {
                        TextField("Search", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(10)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(5)
                            .submitLabel(.search)
                            .onSubmit {
                                addItemToList()
                            }
                        
                        Button(action: {
                            addItemToList()
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                                .frame(width: 50, height: 50)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            searchInGoogle(query: searchText)
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                                .frame(width: 40, height: 40)
                                .background(Color.white)
                                .cornerRadius(5)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Delete buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            clearAllItems()
                        }) {
                            Text("Delete All")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(5)
                        }
                        
                        Button(action: {
                            deleteSelectedItems()
                        }) {
                            Text("Delete Selected")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(5)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Backup button
                    Button(action: {
                        showingDocumentPicker = true
                    }) {
                        Text("Save List Backup")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(5)
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $showingDocumentPicker) {
                        DocumentPicker(items: items)
                    }
                    
                    // Select all
                    HStack {
                        Spacer()
                        
                        Image(systemName: selectAll ? "checkmark.square.fill" : "square")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .onTapGesture {
                                selectAll.toggle()
                                toggleSelectAll()
                            }
                        
                        Text("Select All")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.leading, 10)
                        
                        Spacer()
                    }
                    .padding()
                    
                    // List
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(items.indices, id: \.self) { index in
                                HStack {
                                    Image(systemName: items[index].isSelected ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                        .padding(.leading, 10)
                                        .onTapGesture {
                                            items[index].isSelected.toggle()
                                            updateSelectAllState()
                                        }
                                    
                                    Button(action: {
                                        selectedItem = items[index]
                                        showingDetailView = true
                                    }) {
                                        Text(items[index].title)
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .padding(.horizontal)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        selectedItem = items[index]
                                        showingDetailView = true
                                    }) {
                                        Image(systemName: "tag.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                            .frame(width: 30, height: 30)
                                            .background(Color.orange)
                                            .cornerRadius(5)
                                            .padding(.trailing, 5)
                                    }
                                    
                                    Button(action: {
                                        searchInGoogle(query: items[index].title)
                                    }) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 20))
                                            .foregroundColor(.black)
                                            .frame(width: 30, height: 30)
                                            .background(Color.white)
                                            .cornerRadius(5)
                                            .padding(.trailing, 10)
                                    }
                                }
                                .frame(height: 60)
                                .background(Color.gray.opacity(0.3))
                            }
                        }
                    }
                }
                .padding(.vertical)
                .padding(.bottom, keyboardHeight)
            }
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardHeight = 0
            }
        }
        .task {
            if !isViewLoaded {
                // Initialize view state
                await MainActor.run {
                    requestNotificationPermission()
                    isViewLoaded = true
                }
            }
        }
        .background {
            Color.clear
                .task(priority: .background) {
                    // Handle background initialization
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                }
        }
        .sheet(isPresented: $showingDetailView, onDismiss: {
            selectedItem = nil
        }) {
            if let item = selectedItem,
               let index = items.firstIndex(where: { $0.id == item.id }) {
                ItemDetailView(item: $items[index])
                    .preferredColorScheme(.dark)
            }
        }
        .alert("Warning", isPresented: $showingDuplicateAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Add Anyway") {
                addItemToListForced(title: duplicateTitle)
            }
        } message: {
            Text("\"\(duplicateTitle)\" already exists in your list. Do you want to add it anyway?")
        }
    }
    
    private func requestNotificationPermission() {
        Task {
            do {
                let center = UNUserNotificationCenter.current()
                try await center.requestAuthorization(options: [.alert, .sound, .badge])
                print("Notification permission granted")
            } catch {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleSelectAll() {
        for index in items.indices {
            items[index].isSelected = selectAll
        }
    }
    
    private func updateSelectAllState() {
        selectAll = !items.contains(where: { !$0.isSelected }) && !items.isEmpty
    }
    
    private func addItemToList() {
        guard !searchText.isEmpty else { return }
        
        // Aynı başlığa sahip öğe var mı kontrol et
        if items.contains(where: { $0.title.lowercased() == searchText.lowercased() }) {
            duplicateTitle = searchText
            showingDuplicateAlert = true
            return
        }
        
        addItemToListForced(title: searchText)
    }
    
    private func addItemToListForced(title: String) {
        let newItem = ItemModel(
            title: title,
            content: "User added item: \(Date().formatted())"
        )
        
        items.append(newItem)
        sendNotification(title: "New Item Added", body: "\"\(title)\" added to the list")
        searchText = ""
    }
    
    private func searchInGoogle(query: String) {
        guard !query.isEmpty else { return }
        
        if let searchQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://www.google.com/search?q=\(searchQuery)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func clearAllItems() {
        items.removeAll()
        sendNotification(title: "List Cleared", body: "All items have been deleted")
    }
    
    private func deleteSelectedItems() {
        let selectedItems = items.filter { $0.isSelected }
        guard !selectedItems.isEmpty else { return }
        
        let selectedTitles = selectedItems.map { $0.title }.joined(separator: ", ")
        items.removeAll { $0.isSelected }
        selectAll = false
        
        sendNotification(title: "Selected Items Deleted", body: "\(selectedTitles) deleted")
    }
    
    private func saveListBackup() {
        autoreleasepool {
            DispatchQueue.global(qos: .utility).async {
                do {
                    let fileManager = FileManager.default
                    let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let backupURL = documentsPath.appendingPathComponent("items_backup.json")
                    
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    
                    let data = try encoder.encode(items)
                    
                    try data.write(to: backupURL, options: [.atomic])
                    
                    DispatchQueue.main.async {
                        sendNotification(
                            title: "List Backed Up",
                            body: "\(items.count) items saved successfully"
                        )
                    }
                } catch {
                    DispatchQueue.main.async {
                        print("Backup error: \(error.localizedDescription)")
                        sendNotification(
                            title: "Backup Error",
                            body: "Failed to backup items: \(error.localizedDescription)"
                        )
                    }
                }
            }
        }
    }
    
    private func sendNotification(title: String, body: String) {
        DispatchQueue.main.async {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Notification error: \(error)")
                }
            }
        }
    }
}

struct ItemModel: Identifiable, Codable {
    var id: UUID
    var title: String
    var content: String
    var isSelected: Bool
    
    init(id: UUID = UUID(), title: String, content: String, isSelected: Bool = false) {
        self.id = id
        self.title = title
        self.content = content
        self.isSelected = isSelected
    }
}

struct ItemDetailView: View {
    @Binding var item: ItemModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Title")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        TextField("Title", text: $item.title)
                            .focused($isTitleFocused)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.next)
                            .onSubmit {
                                isContentFocused = true
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Tag Content")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        TextEditor(text: $item.content)
                            .focused($isContentFocused)
                            .frame(minHeight: 200)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                                 to: nil, 
                                                 from: nil, 
                                                 for: nil)
                    dismiss()
                }
                .foregroundColor(.white),
                trailing: Button("Save") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                                 to: nil, 
                                                 from: nil, 
                                                 for: nil)
                    dismiss()
                }
                .foregroundColor(.white)
            )
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTitleFocused = true
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let items: [ItemModel]
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        autoreleasepool {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            do {
                let data = try encoder.encode(items)
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("items_backup.json")
                try data.write(to: tempURL, options: .atomic)
                
                let picker = UIDocumentPickerViewController(forExporting: [tempURL])
                picker.delegate = context.coordinator
                return picker
            } catch {
                print("JSON creation error: \(error)")
                return UIDocumentPickerViewController(forExporting: [])
            }
        }
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedURL = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: selectedURL)
                let decoder = JSONDecoder()
                let items = try decoder.decode([ItemModel].self, from: data)
                print("File saved successfully: \(selectedURL.path)")
            } catch {
                print("File saving error: \(error)")
            }
        }
    }
}

