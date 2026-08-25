//
//  Bookmark.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/15/26.
//

import SwiftUI
internal import CoreData

struct BookmarkCell: View {
    private var thumbnail: UIImage
    private var bookmarkName: String
    private var model: String
    private var palette: String
    private var paletteCycle: PaletteCycleStyle
    
    public init(
        thumbnail: UIImage?,
        bookmarkName: String,
        model: String,
        palette: String,
        paletteCycle: PaletteCycleStyle
    ) {
        self.thumbnail = thumbnail ?? UIImage(imageLiteralResourceName: "placeholder")
        self.bookmarkName = bookmarkName
        self.model = model
        self.palette = palette
        self.paletteCycle = paletteCycle
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .padding([.horizontal], 8)
            Text(bookmarkName)
                .font(.headline)
                .padding([.horizontal], 8)
                .frame(maxWidth: 200, alignment: .leading)
            Spacer()
            VStack(alignment: .trailing) {
                Text(model)
                    .font(.subheadline)
                Text(palette)
                    .font(.subheadline)
                Text(paletteCycle.description)
                    .font(.subheadline)
            }
            .padding([.horizontal], 8)
        }
        .frame(height: 70)
    }
}

enum ActionState: String {
    case Save
    case Load
}

struct BookmarkSheet<Canvas:View>: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedBookmark: Bookmark?
    @State private var bookmarkDelegate: BookmarkProtocol?
    
    @State private var titleKey: String = ""
    @State private var bookmarkModel: FractalModel
    @State private var bookmarkPalette: any ColorSchemeProtocol
    @State private var errorLabel: String = ""
    @State private var realCenter: Double
    @State private var imagCenter: Double
    @State private var zoom: Double
    private var size: CGSize
    @State private var renderBlueprint: (CGSize) -> Canvas
    @State private var thumbnail: UIImage
    @State private var positiveAction: ActionState = .Save
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(
            keyPath: \Bookmark.timestamp,
            ascending: false
        )],
        animation: .default
    )
    private var allBookmarks: FetchedResults<Bookmark>
    
    public init(
        bookmarkModel: FractalModel,
        bookmarkPalette: any ColorSchemeProtocol,
        bookmarkDelegate: BookmarkProtocol? = nil,
        realCenter: Double,
        imagCenter: Double,
        zoom: Double,
        size: CGSize,
        renderBlueprint: @escaping (CGSize) -> Canvas
    ) {
        self.bookmarkModel = bookmarkModel
        self.bookmarkPalette = bookmarkPalette
        self.bookmarkDelegate = bookmarkDelegate
        self.realCenter = realCenter
        self.imagCenter = imagCenter
        self.zoom = zoom
        self.size = size
        self.renderBlueprint = renderBlueprint
        self.thumbnail = UIImage(imageLiteralResourceName: "placeholder")
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 118, height: 118)
                    .padding(16)
                
                VStack(alignment: .leading) {
                    TextField("bookmark", text: $titleKey, prompt: Text("Provide a new Bookmark name"))
                        .textInputAutocapitalization(.words)
                        .onChange(of: titleKey) { oldValue, newValue in
                            errorLabel = titleKey.count > 0 ? "" : errorLabel
                        }
                    Text(errorLabel)
                        .foregroundStyle(.red)
                        .fontWeight(.light)
                        .font(.subheadline)
                    HStack(alignment: .center) {
                        Text(bookmarkModel.rawValue)
                        Spacer()
                        Text(bookmarkPalette.paletteName)
                        Text("(\(UserDefaults.standard.lastPaletteCycle.description))")
                            .font(.caption)
                    }
                    Spacer()
                    HStack(alignment: .top) {
                        Text("Real:" + String(format:"%g", realCenter))
                            .fontWeight(.light)
                            .font(.subheadline)
                        Text("Imaginary:" + String(format:"%g", imagCenter))
                            .fontWeight(.light)
                            .font(.subheadline)
                        Text("Zoom:" + String(format:"%g", zoom) + "x")
                            .fontWeight(.light)
                            .font(.subheadline)
                    }
                }
                .padding()
            }
            .frame(height: 150)
            
            List(selection: $selectedBookmark) {
                ForEach(allBookmarks) { bookmark in
                    BookmarkCell(
                        thumbnail: UIImage(data: bookmark.thumbnail),
                        bookmarkName: bookmark.name,
                        model: bookmark.model,
                        palette: bookmark.palette,
                        paletteCycle: bookmark.cycle()
                    )
                    .tag(bookmark)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            delete(bookmark)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .onChange(of: selectedBookmark) { oldBookmark, newBookmark in
                if let newBookmark {
                    loadInfoViewWith(newBookmark)
                }
            }
            Spacer()
            Divider()
            HStack(alignment: .top) {
                Button("Dismiss") {
                    dismiss() // Closes the modal
                }
                Spacer()
                switch positiveAction {
                    case .Save:
                        Button(positiveAction.rawValue) {
                            save() // Saves the modal
                        }
                    case .Load:
                        Button(positiveAction.rawValue) {
                            restoreBookmark() // Loads the modal
                        }
                }
            }
            .padding([.leading, .trailing], 8)
        }
        .padding()
        .task {
            let renderedImage = renderBlueprint(size)
                .snapshot()
            self.thumbnail = renderedImage ?? UIImage(imageLiteralResourceName: "placeholder")
        }
    }
    
    private func restoreBookmark() {
        if let bookmark = selectedBookmark {
            bookmarkDelegate?.shouldLoadBookmark(bookmark)
        }
        dismiss()
    }
    
    private func delete(_ bookmark: Bookmark) {
        if selectedBookmark == bookmark {
            selectedBookmark = nil
            positiveAction = .Save
            errorLabel = ""
        }
        _ = Bookmark.delete(bookmark, in: viewContext)
    }
    
    private func loadInfoViewWith(_ bookmark:BookmarkObject) {
        thumbnail = bookmark.image()
        titleKey = bookmark.bookmarkName()
        bookmarkModel = FractalModel(rawValue: bookmark.modelName())!
        bookmarkPalette = Palette(rawValue: bookmark.colorScheme().paletteName)!
        realCenter = bookmark.center().centerReal
        imagCenter = bookmark.center().centerImag
        zoom = bookmark.zoom()
        positiveAction = .Load
        errorLabel = ""
    }
    
    private func save() {
        validateInput(onSuccess: {
            let bookmark = Bookmark.newBookmark(in: viewContext)
            bookmark?.name = titleKey
            bookmark?.centerReal = realCenter
            bookmark?.centerImag = imagCenter
            bookmark?.zoomFactor = zoom
            bookmark?.model = bookmarkModel.rawValue
            bookmark?.palette = bookmarkPalette.paletteName
            bookmark?.paletteCycle = Int16(UserDefaults.standard.lastPaletteCycle.rawValue)
            bookmark?.thumbnail = thumbnail.pngData()!
            bookmark?.timestamp = Date()
            
            do {
                try bookmark?.managedObjectContext?.save()
                dismiss()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }, onFailure: {(errorMsg) in
             self.errorLabel = errorMsg!
        })
    }
    
    private func validateInput(onSuccess: () -> (), onFailure: (_ result:String?) -> ()) {
        if titleKey.count == 0 {
            onFailure("You must provide a Snapshot name.")
            return
        }
        if let _ = Bookmark.bookmark(forName: titleKey, in: viewContext) {
            onFailure("A Bookmark already exists with that name.")
            return
        }
        onSuccess()
    }
}


#Preview {
    BookmarkSheet(
        bookmarkModel: .Mandelbrot,
        bookmarkPalette: Palette.Aesthetic,
        realCenter: 1.012344,
        imagCenter: 0.0023456,
        zoom: 1.2,
        size: CGSize(width: 100, height: 100),
        renderBlueprint: { size in
            return EmptyView()
        }
    )
}
