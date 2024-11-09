import XCTest
@testable import CryptoFeed

final class CoinFeedViewModelTests: XCTestCase {
    
    var viewModel: CoinFeedViewModel!
    var mockAPI: MockMainAPI!
    var mockSocketAPI: MockSocketAPI!
    var mockRestAPI: MockRestAPI!
    let initialCoins = [
        Coin(id: "bitcoin",
             symbol: "BTC",
             image: "",
             marketCap: 2222,
             volume: 3333,
             prices: [CoinPrice(platformName: Strings.platform.cg, symbol: "BTC", price: 69999)]),
        Coin(id: "ethereum",
             symbol: "ETH",
             image: "",
             marketCap: 2222,
             volume: 3333,
             prices: [CoinPrice(platformName: Strings.platform.cg, symbol: "ETH", price: 2777)])]
    
    override func setUp() {
        super.setUp()
        
        mockAPI = MockMainAPI()
        mockSocketAPI = MockSocketAPI()
        mockRestAPI = MockRestAPI()
        
        viewModel = CoinFeedViewModel()
        viewModel.api = mockAPI
        viewModel.socketAPIs = [mockSocketAPI]
        viewModel.restAPIs = [mockRestAPI]
    }
    
    override func tearDown() {
        viewModel = nil
        mockAPI = nil
        mockSocketAPI = nil
        mockRestAPI = nil
        
        super.tearDown()
    }
    
    func testSetupConnectsToSocketAPIs() {
        // When
        viewModel.setup()
        
        // Then
        XCTAssertTrue(mockSocketAPI.didConnect, "Socket API should connect during setup")
    }
    
    func testLoadCoinsFetchesDataSuccessfully() async {
        // Given
        let mockOtherRestAPI = MockRestAPI()
        viewModel.restAPIs = [mockRestAPI, mockOtherRestAPI]
        mockAPI.stubbedCoins = initialCoins
        mockRestAPI.stubbedPrices = [
            "BTC": CoinPrice(platformName: Strings.platform.cmc, symbol: "BTC", price: 50000),
            "ETH": CoinPrice(platformName: Strings.platform.cmc, symbol: "ETH", price: 3000)]
        mockOtherRestAPI.stubbedPrices = [
            "BTC": CoinPrice(platformName: "FX", symbol: "BTC", price: 55555),
            "ETH": CoinPrice(platformName: "FX", symbol: "ETH", price: 2555)]
        
        // When
        do {
            try await viewModel.loadCoins()
        } catch {
            XCTFail("loadCoins threw an unexpected error: \(error)")
        }
        
        // Then
        XCTAssertEqual(viewModel.coins.count, 2, "ViewModel should have fetched and stored two coins")
        XCTAssertEqual(viewModel.coins.first?.prices.count, 3, "ViewModel should combine prices from all platforms")
        XCTAssertTrue(viewModel.loadedData, "ViewModel should have set loadedData to true after loading")
        XCTAssertFalse(viewModel.loadingData, "ViewModel should have set loadingData to false after loading")
        XCTAssertEqual(mockSocketAPI.subscribedSymbols, ["BTC", "ETH"], "Socket API should have subscribed to the correct symbols")
    }
    
    func testLoadCoinsCorrectlyLoadsNewCoins() async {
        // Given
        let mockOtherRestAPI = MockRestAPI()
        viewModel.restAPIs = [mockRestAPI, mockOtherRestAPI]
        mockAPI.stubbedCoins = initialCoins
        mockRestAPI.stubbedPrices = [
            "BTC": CoinPrice(platformName: Strings.platform.cmc, symbol: "BTC", price: 50000),
            "ETH": CoinPrice(platformName: Strings.platform.cmc, symbol: "ETH", price: 3000)]
        mockOtherRestAPI.stubbedPrices = [
            "BTC": CoinPrice(platformName: "FX", symbol: "BTC", price: 55555),
            "ETH": CoinPrice(platformName: "FX", symbol: "ETH", price: 2555)]
        do {
            try await viewModel.loadCoins() // loading first page
        } catch {
            XCTFail("loadCoins threw an unexpected error: \(error)")
        }
        mockAPI.stubbedCoins = [
            Coin(id: "dogecoin",
                 symbol: "DOGE",
                 image: "",
                 marketCap: 2222,
                 volume: 3333,
                 prices: [CoinPrice(platformName: Strings.platform.cg, symbol: "DOGE", price: 69999)]),
            Coin(id: "ripple",
                 symbol: "XRP",
                 image: "",
                 marketCap: 2222,
                 volume: 3333,
                 prices: [CoinPrice(platformName: Strings.platform.cg, symbol: "XRP", price: 2777)])]
        
        // When
        do {
            try await viewModel.loadCoins() // loading second page
        } catch {
            XCTFail("loadCoins threw an unexpected error: \(error)")
        }
        
        // Then
        XCTAssertEqual(viewModel.coins.count, 4, "ViewModel should have fetched and stored two coins")
        XCTAssertEqual(viewModel.coins.first?.prices.count, 3, "ViewModel should combine prices from all platforms")
        XCTAssertTrue(viewModel.loadedData, "ViewModel should have set loadedData to true after loading")
        XCTAssertFalse(viewModel.loadingData, "ViewModel should have set loadingData to false after loading")
        XCTAssertEqual(mockSocketAPI.subscribedSymbols, ["BTC", "ETH", "DOGE", "XRP"], "Socket API should have subscribed to the correct symbols")
    }
    
    func testCoinUpdatesOnSocketAPIsOnUpdate() async {
        // Given
        let coins = [
            Coin(id: "bitcoin",
                 symbol: "BTC",
                 image: "",
                 marketCap: 2222,
                 volume: 3333,
                 prices: [])]
        mockAPI.stubbedCoins = coins
        
        // Load coins to set up initial state
        do {
            try await viewModel.loadCoins()
        } catch {
            XCTFail("loadCoins threw an unexpected error: \(error)")
        }
        
        // When
        let updatedPrice = CoinPrice(platformName: Strings.platform.okx, symbol: "BTC", price: 51000)
        mockSocketAPI.onUpdate(updatedPrice)
        sleep(1) // the update happens on a separate thread, so we wait for it to complete
        
        // Then
        let updatedCoin = viewModel.coins.first { $0.symbol == "BTC" }
        XCTAssertNotNil(updatedCoin, "Updated coin should exist in the viewModel's coins array")
        XCTAssertEqual(updatedCoin?.prices.count, 1, "Coin price count should be correct")
        XCTAssertEqual(updatedCoin?.prices.last?.price, 51000, "Coin price should be updated with new price from socket API")
    }
    
    func testCoinUpdatesPriceIncreaseOnSocketAPIsOnUpdate() async {
        // Given
        let coins = [
            Coin(id: "bitcoin",
                 symbol: "BTC",
                 image: "",
                 marketCap: 2222,
                 volume: 3333,
                 prices: [.init(platformName: "OKX", symbol: "BTC", price: 40000)])]
        mockAPI.stubbedCoins = coins
        
        // Load coins to set up initial state
        do {
            try await viewModel.loadCoins()
        } catch {
            XCTFail("loadCoins threw an unexpected error: \(error)")
        }
        
        // When
        let updatedPrice = CoinPrice(platformName: Strings.platform.okx, symbol: "BTC", price: 51000)
        mockSocketAPI.onUpdate(updatedPrice)
        sleep(1) // the update happens on a separate thread, so we wait for it to complete
        
        // Then
        let updatedCoin = viewModel.coins.first { $0.symbol == "BTC" }
        XCTAssertNotNil(updatedCoin, "Updated coin should exist in the viewModel's coins array")
        XCTAssertEqual(updatedCoin?.prices.last?.price, 51000, "Coin price should be updated with new price from socket API")
        XCTAssertEqual(updatedCoin?.prices.count, 1, "Coin price count should remain the same")
        XCTAssertEqual(updatedCoin?.prices.last?.change, .increase, "Coin price change should show increase")
    }
    
    func testCoinUpdatesPriceDecreaseOnSocketAPIsOnUpdate() async {
        // Given
        let coins = [
            Coin(id: "bitcoin",
                 symbol: "BTC",
                 image: "",
                 marketCap: 2222,
                 volume: 3333,
                 prices: [.init(platformName: Strings.platform.okx, symbol: "BTC", price: 40000)])]
        mockAPI.stubbedCoins = coins
        
        // Load coins to set up initial state
        do {
            try await viewModel.loadCoins()
        } catch {
            XCTFail("loadCoins threw an unexpected error: \(error)")
        }
        
        // When
        let updatedPrice = CoinPrice(platformName: Strings.platform.okx, symbol: "BTC", price: 34000)
        mockSocketAPI.onUpdate(updatedPrice)
        sleep(1) // the update happens on a separate thread, so we wait for it to complete
        
        // Then
        let updatedCoin = viewModel.coins.first { $0.symbol == "BTC" }
        XCTAssertNotNil(updatedCoin, "Updated coin should exist in the viewModel's coins array")
        XCTAssertEqual(updatedCoin?.prices.last?.price, 34000, "Coin price should be updated with new price from socket API")
        XCTAssertEqual(updatedCoin?.prices.count, 1, "Coin price count should remain the same")
        XCTAssertEqual(updatedCoin?.prices.last?.change, .decrease, "Coin price change should show increase")
    }
    
    func testLoadCoinsHandlesErrorsGracefully() async {
        // Given
        mockAPI.shouldFail = true
        
        // When
        do {
            try await viewModel.loadCoins()
        } catch {
            // Expected error
        }
        
        // Then
        XCTAssertTrue(viewModel.coins.isEmpty, "ViewModel should not have any coins on error")
        XCTAssertFalse(viewModel.loadingData, "ViewModel should have set loadingData to false even on error")
    }
}
