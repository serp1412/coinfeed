import XCTest
@testable import CryptoFeed

final class CoinCardViewModelTests: XCTestCase {
    
    var viewModel: CoinCardViewModel!
    var mockRestAPI1: MockRestAPI!
    var mockRestAPI2: MockRestAPI!
    
    override func setUp() {
        super.setUp()
        viewModel = CoinCardViewModel()
        
        mockRestAPI1 = MockRestAPI()
        mockRestAPI2 = MockRestAPI()
        
        viewModel.restAPIs = [mockRestAPI1, mockRestAPI2]
    }
    
    override func tearDown() {
        viewModel = nil
        mockRestAPI1 = nil
        mockRestAPI2 = nil
        
        super.tearDown()
    }
    
    func testUpdatePricesSuccessfullyUpdatesCoin() async {
        // Given
        let originalCoin = Coin(id: "bitcoin",
                                symbol: "BTC",
                                image: "",
                                marketCap: 2222,
                                volume: 3333,
                                prices: [])
        let newPrice1 = CoinPrice(platformName: "API1", symbol: "BTC", price: 45000)
        let newPrice2 = CoinPrice(platformName: "API2", symbol: "BTC", price: 46000)
        mockRestAPI1.stubbedPrice = newPrice1
        mockRestAPI2.stubbedPrice = newPrice2
        
        // When
        let updatedCoin = await viewModel.updatePrices(for: originalCoin)
        sleep(2)
        
        // Then
        XCTAssertTrue(updatedCoin.prices.contains(where: { $0.platformName == "API1" && $0.price == 45000 }), "Coin should be updated with price from API1")
        XCTAssertTrue(updatedCoin.prices.contains(where: { $0.platformName == "API2" && $0.price == 46000 }), "Coin should be updated with price from API2")
    }
    
    func testUpdatePricesHandlesFailedRequestsGracefully() async {
        // Given
        let originalCoin = Coin(id: "bitcoin",
                                symbol: "BTC",
                                image: "",
                                marketCap: 2222,
                                volume: 3333,
                                prices: [])
        let newPrice = CoinPrice(platformName: "API1", symbol: "BTC", price: 45000)
        mockRestAPI1.stubbedPrice = newPrice
        mockRestAPI2.shouldFail = true // Simulate a failure
        
        // When
        let updatedCoin = await viewModel.updatePrices(for: originalCoin)
        
        // Then
        XCTAssertTrue(updatedCoin.prices.contains(where: { $0.platformName == "API1" && $0.price == 45000 }), "Coin should be updated with price from API1")
        XCTAssertFalse(updatedCoin.prices.contains(where: { $0.platformName == "API2" }), "Coin should not contain price from API2 due to failure")
    }
}
