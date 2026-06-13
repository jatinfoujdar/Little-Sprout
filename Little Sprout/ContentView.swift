//
//  ContentView.swift
//  Little Sprout
//
//  Created by jatin foujdar on 12/06/26.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @StateObject private var homeVM = HomeScreenViewModel()
    @StateObject private var gardenVM = GardenViewModel()
    
    // Sheet Navigation matching KMP
    @State private var activeSheet: SheetType? = nil
    @State private var selectedDetailTree: TreeData? = nil
    
    enum SheetType: Identifiable {
        case selectTree
        case statistics // equivalent to GardenScreen
        case fullScreenGarden // equivalent to FullScreenGarden
        
        var id: Int { hashValue }
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.96)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Top Status Bar (Only visible in Idle State)
                if homeVM.timerStatus != .running && homeVM.timerStatus != .hasWon && homeVM.timerStatus != .hasQuit {
                    HStack(spacing: 16) {
                        Spacer()
                        
                        // Info Button
                        Button(action: {
                            // Simple Info Alert or logic
                        }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        }
                        
                        // Stats Button (GardenScreen)
                        Button(action: {
                            gardenVM.updateTreeStats()
                            activeSheet = .statistics
                        }) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.black)
                        }
                        
                        // Grid Button (FullScreenGarden)
                        Button(action: {
                            gardenVM.updateTreeStats()
                            activeSheet = .fullScreenGarden
                        }) {
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.black)
                        }
                        
                        // Coin Balance
                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 14))
                            Text("\(homeVM.coins)")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                Spacer()
                
                // Focus Timer Display
                Text(homeVM.formatTime(seconds: homeVM.remainingSeconds))
                    .font(.system(size: 80, weight: .light, design: .default))
                    .foregroundColor(.black)
                
                Spacer()
                
                // Active Tree visual block
                ZStack {
                    if homeVM.timerStatus == .running {
                        TreeGrowthPlayerView(
                            treeId: homeVM.selectedTree.id,
                            seed: homeVM.currentTreeSeedVariant,
                            progress: homeVM.progress
                        )
                        .frame(width: 180, height: 180)
                    } else if homeVM.timerStatus == .hasQuit {
                        Image("weathered_0_grid")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 180, height: 180)
                    } else {
                        Image("\(homeVM.selectedTree.id)_0_grid")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 180, height: 180)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if homeVM.timerStatus != .running && homeVM.timerStatus != .hasWon && homeVM.timerStatus != .hasQuit {
                        activeSheet = .selectTree
                    }
                }
                
                Spacer()
                
                // Motivation message
                VStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 40)
                    
                    Text("He who conquers himself is the mightiest warrior")
                        .font(.system(.subheadline, design: .serif))
                        .italic()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Countdown Controls [-5] [Start/Give Up] [+5]
                HStack(spacing: 12) {
                    Button(action: { homeVM.adjustTime(amount: -5) }) {
                        Text("-5")
                            .font(.body)
                            .foregroundColor(.black)
                            .frame(width: 60, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .disabled(homeVM.timerStatus == .running || homeVM.timerStatus == .hasWon || homeVM.timerStatus == .hasQuit)
                    .opacity((homeVM.timerStatus == .running || homeVM.timerStatus == .hasWon || homeVM.timerStatus == .hasQuit) ? 0.3 : 1.0)
                    
                    Button(action: { homeVM.toggleTimer() }) {
                        Text(homeVM.timerStatus == .running ? "Give Up" : "Start")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 40)
                            .background(homeVM.timerStatus == .running ? Color.red : Color.black)
                            .cornerRadius(20)
                    }
                    .disabled(homeVM.timerStatus == .hasWon || homeVM.timerStatus == .hasQuit)
                    
                    Button(action: { homeVM.adjustTime(amount: 5) }) {
                        Text("+5")
                            .font(.body)
                            .foregroundColor(.black)
                            .frame(width: 60, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .disabled(homeVM.timerStatus == .running || homeVM.timerStatus == .hasWon || homeVM.timerStatus == .hasQuit)
                    .opacity((homeVM.timerStatus == .running || homeVM.timerStatus == .hasWon || homeVM.timerStatus == .hasQuit) ? 0.3 : 1.0)
                }
                .padding(.bottom, 30)
            }
            
            // Win/Loss Overlay Modal dialog
            if homeVM.timerStatus == .hasWon || homeVM.timerStatus == .hasQuit {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 24) {
                    Text(homeVM.timerStatus == .hasWon ? "Focus Complete!" : "Session Aborted")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.top, 8)
                    
                    if homeVM.timerStatus == .hasWon {
                        Text("Your sprout grew successfully! You earned +\(homeVM.calculateRewardedCoin()) coins.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Text("The sprout withered. Keep trying!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        withAnimation {
                            homeVM.cleanTimerSession()
                        }
                    }) {
                        Text("Continue")
                            .font(.system(.headline, design: .default))
                            .foregroundColor(.white)
                            .frame(width: 160, height: 44)
                            .background(Color.black)
                            .cornerRadius(22)
                    }
                    .padding(.bottom, 8)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.15), radius: 20)
                .padding(.horizontal, 40)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .selectTree:
                TreeSelectionSheet(
                    homeVM: homeVM,
                    selectedDetailTree: $selectedDetailTree,
                    isPresented: Binding(
                        get: { activeSheet == .selectTree },
                        set: { if !$0 { activeSheet = nil } }
                    )
                )
            case .statistics:
                StatisticsSheet(
                    gardenVM: gardenVM,
                    onOpenMap: {
                        activeSheet = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            gardenVM.updateTreeStats()
                            activeSheet = .fullScreenGarden
                        }
                    },
                    isPresented: Binding(
                        get: { activeSheet == .statistics },
                        set: { if !$0 { activeSheet = nil } }
                    )
                )
            case .fullScreenGarden:
                FullScreenGardenSheet(
                    gardenVM: gardenVM,
                    isPresented: Binding(
                        get: { activeSheet == .fullScreenGarden },
                        set: { if !$0 { activeSheet = nil } }
                    )
                )
                .interactiveDismissDisabled()
            }
        }
    }
}

// MARK: - Tree Selection Sheet
struct TreeSelectionSheet: View {
    @ObservedObject var homeVM: HomeScreenViewModel
    @Binding var selectedDetailTree: TreeData?
    @Binding var isPresented: Bool
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if let detailTree = selectedDetailTree {
                    TreeDetailsSubView(
                        tree: detailTree,
                        homeVM: homeVM,
                        onBack: { selectedDetailTree = nil },
                        onSelect: {
                            homeVM.selectTree(detailTree)
                            selectedDetailTree = nil
                            isPresented = false
                        }
                    )
                } else {
                    VStack(spacing: 16) {
                        Capsule()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 40, height: 5)
                            .padding(.top, 8)
                        
                        Text("Select a Tree")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Text("Tap to plant, hold to view details")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            // Plant withered tree
                        }) {
                            Text("Plant a Withered Tree")
                                .font(.subheadline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        }
                        
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(homeVM.treeArray) { tree in
                                    VStack(spacing: 8) {
                                        Image("\(tree.id)_0_grid")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 80, height: 80)
                                        
                                        Text(tree.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        homeVM.selectTree(tree)
                                        isPresented = false
                                    }
                                    .onLongPressGesture {
                                        selectedDetailTree = tree
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Tree Details Sub-view
struct TreeDetailsSubView: View {
    let tree: TreeData
    @ObservedObject var homeVM: HomeScreenViewModel
    var onBack: () -> Void
    var onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button(action: onBack) {
                Text("Go Back")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
            }
            .padding(.top, 16)
            
            HStack(spacing: 20) {
                Image("\(tree.id)_0_grid")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(tree.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text("By \(tree.creator)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tree.description)
                    .font(.body)
                    .foregroundColor(.black)
            }
            
            Text("Tree Variants")
                .font(.headline)
                .foregroundColor(.black)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<tree.variants, id: \.self) { vIdx in
                        VStack(spacing: 4) {
                            Image("\(tree.id)_\(vIdx)_grid")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                            .padding(4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            Text("#\(vIdx + 1)")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                // Link out to donate
            }) {
                Text("Donate tree creator")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
            
            Button(action: onSelect) {
                Text("Select This Tree")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

// MARK: - Statistics Sheet (Equivalent to KMP GardenScreen)
struct StatisticsSheet: View {
    @ObservedObject var gardenVM: GardenViewModel
    var onOpenMap: () -> Void
    @Binding var isPresented: Bool
    
    @State private var selectedFocusBarIndex: Int? = nil
    @State private var selectedProdBarIndex: Int? = nil
    
    let focusData = [10, 30, 20, 90, 15, 40, 75]
    let prodData = [5, 12, 10, 45, 80, 50, 35, 70, 15, 25]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header isometric preview Box (tappable to open map)
                    Button(action: {
                        isPresented = false
                        onOpenMap()
                    }) {
                        VStack {
                            IsometricForestView(pngList: gardenVM.pngTreeList)
                                .frame(height: 180)
                                .background(Color(red: 0.15, green: 0.15, blue: 0.17))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.2), radius: 10)
                            
                            Text("Tap to view full screen garden")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Month Navigation Selector
                    HStack {
                        Button(action: { gardenVM.changeMonth(by: -1) }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text(gardenVM.selectedMonthName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { gardenVM.changeMonth(by: 1) }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Key Metrics
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("● Total Focus")
                                .font(.caption).foregroundColor(.gray)
                            Text("\(gardenVM.totalFocus) mins")
                                .font(.title3).bold()
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(red: 0.15, green: 0.15, blue: 0.17))
                        .cornerRadius(15)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("● Current Streak")
                                .font(.caption).foregroundColor(.gray)
                            Text("\(gardenVM.streak) days")
                                .font(.title3).bold()
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(red: 0.15, green: 0.15, blue: 0.17))
                        .cornerRadius(15)
                    }
                    
                    // Focus Health (Efficiency Donut Chart)
                    EfficiencyDonutChartView(stats: gardenVM.stats)
                    
                    // Focus History Bar Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Focus History")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Last 7 sessions by duration (minutes)")
                            .font(.caption).foregroundColor(.gray)
                        
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(0..<focusData.count, id: \.self) { idx in
                                let val = focusData[idx]
                                let isSelected = selectedFocusBarIndex == idx
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isSelected ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 20, height: CGFloat(val))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.white, lineWidth: isSelected ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        if selectedFocusBarIndex == idx {
                                            selectedFocusBarIndex = nil
                                        } else {
                                            selectedFocusBarIndex = idx
                                        }
                                    }
                            }
                        }
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.15, green: 0.15, blue: 0.17))
                        .cornerRadius(15)
                    }
                    
                    // Peak Productivity Bar Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Peak Productivity")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(alignment: .bottom, spacing: 6) {
                            ForEach(0..<prodData.count, id: \.self) { idx in
                                let val = prodData[idx]
                                let isSelected = selectedProdBarIndex == idx
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(isSelected ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 14, height: CGFloat(val))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 2)
                                            .stroke(Color.white, lineWidth: isSelected ? 1.5 : 0)
                                    )
                                    .onTapGesture {
                                        if selectedProdBarIndex == idx {
                                            selectedProdBarIndex = nil
                                        } else {
                                            selectedProdBarIndex = idx
                                        }
                                    }
                            }
                        }
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.15, green: 0.15, blue: 0.17))
                        .cornerRadius(15)
                    }
                }
                .padding()
            }
            .navigationBarTitle("Trease", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                isPresented = false
            }.foregroundColor(.white))
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Full Screen Garden (Equivalent to KMP FullScreenGarden)
struct FullScreenGardenSheet: View {
    @ObservedObject var gardenVM: GardenViewModel
    @Binding var isPresented: Bool
    
    // Zoom and pan gestures variables
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // HUD visibility states
    @State private var showTopRight = true
    @State private var showBottomLeft = true
    @State private var showBottomRight = true
    
    var body: some View {
        ZStack {
            // Isometric Canvas
            GeometryReader { geo in
                IsometricForestView(pngList: gardenVM.pngTreeList)
                    .frame(width: 1200, height: 1200)
                    .contentShape(Rectangle())
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = max(0.5, min(4.0, lastScale * value))
                            }
                            .onEnded { _ in
                                lastScale = scale
                            }
                    )
            }
            .ignoresSafeArea()
            
            // HUD overlay widgets
            VStack {
                // Top HUD row
                HStack(alignment: .top) {
                    // Top-Left: Mini Month Selector
                    GlassHudWidget(onClose: nil) {
                        HStack(spacing: 8) {
                            Button(action: { gardenVM.changeMonth(by: -1) }) {
                                Image(systemName: "chevron.left").font(.caption).foregroundColor(.black)
                            }
                            Text(gardenVM.selectedMonthYearLabel)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                            Button(action: { gardenVM.changeMonth(by: 1) }) {
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(.black)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Top-Right: Mini Resource Counters
                    if showTopRight {
                        GlassHudWidget(onClose: { showTopRight = false }) {
                            HStack(spacing: 12) {
                                VStack(alignment: .trailing) {
                                    Text("\(gardenVM.totalFocus)")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("min")
                                        .font(.system(size: 8))
                                        .foregroundColor(.green)
                                }
                                Rectangle()
                                    .fill(Color.black.opacity(0.1))
                                    .frame(width: 1, height: 16)
                                VStack(alignment: .trailing) {
                                    Text("\(gardenVM.streak)")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("streak")
                                        .font(.system(size: 8))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Bottom HUD row
                HStack(alignment: .bottom) {
                    // Bottom-Left: Mini Weekly Activity
                    if showBottomLeft {
                        GlassHudWidget(onClose: { showBottomLeft = false }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Weekly").font(.system(size: 9)).foregroundColor(.gray)
                                HStack(alignment: .bottom, spacing: 4) {
                                    ForEach([5, 12, 8, 24, 15, 20, 18], id: \.self) { val in
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(Color.black)
                                            .frame(width: 6, height: CGFloat(val * 2))
                                    }
                                }
                            }
                            .frame(width: 100, height: 60)
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom-Right: Mini Hourly Focus
                    if showBottomRight {
                        GlassHudWidget(onClose: { showBottomRight = false }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hourly").font(.system(size: 9)).foregroundColor(.gray)
                                HStack(alignment: .bottom, spacing: 3) {
                                    ForEach([4, 8, 15, 30, 20, 25, 10, 18], id: \.self) { val in
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(Color.black)
                                            .frame(width: 5, height: CGFloat(val * 2))
                                    }
                                }
                            }
                            .frame(width: 100, height: 60)
                        }
                    }
                }
            }
            .padding()
            
            // X Dismiss overlay at top
            VStack {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.black.opacity(0.8))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - Glass HUD Widget Helper
struct GlassHudWidget<Content: View>: View {
    var onClose: (() -> Void)? = nil
    let content: () -> Content
    
    init(onClose: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.onClose = onClose
        self.content = content
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            content()
                .padding(10)
                .background(Color.white.opacity(0.75))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
            
            if let closeAction = onClose {
                Button(action: closeAction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Color.red.opacity(0.8))
                        .clipShape(Circle())
                }
                .offset(x: 4, y: -4)
            }
        }
    }
}

// MARK: - Isometric Forest View
struct IsometricForestView: View {
    let pngList: [String]
    
    @State private var images: [String: UIImage] = [:]
    @State private var isLoading = false
    
    let scale: CGFloat = 2.0
    let tileWidth: CGFloat = 100.0 * 2.0
    let tileHeight: CGFloat = (100.0 * 2.0) / 2.0
    let sourceAnchorYOffset: CGFloat = (150.0 * 2.0) + ((100.0 * 2.0) / 4.0)
    
    var body: some View {
        GeometryReader { geo in
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if pngList.isEmpty {
                VStack {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow.opacity(0.6))
                    Text("Your forest is currently empty")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let placements = calculatePlacements(containerSize: geo.size)
                
                ZStack {
                    ForEach(placements, id: \.id) { placement in
                        if let uiImage = images[placement.filename] {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: uiImage.size.width / 2.0, height: uiImage.size.height / 2.0)
                                .position(x: placement.drawX, y: placement.drawY)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .onAppear {
            loadImages()
        }
        .onChange(of: pngList) { oldValue, newValue in
            loadImages()
        }
    }
    
    struct PlacedTree: Identifiable {
        let id: String
        let filename: String
        let drawX: CGFloat
        let drawY: CGFloat
        let depth: Int
    }
    
    private func calculatePlacements(containerSize: CGSize) -> [PlacedTree] {
        guard !pngList.isEmpty else { return [] }
        
        let gridSize = Int(ceil(sqrt(Double(pngList.count))))
        let isoWidth = CGFloat(gridSize * 2) * (tileWidth / 2.0)
        let isoHeight = CGFloat(gridSize) * tileHeight
        
        let totalWidth = isoWidth + (tileWidth * 2.0)
        let totalHeight = isoHeight + (sourceAnchorYOffset * 2.0)
        
        let originX = totalWidth / 2.0
        let originY = 150.0 * scale
        
        var placements: [PlacedTree] = []
        
        for (index, filename) in pngList.enumerated() {
            let gridX = index % gridSize
            let gridY = index / gridSize
            
            let isoX = CGFloat(gridX - gridY) * (tileWidth / 2.0)
            let isoY = CGFloat(gridX + gridY) * (tileWidth / 4.0)
            
            let targetX = originX + isoX
            let targetY = originY + isoY + (tileWidth / 4.0)
            
            let uiImage = images[filename]
            let sourceAnchorX = (uiImage?.size.width ?? 0) / 4.0
            let sourceAnchorY = sourceAnchorYOffset / 2.0
            
            placements.append(PlacedTree(
                id: "\(index)-\(filename)",
                filename: filename,
                drawX: targetX - sourceAnchorX,
                drawY: targetY - sourceAnchorY,
                depth: gridX + gridY
            ))
        }
        
        placements.sort { (a, b) -> Bool in
            if a.depth != b.depth {
                return a.depth < b.depth
            }
            return a.drawX < b.drawX
        }
        
        let scaleX = containerSize.width / totalWidth
        let scaleY = containerSize.height / totalHeight
        let finalScale = min(scaleX, scaleY)
        
        let usedWidth = totalWidth * finalScale
        let usedHeight = totalHeight * finalScale
        
        let translateX = (containerSize.width - usedWidth) / 2.0
        let translateY = (containerSize.height - usedHeight) / 2.0
        
        return placements.map { placement in
            PlacedTree(
                id: placement.id,
                filename: placement.filename,
                drawX: (placement.drawX * finalScale) + translateX,
                drawY: (placement.drawY * finalScale) + translateY,
                depth: placement.depth
            )
        }
    }
    
    private func loadImages() {
        isLoading = true
        var loadedImages: [String: UIImage] = [:]
        
        for filename in pngList {
            let cleanName = filename.replacingOccurrences(of: ".png", with: "")
            if let uiImage = UIImage(named: cleanName) {
                loadedImages[filename] = uiImage
            }
        }
        
        self.images = loadedImages
        self.isLoading = false
    }
}

// MARK: - Efficiency Donut Chart
struct EfficiencyDonutChartView: View {
    let stats: [FocusStats]
    
    var body: some View {
        let total = stats.count
        let failed = stats.filter { $0.isFailed }.count
        let success = total - failed
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Health")
                .font(.headline)
                .foregroundColor(.white)
            
            if total == 0 {
                HStack {
                    Spacer()
                    Text("Start planting to see health")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 20)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.15, green: 0.15, blue: 0.17))
                .cornerRadius(15)
            } else {
                HStack(spacing: 24) {
                    ZStack {
                        // Empty background ring
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 12)
                            .frame(width: 100, height: 100)
                        
                        // Success percentage arc
                        Circle()
                            .trim(from: 0.0, to: CGFloat(success) / CGFloat(total))
                            .stroke(
                                Color.green,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int((Double(success) / Double(total)) * 100))%")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 10)
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                            Text("Thriving (\(success))")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                            Text("Withered (\(failed))")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                }
                .padding()
                .background(Color(red: 0.15, green: 0.15, blue: 0.17))
                .cornerRadius(15)
            }
        }
    }
}
