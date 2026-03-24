import XCTest
@testable import SurpriseApp

final class FeedViewModelTests: XCTestCase {
    
    func testLoadInitialLoadsGifts() async {
        let viewModel = FeedViewModel(giftService: MockGiftService())
        
        let expectation = expectation(description: "state updated")
        viewModel.onStateChanged = {
            if !viewModel.isLoading {
                expectation.fulfill()
            }
        }
        
        viewModel.loadInitial()
        
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertFalse(viewModel.gifts.isEmpty)
    }
}

