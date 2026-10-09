# Fractal Almanac

Fractal Almanac is an iOS SwiftUI app for exploring fractal models with Metal-backed rendering. The app supports interactive pan and pinch zoom, selectable fractal families, built-in and custom color palettes, bookmarks, and image export to the user's Photo Library.

## Project Layout

```text
FractalAlmanac.xcodeproj       Xcode project
FractalAlmanac/                App source
FractalAlmanac/Database/       Core Data stack and managed object classes
FractalAlmanac/Extensions/     Rendering, palette, snapshot, and utility extensions
FractalAlmanac/Models/         Fractal model selection, render state, and Metal engine code
FractalAlmanac/Protocols/      View/model delegate protocols
FractalAlmanac/Sheets/         Modal SwiftUI controls for model, palette, bookmark, and settings flows
FractalAlmanac/Shaders/        Metal shader functions and shared shader helpers
FractalAlmanac/Utilities/      Image saving, color, and picker helpers
FractalAlmanacTests/           Unit tests
FractalAlmanacUITests/         UI tests
swift-algorithms/              Local Swift package dependency
swift-numerics/                Local Swift package dependency
```

## Requirements

- Xcode with the iOS SDK installed.
- A Metal-capable iPhone or iPad simulator/device.
- iOS deployment target: 26.5.
- Swift language version: 5.0, using SwiftUI, Core Data, Metal, MetalKit, Algorithms, and Numerics.
- Automatic code signing is enabled for the `FractalAlmanac` target.

If command-line builds fail with an `xcode-select` message, switch the active developer directory to a full Xcode install:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Building

### Xcode

1. Open `FractalAlmanac.xcodeproj`.
2. Select the `FractalAlmanac` scheme.
3. Choose an iOS simulator or connected iOS device.
4. Build with `Product > Build` or `Command-B`.
5. Run with `Product > Run` or `Command-R`.

### Command Line

Use `xcodebuild` from the repository root after selecting a full Xcode developer directory:

```sh
xcodebuild -project FractalAlmanac.xcodeproj -scheme FractalAlmanac -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Run tests with:

```sh
xcodebuild -project FractalAlmanac.xcodeproj -scheme FractalAlmanac -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Adjust the destination name to match an installed simulator from `xcrun simctl list devices`.

## General Operational Procedures

### First Launch

`FractalAlmanacApp` checks `@AppStorage("hasSeenOnboarding")`. New users see `InfoDisplay`; after dismissal, the main `ContentView` is shown and receives the shared Core Data context from `PersistenceController`.

### Exploration Workflow

- Use pinch gestures to zoom into or out of the active fractal.
- Use drag gestures to pan the current view.
- Use the model button to switch between Mandelbrot, Julia variants, Dragon, San Marcos, and Phoenix variants.
- Use the palette button to select built-in palettes or custom Core Data palettes.
- Use the bookmark button to save or restore an exact model, center, zoom, palette, and thumbnail.
- Use the photo button to snapshot the current render and save it to Photos.
- Use settings for render-related options exposed by `SettingsSheet`.

### Data Persistence

Core Data is configured in `Database/Persistence.swift` with an `NSPersistentContainer` named `FractalAlmanac`. The main entities are:

- `Bookmark`: stores name, fractal model, center coordinates, zoom factor, palette name, palette cycle mode, thumbnail data, and timestamp.
- `ColorScheme`: stores custom palette names, encoded color arrays, and rendering filter settings.

The data model is stored at `Database/FractalAlmanac.xcdatamodeld/FractalAlmanac.xcdatamodel`.

### Image Export

`ToolbarOverlay` reconstructs the current render through a `renderBlueprint` closure, snapshots the SwiftUI view, writes metadata, and saves the image through `UIImage+Metadata` and `ImageSaver`. The app declares `NSPhotoLibraryAddUsageDescription` in build settings so iOS can prompt for add-only Photo Library access.

### Resetting Local App State

For simulator testing, delete the app from the simulator or choose `Device > Erase All Content and Settings...` to clear `UserDefaults`, Core Data bookmarks, and custom palettes.

## Main Components

### SwiftUI Views

- `FractalAlmanacApp`: app entry point, onboarding switch, and Core Data environment injection.
- `ContentView`: primary canvas, gesture handling, model-specific render dispatch, and toolbar overlay integration.
- `ToolbarOverlay`: floating control stack for model selection, palette selection, bookmarks, export, and settings.
- `InfoDisplay`: onboarding and in-app usage guide.
- `ModelPicker`: modal model chooser.
- `PalettePicker`: built-in/custom palette selection and entry point into palette customization.
- `PaletteBuilder`: custom palette creation/editing.
- `ColorPicker` and `NamedColorPicker`: palette color controls.
- `BookmarkSheet`: bookmark creation, loading, and deletion.
- `SettingsSheet`: render and display settings.

### Data Models

- `FractalModel`: enum describing supported fractal families, initial centers, base zooms, constants, iteration counts, and shader selection.
- `ViewModelState`: value state for the active model, center coordinates, palette, palette cycling, zoom anchors, drag anchors, and cached shader color data.
- `MandelbrotState`: Mandelbrot-specific zoom and iteration policy, including a lower interaction iteration mode for responsiveness.
- `MandelbrotEngine`: Metal compute encoder for the Mandelbrot perturbation renderer.
- `Palette`: built-in palette definitions and interpolation support.
- `UnifiedRowItem`: row abstraction used by list-based picker UIs.
- `Bookmark`: Core Data managed object for saved fractal positions.
- `ColorScheme`: Core Data managed object for custom palettes.

### Protocols

The `Protocols/` group keeps SwiftUI views decoupled from persistence and selection behavior:

- `ModelProtocol`: model selection callbacks.
- `PaletteProtocol`: palette selection callbacks.
- `BookmarkProtocol`: bookmark save/load callbacks.
- `ColorSchemeProtocol`: common interface for built-in and custom palettes.
- `DataModelRenderProtocol`, `SnapshotProtocol`, `PaletteBuilderProtocol`, `ColorPickerSelectionProtocol`, and `NumericColorProtocol`: smaller contracts used by render, snapshot, palette builder, and color picker flows.

## Metal Shaders and Rendering Pipelines

Fractal Almanac has two rendering paths.

### SwiftUI Layer Shader Pipeline

Most non-Mandelbrot models render through SwiftUI `layerEffect` in `ContentView.canvasView`. `FractalModel.newShader(...)` maps the selected model to a Metal shader function in `ShaderLibrary` and passes packed arguments for:

- active center coordinates
- pixel step deltas
- model constants
- canvas size
- iteration tuning
- palette cycling
- palette color arrays

Shader files:

- `Shaders/Julia.metal`: Julia-family functions, including fast single-precision and higher-precision variants.
- `Shaders/Phoenix.metal`: Phoenix-family rendering.
- `Shaders/Dragon.metal`: Dragon rendering.
- `Shaders/SanMarcos.metal`: San Marcos rendering.
- `Shaders/NullShader.metal`: no-op shader used when Mandelbrot is handled by the compute path.
- `Shaders/Helpers/ShaderUtilities.metal`: shared coloring and shader helpers.
- `Shaders/Helpers/DualFloatShaderUtilities.metal`: dual-float precision helpers.
- `Shaders/Helpers/Float2ShaderUtilities.metal`: `float2` precision helpers.

### Mandelbrot Compute Pipeline

Mandelbrot rendering uses an explicit Metal compute pipeline:

1. `ContentView` creates `MetalMandelbrotView` for the Mandelbrot model.
2. `MetalMandelbrotView` wraps an `MTKView` with `UIViewRepresentable`.
3. The `Coordinator` implements `MTKViewDelegate` and requests a redraw when SwiftUI state changes.
4. `MandelbrotEngine` creates an `MTLCommandQueue`, loads the default Metal library, and builds a compute pipeline from `mandelbrotComputePerturbation`.
5. On draw, `MandelbrotEngine.encode(...)` generates a CPU reference orbit, creates Metal buffers for orbit and palette data, binds scalar shader arguments, dispatches threadgroups, and presents the drawable.

Shader file:

- `Shaders/MandelbrotPertubation.metal`: compute kernel for Mandelbrot perturbation rendering.

## Adding a Fractal Model

1. Add a new case to `FractalModel`.
2. Define initial center, base zoom, constants, and iteration behavior in `FractalModelFactory.swift`.
3. Add or reuse a Metal shader function under `Shaders/`.
4. Update `FractalModel.newShader(...)` to route the model to the shader function, or add a dedicated rendering path if the model needs an explicit compute pipeline.
5. Confirm the model appears in `ModelPicker` through `FractalModel.allCases`.
6. Build and test on simulator/device.

## Adding or Changing Palettes

1. Add a case to `Palette` in `PaletteDataModel.swift`.
2. Include it in `classicPalettes()` or `enhancedPalettes()`.
3. Add color stops in `colorScheme()`.
4. Use `interpolatedColorScheme(steps:)` for smoother gradients when needed.
5. Verify that `paletteShaderColors` produces RGBA float arrays expected by the shader pipeline.

## Testing Checklist

Before shipping changes:

- Build the `FractalAlmanac` scheme.
- Run `FractalAlmanacTests`.
- Run `FractalAlmanacUITests` for launch and smoke coverage.
- Manually verify model switching, palette changes, pan/zoom gestures, bookmark save/load/delete, and image export.
- Test at least one non-Mandelbrot model and the Mandelbrot compute path.
- Test on a real device when validating performance or Photo Library behavior.

## Troubleshooting

- Blank render: confirm the selected shader function name matches the Metal function and that the shader file is included in the app target.
- Mandelbrot does not render: check that `MandelbrotEngine` can create a default Metal device, default library, and `mandelbrotComputePerturbation` compute pipeline.
- Palette is missing or black: confirm the palette has at least one color and that `paletteShaderColors` returns packed float color data.
- Bookmark load fails: confirm the Core Data model has the expected `Bookmark` attributes and that saved palette names still map to a built-in `Palette` or custom `ColorScheme`.
- Photo export fails: check Photo Library permission and the `NSPhotoLibraryAddUsageDescription` build setting.
- Command-line build fails before compiling: verify `xcode-select -p` points at a full Xcode installation, not Command Line Tools only.
