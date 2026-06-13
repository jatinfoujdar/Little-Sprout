import Foundation
import Combine

class HomeScreenViewModel: ObservableObject {
    private var timer: Timer?
    
    @Published var selectedMinutes: Int = 2
    @Published var remainingSeconds: Double = 2 * 60
    @Published var timerStatus: TimerStatus = .idle
    @Published var progress: Double = 1.0
    
    @Published var coins: Int = 0
    @Published var selectedTree: TreeData = TreeData(
        id: "tree",
        name: "Tree",
        description: "A generic tree.",
        creator: "Nethical",
        donate: "https://digipaws.life/donate",
        variants: 10,
        basePrice: 0,
        isGrowable: true
    )
    
    @Published var currentTreeSeedVariant: Int = 0
    @Published var treeList: [String: TreeData] = [:]
    @Published var treeArray: [TreeData] = []
    @Published var purchasedTrees: [String] = ["tree"]
    
    private var initialSecondsAtStart: Double = 2 * 60
    
    init() {
        self.coins = StorageManager.shared.getCoins()
        self.purchasedTrees = StorageManager.shared.getPurchasedTrees()
        loadLocalTrees()
        Task {
            await fetchTrees()
        }
    }
    
    func loadLocalTrees() {
        let cached = StorageManager.shared.getCachedTrees()
        if !cached.isEmpty {
            self.treeArray = cached
            self.treeList = Dictionary(uniqueKeysWithValues: cached.map { ($0.id, $0) })
            if let firstTree = cached.first {
                self.selectedTree = firstTree
            }
        }
    }
    
    func fetchTrees() async {
        do {
            let fetched = try await TreeRepository.shared.fetchTrees()
            let varArray = fetched
            DispatchQueue.main.async {
                self.treeArray = varArray
                self.treeList = Dictionary(uniqueKeysWithValues: varArray.map { ($0.id, $0) })
                if let firstTree = varArray.first {
                    self.selectedTree = firstTree
                }
            }
        } catch {
            print("Failed to fetch trees from CDN: \(error)")
        }
    }
    
    func adjustTime(amount: Int) {
        guard timerStatus != .running else { return }
        timerStatus = .idle
        let newMinutes = max(1, min(120, selectedMinutes + amount))
        selectedMinutes = newMinutes
        remainingSeconds = Double(newMinutes * 60)
        progress = 1.0
    }
    
    func selectTree(_ tree: TreeData) {
        guard timerStatus != .running else { return }
        timerStatus = .idle
        selectedTree = tree
        currentTreeSeedVariant = 0
    }
    
    func toggleTimer() {
        if timerStatus != .running {
            startTimer()
        } else {
            timerStatus = .hasQuit
            stopTimer()
        }
    }
    
    private func startTimer() {
        reSelectSeed()
        timerStatus = .running
        initialSecondsAtStart = remainingSeconds
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
                self.progress = self.remainingSeconds / self.initialSecondsAtStart
            } else {
                self.timerStatus = .hasWon
                self.stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        
        // Save focus stats
        let isFailed = timerStatus == .hasQuit
        let stat = FocusStats(
            duration: Double(selectedMinutes * 60) - remainingSeconds,
            treeId: selectedTree.id,
            isFailed: isFailed,
            failureTree: "weathered_0",
            completedOn: Date().timeIntervalSince1970 * 1000,
            treeSeed: currentTreeSeedVariant
        )
        StorageManager.shared.injectStat(stat)
        
        if !isFailed {
            let earnedCoins = calculateRewardedCoin()
            StorageManager.shared.addCoins(earnedCoins)
            coins = StorageManager.shared.getCoins()
        }
    }
    
    func useCoins(value: Int) -> Bool {
        let current = StorageManager.shared.getCoins()
        if current >= value {
            StorageManager.shared.removeCoins(value)
            coins = StorageManager.shared.getCoins()
            return true
        }
        return false
    }
    
    func cleanTimerSession() {
        timerStatus = .idle
        remainingSeconds = Double(selectedMinutes * 60)
        progress = 1.0
    }
    
    func formatTime(seconds: Double) -> String {
        let totalSecs = Int(seconds)
        let m = totalSecs / 60
        let s = totalSecs % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    func calculateRarity() -> Bool {
        return currentTreeSeedVariant == (selectedTree.variants - 1)
    }
    
    func calculateRewardedCoin() -> Int {
        let multiplier = calculateRarity() ? 2 : 1
        return selectedMinutes * multiplier
    }
    
    private func reSelectSeed() {
        let variants = selectedTree.variants
        let bias = calculateBias(Double(selectedMinutes))
        currentTreeSeedVariant = randomBiased(y: variants, bias: bias)
    }
    
    private func calculateBias(_ currentDurationMins: Double) -> Double {
        let todayStats = getTodayStats()
        if todayStats.isEmpty { return 1.0 }
        
        let totalSessions = Double(todayStats.count)
        let successfulSessions = Double(todayStats.filter { !$0.isFailed }.count)
        let failedSessions = totalSessions - successfulSessions
        
        let focusBias = min(4.0, log2(currentDurationMins + 1.0))
        let successRatio = successfulSessions / totalSessions
        let failurePenalty = failedSessions * 0.3
        
        let rawBias = 1.0 - ((focusBias * 0.15) + (successRatio * 0.4) - (failurePenalty * 0.1))
        return max(0.3, min(1.0, rawBias))
    }
    
    private func getTodayStats() -> [FocusStats] {
        let allStats = StorageManager.shared.getStats()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date()).timeIntervalSince1970 * 1000
        return allStats.filter { $0.completedOn >= startOfToday }
    }
    
    private func randomBiased(y: Int, bias: Double) -> Int {
        guard y > 0 else { return 0 }
        let r = Double.random(in: 0..<1.0)
        let biased = pow(r, bias)
        return max(0, min(Int(biased * Double(y)), y - 1))
    }
    
    func buyTree(_ tree: TreeData) -> Bool {
        let current = StorageManager.shared.getCoins()
        if current >= tree.basePrice {
            StorageManager.shared.removeCoins(tree.basePrice)
            StorageManager.shared.purchaseTree(treeId: tree.id)
            self.coins = StorageManager.shared.getCoins()
            self.purchasedTrees = StorageManager.shared.getPurchasedTrees()
            return true
        }
        return false
    }
}
