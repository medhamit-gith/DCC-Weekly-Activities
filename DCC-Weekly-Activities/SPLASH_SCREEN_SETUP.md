# Adding Images to Your Splash Screen

## Step 1: Add Images to Xcode Assets

1. **Open your Xcode project**
2. **Find Assets.xcassets** in the Project Navigator (left sidebar)
3. **Click the + button** at the bottom of the Assets panel
4. **Select "Image Set"** from the menu
5. **Name it `club_photo_1`**
6. **Drag and drop your first image** (the "Champan at the Spinning Wheel" photo) into the 1x, 2x, or 3x slot
7. **Repeat steps 3-6** to create `club_photo_2` with the second image

### Quick Method:
- Right-click in Assets.xcassets
- Select "Import..."
- Choose both images
- Rename them to `club_photo_1` and `club_photo_2`

## Step 2: The New Splash Screen Features

The updated login screen now includes:

✨ **Professional Design Elements:**
- **Gradient background** with orange and blue colors matching cycling theme
- **Photo carousel** that auto-slides between your two club photos
- **Large app title** with shadow effects
- **Descriptive subtitle** explaining the app's purpose
- **Prominent login button** with gradient and shadow
- **User guidance text** explaining the OAuth permission prompt

🎨 **Visual Features:**
- Rounded corners on photos
- Drop shadows for depth
- Page indicators for the photo carousel
- Smooth transitions between photos
- Full-screen immersive design

## Step 3: Customize (Optional)

You can adjust colors, sizes, and text in ContentView.swift:

```swift
// Change gradient colors
LinearGradient(
    colors: [Color.orange.opacity(0.8), Color.blue.opacity(0.6)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// Change button color
.background(
    LinearGradient(
        colors: [Color.orange, Color.orange.opacity(0.8)],
        startPoint: .leading,
        endPoint: .trailing
    )
)

// Change text
Text("DCC Club Activities")
Text("Track your club's weekly rides")
```

## Alternative: If Images Don't Load

If you prefer to use system images or don't want to add the photos:

Replace the TabView section with:
```swift
Image(systemName: "figure.outdoor.cycle")
    .font(.system(size: 120))
    .foregroundStyle(.white)
    .shadow(color: .black.opacity(0.3), radius: 10)
```

## Tips for Best Results:

1. **Image Resolution**: Use high-quality images (at least 1000px wide)
2. **Aspect Ratio**: The photos will be cropped to fill, so centered subjects work best
3. **File Format**: Use PNG or JPEG
4. **File Size**: Optimize images to keep app size reasonable (< 1MB each recommended)

## What It Looks Like:

- Top: Sliding photo carousel of your club rides
- Middle: App title and icon
- Bottom: Large "Connect with Strava" button
- Background: Beautiful gradient
- Overall: Professional, modern, welcoming!

The splash screen now tells the story of your cycling club while making it easy and inviting for members to log in! 🚴‍♂️
