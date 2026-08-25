//
//  InfoDisplay.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/30/26.
//

import SwiftUI

struct InfoDisplay: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Image(uiImage: UIImage(imageLiteralResourceName: "placeholder"))
                        .padding(.trailing, 20)
                    VStack(alignment: .leading) {
                        Text("Fractal Almanac")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                        Text("Your new compendium of exploration awaits!")
                            .font(.subheadline)
                    }
                }
                .padding(.bottom, 25)
                Divider()

                Text("Welcome, first timers! Please review these quick guides to help you find your way easier in the app. The goal here is to let your creativity take the lead, so no strict rules on how this app should be used. Have fun and discover something new.")
                    .padding(.bottom, 16)
                
                HStack(alignment: .top) {
                    Image(systemName: "hand.pinch.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .padding(.trailing, 8)
                    Text("Zooming into the Current model")
                        .font(.title2)
                }
                Text("Zooming into your favorite model counldn't be more intuitive and easy. Just use the familiar pinch out gesture to zoom in and pinch out to zoom out. Due to extensive use of the Metal shader pipeline, the fractal will continually render as you zoom in and out. For performace, the number of iterations will remain low as you zoom in and out and then increase to a better amount once your finished. A more robust image of where you are in the fractal will then appear automatatically.")
                    .font(.body)
                    .padding(.bottom, 16)
                
                HStack(alignment: .top) {
                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .padding(.trailing, 8)
                    Text("Navigation")
                        .font(.title2)
                }
                Text("Similar to zooming, navigation is easy as a single-finger pan motion to move around the rendered set irregardless of how deep you are. Also, the iterations will temporarily reduce at deep zoom levels to provide more performant moving around. Again, once done moving, the rendered set will update with a more richer coloring and intricate model.")
                    .font(.body)
                    .padding(.bottom, 16)
                
                HStack(alignment: .top) {
                    Image(systemName: "map.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .padding(.trailing, 8)
                    Text("Model Selection")
                        .font(.title2)
                }
                Text("Model selection is pretty straightforward here. Select the Model menu item and then select which model you want to start exploring. All navigation from the prior model is reset once a new model is selected. Your current Palette selection is used with the new model.")
                    .font(.body)
                    .padding(.bottom, 16)
                
                HStack(alignment: .top) {
                    Image(systemName: "photo.badge.arrow.down.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .padding(.trailing, 8)
                    Text("Screenshots")
                        .font(.title2)
                }
                Text("You can take a photo of the currently rendered model and save it directly into your Camera roll. Fractal Almanac will prompt you once for permissions to access Photos. Once an screenshot is captured, you can continue to explore or immediately navigate to Photos and work on that image as you so desire.")
                    .font(.body)
                    .padding(.bottom, 16)
                
                HStack(alignment: .top) {
                    Image(systemName: "bookmark.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .padding(.trailing, 8)
                    Text("Bookmarks")
                        .font(.title2)
                }
                Text("Even a great adventurer needs time to rest. If you want to start exploring other models, you can create a bookmark of exactly where you are in the current model. Simnply provide a suitable name and a bookmark is saved for you. Existing bookmarks can be re-loaded at anytime after this. Keep in mind that if you do not create a bookmark of where you are in the current model, a loaded bookmark after that will erase that past navigation state. Existing palette color schemes created as part of that work will remain available. A standard left swipe on a Bookmark will remove it permanently from the app.")
                    .font(.body)
                    .padding(.bottom, 16)
                
                HStack(alignment: .top) {
                    Image(systemName: "swatchpalette.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .padding(.trailing, 8)
                    Text("Pallete Selection")
                        .font(.title2)
                }
                Text("A set of pre-defined General and Enhanced palettes are available to you here. Just select one and the curent model will re-render with these colors. As you add your new color palettes, they will apear in the Custom section of the list.")
                    .font(.body)
                    .padding(.bottom, 16)
                
                Text("Palette Creation")
                    .font(.title3)
                Text("While Fractal Almanac does provide you with a bevy of palletes to explore with, you may find yourself wanting to create a new set of colors to work with. By selecting the Customize... option in the Palette menu, you will be presented with an editor to create a whole new color palette. Explore your creativity here and select colors that match what you are looking for. You also have the option to apply generic filters as part of the Palette:")
                    .font(.body)
                Text("""
                     Glow: Applies an interpolated glow along color borders.
                     Blur: Applies a generic light blurring of the final image. This works well with a custom Palette that has many gradient colors.
                     """)
                .font(.subheadline)
                .padding(.leading, 35)
                .padding(.bottom, 16)

                Text("Palette Features")
                    .font(.title3)
                Text("You can also enable an Interpolation of the selected colors to span more levels of the rendered model. The interpolation count is between 16 and 64. See what interesting color palettes you can make once you edit and Palette that has many colors in it. ")
                    .font(.body)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        Divider()
        HStack(alignment: .bottom) {
            Spacer()
            Button("Dismiss") {
                hasSeenOnboarding = true
            }
            .padding([.trailing, .bottom], 8)
        }
        .frame(height: 45)
        .background(.white)
        .padding()
    }
}

#Preview {
    InfoDisplay()
}
